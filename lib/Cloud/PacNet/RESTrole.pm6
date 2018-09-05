use JSON::Fast  ;
use HTTP::UserAgent ;

unit role RESTrole ;
has $.owner ;
my Str \URL = 'https://api.packet.net' ;

method GET-something($endpoint) {
    my $req = HTTP::Request.new: GET => URL.IO.add($endpoint).Str, 
                                 :X-Auth-Token($!owner.API-token) ,
                                 :Accept<application/json>  ;
    self!return-results:  $!owner.ua.request($req)
}

method PUT-something($endpoint, *%content) {
    my $req = HTTP::Request.new: PUT => URL.IO.add($endpoint).Str,
                                 :X-Auth-Token($!owner.API-token) ,
                                 :Content-Type<application/json> ,
                                 :Accept<application/json>  ;
    $req.add-content: to-json( %content );
    self!return-results:  $!owner.ua.request($req)
}


method POST-something($endpoint, *%content) {
    my $req = HTTP::Request.new: POST => URL.IO.add($endpoint).Str,
                                 :X-Auth-Token($!owner.API-token) ,
                                 :Content-Type<application/json> ,
                                 :Accept<application/json>  ;
    $req.add-content: to-json( %content );
    self!return-results:  $!owner.ua.request($req)
}

method DELETE-something($endpoint) {
    my $req = HTTP::Request.new: DELETE => URL.IO.add($endpoint).Str,
                                 :X-Auth-Token($!owner.API-token),
                                 :Accept<application/json>  ;
    self!return-results:  $!owner.ua.request($req)
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
