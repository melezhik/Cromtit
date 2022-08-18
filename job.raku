use Sparky::JobApi;

class Pipeline

  does Sparky::JobApi::Role

  has Str $.crompt-project = tags()<cromt-project>;
  has Str $.action = tags()<action>;

  {

    method stage-main {

      my $j = self.new-job;
  
      $j.queue: %(
        description => "{tags()<SPARKY_PROJECT>}.run"
        tags => %(
          stage => "run"
        )
      );

      my $st = self.wait-job($j);

      die $st.perl unless $st<OK>;

    }

    method stage-run {

      my $options = config()<projects><$.crompt-project><tomtit_options> || "--verbose";

      my $action = $.action || config()<projects><$.crompt-project><action>;

      my $j = Sparky::JobApi.new( mine => True );

      my $vars = $j.get-stash();

      my $envvars = $vars || config()<projects><$.crompt-project><vars> || {};

      my $path = config()<projects><$.crompt-project><path>;

      my @jobs = self!run-job-dependency(config()<projects><$.crompt-project><before> || []);

      my $st = self.wait-jobs(@jobs);

      die $st.perl unless $st<OK>;

      self!job-run: :$action,:$options,:$envvars,:$path;

      @jobs = self!run-job-dependency(config()<projects><$.crompt-project><after> || []);

      $st = self.wait-jobs(@jobs);

      die $st.perl unless $st<OK>;

    }

    method !job-run-dependency ($jobs) {

      my @jobs;

      for $jobs -> $j {

        my $action = $.action || $j<action>;
  
        my $crompt-project = $j<name>;

        my $job = self.new-job;

        if $job<vars> {
          $job.put-stash({ vars => $j<vars> });
        }

        $job.queue: %(
          description => "{$crompt-project}.run"
          tags => %(
            stage => "run",
            crompt-project => $crompt-project,
          )
        );

        @jobs.push: $job;
      }

      return @jobs;

    }

    method !job-run (:$action,:$options,:$envvars,:$path) {

      my $log-file = "{$*CWD}/job.log"
      my $status-file = "{$*CWD}/job.status.log"

      say "job-run path={$path} action={$action} options={$options} envvars={$envvars.perl}";

      bash(qq:to/HERE/, cwd => $path, envvars => $envvars );
        tom $options $action 1>$log-file 2>$log-file
        echo \$? > $status-file
      HERE

      my $job-id = now.Int;

      mkdir "{%*ENV<HOME>}/.cromtit/reports/{$job-id}";

      say "copy report and status to {%*ENV<HOME>}/.cromtit/reports/{$job-id} ...";

      cp($log-file,"{%*ENV<HOME>}/.cromtit/reports/{$job-id}/{$log-file.IO.basename}");

      cp($status-file,"{%*ENV<HOME>}/.cromtit/reports/{$job-id}/{$status-file.IO.basename}");

    }

  }


Pipeline.new.run;


