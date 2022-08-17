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

      my $action = $action || config()<projects><$.crompt-project><action>;
      my $options = config()<projects><$.crompt-project><tomtit_options> || "--verbose";
      my $log-file = "{$*CWD}/job.log"
      my $status-file = "{$*CWD}/job.status.log"

      my $j = Sparky::JobApi.new( mine => True );

      my $vars = $j.get-stash();

      my %envvars = $vars || config()<projects><$.crompt-project><vars> || {};

      bash(qq:to/HERE/, cwd => config()<projects><$.crompt-project><path>, envvars => %envvars );
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


