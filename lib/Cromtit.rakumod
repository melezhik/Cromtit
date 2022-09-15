#!raku

use v6;

unit module Cromtit:ver<0.0.13>;

our sub job-template () is export {
  %?RESOURCES<job.raku>.Str.IO.slurp;
}

our sub sparky-template () is export {
  %?RESOURCES<sparky.yaml>.Str.IO.slurp;
}
