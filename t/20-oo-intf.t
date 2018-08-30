use v6.c ;
use Test ;
use lib 'lib' ;
use lib 't/lib' ;
use Fake::HTTPua ;
use Cloud::PacNet ;

plan 4 ;
my $API-token = 'secret-bizzo' ;
my $HUA-Class = Fake::HTTPua ;

my token lcxdigit {  <[0..9a..f]> }  # Lowercase hex digit
my token uuid     {
                    <lcxdigit> ** 8 '-'
                    [ <lcxdigit> ** 4 '-' ] ** 3
                    <lcxdigit> ** 12
                  }

my $cpn = Cloud::PacNet::API.new(:$API-token, :$HUA-Class, :!verify);  # token compolsory

subtest 'Initial connection' => {
    plan 2;

    # verify-auth should result in a populated current-org
    $cpn.verify-auth ;
    like  $cpn.current-org , /^^ <uuid> $$/,  "Got an org id" ;
    
    # gist starts with "User Name";
    like  $cpn.gist , /^^  'User Name:  John Doe' /,  "Gist looks ok" ;
}

subtest 'user' => {
    plan 6 ;

    my $user-details := $cpn.GET-user ;
    isa-ok $user-details            ,  Hash             , 'user-details is a Hash' ;
    is     $user-details<full_name> , 'John Doe'        , 'full_name is correct';
    is     $user-details<email>     , 'Bogus@gmail.com' , 'email is correct';

    $user-details := $cpn.get-user ;
    isa-ok $user-details            ,  Hash             , 'user-details is a Hash' ;
    is     $user-details<full_name> , 'John Doe'        , 'full_name is correct';
    is     $user-details<email>     , 'Bogus@gmail.com' , 'email is correct';
}

subtest 'facilities' => {
    plan 11 ;

    my $facilities := $cpn.GET-facilities ;
    isa-ok $facilities                      ,  Hash  , 'facilities returns a Hash' ;
    isa-ok $facilities<facilities>          ,  Array , 'facilities<facilities> is an Array ' ;
    is    +$facilities<facilities>          ,  15    , 'facilities<facilities> has 15 elems';
    isa-ok $facilities<facilities>[2]       ,  Hash  , 'facilities<facilities>[2] is a Hash';
    is     $facilities<facilities>[2]<code> , 'atl1' , 'facilities<facilities>[2]<code> is correct';
    is     $facilities<facilities>[2]<features>[0]   , 'baremetal'  , 'facilities<facilities>[2]<features>[0] is correct';

    $facilities := $cpn.get-facilities ;
    isa-ok $facilities            ,  Array            , 'facilities is an Array' ;
    is    +$facilities            ,  15               , 'facilities has 15 elems';
    isa-ok $facilities[9]         ,  Hash             , 'facilities[9] is a Hash';
    is     $facilities[9]<name>   , 'Sydney, Australia' , 'facilities[9]<name> is correct';
    is     $facilities[9]<features>[1] , 'layer_2'    , 'facilities[9]<features>[1] is correct';
}

subtest 'organizations' => {
    plan 11 ;

    my $orgs := $cpn.GET-organizations ;
    isa-ok $orgs                   ,  Hash             , 'organizationss returns a Hash' ;
    isa-ok $orgs<organizations>    ,  Array            , 'orgs<organizations> is an Array';
    is    +$orgs<organizations>    ,   1               , 'orgs<organizations> has 1 elem';
    isa-ok $orgs<organizations>[0] ,  Hash             , 'orgs<organizations>[0] is a Hash';
    is     $orgs<organizations>[0]<name> ,  "John’s Projects"  , 'orgs<organizations>[0]<name> is correct';
    isa-ok $orgs<meta>             ,  Hash             , 'orgs<meta> is a Hash';
    isa-ok $orgs<meta><total>      ,   1               , 'orgs<meta><total> is correct';

    $orgs := $cpn.get-orgs ;
    isa-ok $orgs                   ,  Array              , 'orgs is an Array' ;
    is    +$orgs                   ,   1                 , 'orgs has 1 elem';
    isa-ok $orgs[0]                ,  Hash               , 'orgs[0] is a Hash';
    is     $orgs[0]<name>          ,  "John’s Projects"  , 'orgs[0]<name> is correct';
}
