use Sparky::JobApi;

class Pipeline does Sparky::JobApi::Role {

  has Str $.cromt-project = tags()<cromt-project>;

  has Str $.action = tags()<action> || config()<projects>{$!cromt-project}<action> || "default";

  has Str $.options = tags()<options> || config()<projects>{$!cromt-project}<options> || "--verbose";

  has Str $.resolve-hosts = tags()<resolve-hosts> || "yes";

  has Str $.resolve-deps = tags()<resolve-deps> || "yes";

  has Str $.storage_project = tags()<storage_project> || "";

  has Str $.storage_job_id = tags()<storage_job_id> || "";

  has Str $.storage_api = config()<storage> || "http://127.0.0.1:4000";

  has Hash $.sparrowdo = config()<projects>{$!cromt-project}<sparrowdo> || {};

    method stage-main {

      my $j = self.new-job;

      my $storage = self.new-job: api => $.storage_api;  

      my %storage = $storage.info();

      $j.queue: %(
        description => "{tags()<SPARKY_PROJECT>} [job run]",
        tags => %(
          stage => "run",
          cromt-project => $.cromt-project,
          action => $.action,
          options => $.options,
          storage_project => %storage<project>,
          storage_job_id => %storage<job-id>,
        ),
        sparrowdo => $.sparrowdo
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

      if $.resolve-deps eq "yes" and config()<projects>{$.cromt-project}<before> {

        my @jobs = self!run-job-dependency(config()<projects>{$.cromt-project}<before>);

        say "waiting for dependencies jobs have finsihed ...";

        my $st = self.wait-jobs(@jobs);

        die $st.perl unless $st<OK>;

      }

      if $.resolve-hosts eq "yes" && config()<projects>{$.cromt-project}<hosts><> {

          my @jobs;

          say "stage-run - handle hosts: ", config()<projects>{$.cromt-project}<hosts><>.perl;

          for config()<projects>{$.cromt-project}<hosts><> -> $host {

            my $api = $host<url>;

            my $job = $host<queue-id> ?? self.new-job: :$api !! self.new-job: :$api, :project{$host<queue-id>};

            say "trigger job on host: {$api}";

            if $host<vars> {
              say "save job vars ...";    
              $job.put-stash({ vars => $host<vars> });
            } else {
              say "save job vars ...";    
              $job.put-stash({ vars => $envvars });
            }

            if $host<vars> {
              say "save job vars ...";    
              $job.put-stash({ vars => $host<vars> });
            } else {
              say "save job vars ...";    
              $job.put-stash({ vars => $envvars });
            }

            $job.queue: %(
              description => "(h) {$.cromt-project} [job run]",
              tags => %(
                stage => "run",
                cromt-project => $.cromt-project,
                action => $action,
                options => $options,
                resolve-hosts => "no",
                resolve-deps => "no",
                storage_project => $.storage_project,
                storage_job_id => $.storage_job_id,
              ),
              sparrowdo => $host<sparrowdo> || $.sparrowdo
            );

            @jobs.push: $job;

          }

          say "waiting for hosts jobs have finsihed ...";

          my $st = self.wait-jobs(@jobs);

          die $st.perl unless $st<OK>;

      } else {
        self!job-run: :$action,:$options,:$envvars,:$path;
      }
 
      if $.resolve-deps eq "yes" and config()<projects>{$.cromt-project}<after> {

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

        if $.resolve-hosts eq "yes" and $j<hosts> {

          say "run-job-dependency - handle hosts: ", $j<hosts><>.perl;

          for $j<hosts><> -> $host {

            my $job;

            if $host<url> {
                my $api = $host<url>;
                $job = $host<queue-id> ?? self.new-job: :$api !! self.new-job: :$api, :project{$host<queue-id>};
                say "trigger job on host: {$api}";
            } else {
                $job = $host<queue-id> ?? self.new-job !! self.new-job: :project{$host<queue-id>};
                say "trigger job on host: localhost";
            }

            my $cp = config()<projects>{$cromt-project};

            if $host<vars> {
              say "save job vars ...";    
              $job.put-stash({ vars => $host<vars> });
            } elsif $j<vars> {
              say "save job vars ...";    
              $job.put-stash({ vars => $j<vars> });
            }

            $job.queue: %(
              description => "(dh) {$cromt-project} [job run]",
              tags => %(
                stage => "run",
                cromt-project => $cromt-project,
                action => $j<action>,
                options => $j<options>,
                resolve-hosts => "no",
                storage_project => $.storage_project,
                storage_job_id => $.storage_job_id,              
              ),
              sparrowdo => $host<sparrowdo> || $j<sparrowdo> || $cp<sparrowdo> || {},
            );

            @jobs.push: $job;

          }    
        } else {

          my $job = self.new-job;

          say "trigger job on host: localhost";

          my $cp = config()<projects>{$cromt-project};

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
              options => $j<options>,
              storage_project => $.storage_project,
              storage_job_id => $.storage_job_id,
            ),
            sparrowdo => $j<sparrowdo> || $cp<sparrowdo> || {}
          );

          @jobs.push: $job;

        }

      }

      return @jobs;

    }

    method !job-run (:$action,:$options,:$envvars,:$path) {

      my $eff-path;

      if $path ~~ /^^ 'git@' || 'https://' / {
        directory-delete "scm";
        directory "scm";
        git-scm $path, %( to => "scm" );
        $eff-path = "{$*CWD}/scm";
      } else {
        $eff-path = $path.subst(/^ '~' "/" /,"{%*ENV<HOME>}/");
      }

      my $log-file = "{$*CWD}/job.log";
      my $status-file = "{$*CWD}/job.status.log";

      directory "{$eff-path}/.artifacts";

      if config()<projects>{$.cromt-project}<artifacts> && config()<projects>{$.cromt-project}<artifacts><in> {
        my $job = self.new-job: job-id => $.storage_job_id, project => $.storage_project, api => $.storage_api;
        for config()<projects>{$.cromt-project}<artifacts><in><> -> $f {
          say "copy artifact $f from storage to {$eff-path}/.artifacts/";
          "{$eff-path}/.artifacts/{$f}".IO.spurt($job.get-file($f),:bin);
        }
      } 

      for $action.split(/\s+/) -> $act {  

        say ">> run job path={$path} action={$act} options={$options} envvars={$envvars.perl}";
        
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

      if config()<projects>{$.cromt-project}<artifacts> && config()<projects>{$.cromt-project}<artifacts><out> {
        my $job = self.new-job: job-id => $.storage_job_id, project => $.storage_project, api => $.storage_api;
        for config()<projects>{$.cromt-project}<artifacts><out><> -> $f {
          say "copy artifact {$f<file>} to storage";
          $job.put-file("{$eff-path}/{$f<path>}",$f<file>);
        }
      } 

    }

  }


Pipeline.new.run;


