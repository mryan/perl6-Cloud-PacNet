use v6.c;
use Test;
use Cloud::PacNet;
::Cloud::PacNet::<$Local-Testing> = True ;

plan 1;
my $first_query = pn-query(:method<get>, :endpoint<user>, :token<secret-bizzo>);
is($first_query, '{ "hello": "world" }' );

# my $second_query = pn_query(:method<get>, :endpoint<user>, :token<secret-bizzo>, :perl6);
