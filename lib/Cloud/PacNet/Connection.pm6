unit class Cloud::PacNet::Connection ;

has $.ua is rw ;
has $.URL = 'https://api.packet.net' ;
has %.min-headers ;
has $.response is rw ;
has $.request is rw ;
