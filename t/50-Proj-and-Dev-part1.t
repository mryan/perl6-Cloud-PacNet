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
my $org-id = $cpn.default-org.id ;

my $new-proj-id ;
my $new-dev-id  ;

subtest 'Create Project' => {
    plan 6;

    my $projects := $cpn.org($org-id).GET-projects ;
    isa-ok $projects<meta><total>      ,   1                  , 'projects<meta><total> is correct';
    is     $projects<projects>[0]<name> ,  "Not VIRL kickoff" , 'projects<projects>[0]<name> is correct';

    my $response := $cpn.org($org-id).POST-projects:  :name("Temp Testing Project") ;
    .throw without $response ;
    is     $response<name>      ,  "Temp Testing Project"    , 'Newly created project has correct name' ;

    $projects := $cpn.org($org-id).GET-projects ;
    is     $projects<meta><total>      ,   2               ,    'projects<meta><total> is correct';
    is     $projects<projects>[0]<name> ,  "Not VIRL kickoff" , 'projects<projects>[0]<name> is correct';
    is     $projects<projects>[1]<name> ,  "Temp Testing Project", 'projects<projects>[1]<name> is correct';

    $new-proj-id = $projects<projects>[1]<id> ;
}

subtest 'Update Project' => {
    plan 6;

    my $proj-details := $cpn.project($new-proj-id).GET ;
    is     $proj-details<name> ,    "Temp Testing Project" , 'proj-details<name> is correct';

    my $response := $cpn.project($new-proj-id).PUT:  :name("Temp Testing Project") ;
    is     $response<name>      ,  "Project Name Change"    , 'New project name correctly modified' ;

    $proj-details := $cpn.project($new-proj-id).GET ;
    is     $proj-details<name> ,    "Project Name Change" , 'proj-details<name> stays correct';

    my $proj-events := $cpn.project($new-proj-id).GET-events ;
    is     $proj-events<meta><total>      ,   0               ,    'proj-events<meta><total> is correct';
    isa-ok $proj-events<events>           ,  Array            , 'proj-events<events> is an Array';
    is     $proj-events<events>.elems     ,  0                , 'proj-events<events> is empty';
}

subtest 'Create Device' => {
    plan 9;

    # Get devices on the project
    my $devices := $cpn.project($new-proj-id).GET-devices ;
    is     $devices<meta><total>      ,   0                  , 'devices<meta><total> is correct';

    # POST devices on the project
    my $FreeBSD_11_1 = 'f11492e0-890f-448f-a167-8a9257c22b73' ;
    my $response = $cpn.project($new-proj-id).POST-devices: :hostname("TestBox") ,
                                                            :operating_system($FreeBSD_11_1) ,
                                                            :description("Original Description") ,
                                                            :plan<t1.small.x86> ,
                                                            :facility<ewr1> ;
    .throw without $response ;
    is     $response<hostname>         ,  "TestBox"               , 'Newly created device has correct hostname' ;
    is     $response<operating_system><id> ,  $FreeBSD_11_1       , 'Newly created device has correct operating system' ;
    $new-dev-id = $response<id> ;

    # GET devices on the project
    $devices := $cpn.project($new-proj-id).GET-devices ;
    is     $devices<meta><total>      ,   1                  , 'devices<meta><total> is correct';
    is     $devices<devices>[0]<hostname> ,  "TestBox"       , 'devices<devices>[0]<name> is correct';
    is     $devices<devices>[0]<facility><code>,  "ewr1"     , 'devices<devices>[0]<facility> is correct';

    # GET devices on the org
    $devices := $cpn.org($org-id).GET-devices ;
    is     $devices<meta><total>         ,   1               ,    'devices<meta><total> is correct';
    is     $devices<devices>[0]<hostname> ,  "TestBox"       , 'devices<devices>[0]<hostname> is correct';
    is     $devices<devices>[0]<plan><slug>, "t1.small.x86"  , 'devices<devices>[0]<plan> is correct';
}
