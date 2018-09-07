use v6.c ;
use Test ;
use lib 'lib' ;
use lib 't/lib' ;
use Fake::HTTPua ;
use Cloud::PacNet ;
use Data::Dump::Tree ;

plan 3 ;

my $API-token = 'secret-bizzo' ;
# my $API-token = %*ENV<PN_TOKEN> ;
my $HUA-Class = Fake::HTTPua ;

my token lcxdigit {  <[0..9a..f]> }  # Lowercase hex digit
my token uuid     {
                    <lcxdigit> ** 8 '-'
                    [ <lcxdigit> ** 4 '-' ] ** 3
                    <lcxdigit> ** 12
                  }

my $cpn = Cloud::PacNet.new(:$API-token, :$HUA-Class);  # token compolsory
my $org-id = '6c9fe02e-3422-49fa-1193-95633367e00a' ;
my $response := $cpn.org($org-id).create-project( :name("Testing Project") ,
                                                  :customdata('{ "Some-key": "Some stuff" }')
                                                );
my $proj-id = '5fc2fc2e-39f4-4953-8c28-8a3b8a03261f';
subtest 'Initial connection setup' => {
    plan 2;

    # should be able to get details using the proj object
    my $details = $cpn.project($proj-id).get-details ;

    like  $cpn.current-org , /^^ <uuid> $$/,  "Got an org id" ;
    is    $cpn.current-org , $expected-org,  "Correct org id"
}

subtest 'orgs(id).get-projects' => {
    plan 10 ;

    my $specific-org = $cpn.org($expected-org) ;
    isa-ok $specific-org      , Cloud::PacNet::Organization, 'Able to fetch an Organization' ;
    is     $specific-org.id   , $expected-org,               'Organization object has correct id' ;

    my $projects := $specific-org.GET-projects ;
    .throw without $projects ;

    isa-ok $projects                   ,  Hash             , 'projects returns a Hash' ;
    isa-ok $projects<projects>         ,  Array            , 'projects<projects> is an Array';
    is    +$projects<projects>         ,   1               , 'projects<projects> has 1 elem';
    isa-ok $projects<projects>[0]      ,  Hash             , 'projects<projects>[0] is a Hash';
    is     $projects<projects>[0]<name> ,  "VIRL Kickoff"  , 'projects<projects>[0]<name> is correct';
    isa-ok $projects<meta>             ,  Hash             , 'projects<meta> is a Hash';
    isa-ok $projects<meta><total>      ,   1               , 'projects<meta><total> is correct';

    my $first-time = $specific-org.WHICH ;
    my $second-time = $cpn.organization($expected-org).WHICH ;
    is    $first-time                  , $second-time      , 'repeatedly fetching orgs only creates one';
}

subtest 'orgs(id).POST-projects' => {
    plan 3 ;

    my $id = $expected-org ;
    my $response := $cpn.org($id).create-project( :name("Testing Project") ,
                                                  :customdata('{ "Some-key": "Some stuff" }')
                                                );
    .throw without $response ;

    isa-ok $response            ,  Hash             , 'response is a Hash' ;
    is     $response<name>      ,  "Testing Project", 'response<name> is correct' ;
    is     $response<customdata><Some-key> ,  "Some stuff", '<customdata<Some-key>  is correct' ;
}
