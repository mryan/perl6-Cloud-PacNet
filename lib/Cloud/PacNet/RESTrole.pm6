use JSON::Fast  ;
use HTTP::UserAgent ;

unit role RESTrole ;
has $.shared handles <response request> ;

method GET-something($endpoint) {
    self.request = HTTP::Request.new: GET => $!shared.URL.IO.add($endpoint).Str, 
                                 |$!shared.min-headers ;
    self!return-results:  $!shared.ua.request(self.request)
}

method PUT-something($endpoint, *%content) {
    self.request = HTTP::Request.new: PUT => $!shared.URL.IO.add($endpoint).Str,
                                 |$!shared.min-headers,
                                 :Accept<application/json>  ;
    self.request.add-content: to-json( %content );
    self!return-results:  $!shared.ua.request(self.request)
}


method POST-something($endpoint, *%content) {
    self.request = HTTP::Request.new: POST => $!shared.URL.IO.add($endpoint).Str,
                                 |$!shared.min-headers,
                                 :Accept<application/json>  ;
    self.request.add-content: to-json( %content );
    self!return-results:  $!shared.ua.request(self.request)
}

method DELETE-something($endpoint) {
    self.request = HTTP::Request.new: DELETE => $!shared.URL.IO.add($endpoint).Str,
                                 |$!shared.min-headers ;
    self!return-results:  $!shared.ua.request(self.request)
}

method !return-results($response) {
    self.response = $response ;
    with $response {
        .is-success ??
            .has-content ??
                return from-json( .content ) 
            !!
                "" but True
        !!    
            fail qq:to/END_HERE/
            Error while { self.request.method }ing: {.status-line}
            { .content if .has-content }
            END_HERE
    }
}
