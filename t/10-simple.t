use v6.c;
use Test;
use Cloud::PacNet;
::Cloud::PacNet::<$Local-Testing> = True ;

plan 3;

my $first_query = pn-query(:method<get>, :endpoint<no-cache>, :token<TOKEN>);
is($first_query, '{ "hard": "coded" }', "Simplest, hard-coded query" );

my $token = 'secret-bizzo' ;
my $second_query = pn-query(:method<get>, :endpoint<second>, :$token, :perl6);
isa-ok($second_query, Hash, "Second query returned a hash");
is($second_query<result>, "OK2", "Second query had the right content");
