use v6.c ;
use Test ;
use lib 'lib' ;
use lib 't/lib' ;
use Fake::HTTPua ;
use Cloud::PacNet :pn-get ;

my $token = 'secret-bizzo' ;
my $HUA-Class = Fake::HTTPua ;

plan 3;

my $first_query = pn-get(:endpoint<first>, :$token :$HUA-Class);
is($first_query, '{ "local": "file" }' ~ "\n", "Local testing scafold using local file results" );

subtest 'Simple get query' => {
    plan 2 ;
    my $second_query = pn-get(:endpoint<second>, :$token, :$HUA-Class, :perl6);
    isa-ok $second_query         , Hash  , "Second query returned a hash" ;
    is     $second_query<result> , "OK2" , "Second query had the right content" ;
}

subtest 'Emulated get /plans' => {
    plan 8 ;
    my $third_query = pn-get(:endpoint<third/plans>, :$token, :$HUA-Class, :perl6);
    isa-ok  $third_query , Hash , "Third query returned a hash" ;
    my $plans := $third_query<plans> ;
    isa-ok  $plans , Array , "Third query plans is an Array" ;
    my $plan := $plans[2] ;
    isa-ok  $plan , Hash , "Third query, third plan is a Hash" ;
    my $id := $plan<id> ;
    isa-ok  $id , Str , "Third query, third plan id is a Str" ;
    is $id , '87728148-3155-4992-a730-8d1e6aca8a32' , "Third query, third plan id is correct";
    my $pricing := $plan<pricing> ;
    isa-ok  $pricing , Hash , "Third query, third plan pricing is a Hash" ;
    my $hourly := $pricing<hour> ;
    isa-ok  $hourly , Rat , "Third query, third plan hourly pricing is a Num" ;
    is $hourly , 0.000104 , "Third query, third plan hourly price is correct" ;
}
