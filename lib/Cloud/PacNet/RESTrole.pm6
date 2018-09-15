use JSON::Fast  ;
use HTTP::Request ;
use Cloud::PacNet::Connection ;

unit role RESTrole ;
has $.con handles <ua response request> = Cloud::PacNet::Connection.instance ;

method GET-something($endpoint) {
    self.request = HTTP::Request.new: GET => $!con.URL.IO.add($endpoint).Str, 
                                 |$!con.min-headers ;
    self!return-results:  $!con.ua.request(self.request)
}

method PUT-something($endpoint, *%content) {
    self.request = HTTP::Request.new: PUT => $!con.URL.IO.add($endpoint).Str,
                                 |$!con.min-headers,
                                 :Content-Type<application/json>  ;
    self.request.add-content: to-json( %content );
    self!return-results:  $!con.ua.request(self.request)
}


method POST-something($endpoint, *%content) {
    self.request = HTTP::Request.new: POST => $!con.URL.IO.add($endpoint).Str,
                                 |$!con.min-headers,
                                 :Content-Type<application/json>  ;
    self.request.add-content: to-json( %content );
    self!return-results:  $!con.ua.request(self.request)
}

method DELETE-something($endpoint) {
    self.request = HTTP::Request.new: DELETE => $!con.URL.IO.add($endpoint).Str,
                                 |$!con.min-headers ;
    self!return-results:  $!con.ua.request(self.request)
}

method !return-results($response) {
    self.response = $response ;
    with $response {
        .is-success ??
            .has-content ??
                return from-json( .content ) 
            !!
                ""
        !!    
            fail qq:to/END_HERE/
            Error while { self.request.method }ing { self.request.uri.path }: {.status-line}
            { .content if .has-content }
            END_HERE
    }
}
