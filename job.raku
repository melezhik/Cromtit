use Sparky::JobApi;

class Pipeline

  does Sparky::JobApi::Role

  has Str $.crompt-project = tags()<cromt-project>;

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

      my $action = config()<projects><$.crompt-project><action>;
      my $options = config()<projects><$.crompt-project><tomtit_options> || "--verbose";
      my $log-file = "{$*CWD}/job.log"
      my $status-file = "{$*CWD}/job.status.log"

      bash(qq:to/HERE/, cwd => config()<projects><$.crompt-project><path> );
        tom $options $action 1>$log-file 2>$log-file
        echo \$? > $status-file
      HERE

    }

  }


Pipeline.new.run;


