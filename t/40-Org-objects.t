use v6.c ;
use Test ;
use lib 'lib' ;
use lib 't/lib' ;
use Fake::HTTPua ;
use Cloud::PacNet ;
use Data::Dump::Tree ;

plan 3 ;

my $token = 'secret-bizzo' ;
# my $token = %*ENV<PN_TOKEN> ;
my $HUA-Class = Fake::HTTPua ;

my token lcxdigit {  <[0..9a..f]> }  # Lowercase hex digit
my token uuid     {
                    <lcxdigit> ** 8 '-'
                    [ <lcxdigit> ** 4 '-' ] ** 3
                    <lcxdigit> ** 12
                  }

my $cpn = Cloud::PacNet.new(:$token, :$HUA-Class);  # token compolsory
my $default-org = $cpn.default-org ;
my $expected-org-id = '6c9fe02e-3422-49fa-1193-95633367e00a' ;

subtest 'Initial connection' => {
    plan 2;

    # verified connection should result in a populated .user.default-org.id
    like  $default-org.id , /^^ <uuid> $$/,  "Got an org id" ;
    is    $default-org.id , $expected-org-id,  "Correct org id"
}

subtest 'orgs(id).get-projects' => {
    plan 10 ;

    my $specific-org = $cpn.org($expected-org-id) ;
    isa-ok $specific-org      , Cloud::PacNet::Organization, 'Able to fetch an Organization' ;
    is     $specific-org.id   , $expected-org-id,               'Organization object has correct id' ;

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
    my $second-time = $cpn.organization($expected-org-id).WHICH ;
    is    $first-time                  , $second-time      , 'repeatedly fetching orgs only creates one';
}

subtest 'orgs(id).POST-projects' => {
    plan 3 ;

    my $id = $expected-org-id ;
    my $response := $cpn.org($id).create-project( :name("Testing Project") ,
                                                  :customdata('{ "Some-key": "Some stuff" }')
                                                );
    .throw without $response ;

    isa-ok $response            ,  Hash             , 'response is a Hash' ;
    is     $response<name>      ,  "Testing Project", 'response<name> is correct' ;
    is     $response<customdata><Some-key> ,  "Some stuff", '<customdata<Some-key>  is correct' ;
}
