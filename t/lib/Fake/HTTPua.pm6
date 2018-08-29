unit class Fake::HTTPua:ver<0.0.1>;
has $.decoded-content;
has $.status-line;
has $.is-success;
has $.code;

constant TestDataDir = 't/data' ;
my $counter = BagHash.new ;

method !make-unique-name($m, $u is copy) {
    $u ~~ s:i[ ^^ 'http' s? '://' ] = '' ; 
    my $name = TestDataDir.IO.add($u).add($m) ;
    $name ~ ++$counter{$name} ~ '.json'
}

method get(|c)    { self!emulate: 'get',    |c }
method put(|c)    { self!emulate: 'put',    |c }
method post(|c)   { self!emulate: 'post',   |c }
method delete(|c) { self!emulate: 'delete', |c }

method !emulate($method, $uri, Bool :$bin, *%header)  {
    $!is-success = Nil ;   # the new undef
    my $filename = self!make-unique-name($method, $uri);
    try {
        $!decoded-content = slurp $filename ;
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
    self 
}