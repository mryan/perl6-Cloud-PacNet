#!/usr/bin/env perl6
use lib '.' ;
use PacNet::RAPI ;
use Data::Dump::Tree ;
use JSON::Fast ;

sub MAIN( :$token = %*ENV<PN_TOKEN>,
          :$plan  = <baremetal_0 baremetal_1>, 
          :$facility,
     Bool :$cache = True) {

    my %smp := from-json q:to<EOJ> ;
               {
                 "spot_market_prices" : {
                   "dfw1" : {
                     "baremetal_1e" : {
                       "price" : 0.08
                     }
                   },
                   "ams1" : {
                     "m2.xlarge.x86" : {
                       "price" : 20.01
                     },
                     "baremetal_3" : {
                       "price" : 17.51
                     },
                     "baremetal_2a2" : {
                       "price" : 5.01
                     },
                     "baremetal_2" : {
                       "price" : 0.4
                     },
                     "baremetal_0" : {
                       "price" : 0.03
                     },
                     "baremetal_s" : {
                       "price" : 15.01
                     },
                     "c2.medium.x86" : {
                       "price" : 0.3
                     },
                     "baremetal_1" : {
                       "price" : 0.25
                     },
                     "baremetal_2a" : {
                       "price" : 5.01
                     }
                   },
                   "yyz1" : {
                     "baremetal_1e" : {
                       "price" : 0.08
                     }
                   },
                   "ord1" : {
                     "baremetal_1e" : {
                       "price" : 4.01
                     }
                   },
                   "atl1" : {
                     "baremetal_1e" : {
                       "price" : 0.08
                     }
                   },
                   "nrt1" : {
                     "m2.xlarge.x86" : {
                       "price" : 0.4
                     },
                     "baremetal_2a2" : {
                       "price" : 5.01
                     },
                     "baremetal_2" : {
                       "price" : 17.01
                     },
                     "baremetal_0" : {
                       "price" : 0.01
                     },
                     "baremetal_s" : {
                       "price" : 15.01
                     },
                     "c2.medium.x86" : {
                       "price" : 0.2
                     },
                     "baremetal_1" : {
                       "price" : 0.08
                     },
                     "baremetal_2a" : {
                       "price" : 5.01
                     }
                   },
                   "ewr1" : {
                     "m2.xlarge.x86" : {
                       "price" : 0.45
                     },
                     "baremetal_3" : {
                       "price" : 0.35
                     },
                     "baremetal_2a2" : {
                       "price" : 5.01
                     },
                     "baremetal_2" : {
                       "price" : 0.34
                     },
                     "baremetal_0" : {
                       "price" : 0.07
                     },
                     "baremetal_s" : {
                       "price" : 15.01
                     },
                     "c2.medium.x86" : {
                       "price" : 0.2
                     },
                     "baremetal_1" : {
                       "price" : 0.08
                     },
                     "baremetal_2a" : {
                       "price" : 5.01
                     }
                   },
                   "fra1" : {
                     "baremetal_1e" : {
                       "price" : 4.01
                     }
                   },
                   "syd1" : {
                     "baremetal_1e" : {
                       "price" : 0.08
                     }
                   },
                   "sjc1" : {
                     "m2.xlarge.x86" : {
                       "price" : 0.4
                     },
                     "baremetal_3" : {
                       "price" : 0.35
                     },
                     "baremetal_2a2" : {
                       "price" : 5.01
                     },
                     "baremetal_2" : {
                       "price" : 0.34
                     },
                     "baremetal_0" : {
                       "price" : 0.05
                     },
                     "c2.medium.x86" : {
                       "price" : 0.29
                     },
                     "baremetal_1" : {
                       "price" : 0.08
                     },
                     "baremetal_2a" : {
                       "price" : 5.01
                     }
                   },
                   "sea1" : {
                     "baremetal_1e" : {
                       "price" : 0.08
                     }
                   },
                   "lax1" : {
                     "baremetal_1e" : {
                       "price" : 0.08
                     }
                   },
                   "sin1" : {
                     "baremetal_1e" : {
                       "price" : 0.08
                     }
                   },
                   "iad1" : {
                     "baremetal_1e" : {
                       "price" : 0.08
                     }
                   }
                 }
               }
               EOJ

    ddt %( :$token , :$plan , :$facility , :$cache );
    for $facility -> $f {
        say "Facility: $f,  Plan: $_" for $plan ;
    }
}
