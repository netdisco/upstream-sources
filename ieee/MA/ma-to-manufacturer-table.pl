#!/usr/bin/env perl

use strict;
use warnings;

use Text::CSV 'csv';
use Math::BigInt;

binmode STDOUT, ":utf8";

my %oui = ();

# conflicts of registered ranges with locally administered addresses, we'll skip these

# |company                            |abbrev                |base  |
# |-----------------------------------|----------------------|------|
# |RACAL-DATACOM                      |Racal-Datacom         |020701|
# |PERQ SYSTEMS CORPORATION           |Perq                  |021c7c|
# |LOGIC REPLACEMENT TECH. LTD.       |LogicReplacement      |026086|
# |3COM                               |3com                  |02608c|
# |RACAL-DATACOM                      |Racal-Datacom         |027001|
# |M/A-COM INC. COMPANIES             |M/A-ComCompanies      |0270b0|
# |DATA RECALL LTD.                   |DataRecall            |0270b3|
# |CARDIAC RECORDERS, INC.            |CardiacRecorders      |029d8e|
# |OLIVETTI TELECOMM SPA (OLTECO)     |OlivettiTelecomm      |02aa3c|
# |OCTOTHORPE CORP.                   |Octothorpe            |02bb01|
# |3COM                               |3com                  |02c08c|
# |Communication Machinery Corporation|CommunicationMachinery|02cf1c|
# |NIXDORF COMPUTER CORP.             |NixdorfComputer       |02e6d3|
# |DIGITAL EQUIPMENT CORPORATION      |DigitalEquipment      |aa0000|
# |DIGITAL EQUIPMENT CORPORATION      |DigitalEquipment      |aa0001|
# |DIGITAL EQUIPMENT CORPORATION      |DigitalEquipment      |aa0002|
# |DIGITAL EQUIPMENT CORPORATION      |DigitalEquipment      |aa0003|
# |DIGITAL EQUIPMENT CORPORATION      |DigitalEquipment      |aa0004|

my @conflict_bases = qw/
020701 021c7c 026086 02608c 027001
0270b0 0270b3 029d8e 02aa3c 02bb01
02c08c 02cf1c 02e6d3 
aa0000 aa0001 aa0002 aa0003 aa0004
/;

my $content = do { local $/; <STDIN> };
my $aoh = csv( in => \$content, headers => 'auto', encoding => 'UTF-8' );

foreach my $row (@$aoh) {
    next if $row->{'Organization Name'} eq 'IEEE Registration Authority';
    next if exists $oui{ lc $row->{'Assignment'} };

    $row->{abbrev} = shorten($row->{'Organization Name'});

    $row->{base} = lc $row->{'Assignment'};

    next if (grep { $_ eq $row->{base} } @conflict_bases);
    $row->{bits} = length($row->{base}) * 4;

    $row->{first} = $row->{'Assignment'} . '0' x ( 12 - length( $row->{'Assignment'} ) );
    $row->{last}  = $row->{'Assignment'} . 'F' x ( 12 - length( $row->{'Assignment'} ) );

    $row->{range} = '['. Math::BigInt->from_hex($row->{first})->as_int()
      .','. Math::BigInt->from_hex($row->{last})->as_int() .']';

    $oui{ $row->{base} } = $row;
}

foreach my $localbit (qw/2 6 a e/) {
  foreach my $firstdigit (qw/0 1 2 3 4 5 6 7 8 9 a b c d e f/){

    my $bits = 8;
    my $strbase = $firstdigit.$localbit.":00:00:00:00:00";
    my $strlast = $firstdigit.$localbit.":ff:ff:ff:ff:ff";
    my $assignment = $firstdigit.$localbit;

    my $randrow = {
      'Organization Name' => "randomized address [0-f][26ae]:...",
      'abbrev' => "randomized",
      'first' => $strbase,
      'last' => $strlast,
      'base' => $firstdigit.$localbit,
      'bits' => $bits,
      'range' => '['. Math::BigInt->from_hex($strbase =~ s/://gr)->as_int() .','. Math::BigInt->from_hex($strlast =~ s/://gr)->as_int() .']' 
    };

    #print "add local range $firstdigit$localbit:00:00:00:00:00 - $firstdigit$localbit:ff:ff:ff:ff:ff\n". Dumper($randrow);
    $oui{ $randrow->{base} } = $randrow;
  }
}

# COPY "manufacturer" ("company", "abbrev", "base", "bits", "first", "last", "range") FROM STDIN;
# XEROX CORPORATION	Xerox	000000	24	00:00:00:00:00:00	00:00:00:ff:ff:ff	[0,16777216)

foreach my $row (values %oui) {
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
      $row->{'Organization Name'},
      $row->{abbrev},
      $row->{base},
      $row->{bits},
      $row->{first},
      $row->{last},
      $row->{range};
}

exit 0;

# This subroutine is based on Wireshark's make-manuf
# http://anonsvn.wireshark.org/wireshark/trunk/tools/make-manuf
sub shorten {
    my $manuf = shift;

    #$manuf = decode("utf8", $manuf, Encode::FB_CROAK);
    $manuf = " " . $manuf . " ";

    # Remove any punctuation
    $manuf =~ tr/',.()/    /;

    # & isn't needed when Standalone
    $manuf =~ s/ \& / /g;

    # remove junk whitespace
    $manuf =~ s/\s+/ /g;

    # Remove any "the", "inc", "plc" ...
    $manuf
        =~ s/\s(?:the|inc|incorporated|plc|systems|corp|corporation|s\/a|a\/s|ab|ag|kg|gmbh|co|company|limited|ltd|holding|spa)(?= )//gi;

    # Convert to consistent case
    $manuf =~ s/(\w+)/\u\L$1/g;

    # Deviating from make-manuf for HP
    $manuf =~ s/Hewlett[-]?Packard/Hp/;

    # Truncate all names to first two words max 20 chars
    if (length($manuf) > 21) {
        my @twowords = grep {defined} (split ' ', $manuf)[0 .. 1];
        $manuf = join ' ', @twowords;
    }

    # Remove all spaces
    $manuf =~ s/\s+//g;

    #return encode( "utf8", $manuf );
    return $manuf;
}

__DATA__

    0C15C5000000   {
        Assignment               "0C15C5",
        bits                     24,
        first                    "0C15C5000000",
        last                     "0C15C5FFFFFF",
        "Organization Address"   "167, Churye-2Dong, Sasang-Gu, Busan   KR 617-716 " (dualvar: 167),
        "Organization Name"      "SDTEC Co., Ltd.",
        oui                      "0c:15:c5",
        Registry                 "MA-L",
        abbrev                   "Sdtec"
    },

    [98] {
             Assignment               "8C1F64117" (dualvar: 8),
             "Organization Address"   "Spinnereistrasse 10 St. Gallen  CH 9008 ",
             "Organization Name"      "Grossenbacher Systeme AG",
             Registry                 "MA-S"
         },
