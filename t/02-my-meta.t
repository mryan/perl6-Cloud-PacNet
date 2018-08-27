use v6;
# use lib 'lib';
use Test;
use Test::When <author>;

plan 1;

require Test::META <&meta-ok>;
meta-ok();
