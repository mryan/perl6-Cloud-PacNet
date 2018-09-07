use v6.c ;
use Test ;
use lib 'lib' ;
use lib 't/lib' ;
use Fake::HTTPua ;
use Cloud::PacNet ;
use Data::Dump::Tree ;

plan 4 ;

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

subtest 'Initial connection' => {
    plan 1;

    # verified connection should result in a populated current-org
    like  $cpn.current-org , /^^ <uuid> $$/,  "Got an org id" ;
}

subtest 'post' => {
    plan 3 ;

    my $response := $cpn.POST-projects( :name("Testing Project") ,
                                        :customdata('{ "Some-key": "Some stuff" }')
                                      );
    .throw without $response ;

    isa-ok $response            ,  Hash             , 'response is a Hash' ;
    is     $response<name>      ,  "Testing Project", 'response<name> is correct' ;
    is     $response<customdata><Some-key> ,  "Some stuff", '<customdata<Some-key>  is correct' ;
}

subtest 'put' => {
    plan 3 ;

    my $response := $cpn.PUT-projects( '5fc2fc2e-39f4-4953-8c28-8a3b8a03261f',
                                       :name("New Testing Name")
                                     );
    .throw without $response ;

    isa-ok $response            ,  Hash             , 'response is a Hash' ;
    is     $response<name>      ,  "New Testing Name", 'response<name> has changed' ;
    is     $response<customdata><Some-key> ,  "Some stuff", '<customdata<Some-key>  hasnt changed' ;
}

subtest 'delete' => {
    plan 2 ;

    my $response := $cpn.DELETE-projects( '5fc2fc2e-39f4-4953-8c28-8a3b8a03261f' );
    .throw without $response ;

    isa-ok $response           , Bool                  , 'reponse is Bool' ;
    is     $response           , True                  , 'and True' ;
}
