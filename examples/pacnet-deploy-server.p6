#!/usr/bin/env perl6
use lib '.' ;
use PacNet::RAPI ;

sub MAIN( :$token = %*ENV<PN_TOKEN>,
          :$plan, = <baremetal_1>, 
          :$site,
      Int :$max-price
     Bool :$cache = True) {

    my $cache-info = pn-fetch-cache($token) ;
    my %names = $cache-info<facilities>.map: { .<code> => .<name> }
    my $packet-net := pn-query(:method<get>, :endpoint<market/spot/prices>, :$token, :perl6);
    
    my %printed ;
    for $packet-net<spot_market_prices>.kv -> $site_code, $plans {
        with $site { next unless $site_code eq one(.flat) }
        for $plans.kv -> $machine, $info {
            with $plan { next unless $machine eq one(.flat) }
            say "$site_code: %names{ $site_code }" unless %printed{ $site_code }++ ;
            say "  $machine:  \$" ~ $info<price>
        }
    }
}
