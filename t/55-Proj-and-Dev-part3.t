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

my $new-proj-id ;
my $new-dev-id  ;

subtest 'Create Project' => {
    plan 7;

    my $projects := $cpn.org($org-id).get-projects ;     # Returns an Array of projects (no meta)
    isa-ok $projects               , Array                  , 'projects is an Array';
    is     $projects.elems      ,   1                  ,      'number of elements in $projects is correct';
    is     $projects[0]<name> ,  "Not VIRL kickoff" , 'projects[0]<name> is correct';

    my $response := $cpn.org($org-id).create-project:  :name("Temp Testing Project") ;
    .throw without $response ;
    is     $response<name>      ,  "Temp Testing Project"    , 'Newly created project has correct name' ;

    $projects := $cpn.org($org-id).get-projects ;     # Returns an Array of projects (no meta)
    isa-ok $projects               , Array                  , 'projects is an Array';
    is     $projects[0]<name>      ,  "Not VIRL kickoff"    , 'projects[0]<name> is correct';
    is     $projects[1]<name>      ,  "Temp Testing Project", 'projects[1]<name> is correct';

    $new-proj-id = $projects[1]<id> ;
}

subtest 'Update Project' => {
    plan 5;

    my $proj-details := $cpn.project($new-proj-id).get-details ;
    is     $proj-details<name> ,    "Temp Testing Project" , 'proj-details<name> is correct';

    my $response := $cpn.project($new-proj-id).update:  :name("Temp Testing Project") ;
    is     $response<name>      ,  "Project Name Change"    , 'New project name correctly modified' ;

    $proj-details := $cpn.project($new-proj-id).get-details ;
    is     $proj-details<name> ,    "Project Name Change" , 'proj-details<name> stays correct';

    my $proj-events := $cpn.project($new-proj-id).get-events ;  # Returns an Array of projects (no meta)
    isa-ok $proj-events           ,  Array            , 'proj-events<events> is an Array';
    is     $proj-events.elems     ,  0                , 'proj-events<events> is empty';
}

subtest 'Create Device' => {
    plan 12;

    # Get devices on the project
    my $devices := $cpn.project($new-proj-id).get-devices ; # No meta
    isa-ok $devices           ,  Array            , 'devices is an Array';
    is     $devices.elems     ,  0                , 'devices is empty';

    # POST devices on the project
    my $FreeBSD_11_1 = 'f11492e0-890f-448f-a167-8a9257c22b73' ;
    my $response = $cpn.project($new-proj-id).create-device: :hostname("TestBox") ,
                                                            :operating_system($FreeBSD_11_1) ,
                                                            :description("Original Description") ,
                                                            :plan<t1.small.x86> ,
                                                            :facility<ewr1> ;
    .throw without $response ;
    is     $response<hostname>         ,  "TestBox"               , 'Newly created device has correct hostname' ;
    is     $response<operating_system><id> ,  $FreeBSD_11_1       , 'Newly created device has correct operating system' ;
    $new-dev-id = $response<id> ;

    # GET devices on the project
    $devices := $cpn.project($new-proj-id).get-devices ;
    isa-ok $devices           ,  Array            , 'devices is an Array';
    is     $devices.elems     ,  1                , 'devices is empty';
    is     $devices[0]<hostname> ,  "TestBox"       , 'devices[0]<name> is correct';
    is     $devices[0]<facility><code>,  "ewr1"     , 'devices[0]<facility><code> is correct';

    # GET devices on the org
    $devices := $cpn.org($org-id).get-devices ;
    isa-ok $devices           ,  Array            , 'devices is an Array';
    is     $devices.elems     ,  1                , 'devices is empty';
    is     $devices[0]<hostname> ,  "TestBox"       , 'devices[0]<hostname> is correct';
    is     $devices[0]<plan><slug>, "t1.small.x86"  , 'devices[0]<plan><slug> is correct';
}
