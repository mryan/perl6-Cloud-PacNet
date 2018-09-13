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
    plan 7;

    # get-details on the device
    my $dev-details := $cpn.device($dev-id).get-details ;
    is     $dev-details<hostname> ,    "TestBox"               , 'dev-details<hostname> is correct';
    is     $dev-details<description> ,  Any                    , 'New device has no description' ;

    # update on the device
    my $response := $cpn.device($dev-id).update:  :description("New box with new description") ;
    is     $response<description> ,  "New box with new description" , 'New device description correctly modified' ;

    # get-details on the device
    $dev-details := $cpn.device($dev-id).get-details ;
    is     $dev-details<hostname> ,    "TestBox"                , 'dev-details<hostname> stays correct';
    is     $dev-details<description> ,  "New box with new description" , 'New device description stays correct' ;

    # get-events on the device                          # Returns an Array - no meta
    my $dev-events := $cpn.device($dev-id).get-events ;
    isa-ok $dev-events           ,  Array            , 'dev-events is an Array';
    is     $dev-events.elems     ,  10               , 'dev-events has correct number of elements';
}

subtest 'Delete Device' => {
    plan 10;

    # DELETE on the device
    my $result = $cpn.device($dev-id).DELETE ;
    isa-ok $result          ,  Str              , 'result isa Str';
    is     $result          ,   ""              , 'result is empty';

    # get-events on the project                             # Returns an Array - no meta
    my $dev-events := $cpn.project($proj-id).get-events ;
    isa-ok $dev-events           ,  Array            , 'dev-events is an Array';
    is     $dev-events.elems     ,  4                , 'dev-events has correct number of elements';
    is     $dev-events[1]<type>           ,  "instance.created"  , 'there is a device "created" event';
    is     $dev-events[2]<type>           ,  "instance.deleted"  , 'there is a device "deleted" event';

    # get-devices on the project
    my $devices := $cpn.project($proj-id).get-devices ;     # REturns an array - no meta
    isa-ok $devices           ,  Array            , 'devices is an Array';
    is     $devices.elems     ,  0                , 'devices has correct number of elements';

    # get-devices on the org                                # REturns an array - no meta
    $devices := $cpn.org($org-id).get-devices ;
    isa-ok $devices           ,  Array            , 'devices is an Array';
    is     $devices.elems     ,  0                , 'devices has correct number of elements';
}

subtest 'Delete Project' => {
    plan 5;

    # DELETE on the project
    my $result = $cpn.project($proj-id).DELETE ;
    isa-ok $result          ,  Str              , 'result isa Str';
    is     $result          ,   ""              , 'result is empty';

    # get-projects on the org                             # Returns an Array - no meta
    my $projects := $cpn.org($org-id).get-projects ;
    isa-ok $projects           ,  Array            , 'projects is an Array';
    is     $projects.elems     ,  1                , 'projects has correct number of elements';
    is     $projects[0]<name>  , "Not VIRL kickoff", 'project has correct name';
}
