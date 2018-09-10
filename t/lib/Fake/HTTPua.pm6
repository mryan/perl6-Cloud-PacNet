unit class Fake::HTTPua:ver<0.0.1>;
use HTTP::Request ;
has $.content;
has $.status-line;
has $.is-success;
has $.has-content;
has $.code;

constant TestDataDir = 't/data' ;
my $counter = BagHash.new ;

method !make-unique-name($m, $u is copy) {
    $u ~~ s:i[ ^^ 'http' s? '://' ] = '' ; 
    my $name = TestDataDir.IO.add($u).add($m).Str ;
    $name ~= ++$counter{$name} ~ '.json' ;
}

method get(|c)    { self!emulate: 'get',    |c }
method put(|c)    { self!emulate: 'put',    |c }
method post(|c)   { self!emulate: 'post',   |c }
method delete(|c) { self!emulate: 'delete', |c }

method request(HTTP::Request $r) {
    self!emulate($r.method.lc, $r.uri.Str);
}

method !emulate($method, $uri, Bool :$bin, *%header)  {
    $!is-success  = Nil ;   # the new undef
    $!has-content = Nil ;   # the new undef
    my $filename = self!make-unique-name($method, $uri);
    # say "# Using $filename contents to fake $method $uri" ;
    try {
        $!content = slurp $filename ;
        CATCH { 
            default {
                $!code = 'Fake::HTTPua' ;
                $!status-line = "Could not slurp $filename while fakeing '$method $uri'" ;
                $!is-success = False ;    # slurp failed
                # Drop out of try block and soldier on
            }
        }
    }
    $!is-success //= True ;    # Set True unless its already been defined
    $!has-content = True if $!content.defined && $!content.chars > 0 ;
    self 
}
