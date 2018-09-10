use JSON::Fast  ;
use HTTP::UserAgent ;

unit role RESTrole ;

has $.shared = class {            # only "executed" once - when the "outer"
    has $.ua ;                    # class is instantiated.  Thereafter passed
    has $.token is required ;     # into component classes on insantiation
    has $.URL = 'https://api.packet.net' ;
    has $.min-headers ;
}

method GET-something($endpoint) {
    my $req = HTTP::Request.new: GET => $!shared.URL.IO.add($endpoint).Str, 
                                 :X-Auth-Token($!shared.token) ,
                                 :Accept<application/json>  ;
    self!return-results:  $!shared.ua.request($req)
}

method PUT-something($endpoint, *%content) {
    my $req = HTTP::Request.new: PUT => $!shared.URL.IO.add($endpoint).Str,
                                 :X-Auth-Token($!shared.token) ,
                                 :Content-Type<application/json> ,
                                 :Accept<application/json>  ;
    $req.add-content: to-json( %content );
    self!return-results:  $!shared.ua.request($req)
}


method POST-something($endpoint, *%content) {
    my $req = HTTP::Request.new: POST => $!shared.URL.IO.add($endpoint).Str,
                                 :X-Auth-Token($!shared.token) ,
                                 :Content-Type<application/json> ,
                                 :Accept<application/json>  ;
    $req.add-content: to-json( %content );
    self!return-results:  $!shared.ua.request($req)
}

method DELETE-something($endpoint) {
    my $req = HTTP::Request.new: DELETE => $!shared.URL.IO.add($endpoint).Str,
                                 :X-Auth-Token($!shared.token),
                                 :Accept<application/json>  ;
    self!return-results:  $!shared.ua.request($req)
}

method !return-results($response) {
    with $response {
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
