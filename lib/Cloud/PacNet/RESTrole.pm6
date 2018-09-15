use JSON::Fast  ;
use HTTP::Request ;
use Cloud::PacNet::Connection ;

unit role RESTrole ;
has $.con = Cloud::PacNet::Connection.instance ;

method GET-something($endpoint) {
    $!con.request = HTTP::Request.new: GET => $!con.URL.IO.add($endpoint).Str, 
                                 |$!con.min-headers ;
    self!return-results:  $!con.ua.request($!con.request)
}

method PUT-something($endpoint, *%content) {
    $!con.request = HTTP::Request.new: PUT => $!con.URL.IO.add($endpoint).Str,
                                 |$!con.min-headers,
                                 :Content-Type<application/json>  ;
    $!con.request.add-content: to-json( %content );
    self!return-results:  $!con.ua.request($!con.request)
}


method POST-something($endpoint, *%content) {
    $!con.request = HTTP::Request.new: POST => $!con.URL.IO.add($endpoint).Str,
                                 |$!con.min-headers,
                                 :Content-Type<application/json>  ;
    $!con.request.add-content: to-json( %content );
    self!return-results:  $!con.ua.request($!con.request)
}

method DELETE-something($endpoint) {
    $!con.request = HTTP::Request.new: DELETE => $!con.URL.IO.add($endpoint).Str,
                                 |$!con.min-headers ;
    self!return-results:  $!con.ua.request($!con.request)
}

method !return-results($response) {
    $!con.response = $response ;
    with $response {
        .is-success ??
            .has-content ??
                return from-json( .content ) 
            !!
                ""
        !!    
            fail qq:to/END_HERE/
            Error while { $!con.request.method }ing { $!con.request.uri.path }: {.status-line}
            { .content if .has-content }
            END_HERE
    }
}
