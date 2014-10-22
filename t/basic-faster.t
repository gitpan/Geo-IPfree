use strict;
use warnings;

use Test::More tests => 13;

use Geo::IPfree;
my $g = Geo::IPfree->new;
$g->Faster;

{    # localhost
    my ( $country, $country_name, $ip ) = $g->LookUp( '127.0.0.1' );
    is( $country, 'ZZ' );
    is( $country_name, 'Reserved for private IP addresses' );
}

{    # intranet
    my ( $country, $country_name, $ip ) = $g->LookUp( '10.0.0.1' );
    is( $country, 'ZZ' );
    is( $country_name, 'Reserved for private IP addresses' );
}

{    # www.nic.br
    my ( $country, $country_name, $ip ) = $g->LookUp( '200.160.7.2' );
    is( $country,      'BR' );
    is( $country_name, 'Brazil' );
}

{    # www.nic.us
    my ( $country, $country_name, $ip ) = $g->LookUp( '209.173.53.26' );
    is( $country,      'US' );
    is( $country_name, 'United States' );
}

{    # www.nic.fr
    my ( $country, $country_name, $ip ) = $g->LookUp( '192.134.4.20' );
    is( $country,      'EU' );
    is( $country_name, 'Europe' );
}

SKIP: {    # does not exist
    my @result = $g->LookUp( 'dne.undef' );
    skip '"dne.undef" should not resolve, but it does for you.', 1
        if @result == 3;
    is( scalar @result, 0, 'undef result' );
}

# rudimentary cache check
ok( $g->{ CACHE }, 'cache exists' );
$g->Clean_Cache;
ok( !$g->{ CACHE }, 'cache cleared' );
