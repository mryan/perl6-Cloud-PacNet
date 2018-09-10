use JSON::Fast  ;
use Config::JSON '';
use HTTP::UserAgent ;
use Cloud::PacNet::RESTrole ;

unit class Cloud::PacNet does RESTrole ;

constant DefaultConfigFile = %*ENV<HOME> ~ '/.cloud-pacnet.json' ;
my @REST-methods = <get post put delete> ;

has $.token is required ;              # Compolsory
has $.HUA-Class = HTTP::UserAgent ;    # For testing
has $.verify = True ;                  # Verify auth at instantiation?
has $.user ;

has %!orgs ;
has %!projects ;

class User {
    has $.id ;
    has $.full-name ; 
    has $.default-org ;
    has $.default-project ;
}

class Shared {
    has $.ua ;
    has $.URL = 'https://api.packet.net' ;
    has %.min-headers ;
    has $.response is rw ;
}

submethod TWEAK { 
    # Setup shared data b/w this class and component classes
    $!shared = Shared.new:  :ua($!HUA-Class.new) ,
                            :min-headers(  
                                :X-Auth-Token($!token) ,
                                :Accept<application/json>
                            );
    self.verify-auth if $!verify
}

method gist {
    qq:to/END_HERE/
    Instance of Cloud::PacNet
    User Name:  { $!user.full-name }
    User ID:    { $!user.id }
    Org ID:     { $!user.default-org.id }
    END_HERE
}

class Organization does RESTrole {
    has $.id    is required ;

    method GET-projects   {  self.GET-something("/organizations/$!id/projects")              }
    method get-projects   {  self.GET-something("/organizations/$!id/projects")<projects>    }
    method POST-projects  {  self.POST-something("/organizations/$!id/projects")             }
    method create-project {  self.POST-something("/organizations/$!id/projects")             }

    method GET-devices    {  self.GET-something("/organizations/$!id/devices")               }
    method get-devices    {  self.GET-something("/organizations/$!id/devices")               }

    method GET            {  self.GET-something("/organizations/$!id")                }
    method get-details    {  self.GET-something("/organizations/$!id")                }
    method PUT(|c)        {  self.PUT-something("/organizations/$!id", |c)                   }
    method update(|c)     {  self.PUT-something("/organizations/$!id", |c)                   }
    method DELETE         {  self.DELETE-something("/organizations/$!id")             }
}

method organization($id)  { %!orgs{ $id } //=  Organization.new: :$id, :$!shared }
method org($id)           { %!orgs{ $id } //=  Organization.new: :$id, :$!shared }

class Project does RESTrole {
    has $.id    is required ;

    method GET-events        {  self.GET-something("/projects/$!id/events")         }
    method get-events        {  self.GET-something("/projects/$!id/events")<events> }
    method GET-devices       {  self.GET-something("/projects/$!id/devices")        }
    method get-devices       {  self.GET-something("/projects/$!id/devices")<devices> }
    method POST-devices(|c)  {  self.POST-something("/projects/$!id/devices", |c)   }
    method create-device(|c) {  self.POST-something("/projects/$!id/devices", |c)   }
    method GET               {  self.GET-something("/projects/$!id")                }
    method get-details       {  self.GET-something("/projects/$!id")                }
    method PUT(|c)           {  self.PUT-something("/projects/$!id", |c)            }
    method update(|c)        {  self.PUT-something("/projects/$!id", |c)            }
    method DELETE            {  self.DELETE-something("/projects/$!id")             }
}

method project($id)     { %!projects{ $id } //=  Project.new: :$id, :$!shared }

method verify-auth {
    with $!shared.ua.get: $!shared.URL ~ '/user' , |$!shared.min-headers {
        if .is-success {
            my %user-data := from-json( .content ) ;
            my $id = %user-data<default_organization_id> ;
            %!orgs{ $id } =  Organization.new: :$id , :$!shared ;
            $!user = User.new:
                :id(           %user-data<id>        ) ,
                :full-name(    %user-data<full_name> ) ,
                :default-org(  %!orgs{ $id }         ) ;
                # Set default project
        }
        else {
            fail err-message($_)
        }
    }
}

method GET-user           {  self.GET-something('user')                         }
method get-user           {  self.GET-something('user')                         }
method GET-organizations  {  self.GET-something('organizations')                }
method get-orgs           {  self.GET-something('organizations')<organizations> }
method GET-projects       {  self.GET-something('projects')                     }
method get-projects       {  self.GET-something('projects')<projects>           }
method GET-facilities     {  self.GET-something('facilities')                   }
method get-facilities     {  self.GET-something('facilities')<facilities>       }
method GET-plans          {  self.GET-something('plans')                        }
method get-plans          {  self.GET-something('plans')<plans>                 }
method GET-market-spot-prices {  self.GET-something('market/spot/prices')       }
method get-spot-prices    {  self.GET-something('market/spot/prices')<spot_market_prices> }

# Not supporting the creation of organizations at this point
# method POST-organizations(|c)   { self.POST-something("/organizations", |c)  }
# method create-org(|c)           { self.POST-something("/organizations", |c)  }

method PUT-projects($id, |c)        { self.PUT-something("/projects/$id", |c)  }
method POST-projects(|c)        { self.POST-something("/projects", |c)  }
method DELETE-projects($id)        { self.DELETE-something("/projects/$id")  }

my sub err-message($_) { "Error {.code}: {.status-line}" }

# :pn-get
my \URL = 'https://api.packet.net' ;
our sub pn-get( :$endpoint, 
            :$token,
            :$debug = False,
       Bool :$perl6 = False,
            :$HUA-Class = HTTP::UserAgent,
            *%headers is copy) is export(:pn-get) {

    %headers<User-Agent>   //=  'perl6-Cloud::PacNet' ;
    %headers<Accept>       //=  'application/json' ;
    %headers<X-Auth-Token> //=  $token // die "No token" ;

    my $req = HTTP::Request.new: GET => URL.IO.add($endpoint).Str, |%headers ;

    with $HUA-Class.new(:throw-exceptions, :$debug).request: $req  {
        $perl6 ?? 
            from-json .content
            !!
            .content
    }

}

my constant $MAX_AGE = 24 * 3600;  # 1 day

our sub pn-fetch-cache($token, :$ConfigFile = DefaultConfigFile) is export(:pn-get) {
    die "Cannot read config file $ConfigFile" unless $ConfigFile.IO ~~ :r ;
    my $then = DateTime.new: jconf $ConfigFile.IO, 'cache-timestamp' ;
    if now - $then.Instant > $MAX_AGE {
        # Update the cache
        note "Cache data expired.  Updating...";
        update_cache($token, :$ConfigFile);
        note "Done."
    }
    my $data = jconf $ConfigFile.IO, 'cache' ;
    return $data
}

our sub update_cache($token, :$ConfigFile) is export(:pn-get) {
    my %cache := pn-get(:endpoint<facilities>, :$token, :perl6);
    %cache<plans> := pn-get(:endpoint<plans>, :$token, :perl6)<plans> ;
    jconf-write $ConfigFile.IO, 'cache', %cache ;
    jconf-write $ConfigFile.IO, 'cache-timestamp', now ;
}
