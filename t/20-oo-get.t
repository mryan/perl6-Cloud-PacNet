use v6.c ;
use Test ;
use lib 'lib' ;
use lib 't/lib' ;
use Fake::HTTPua ;
use Cloud::PacNet ;

plan 7 ;
my $token = 'secret-bizzo' ;
my $HUA-Class = Fake::HTTPua ;

my token lcxdigit {  <[0..9a..f]> }  # Lowercase hex digit
my token uuid     {
                    <lcxdigit> ** 8 '-'
                    [ <lcxdigit> ** 4 '-' ] ** 3
                    <lcxdigit> ** 12
                  }

my $cpn = Cloud::PacNet.new(:$token, :$HUA-Class);  # token compolsory

subtest 'Initial connection' => {
    plan 2;

    # verify-auth should result in a populated current-org
    # $cpn.verify-auth ;     
    like  $cpn.default-org.id , /^^ <uuid> $$/,  "Got an org id" ;
    
    # gist has "User Name";
    like  $cpn.gist , / 'User Name:  John Doe' /,  "Gist looks ok" ;
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

subtest 'projects' => {
    plan 11 ;

    my $projects := $cpn.GET-projects ;
    isa-ok $projects                   ,  Hash             , 'projectss returns a Hash' ;
    isa-ok $projects<projects>         ,  Array            , 'projects<projects> is an Array';
    is    +$projects<projects>         ,   1               , 'projects<projects> has 1 elem';
    isa-ok $projects<projects>[0]      ,  Hash             , 'projects<projects>[0] is a Hash';
    is     $projects<projects>[0]<name> ,  "VIRL Kickoff"  , 'projects<projects>[0]<name> is correct';
    isa-ok $projects<meta>             ,  Hash             , 'projects<meta> is a Hash';
    isa-ok $projects<meta><total>      ,   1               , 'projects<meta><total> is correct';

    $projects := $cpn.get-projects ;
    isa-ok $projects                   ,  Array            , 'projects is an Array' ;
    is    +$projects                   ,   1               , 'projects has 1 elem';
    isa-ok $projects[0]                ,  Hash             , 'projects[0] is a Hash';
    is     $projects[0]<name>          ,  "VIRL Kickoff"   , 'projects[0]<name> is correct';
}

subtest 'plans' => {
    plan 11 ;

    my $plans := $cpn.GET-plans ;
    isa-ok $plans                      ,  Hash           , 'plans returns a Hash' ;
    isa-ok $plans<plans>               ,  Array          , 'plans<plans> is an Array ' ;
    is    +$plans<plans>               ,  11             , 'plans<plans> has 11 elems';
    isa-ok $plans<plans>[1]            ,  Hash           , 'plans<plans>[1] is a Hash';
    is     $plans<plans>[1]<name>      , 'm2.xlarge.x86' , 'plans<plans>[1]<name> is correct';
    is     $plans<plans>[1]<specs><nics>[0]<type> , '10Gbps' , 'plans<plans>[1]<specs><nics>[0]<type> is correct';

    $plans := $cpn.get-plans ;
    isa-ok $plans                    ,  Array          , 'plans is an Array' ;
    is    +$plans                    ,  11             , 'plans has 11 elems';
    isa-ok $plans[10]                ,  Hash           , 'plans[10] is a Hash';
    is     $plans[10]<name>          , 'x1.small.x86'  , 'plans[10]<name> is correct';
    is     $plans[10]<specs><nics>[0]<type> , '10Gbps' , 'plans[10]<specs><nics>[0]<type> is correct';
}

subtest 'msp' => {
    plan 11 ;

    my $msp := $cpn.GET-market-spot-prices ;
    isa-ok $msp                              ,  Hash  , 'msp returns a Hash' ;
    isa-ok $msp<spot_market_prices>          ,  Hash  , 'msp<spot_market_prices> is an Hash ' ;
    is    +$msp<spot_market_prices>.keys     ,  14    , 'msp<spot_market_prices>.keys has 14 elems';
    isa-ok $msp<spot_market_prices><sjc1>    ,  Hash  , 'msp<spot_market_prices><sjc1> is a Hash';
    isa-ok $msp<spot_market_prices><sjc1><baremetal_1> , Hash , 'msp<spot_market_prices><sjc1><baremetal_1> is a Hash';
    is     $msp<spot_market_prices><sjc1><baremetal_1><price> , 4.01  , 'msp<spot_market_prices><sjc1><baremetal_1><price> is correct';

    my $spot-prices := $cpn.get-spot-prices ;
    isa-ok $spot-prices                             , Hash  , 'spot-prices returns a Hash' ;
    is    +$spot-prices.keys                        , 14    , 'spot-prices.keys has 14 elems';
    isa-ok $spot-prices<ams1>                       , Hash  , 'spot-prices<ams1> is a Hash';
    isa-ok $spot-prices<ams1><baremetal_2a2>        , Hash  , 'spot-prices<ams1><baremetal_2a2> is a Hash';
    is     $spot-prices<ams1><baremetal_2a2><price> , 5.01  , 'spot-prices<ams1><baremetal_2a2><price> is correct';
}
