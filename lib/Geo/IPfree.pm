#############################################################################
## Name:        Geo/IPfree.pm
## Purpose:     Look up country of IP Address.
## Author:      Graciliano M. P.
## Modified by:
## Created:     20/10/2002
## RCS-ID:      
## Copyright:   (c) 2002 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Geo::IPfree;
use 5.006;
use Carp qw() ;
use strict qw(vars) ;

require Exporter;
our @ISA = qw(Exporter);

our $VERSION = '0.01';

our @EXPORT = qw(LookUp LoadDB) ;
our @EXPORT_OK = @EXPORT ;

my $def_db = 'ipscountry.dat' ;

my @baseX = qw(0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z . , ; ' " ` < > { } [ ] = + - ~ * @ # % $ & ! ?) ;

my %countrys = qw(
-- N/A L0 localhost I0 IntraNet A1 Anonymous_Proxy A2 Satellite_Provider
AD Andorra AE United_Arab_Emirates AF Afghanistan AG Antigua_and_Barbuda AI Anguilla AL Albania AM Armenia AN Netherlands_Antilles 
AO Angola AP Asia/Pacific_Region AQ Antarctica AR Argentina AS American_Samoa AT Austria AU Australia AW Aruba AZ Azerbaijan BA Bosnia_and_Herzegovina BB Barbados BD Bangladesh 
BE Belgium BF Burkina_Faso BG Bulgaria BH Bahrain BI Burundi BJ Benin BM Bermuda BN Brunei_Darussalam BO Bolivia BR Brazil BS Bahamas BT Bhutan BV Bouvet_Island BW Botswana 
BY Belarus BZ Belize CA Canada CC Cocos_(Keeling)_Islands CD Congo,_The_Democratic_Republic_of_the CF Central_African_Republic CG Congo CH Switzerland CI Cote_D'Ivoire CK Cook_Islands 
CL Chile CM Cameroon CN China CO Colombia CR Costa_Rica CU Cuba CV Cape_Verde CX Christmas_Island CY Cyprus CZ Czech_Republic DE Germany DJ Djibouti DK Denmark DM Dominica 
DO Dominican_Republic DZ Algeria EC Ecuador EE Estonia EG Egypt EH Western_Sahara ER Eritrea ES Spain ET Ethiopia EU Europe FI Finland FJ Fiji FK Falkland_Islands_(Malvinas) 
FM Micronesia,_Federated_States_of FO Faroe_Islands FR France FX France,_Metropolitan GA Gabon GB United_Kingdom GD Grenada GE Georgia GF French_Guiana GH Ghana GI Gibraltar 
GL Greenland GM Gambia GN Guinea GP Guadeloupe GQ Equatorial_Guinea GR Greece GS South_Georgia_and_the_South_Sandwich_Islands GT Guatemala GU Guam GW Guinea-Bissau GY Guyana 
HK Hong_Kong HM Heard_Island_and_McDonald_Islands HN Honduras HR Croatia HT Haiti HU Hungary ID Indonesia IE Ireland IL Israel IN India IO British_Indian_Ocean_Territory 
IQ Iraq IR Iran,_Islamic_Republic_of IS Iceland IT Italy JM Jamaica JO Jordan JP Japan KE Kenya KG Kyrgyzstan KH Cambodia KI Kiribati KM Comoros KN Saint_Kitts_and_Nevis 
KP Korea,_Democratic_People's_Republic_of KR Korea,_Republic_of KW Kuwait KY Cayman_Islands KZ Kazakhstan LA Lao_People's_Democratic_Republic LB Lebanon LC Saint_Lucia LI Liechtenstein 
LK Sri_Lanka LR Liberia LS Lesotho LT Lithuania LU Luxembourg LV Latvia LY Libyan_Arab_Jamahiriya MA Morocco MC Monaco MD Moldova,_Republic_of MG Madagascar MH Marshall_Islands 
MK Macedonia,_the_Former_Yugoslav_Republic_of ML Mali MM Myanmar MN Mongolia MO Macau MP Northern_Mariana_Islands MQ Martinique MR Mauritania MS Montserrat MT Malta MU Mauritius 
MV Maldives MW Malawi MX Mexico MY Malaysia MZ Mozambique NA Namibia NC New_Caledonia NE Niger NF Norfolk_Island NG Nigeria NI Nicaragua NL Netherlands NO Norway NP Nepal 
NR Nauru NU Niue NZ New_Zealand OM Oman PA Panama PE Peru PF French_Polynesia PG Papua_New_Guinea PH Philippines PK Pakistan PL Poland PM Saint_Pierre_and_Miquelon PN Pitcairn 
PR Puerto_Rico PS Palestinian_Territory,_Occupied PT Portugal PW Palau PY Paraguay QA Qatar RE Reunion RO Romania RU Russian_Federation RW Rwanda SA Saudi_Arabia SB Solomon_Islands 
SC Seychelles SD Sudan SE Sweden SG Singapore SH Saint_Helena SI Slovenia SJ Svalbard_and_Jan_Mayen SK Slovakia SL Sierra_Leone SM San_Marino SN Senegal SO Somalia SR Suriname 
ST Sao_Tome_and_Principe SV El_Salvador SY Syrian_Arab_Republic SZ Swaziland TC Turks_and_Caicos_Islands TD Chad TF French_Southern_Territories TG Togo TH Thailand TJ Tajikistan 
TK Tokelau TM Turkmenistan TN Tunisia TO Tonga TP East_Timor TR Turkey TT Trinidad_and_Tobago TV Tuvalu TW Taiwan,_Province_of_China TZ Tanzania,_United_Republic_of UA Ukraine 
UG Uganda UM United_States_Minor_Outlying_Islands US United_States UY Uruguay UZ Uzbekistan VA Holy_See_(Vatican_City_State) VC Saint_Vincent_and_the_Grenadines VE Venezuela 
VG Virgin_Islands,_British VI Virgin_Islands,_U.S. VN Vietnam VU Vanuatu WF Wallis_and_Futuna WS Samoa YE Yemen YT Mayotte YU Yugoslavia ZA South_Africa ZM Zambia ZR Zaire ZW Zimbabwe
) ;

my (%baseX,$THIS) ;

#######
# NEW #
#######

sub new {
  my ($class, $db_file) = @_ ;

  if ($#_ <= 0 && $_[0] !~ /^[\w:]+$/) {
    $class = 'Geo::IPfree' ;
    $db_file = $_[0] ;
  }
  
  my $this = {} ;
  bless($this , $class) ;

  if (!defined $db_file) { $db_file = &find_db_file ;}
  
  $this->LoadDB($db_file) ;

  return( $this ) ;
}

##########
# LOADDB #
##########

sub LoadDB {
  my $this = shift ;
  my ( $db_file ) = @_ ;

  if (-d $db_file) { $db_file .= "/$def_db" ;}

  if (!-s $db_file) { Carp::croak("Can't load database: $db_file") ;}

  $this->{db} = $db_file ;

  my ($handler,$buffer) ;
  open($handler,$db_file) ;
  
  if ( $this->{pos} ) { delete($this->{pos}) ;}
  
  while( sysread($handler, $buffer , 1 , length($buffer) ) ) {

    if ($buffer =~ /##headers##(\d+)##$/s  ) {
      my $headers ;
      sysread($handler, $headers , $1 ) ;
      my (%head) = ( $headers =~ /(\d+)=(\d+)/gs );
      foreach my $Key ( keys %head ) { $this->{pos}{$Key} = $head{$Key} ;}
      $buffer = '' ;
    }
    elsif ($buffer =~ /##start##$/s  ) {
      my $pos = tell($handler) ;
      $this->{start} = $pos ;
      last ;
    }
  }
  
  $this->{handler} = $handler ;
}

##########
# LOOKUP #
##########

sub LookUp {
  my $this ;
  
  if ($#_ == 0) {
    if ($THIS) { $this = $THIS ;}
    else {
      $this = Geo::IPfree->new() ;
      $THIS = $this ;
    }
  }
  else { $this = shift ;}

  my ( $ip ) = @_ ;
  
  $ip =~ s/\.+/\./gs ;
  $ip =~ s/^\.// ;
  $ip =~ s/\.$// ;
  
  if ($ip !~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) { $ip = nslookup($ip) ;}
  
  my $ipnb = ip2nb($ip) ;
  
  my $buf_pos = 0 ;
  
  foreach my $Key ( sort {$a <=> $b} keys %{$this->{pos}} ) {
    if ($this->{pos}{$Key} && $ipnb <= $Key) { $buf_pos = $this->{pos}{$Key} ; last ;}
  }
  
  seek($this->{handler} , $buf_pos + $this->{start} , 0) ;
  
  my (@ret,$buffer) ;
  
  while( sysread($this->{handler} , $buffer , 7) ) {
    my $country = substr($buffer , 0 , 2) ;
    my $iprange = baseX2dec( substr($buffer , 2) ) ;
    if ($ipnb >= $iprange) {
      @ret = ($country,$countrys{"\U$country\E"}) ;
      $ret[1] =~ s/_/ /gs ;
      last ;
    }
  }

  return( @ret , $ip ) ;
}

############
# NSLOOKUP #
############

sub nslookup {
  my ( $host ) = @_ ;
  require Socket ;
  my $iaddr = Socket::inet_aton($host) ;
  my @ip = unpack('C4',$iaddr) ;
  if (! @ip && ! $_[1]) { return( &nslookup("www.$host",1) ) ;}
  return( join (".",@ip) ) ;
}

################
# FIND_DB_FILE #
################

sub find_db_file {
  my $lib_path ;

  foreach my $Key ( keys %INC ) {
    if ($Key =~ /^IPfree.pm$/i) {
      my ($lib) = ( $INC{$Key} =~ /^(.*?)[\\\/]+[^\\\/]+$/gs ) ;
      if (-e "$lib/$def_db") { $lib_path = $lib ; last ;}
    }
  }

  if ($lib_path eq '') {
    foreach my $INC_i ( @INC ) {
      my $lib = "$INC_i/Geo" ;
      if (-e "$lib/$def_db") { $lib_path = $lib ; last ;}
    }
  }
  
  if ($lib_path eq '') {
    foreach my $dir ( @INC , '/tmp' , '/usr/local/share' , '/usr/local/share/GeoIPfree' ) {
      if (-e "$dir/$def_db") { $lib_path = $dir ; last ;}
    }
  }
  
  return( "$lib_path/$def_db" ) ;
}


#########
# IP2NB #
#########

sub ip2nb {
  my @ip = split(/\./ , $_[0]) ;
  return( 16777216* $ip[0] + 65536* $ip[1] + 256* $ip[2] + $ip[3] ) ;
}

#########
# NB2IP #
#########

sub nb2ip {
  my ( $ipn ) = @_ ;
  
  my @ip ;
  
  my $x = $ipn ;
  
  while($x > 1) {
    my $c = $x / 256 ;
    my $ci = int($x / 256) ;

    my $r = $x - ($ci*256) ;
    push(@ip , $r) ;

    $x = $ci ;
  }
  
  push(@ip , $x) if $x > 0 ;
  
  while( $#ip < 3 ) { push(@ip , 0) ;}
  
  @ip = reverse (@ip) ;
    
  return( join (".", @ip) ) ;
}
 
#############
# DEC2BASEX #
#############

sub dec2baseX {
  my ( $dec ) = @_ ;
  
  my @base ;
  my $base = @baseX ;
  
  my $x = $dec ;
  
  while($x > 1) {
    my $c = $x / $base ;
    my $ci = int($x / $base) ;

    my $r = $x - ($ci*$base) ;
    push(@base , $r) ;

    $x = $ci ;
  }
  
  push(@base , $x) if $x > 0 ;
  
  while( $#base < 4 ) { push(@base , 0) ;}
  
  my $baseX ;
  
  foreach my $base_i ( reverse @base ) {
    $baseX .= $baseX[$base_i] ;
  }
  
  return( $baseX ) ;
}

#############
# BASEX2DEC #
#############

sub baseX2dec {
  my ( $baseX ) = @_ ;
  
  if (! %baseX ) {
    my $c = 0 ;
    %baseX = map { $_ => ($c++) } @baseX ;
  }
  
  my $base = @baseX ;
  my @base = split("" , $baseX) ;
  my $dec ;
  
  my $i = -1 ;
  foreach my $base_i ( reverse @base ) {
    $i++ ;
    my $n = $baseX{$base_i} ;
    
    $dec += $n * ($base**$i) ;
  }
  
  return( $dec ) ;
}

#######
# END #
#######

1;

__END__

=head1 NAME

Geo::IPfree - Look up country of IP Address. This module make this off-line and the DB of IPs is free.

=head1 SYNOPSIS

  use Geo::IPfree;
  my ($country,$country_name) = Geo::IPfree::LookUp("192.168.0.1") ;
  
  ... or ...
  
  use Geo::IPfree qw(LookUp) ;
  my ($country,$country_name) = LookUp("200.176.3.142") ;
  
  ... or ...

  use Geo::IPfree;
  my $GeoIP = Geo::IPfree->new('/GeoIPfree/ipscountry.dat') ;
  my ($country,$country_name,$ip) = $GeoIP->LookUp("www.cnn.com") ; ## Getting by Hostname.
  
  $GeoIP->LoadDB('/GeoIPfree/ips.dat') ;
  
  my ($country,$country_name,$ip) = $GeoIP->LookUp("www.sf.net") ; ## Getting by Hostname.
  
  ... or ...
  
  use Geo::IPfree;  
  my $GeoIP = Geo::IPfree::new() ; ## Using the default DB!
  my ($country,$country_name) = $GeoIP->LookUp("64.236.24.28") ;

=head1 DESCRIPTION

  This package comes with it's own database to look up the IP's country, and is totally free.
  
  Take a look in CPAN for updates...
  
=head1 METHODS

=over 4

=item LoadDB

Load the database to use to LookUp the IPs.

=item LookUp

Returns the ISO 3166 country (XX) code for an IP address or Hostname.

**If you send a Hostname you will need to be connected to the internet to resolve the host IP.

=back

=head1 VARS

=over 4

=item $GeoIP->{db}

The database file in use.

=item $this->{handler}

The database file handler.

=back

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


