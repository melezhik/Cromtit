use Sparky::JobApi;

class Pipeline

  does Sparky::JobApi::Role

  has Str $.crompt-project = tags()<cromt-project>;
  has Str $.action = tags()<action>;

  {

    method stage-main {

      my $j = self.new-job :project<cromtit.queue>;
  
      $j.queue: %(
        description => "{tags()<SPARKY_PROJECT>}.run"
        tags => %(
          stage => "run"
        )
      );

    }

    method stage-run {


      my $options = config()<projects><$.crompt-project><tomtit_options> || "--verbose";

      my $action = $.action || config()<projects><$.crompt-project><action>;

      my $j = Sparky::JobApi.new( mine => True );

      my $vars = $j.get-stash();

      my $envvars = $vars || config()<projects><$.crompt-project><vars> || {};

      my $path = config()<projects><$.crompt-project><path>;

      self!run-job-dependeny(config()<projects><$.crompt-project><before> || []);

      self!job-run: :$action,:$options,:$envvars,:$path;

      self!run-job-dependeny(config()<projects><$.crompt-project><after> || []);

    }

    method !job-run-dependency ($jobs) {

      for $jobs -> $j {

        my $action = $.action || $j<action>;
  
        my $crompt-project = $j<project>;

        my $j = self.new-job :project<cromtit.queue>;

        if $j<vars> {
          $j.put-stash({ vars => $j<vars> });
        }

        $j.queue: %(
          description => "{$crompt-project}.run"
          tags => %(
            stage => "run",
            crompt-project => $crompt-project,
          )
        );

      }

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


