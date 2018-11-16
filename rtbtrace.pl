#! /usr/bin/perl
# Copyright (C) 2018 - Steve Schnepp - Apache2

use strict;
use warnings;
	
# Give the blocksize as first arg
my $nb_sectors = shift;
if (! $nb_sectors) {
	die "Should give the number of 512b sectors as first arg";
}

my $fileno = 0;
my $tstp_step = 1 / 25; # 25 Hz
my $last_tstp = 0;


my @io_ops = ();
while( my $line = <>) {
	chomp($line);
	# 8,0    3        1     0.000000000   697  G   W 223490 + 8 [kjournald]
	my ($device, $cpu_id, $seqno, $tstp, $pid, $action, $mode, $offset, $dummy, $length, $detail) = split(/ +/, trim($line), 11);

	# Only take complete lines
	next unless $detail;

	# Only take the C (completed) requests to take care of an eventual buffering/queuing
	next unless $action eq 'C';

	# Flush if needed. Assumes the data is timestamp ordered
	if ($tstp > $last_tstp + $tstp_step) {
		$last_tstp += $tstp_step;

		# flush to img
		draw(\@io_ops);

		# flush the in-flight IO ops
		@io_ops = ();
	}

	# Fill the in-flight IO ops
	push @io_ops, [ $offset, $mode, $length ];
} continue {
}

sub draw 
{
	my ($io_ops) = @_;

	# 720p
	my $pixel_size = 10;
	my $columns = 1280 / $pixel_size;
	my $rows = 720 / $pixel_size;
	my $kb_per_pixels = $nb_sectors / ($columns * $rows) / 2;

	use GD;

	my $img = new GD::Image($columns*$pixel_size, $rows*$pixel_size);
	# allocate some colors
	my $black = $img->colorAllocate(0,0,0); # First color, also background
	my $white = $img->colorAllocate(255,255,255);
	my $red = $img->colorAllocate(255,0,0);    
	my $blue = $img->colorAllocate(0,0,255);
	my $green = $img->colorAllocate(0,255,0);

	# Update the status line
	my $last_tstp_as_string = sprintf("%.2f", $last_tstp);
	$img->string(gdSmallFont, 0, 0, "t: $last_tstp_as_string", $white);

	# Iterate & fill the window
	for my $io_op (@$io_ops) {
		my ($offset_in_kb, $mode, $length) = @$io_op;


		# Green = read, Red = Write
		my $color = $white;
		if ($mode =~ m/R/) {
			$color = $green;
		} elsif ($mode =~ m/W/) {
			$color = $red;
		} elsif ($mode =~ m/D/) {
			$color = $blue;
		}

		my $len = int($length / $kb_per_pixels) + 1;
		for my $i (0 .. ($len-1)) {
			my $offset_in_pixels = ($offset_in_kb + $len) / $kb_per_pixels;
			my $x = int ($offset_in_pixels % $columns);
			my $y = int ($offset_in_pixels / $columns);
			$img->rectangle($x *$pixel_size, $y *$pixel_size, $x*$pixel_size+$pixel_size, $y*$pixel_size+$pixel_size, $color);
		}
	}

	# Open a file for writing 
#	binmode STDOUT;
#	print $img->gif();

#	return;

	my $filename = "t-" . sprintf("%05d", $fileno) . ".png";
	print STDERR "write $filename";
	open(PICTURE, "> $filename") or die("Cannot open file for writing");

	# Make sure we are writing to a binary stream
	binmode PICTURE;
	# Convert the image to PNG and print it to the file PICTURE
	print PICTURE $img->png();

	close PICTURE;
	print STDERR ".\n";
	$fileno ++;
}

# haaa.. this should really be part of Perl :-)
# And, it was benchmark worthy
# https://www.perlmonks.org/?node_id=694849
sub trim
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}
