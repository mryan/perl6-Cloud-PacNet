use JSON::Fast  ;
use HTTP::Request ;
use Cloud::PacNet::Connection ;

unit role RESTrole ;
has $.con = Cloud::PacNet::Connection.instance ;

method GET-something($endpoint) {
    $!con.request = HTTP::Request.new: GET => $!con.host.add($endpoint).Str, 
                                 |$!con.min-headers ;
    self!return-results:  $!con.ua.request($!con.request)
}

method PUT-something($endpoint, *%content) {
    $!con.request = HTTP::Request.new: PUT => $!con.host.add($endpoint).Str,
                                 |$!con.min-headers,
                                 :Content-Type<application/json>  ;
    $!con.request.add-content: to-json( %content );
    self!return-results:  $!con.ua.request($!con.request)
}


method POST-something($endpoint, *%content) {
    $!con.request = HTTP::Request.new: POST => $!con.host.add($endpoint).Str,
                                 |$!con.min-headers,
                                 :Content-Type<application/json>  ;
    $!con.request.add-content: to-json( %content );
    self!return-results:  $!con.ua.request($!con.request)
}

method DELETE-something($endpoint) {
    $!con.request = HTTP::Request.new: DELETE => $!con.host.add($endpoint).Str,
                                 |$!con.min-headers ;
    self!return-results:  $!con.ua.request($!con.request)
}

method !return-results($response) {
    $!con.response = $response ;
    with $response {
        .is-success ??
            # When doing /actions (reboot), getting zero length Buf from .content 
            # with .is-text set to "True" (!)  and content-type header set to 
            # 'applications/json'.  Cant call .chars on Bufs to check length

            # .has-content  &&
            .content.isa(Str) && .content.chars > 0 &&
            .content-type.starts-with('application/json') ??
                return from-json( .content ) 
            !!
                return ""  # Empty but defined
        !!    
            fail qq:to/END_HERE/
            Error while { $!con.request.method }ing { $!con.request.uri.path }: {.status-line}
            { .content if .has-content }
            END_HERE
    }
}
