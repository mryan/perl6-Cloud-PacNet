unit module Cloud::PacNet ;
use WWW ;
use JSON::Fast  ;
use Config::JSON '';
use HTTP::UserAgent ;
use Data::Dump::Tree ;

our $Local-Testing = False;
constant DefaultConfigFile = %*ENV<HOME> ~ '/.cloud-pacnet.json' ;
constant TestDataDir = 't/data/' ;
constant URL = 'https://api.packet.net/' ;
my @REST-methods = <get post put delete> ;

class API is export {
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
        with $!ua.get: URL ~ 'user' , |%!minimum-headers {
            if .is-success {
                my %user-data := from-json( .decoded-content ) ;
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
        qq:to/END_HERE/ ;
        User Name:  $!user-full-name
        User ID:    $!user-id
        Org ID:     $!default-org-id
        Project ID: { $!default-project-id // "[Not Specified]" }
        END_HERE
    }

    method GET-user           {  self!GET-something('user')          }
    method get-user           {  self!GET-something('user')          }
    method GET-organizations  {  self!GET-something('organizations') }
    method get-orgs           {  self!GET-something('organizations') }
    method GET-projects       {  self!GET-something('projects')      }
    method get-projects       {  self!GET-something('projects')      }
    method GET-facilities     {  self!GET-something('facilities')    }
    method get-facilities     {  self!GET-something('facilities')    }
    method GET-plans          {  self!GET-something('plans')         }
    method get-plans          {  self!GET-something('plans')         }
    method GET-market-spot-prices {  self!GET-something('market-spot-prices') }
    method get-spot-prices {  self!GET-something('market-spot-prices') }

    method !GET-something($endpoint) {
        self.verify-auth unless $!verified-auth ;
        with $!ua.get: URL ~ $endpoint , |%!minimum-headers {
            .is-success ??
                return from-json( .decoded-content ) 
            !!    
                fail "Error {.code}: {.status-line}"
        }
    }

    sub err-message($_) { "Error {.code}: {.status-line}" }
}

sub pn-query( Str :$method where any(@REST-methods),
                  :$endpoint, 
                  :$token,
                # :%headers,
                # :%form,
             Bool :$perl6 = False) is export(:functional) {

    my $json-data ;
    if $Local-Testing {
        my $data-filename = join '+' , $method , $endpoint , $token ;
        $json-data = $data-filename eq 'get+no-cache+TOKEN' ??
            '{ "hard": "coded" }' 
        !!    
            # Fetch from files in test data dir
            slurp TestDataDir ~ $data-filename ~ '.json' ;
    }
    else {   
        # Real thing
        # module WWW exports subs whose names' match REST method names
        $json-data = ::{ '&' ~ $method }.( URL ~ $endpoint , 
                                      #  %(
                                            :X-Auth-Token($token) ,
                                            :Accept<application/json> ,
                                      #     |%headers
                                      #   )
                                      #  |%form
                                         );
    }

    return $perl6 ?? from-json($json-data)
                  !! $json-data 
}

my constant $MAX_AGE = 24 * 3600;  # 1 day

sub pn-fetch-cache($token, :$ConfigFile = DefaultConfigFile) is export(:functional) {
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
    my %cache := pn-query(:method<get>, :endpoint<facilities>, :$token, :perl6);
    %cache<plans> := pn-query(:method<get>, :endpoint<plans>, :$token, :perl6)<plans> ;
    jconf-write $ConfigFile.IO, 'cache', %cache ;
    jconf-write $ConfigFile.IO, 'cache-timestamp', now ;
}
