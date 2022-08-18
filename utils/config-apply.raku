use YAMLish;

my $conf-file = "{%*ENV<HOME>}/cromtit.yaml";

if $conf-file.IO ~~ :e {
  say "load conf from file $conf-file  ...";
  my %conf = load-yaml($conf-file.IO.slurp);
} else {
  say "conf file $conf-file doesn't exist, exiting ..."
}
