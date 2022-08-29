use Sparky::JobApi;

class Pipeline does Sparky::JobApi::Role {

  has Str $.cromt-project = tags()<cromt-project>;

  has Str $.action = tags()<action> || config()<projects>{$!cromt-project}<action> || "default";

  has Str $.options = tags()<options> || config()<projects>{$!cromt-project}<options> || "--verbose";

    method stage-main {

      my $j = self.new-job;
  
      $j.queue: %(
        description => "{tags()<SPARKY_PROJECT>} [job run]",
        tags => %(
          stage => "run",
          cromt-project => $.cromt-project,
          action => $.action,
          options => $.options,
        )
      );

      my $st = self.wait-job($j);

      die $st.perl unless $st<OK>;

    }

    method stage-run {

      my $options = $.options;

      my $action = $.action;

      my $j = Sparky::JobApi.new( mine => True );

      my $stash = $j.get-stash();

      my $envvars = $stash<vars> || config()<projects>{$.cromt-project}<vars> || {};

      my $path = config()<projects>{$.cromt-project}<path>;

      if config()<projects>{$.cromt-project}<before> {

        my @jobs = self!run-job-dependency(config()<projects>{$.cromt-project}<before>);

        say "waiting for dependencies jobs have finsihed ...";
        my $st = self.wait-jobs(@jobs);

        die $st.perl unless $st<OK>;

      }

      self!job-run: :$action,:$options,:$envvars,:$path;

      if config()<projects>{$.cromt-project}<after> {

        my @jobs = self!run-job-dependency(config()<projects>{$.cromt-project}<after>);

        say "waiting for dependencies jobs have finsihed ...";

        my $st = self.wait-jobs(@jobs);

        die $st.perl unless $st<OK>;

      }

    }

    method !run-job-dependency ($jobs) {

      my @jobs;

      for $jobs<> -> $j {
  
        my $cromt-project = $j<name>;

        if $j<hosts> {

          for $j<hosts> -> $host {

            my $api = $host<url>;

            my $job = self.new-job: :$api;

            say "trigger job on host: {$api}";

            if $host<vars> {
              say "save job vars ...";    
              $job.put-stash({ vars => $j<vars> });
            }

            $job.queue: %(
              description => "(d) {$cromt-project} [job run]",
              tags => %(
                stage => "run",
                cromt-project => $cromt-project,
                action => $j<action>,
                options => $j<options>
              )
            );

            @jobs.push: $job;

          }    
        } else {

          my $job = self.new-job;

          say "trigger job on host: localhost";

          if $j<vars> {
            say "save job vars ...";    
            $job.put-stash({ vars => $j<vars> });
          }

          $job.queue: %(
            description => "(d) {$cromt-project} [job run]",
            tags => %(
              stage => "run",
              cromt-project => $cromt-project,
              action => $j<action>,
              options => $j<options>
            )
          );

          @jobs.push: $job;

        }

      }

      return @jobs;

    }

    method !job-run (:$action,:$options,:$envvars,:$path) {

      for $action.split(/\s+/) -> $act {  

        my $log-file = "{$*CWD}/job.log";
        my $status-file = "{$*CWD}/job.status.log";
        my $effective-path = $path.subst(/^ '~' "/" /,"{%*ENV<HOME>}/");

        say ">> run job path={$path} action={$act} options={$options} envvars={$envvars.perl}";
        my $eff-path = $path;
        if $path ~~ /^^ 'git@' / {
          directory-delete "scm";
          directory "scm";
          git-scm $path, %( to => "scm" );
          $eff-path = "{$*CWD}/scm";
        }
        bash qq:to/HERE/, %( cwd => $eff-path, envvars => $envvars, description => "tomtit job"  );
          #tom $options $act 1>$log-file 2>$log-file
          #echo \$? > $status-file
          SP6_LOG_NO_TIMESTAMPS=1 tom $options $act
        HERE
        # my $job-id = now.Int;

        # mkdir "{%*ENV<HOME>}/.cromtit/reports/{$job-id}";

        # say "copy report and status to {%*ENV<HOME>}/.cromtit/reports/{$job-id} ...";

        # copy($log-file,"{%*ENV<HOME>}/.cromtit/reports/{$job-id}/{$log-file.IO.basename}");

        # copy($status-file,"{%*ENV<HOME>}/.cromtit/reports/{$job-id}/{$status-file.IO.basename}");

      }
    }

  }


Pipeline.new.run;


