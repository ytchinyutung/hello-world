#!/usr/bin/perl

#use strict;
#use warnings;
use Data::Dumper;

#my $filename = "SL0004.txt";
#my $outfile = "OutputOdds1.txt";

print "Please enter the input file: " ;
$filename =  <STDIN>;
chomp $filename;
open(my $fh, "<", $filename) 
	or die "cannot open input file: $!";
print "Please enter the output file: ";
$outfile = <STDIN>;
chomp $outfile;
open(STDOUT, ">", $outfile)
	or die "cannot open output file: $!";
print "Your input are:  " , $filename, "   ", $outfile;

#if (-e $filename) { print "Odds1, Odds2\n"; }
#unless (-e $filename) { print "InFile Doesn't Exist!\n"; }

#
#Declaring variables
#	
my @v_string1=();
my $temp="";
#
# Below are Betbrain Patterns to be parsed!
#
my $pat0='newRow';				# Betbrain's main contents starting from here...
my $pat1='"rowId":';				# Hedging opportunity records, unique per opportunity
my $pat2='"returnValue":';           		# estimated profit margin of the opportunity
my $pat3='"name":';                  		# bet type of the opportunity
my $pat4='"startDate":';
my $pat5='"discName":';              		# sports type of the opportunity
my $pat6='"link":';
my $pat7='"aTitle":"Place this bet on '; 	# the broker's name, 
my $pat8='"outcomeName":';           		# team's name
my $pat9='"locationName":';          		# country name
my $pat10='"shortName":';			# The handicap information
my $pat11='"eventName":';			# The event name 
my $pat12='"scopeName":';			# Scope and other conditions of the offer

my $i=1;
my $j=1;
my $t_string="";
my $s_string="";
my $pos=0;
my $nxtpos=0;

my %seen = ();
my %k_table=();
$row_hashtbl1{$pos} = [] unless exists $row_hashtbl1{$pos};

