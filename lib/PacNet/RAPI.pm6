unit module PacNet::RAPI ;
use WWW ;
use JSON::Fast  ;
use Config::JSON '';
use Data::Dump::Tree ;

constant ConfigFile = %*ENV<HOME> ~ '/.pacnet-rapi.json' ;
constant URL = 'https://api.packet.net/' ;
my @REST-methods = <get post put delete> ;

sub pn-query( Str :$method where any(@REST-methods),
                  :$endpoint, 
                  :$token,
                # :%headers,
                # :%form,
             Bool :$perl6 = False) is export {

    # ddt %( :$method , :url(URL) , :$endpoint , :$token , :$perl6 );
    # module WWW exports subs whose names' match REST method names
    my $json-data = ::{ '&' ~ $method }.( URL ~ $endpoint , 
                                       #  %(
                                             :X-Auth-Token($token) ,
                                             :Accept<application/json> ,
                                       #     |%headers
                                       #   )
                                       #  |%form
                                        );
    return $perl6 ?? from-json($json-data)
                  !! $json-data 
}

my constant $MAX_AGE = 24 * 3600;  # 1 day

sub pn-fetch-cache($token) is export {
    my $then = DateTime.new: jconf ConfigFile.IO, 'cache-timestamp' ;
    if now - $then.Instant > $MAX_AGE {
        # Update the cache
        note "Cache data expired.  Updating...";
        update_cache($token);
        note "Done."
    }
    my $data = jconf ConfigFile.IO, 'cache' ;
    return $data
}

sub update_cache($token) {
    my %cache := pn-query(:method<get>, :endpoint<facilities>, :$token, :perl6);
    %cache<plans> := pn-query(:method<get>, :endpoint<plans>, :$token, :perl6)<plans> ;
    jconf-write ConfigFile.IO, 'cache', %cache ;
    jconf-write ConfigFile.IO, 'cache-timestamp', now ;
}
