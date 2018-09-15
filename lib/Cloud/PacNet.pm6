use JSON::Fast  ;
use Config::JSON '';
use HTTP::UserAgent ;
use Cloud::PacNet::RESTrole ;
use Cloud::PacNet::Orgs-Projs-Devs ;
use Cloud::PacNet::Connection ;

unit class Cloud::PacNet does RESTrole ;

constant DefaultConfigFile = %*ENV<HOME> ~ '/.cloud-pacnet.json' ;
my @REST-methods = <get post put delete> ;

has $.token is required ;              # Compolsory
has $.HUA-Class = HTTP::UserAgent ;    # For testing
has $.verify = True ;                  # Verify auth at instantiation?
has $.default-org ;
has $.default-project ;

has %!orgs ;
has %!projects ;
has %!devices ;
has $!user-id ;
has $!user-name ; 

submethod TWEAK { 
    # Setup connection data used by this class and component classes
    $!con = Connection.instance ;
    $!con.ua = $!HUA-Class.new ;
    $!con.min-headers = :X-Auth-Token($!token) ,
                        :Accept<application/json> ,
                        :User-Agent<perl6-Cloud::PacNet> ;
    self.verify-auth if $!verify
}

method gist {
    qq:to/END_HERE/
        Instance of Cloud::PacNet
        User Name:  { $!user-name }
        User ID:    { $!user-id }
        Org ID:     { $!default-org.id }
        END_HERE 
}

method organization($id)  { %!orgs{ $id }     //=  Organization.new: :$id }
method org($id)           { %!orgs{ $id }     //=  Organization.new: :$id }
method project($id)       { %!projects{ $id } //=  Project.new: :$id }
method device($id)        { %!devices{ $id }  //=  Device.new: :$id }

method verify-auth {
    with self.GET-user {
        # We now have a hash of user data as topic
        $!user-id = .<id> ;
        $!user-name = .<full_name> ;
        $!default-org = self.org: .<default_organization_id> ;
        # Set default project
    }
    else {
        .throw    # GET-user returns a fail object if request unsuccessfull
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
