#!/usr/local/bin/perl -w

#######################################################################################
#
# Copyright (c) 2009 - 2015 J. Craig Venter Institute.
#   This file is part of JCVI VIGOR
# 
#   JCVI VIGOR is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#   
#   JCVI VIGOR is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#   
#   You should have received a copy of the GNU General Public License
#   along with JCVI VIGOR.  If not, see <http://www.gnu.org/licenses/>.
# 
# Contributors:
#     Shiliang Wang - Initial idea and implementation.
#     Jeff Hoover - Redesigning, refactoring, and expanding the scope.
#     Susmita Shrivastava and Neha Gupta - Creation and curation of sequence databases.
#     Paolo Amedeo and Danny Katzel - Maintenance and further improvements.
#
#######################################################################################

use strict;
use Getopt::Std;
use Cwd 'realpath';
use File::Basename;

my $program = realpath($0);
our $myBin = dirname( dirname($program) );
our $myData = "$myBin/data";
our $myConf = "$myBin/conf";
require "$myBin/VIGOR3.pm";
$|++;

my $fasta = shift @ARGV;
my @filters = @ARGV;

my %refseqs = loadFasta( $fasta );
set_reference_seqs( %refseqs );

# write results, sorted by gene
for my $seqid ( sort { compare( $a, $b )+0 } keys %refseqs ) {
    my $ref = get_reference_seq( $seqid );
    
    my $skip = 0;
    for my $filter ( @filters ) {
        if ( $$ref{defline} =~ /$filter/i ) {
            $skip = 1;
            last;
        }
    }
    if ( $skip ) { next }

    my $seq = $$ref{sequence};
    $seq =~ s/\*$//;
    my $len = length( $seq );
    $seq =~ s/(.{60})/$1\n/g;
    $seq =~ s/\n$//;
    $$ref{defline} =~ s/ len[gth]*=[0-9]+//i;
    #print "\n>$$protein{defline} length=$len gene_variation=$genevar{$gene}{variation}\n$seq\n";
    if ( $$ref{defline} =~ / length=/ ) {
        print "\n>$$ref{defline}\n$seq\n";
    }
    else {
        print "\n>$$ref{defline} length=$len\n$seq\n";
    }
}
exit(0);

sub compare {
    my ( $a, $b ) = @_;

    my $genea = get_reference_name( $a );
    my $geneb = get_reference_name( $b );
    if ( $genea lt $geneb ) { return -1 }
    if ( $genea gt $geneb ) { return 1 }
    
#print "GENE TIE $genea ALEN $refseqs{$a}{seqlen} vs BLEN $refseqs{$b}{seqlen}\n";    
    if ( $refseqs{$a}{seqlen} < $refseqs{$b}{seqlen} ) { return -1 }
    if ( $refseqs{$a}{seqlen} > $refseqs{$b}{seqlen} ) { return 1 }
    
    return $a cmp $b;
}