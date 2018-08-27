unit module Cloud::PacNet ;
use WWW ;
use JSON::Fast  ;
use Config::JSON '';
use Data::Dump::Tree ;

our $Local-Testing = False;
constant DefaultConfigFile = %*ENV<HOME> ~ '/.cloud-pacnet.json' ;
constant TestDataDir = 't/data/' ;
constant URL = 'https://api.packet.net/' ;
my @REST-methods = <get post put delete> ;

sub pn-query( Str :$method where any(@REST-methods),
                  :$endpoint, 
                  :$token,
                # :%headers,
                # :%form,
             Bool :$perl6 = False) is export {

    my $json-data ;
    if $Local-Testing {
        my $data-filename = join '+' , $method , $endpoint , $token ;
        $json-data = $data-filename eq 'get+no-cache+TOKEN' ??
            '{ "hard": "coded" }' 
        !!    
            # Fetch from testing-cache-config file
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

sub pn-fetch-cache($token, :$ConfigFile = DefaultConfigFile) is export {
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
