#!/usr/bin/env perl6
use lib '../../lib' ;
use Cloud::PacNet ;
use JSON::Pretty ;
use Config::JSON '' ;
use Data::Dump::Tree ;

constant ConfigFile = %*ENV<HOME> ~ '/.pacnet-rapi-cache.json' ;
my %*SUB-MAIN-OPTS = :named-anywhere ;

#| where method is get, post, put or delete
multi sub MAIN( $method,  $endpoint, 
                $token = %*ENV<PN_TOKEN>, 
                Bool :$perl6, Bool :$raw  ) {
    my $raw_result = pn-query :$method, :$endpoint , :$token ;
    my $perl6_data = from-json $raw_result ;

    if $perl6 {
        $raw ?? $perl6_data.perl.put !! ddt $perl6_data , :!display_info
    }
    else {
        $raw ?? $raw_result.put !! to-json($perl6_data).put 
    }
    exit 0;
}

#| Update local cache of plans, facilities, etc
multi sub MAIN( 'update-cache' , $token = %*ENV<PN_TOKEN> )  { 

    # The packet.net API returns a surrounding hash with a single entry
    # being the result of your request.  Might as well use that outer hash.
    my %cache := pn-query(:method<get>, :endpoint<facilities>, :$token, :perl6);

    # This time, need to index into the surrounding hash to extract the results
    %cache<plans> := pn-query(:method<get>, :endpoint<plans>, :$token, :perl6)<plans> ;

    # Simple cache arrangement - a single timestamp for the whole lot
    jconf-write ConfigFile.IO, 'cache', %cache ;
    jconf-write ConfigFile.IO, 'cache-timestamp', now ;
}
