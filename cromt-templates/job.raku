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

      my $vars = $j.get-stash();

      my $envvars = $vars || config()<projects>{$.cromt-project}<vars> || {};

      my $path = config()<projects>{$.cromt-project}<path>;

      if config()<projects>{$.cromt-project}<before> {

        my @jobs = self!run-job-dependency(config()<projects>{$.cromt-project}<before>);

        my $st = self.wait-jobs(@jobs);

        die $st.perl unless $st<OK>;

      }

      self!job-run: :$action,:$options,:$envvars,:$path;

      if config()<projects>{$.cromt-project}<after> {

        my @jobs = self!run-job-dependency(config()<projects>{$.cromt-project}<after>);

        my $st = self.wait-jobs(@jobs);

        die $st.perl unless $st<OK>;

      }

    }

    method !run-job-dependency ($jobs) {

      my @jobs;

      for $jobs<> -> $j {
  
        my $cromt-project = $j<name>;

        my $job = self.new-job;

        if $job<vars> {
          $job.put-stash({ vars => $j<vars> });
        }

        $job.queue: %(
          description => "{$cromt-project} [job prepare]",
          tags => %(
            stage => "run",
            cromt-project => $cromt-project,
            action => $j<action>,
            options => $j<options>
          )
        );

        @jobs.push: $job;
      }

      return @jobs;

    }

    method !job-run (:$action,:$options,:$envvars,:$path) {

      for $action.split(/\s+/) -> $act {  

        my $log-file = "{$*CWD}/job.log";
        my $status-file = "{$*CWD}/job.status.log";

        say "job-run path={$path} action={$act} options={$options} envvars={$envvars.perl}";

        # bash qq:to/HERE/, %( cwd => $path, envvars => $envvars );
        #   tom $options $act 1>$log-file 2>$log-file
        #   echo \$? > $status-file
        # HERE

        # my $job-id = now.Int;

        # mkdir "{%*ENV<HOME>}/.cromtit/reports/{$job-id}";

        # say "copy report and status to {%*ENV<HOME>}/.cromtit/reports/{$job-id} ...";

        # copy($log-file,"{%*ENV<HOME>}/.cromtit/reports/{$job-id}/{$log-file.IO.basename}");

        # copy($status-file,"{%*ENV<HOME>}/.cromtit/reports/{$job-id}/{$status-file.IO.basename}");

      }
    }

  }


Pipeline.new.run;


