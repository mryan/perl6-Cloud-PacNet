use JSON::Fast  ;
use HTTP::UserAgent ;

unit role RESTrole ;
has $.shared handles 'response' ;

method GET-something($endpoint) {
    my $req = HTTP::Request.new: GET => $!shared.URL.IO.add($endpoint).Str, 
                                 |$!shared.min-headers ;
    self!return-results:  $!shared.ua.request($req)
}

method PUT-something($endpoint, *%content) {
    my $req = HTTP::Request.new: PUT => $!shared.URL.IO.add($endpoint).Str,
                                 |$!shared.min-headers,
                                 :Accept<application/json>  ;
    $req.add-content: to-json( %content );
    self!return-results:  $!shared.ua.request($req)
}


method POST-something($endpoint, *%content) {
    my $req = HTTP::Request.new: POST => $!shared.URL.IO.add($endpoint).Str,
                                 |$!shared.min-headers,
                                 :Accept<application/json>  ;
    $req.add-content: to-json( %content );
    self!return-results:  $!shared.ua.request($req)
}

method DELETE-something($endpoint) {
    my $req = HTTP::Request.new: DELETE => $!shared.URL.IO.add($endpoint).Str,
                                 |$!shared.min-headers ;
    self!return-results:  $!shared.ua.request($req)
}

method !return-results($response) {
    $!shared.response = $response ;
    with $response {
        .is-success ??
            .has-content ??
                return from-json( .content ) 
            !!
                ""
        !!    
            fail qq:to/END_HERE/
            Error while DELETEing: {.status-line}
            { .content if .has-content }
            END_HERE
    }
}
