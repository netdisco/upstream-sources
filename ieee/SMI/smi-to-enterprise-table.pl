#!/usr/bin/env perl

use strict;
use warnings;

binmode STDOUT, ":utf8";

my @lines = <STDIN>;

my $seen_start = 0;
my $number = 0;

foreach my $row (@lines) {
    next if !defined $row;
    chomp $row;
    next if not length $row;

    $seen_start = 1 if $row eq '1';
    next if not $seen_start;

    if ($row =~ m/^\d+$/) {
        $number = $row;
    }
    elsif ($row =~ m/^\s\s\S/) {
        $row =~ s/^\s+|\s+$//g;
        print "$number\t$row\n";
    }
    else {
        $number = 0;
        next;
    }
}

exit 0;

__DATA__

Decimal
| Organization
| | Contact
| | | Email
| | | |
0
  Reserved
    Internet Assigned Numbers Authority
      iana&iana.org
1
  NxNetworks
    Michael Kellen
      OID.Admin&NxNetworks.com
2
  IBM (https://w3.ibm.com/standards )
    Glenn Daly
      gdaly&us.ibm.com