while (defined ($line = <$fh>)) {
	chomp($line);
	$_=$line;
	if (/$pat0/) {
		#
		# Split the input data into rowId related strings 
		#
		@v_string1 = split /$pat1/, $_; 
		$j=1;
		foreach (@v_string1) {
			$temp = "";
			#
			# Parse the hash key = rowId and use it to hash its related strings
			#
			$t_string = \@v_string1;
			$nxtpos = index $t_string->[$j],qq/"/,1;
			$s_string=substr($t_string->[$j],1,$nxtpos-1);	
			#
			# Store away the key and the items in hash table %k_table 	
			#
			$pos = $nxtpos+1;
			$nxtpos = length $t_string->[$j];	
			if ($s_string ne "" ) { push @{$k_table{$s_string}},substr($t_string->[$j],$pos+1,$nxtpos-$pos+1);}
			++$j;
		}
	}    
}
$s_string = "";
foreach $s_string (sort keys %k_table) {
	#	
	# There are one-to-many relationships between the hash key and its related strings
	#
	if (defined $s_string) {
		@v_string1=@{$k_table{$s_string}};
		$t_string=\@v_string1;
		$j=0;
		$temp="";
		while (defined $t_string->[$j] and length $t_string->[$j]){
			#
			# Parse the startdate
			#			
			$_ = $t_string->[$j];
			if (/$pat4/){
				$nxtpos = index $t_string->[$j],qq/$pat4/,2;
				$pos = $nxtpos;
				$nxtpos = index $t_string->[$j],qq/,/,$pos;
				$temp = substr($t_string->[$j],$pos,$nxtpos-$pos);
				push @{$row_hashtbl1{$s_string}},$temp ;
			}
			#
			# Parse the returnValue & bet type
			#
			if (/$pat2/) {
				$nxtpos = index $t_string->[$j],qq/$pat2/,2;
				$pos = $nxtpos;
				$nxtpos = index $t_string->[$j],qq/,/,$pos;
				$temp = substr($t_string->[$j],$pos,$nxtpos-$pos);
				#
				# Make it friendly for comma delimited parser such as Excel
				#
				$temp =~ s/,/ /;
				push @{$row_hashtbl1{$s_string}},$temp ;
				$pos = index $t_string->[$j],qq/"name":/,$nxtpos;
				$nxtpos = index $t_string->[$j],qq/\}/,$pos;
				$temp = substr($t_string->[$j],$pos,$nxtpos-$pos);
				#
				# Make it friendly for comma delimited parser such as Excel
				#
				$temp =~ s/,/ /;
				push @{$row_hashtbl1{$s_string}},$temp ;
			}	
			#
			# Handle handicap, pain in the ass!
			#
			if (/$pat10/) {
				$nxtpos = index $t_string->[$j],qq/$pat10/,2;
				$pos = index $t_string->[$j],qq/$pat6/,$nxtpos;
				$nxtpos = $pos-2;
				$pos = rindex $t_string->[$j],qq/>/,$nxtpos;
				$temp = substr($t_string->[$j],$pos,$nxtpos-$pos+1);
				#
				# Make it friendly for comma delimited parser such as Excel
				#
				$temp =~ s/,/ /;
				$temp =~ s/\{/\"\"/;
				$temp =~ s/>/\"/;
				push @{$row_hashtbl1{$s_string}},'"Handicap":'.$temp ;
			}
			#
			# Parse the Leagues, event title and scope
			#
			if (/$pat9/) {
				$nxtpos = index $t_string->[$j],qq/$pat9/,2;
				$pos = $nxtpos;
				$nxtpos = index $t_string->[$j],qq/,/,$pos;
				$temp = substr($t_string->[$j],$pos,$nxtpos-$pos);
				#
				# Make it friendly for comma delimited parser such as Excel
				#
				$temp =~ s/,/ /;
				push @{$row_hashtbl1{$s_string}},$temp ;
			}
			if (/$pat11/) {
				$nxtpos = index $t_string->[$j],qq/$pat11/,2;
				$pos = $nxtpos;
				$nxtpos = index $t_string->[$j],qq/,/,$pos;
				$temp = substr($t_string->[$j],$pos,$nxtpos-$pos);
				#
				# Make it friendly for comma delimited parser such as Excel
				#
				$temp =~ s/,/ /;		
				push @{$row_hashtbl1{$s_string}},$temp ;
			}
			if (/$pat12/) {
				$nxtpos = index $t_string->[$j],qq/$pat12/,2;
				$pos = $nxtpos;
				$nxtpos = index $t_string->[$j],qq/,/,$pos;
				$temp = substr($t_string->[$j],$pos,$nxtpos-$pos);
				#
				# Make it friendly for comma delimited parser such as Excel
				#
				$temp =~ s/,/ /;
				push @{$row_hashtbl1{$s_string}},$temp ;
			}
			#
			# Parse the sports type
			#
			if (/$pat5/) {
				$nxtpos = index $t_string->[$j],qq/$pat5/,2;
				$pos = $nxtpos;
				$nxtpos = index $t_string->[$j],qq/,/,$pos;
				$temp = substr($t_string->[$j],$pos,$nxtpos-$pos);
				#
				# Make it friendly for comma delimited parser such as Excel
				#
				$temp =~ s/,/ /;
				push @{$row_hashtbl1{$s_string}},$temp ;
			}
			#
			# Parse the team name and if they are back/lay
			#
			if (/$pat8/) {
				$nxtpos = index $t_string->[$j],qq/$pat8/,2;
				$pos = $nxtpos;
				$nxtpos = index $t_string->[$j],qq/,/,$pos;
				$pos = index $t_string->[$j],qq/"isBack":/,$nxtpos;
				$nxtpos = index $t_string->[$j],qq/}/,$pos;
				$temp = substr($t_string->[$j],$pos,$nxtpos-$pos);
				#
				# Make it friendly for comma delimited parser such as Excel
				#
				$temp =~ s/,/ /;
				push @{$row_hashtbl1{$s_string}},$temp ;
			}
			#
			# Parse the broker's title and the odds following it
			#
			if (/$pat7/) {
				$nxtpos = index $t_string->[$j],qq/$pat7/,2;
				$pos = $nxtpos + 28;
				$nxtpos = index $t_string->[$j],qq/now/,$pos;
				$temp = substr($t_string->[$j],$pos,$nxtpos-$pos);
				#
				# Make it friendly for comma delimited parser such as Excel
				#
				$temp =~ s/,/ /;
				push @{$row_hashtbl1{$s_string}},$temp ;
				$pos = index $t_string->[$j],qq/"odds":/,$nxtpos;
				$nxtpos = index $t_string->[$j],qq/}/,$pos;
				$temp = substr($t_string->[$j],$pos,$nxtpos-$pos);
				#
				# Make it friendly for comma delimited parser such as Excel
				#
				$temp =~ s/,/ /;
				push @{$row_hashtbl1{$s_string}},$temp ;
			}
			++$j;
		}
	}
}
# print Dumper(\%k_table);
# print Dumper(\%row_hashtbl1);
foreach $s_string (sort keys %row_hashtbl1) {
	if (defined $s_string and length $s_string) {
		print $s_string, " , ";
		@v_string1=@{$row_hashtbl1{$s_string}};
		$t_string=\@v_string1;
		$j=0;
		while (defined $t_string->[$j] and length $t_string->[$j]){
			print $t_string->[$j]," , ";
			++$j;		
		}
		print "\n";
	}
}
