####################
# GEO::IPFREE TEST #
####################

use Test;
BEGIN { plan tests => 2 };
use Geo::IPfree;

#########################

my ($country,$country_name,$ip) = Geo::IPfree::LookUp("127.0.0.1") ;
ok($country,'L0');

#########################

my ($country,$country_name,$ip) = Geo::IPfree::LookUp("10.0.0.1") ;
ok($country,'I0');

#########################


