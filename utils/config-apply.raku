use YAMLish;
use Data::Dump;

my $conf-file = "{%*ENV<HOME>}/cromtit.yaml";

my $sparky-root-dir = "{%*ENV<HOME>}/.sparky/projects";

if $conf-file.IO ~~ :e {

  say "load conf from file $conf-file  ...";

  my $conf = load-yaml($conf-file.IO.slurp);

  #say Dump($conf);

  for $conf<projects>.kv -> $p, $pd {
    say "[import project $p to sparky]";
    say "create dir $sparky-root-dir/$p";
    mkdir "$sparky-root-dir/$p";
    say "cp cromt-templates/job.raku -> $sparky-root-dir/$p/sparrowfile";
    copy "cromt-templates/job.raku", "$sparky-root-dir/$p/sparrowfile";
    say "prepare sparky.yaml ...";
    my $sparky-yaml = "cromt-templates/sparky.yaml".IO.slurp;
    $sparky-yaml.=subst("%cromt-project%",$p);
    if $pd<crontab> {
      $sparky-yaml.=subst("#%crontab%","crontab: {$pd<crontab>}") 
    }
    say "create  $sparky-root-dir/$p/sparky.yaml";
    "$sparky-root-dir/$p/sparky.yaml".IO.spurt($sparky-yaml);

    say "create  $sparky-root-dir/$p/config.pl6";
    "$sparky-root-dir/$p/config.pl6".IO.spurt($conf.perl);

  }

} else {
  say "conf file $conf-file doesn't exist, exiting ..."
}
