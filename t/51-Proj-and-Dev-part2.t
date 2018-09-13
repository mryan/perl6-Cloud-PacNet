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

my $cpn = Cloud::PacNet.new(:$token, :$HUA-Class);  # token compolsory
my $org-id = $cpn.default-org.id ;
my $proj-id = '45939588-2d47-4cbd-830c-9f02363ebb5e' ;
my $dev-id = '44a8493a-fb17-453e-98b5-327eee9225e9';

subtest 'Update Device' => {
    plan 8;

    # GET on the device
    my $dev-details := $cpn.device($dev-id).GET ;
    is     $dev-details<hostname> ,    "TestBox"               , 'dev-details<hostname> is correct';
    is     $dev-details<description> ,  Any                    , 'New device has no description' ;

    # PUT on the device
    my $response := $cpn.device($dev-id).PUT:  :description("New box with new description") ;
    is     $response<description> ,  "New box with new description" , 'New device description correctly modified' ;

    # GET on the device
    $dev-details := $cpn.device($dev-id).GET ;
    is     $dev-details<hostname> ,    "TestBox"                , 'dev-details<hostname> stays correct';
    is     $dev-details<description> ,  "New box with new description" , 'New device description stays correct' ;

    # GET-events on the device
    my $dev-events := $cpn.device($dev-id).GET-events ;
    is     $dev-events<meta><total>      ,  10               , 'dev-events<meta><total> is correct';
    isa-ok $dev-events<events>           ,  Array            , 'dev-events<events> is an Array';
    is     $dev-events<events>.elems     ,  10               , 'dev-events<events> has correct number of elements';
}

subtest 'Delete Device' => {
    plan 9;

    # DELETE on the device
    my $result = $cpn.device($dev-id).DELETE ;
    isa-ok $result          ,  Str              , 'result isa Str';
    is     $result          ,   ""              , 'result is empty';

    # GET-events on the project
    my $dev-events := $cpn.project($proj-id).GET-events ;
    is     $dev-events<meta><total>      ,  4                , 'dev-events<meta><total> is correct';
    isa-ok $dev-events<events>           ,  Array            , 'dev-events<events> is an Array';
    is     $dev-events<events>.elems     ,  4                , 'dev-events<events> has correct number of elements';
    my @events := $dev-events<events> ;
    is     @events[1]<type>           ,  "instance.created"  , 'there is a device "created" event';
    is     @events[2]<type>           ,  "instance.deleted"  , 'there is a device "deleted" event';

    # GET-devices on the project
    my $devices := $cpn.project($proj-id).GET-devices ;
    is     $devices<meta><total>      ,   0                  , 'devices<meta><total> is correct';

    # GET-devices on the org
    $devices := $cpn.org($org-id).GET-devices ;
    is     $devices<meta><total>        ,  0                 , 'devices<meta><total> is correct';
}

subtest 'Delete Project' => {
    plan 4;

    # DELETE on the project
    my $result = $cpn.project($proj-id).DELETE ;
    isa-ok $result          ,  Str              , 'result isa Str';
    is     $result          ,   ""              , 'result is empty';

    # GET-projects on the org
    my $projects := $cpn.org($org-id).GET-projects ;
    isa-ok $projects<meta><total>      ,   1                  , 'projects<meta><total> is correct';
    is     $projects<projects>[0]<name> ,  "Not VIRL kickoff" , 'projects<projects>[0]<name> is correct';
}
