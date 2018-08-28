use v6.c ;
use Test ;
use lib 'lib' ;
use Cloud::PacNet ;

my $token = 'secret-bizzo' ;
::Cloud::PacNet::<$Local-Testing> = True ;

plan 3;

my $connection = Cloud::Pacnet.new($token, :!verify);  # token compolsory first positional

   $connection.verify ;                    # calls /user, /projects, ( or use 'include' for projects) 
                                           # defines default-project

my $user-details = $connection.GET-user ;  # returns a hash
my $user-details = $connection.get-user ;

my @orgs-list := $connection.GET-organizations ;    # returns an array
my @orgs-list := $connection.get-orgs ;

my @projects-list := $connection.GET-projects ; # array of projects this users is member of
my @projects-list := $connection.get-projects ; # array of projects this users is member of

$connection.set-current-project($ID) ;    # Different concept to that of packet's "default project"
                                          # This is an attribute on the object only.
                                          # Only relevant when creating devices, not when getting them

my @devices := $connection.get-devices ;  # Works by using GET /projects - ok to not have a
                                          # set project defined
my $spot-market-info := $connection.get-market-spot-prices

my $first_query = pn-query(:method<get>, :endpoint<no-cache>, :token<TOKEN>);
is($first_query, '{ "hard": "coded" }', "Local testing scafold using hard-coded result" );

subtest 'Simple get query' => {
    plan 2 ;
    my $second_query = pn-query(:method<get>, :endpoint<second>, :$token, :perl6);
    isa-ok $second_query         , Hash  , "Second query returned a hash" ;
    is     $second_query<result> , "OK2" , "Second query had the right content" ;
}

subtest 'Emulated get /plans' => {
    plan 8 ;
    my $third_query = pn-query(:method<get>, :endpoint<plans>, :$token, :perl6);
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
