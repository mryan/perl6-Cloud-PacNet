use v6;
use Test;
use Test::When <author>;
use lib 'lib';

plan 1;

require Test::META <&meta-ok>;
meta-ok();
