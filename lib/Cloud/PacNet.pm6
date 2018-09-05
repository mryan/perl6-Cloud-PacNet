unit class Cloud::PacNet ;
use JSON::Fast  ;
use Config::JSON '';
use HTTP::UserAgent ;
use Data::Dump::Tree ;

constant DefaultConfigFile = %*ENV<HOME> ~ '/.cloud-pacnet.json' ;
constant URL = 'https://api.packet.net' ;
my @REST-methods = <get post put delete> ;

has $.API-token is required ;          # Compolsory
has $.HUA-Class = HTTP::UserAgent ;    # For testing
has $.current-org is rw ;              # Expects a UUID
has $.current-project is rw ;          # Expects a UUID
has $.current-device  is rw ;          # Expects a UUID
has Bool $.verify = True ;             # Verify token at object creation time?

has $!ua = $!HUA-Class.new ;
has $!user-id ;
has $!user-full-name ; 
has $!verified-auth = False ;
has $!default-org-id ;
has $!default-project-id ;
has %!minimum-headers = %(  :X-Auth-Token($!API-token) ,
                            :Accept<application/json>) ;
submethod TWEAK {
    self.verify-auth if $!verify ;
}

method verify-auth {
    with $!ua.get: URL ~ '/user' , |%!minimum-headers {
        if .is-success {
            my %user-data := from-json( .content ) ;
            ( $!user-id , $!user-full-name ) = %user-data<id full_name> ;
            $!current-org = $!default-org-id  = %user-data<default_organization_id> ;
            $!current-project = $!default-project-id = %user-data<default_project_id> ;
            $!verified-auth = True ;
        }
        else {
            fail err-message($_)
        }
    }
}

method gist {
    $!verified-auth ??
        qq:to/END_HERE/
        Verified instance of Cloud::PacNet
        User Name:  $!user-full-name
        User ID:    $!user-id
        Org ID:     $!default-org-id
        END_HERE
    !!
        "Unverified instance of $?CLASS"
}
        # Project ID: { $!default-project-id // "[Not Specified]" }

method GET-user           {  self!GET-something('user')                         }
method get-user           {  self!GET-something('user')                         }
method GET-organizations  {  self!GET-something('organizations')                }
method get-orgs           {  self!GET-something('organizations')<organizations> }
method GET-projects       {  self!GET-something('projects')                     }
method get-projects       {  self!GET-something('projects')<projects>           }
method GET-facilities     {  self!GET-something('facilities')                   }
method get-facilities     {  self!GET-something('facilities')<facilities>       }
method GET-plans          {  self!GET-something('plans')                        }
method get-plans          {  self!GET-something('plans')<plans>                 }
method GET-market-spot-prices {  self!GET-something('market/spot/prices')       }
method get-spot-prices    {  self!GET-something('market/spot/prices')<spot_market_prices> }

method !GET-something($endpoint) {
    self.verify-auth unless $!verified-auth ;
    my $req = HTTP::Request.new: GET => URL.IO.add($endpoint).Str, |%!minimum-headers ;

    with $!ua.request: $req  {
        .is-success ??
            # A successful get is presumed to have content
            return from-json( .content ) 
        !!    
            fail qq:to/END_HERE/
            Error while GETing: {.status-line}
            { .content if .has-content }
            END_HERE
    }
}

method PUT-projects($id, |c)        { self!PUT-something("/projects/$id", |c)  }

method !PUT-something($endpoint, *%content) {
    self.verify-auth unless $!verified-auth ;
    
    my %headers = %!minimum-headers ;
    %headers<Content-Type> = 'application/json' ;
    my $req = HTTP::Request.new: PUT => URL.IO.add($endpoint).Str, |%headers ;
    $req.add-content: to-json( %content );
    with $!ua.request: $req  {
        .is-success ??
            .has-content ??
                return from-json( .content ) 
                # return  .content  
            !!
                True
        !!    
            fail qq:to/END_HERE/
            Error while PUTing: {.status-line}
            { .content if .has-content }
            END_HERE
    }
}

method POST-projects(|c)        { self!POST-something("/projects", |c)  }

method !POST-something($endpoint, *%content) {
    self.verify-auth unless $!verified-auth ;
    
    my %headers = %!minimum-headers ;
    %headers<Content-Type> = 'application/json' ;
    my $req = HTTP::Request.new: POST => URL.IO.add($endpoint).Str, |%headers ;
    $req.add-content: to-json( %content );
    with $!ua.request: $req  {
        .is-success ??
            .has-content ??
                return from-json( .content ) 
                # return  .content  
            !!
                True
        !!    
            fail qq:to/END_HERE/
            Error while POSTing: {.status-line}
            { .content if .has-content }
            END_HERE
    }
}

method DELETE-projects($id)        { self!DELETE-something("/projects/$id")  }

method !DELETE-something($endpoint) {
    self.verify-auth unless $!verified-auth ;
    my $req = HTTP::Request.new: DELETE => URL.IO.add($endpoint).Str, |%!minimum-headers ;

    with $!ua.request: $req  {
        .is-success ??
            .has-content ??
                return from-json( .content ) 
                # return  .content  
            !!
                True
        !!    
            fail qq:to/END_HERE/
            Error while DELETEing: {.status-line}
            { .content if .has-content }
            END_HERE
    }
}

my sub err-message($_) { "Error {.code}: {.status-line}" }

# :pn-get
our sub pn-get( :$endpoint, 
            :$token,
            :$debug = False,
       Bool :$perl6 = False,
            *%headers is copy) is export(:pn-get) {

    %headers<User-Agent>   //=  'perl6-Cloud::PacNet' ;
    %headers<Accept>       //=  'application/json' ;
    %headers<X-Auth-Token> //=  $token // die "No token" ;

    my $req = HTTP::Request.new: GET => URL.IO.add($endpoint).Str, |%headers ;

    with HTTP::UserAgent.new(:throw-exceptions, :$debug).request: $req  {
        $perl6 ?? 
            from-json .content
            !!
            .content
    }

}

my constant $MAX_AGE = 24 * 3600;  # 1 day

sub pn-fetch-cache($token, :$ConfigFile = DefaultConfigFile) is export(:pn-fetch-cache) {
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

sub update_cache($token, :$ConfigFile) {
    my %cache := pn-get(:endpoint<facilities>, :$token, :perl6);
    %cache<plans> := pn-get(:endpoint<plans>, :$token, :perl6)<plans> ;
    jconf-write $ConfigFile.IO, 'cache', %cache ;
    jconf-write $ConfigFile.IO, 'cache-timestamp', now ;
}
