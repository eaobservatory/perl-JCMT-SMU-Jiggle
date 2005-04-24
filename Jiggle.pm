package JCMT::SMU::JigPattern;

=head1 NAME

JCMT::SMU::JigPattern - find out details of a JCMT SMU jiggle pattern

=head1 SYNOPSIS

  use JCMT::SMU::JigPattern;

  my $smu = new JCMT::SMU::JigPattern( File => $file );


=head1 DESCRIPTION

This class enables easy access to jiggle parameters associated
with a particular jiggle file. This includes the actual offsets and
the number of jiggle positions.

=cut

use 5.006;
use strict;
use warnings;
use Carp;

use List::Util qw/ min max /;

use vars qw/ $VERSION /;

$VERSION = sprintf("%d.%03d", q$Revision$ =~ /(\d+)\.(\d+)/);

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new JigPattern object. Can be created from a filename.

  $jig = new JCMT::SMU::JigPattern( File => $file );

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # Read the arguments
  my %args = @_;

  croak "Must specify a file name" unless exists $args{File};

  my $jig = bless {
		   FileName => undef,
		   Pattern => [],
		   ScaleFactor => 1,
		  };

  $jig->_import_file( $args{File} );

  return $jig;

}

=head2 Accessor Methods

=over 4

=item B<filename>

Name of XML file used to construct the object (if any).

=cut

sub filename {
  my $self = shift;
  if (@_) { $self->{FileName} = shift; }
  return $self->{FileName};
}

=item B<scale>

The scale factor to be applied to the jiggle pattern when offsets
are retrieved or extent calculated. This number is multiplied by
each of the positions in the original pattern. Defaults to 1.

  $jig->scale( 3 );

=cut

sub scale {
  my $self = shift;
  if (@_) { $self->{ScaleFactor} = shift; }
  return $self->{ScaleFactor};
}

=item B<pattern>

Retrieves (or sets) the jiggle pattern as a list of arrays containing
x,y pairs in the pattern.

  @pattern = $jig->pattern();

For the above, for a 9 position jiggle, C<@pattern> would contain 9 elements, each of which was a reference to an array containing two elements.

See the C<xy> method to get independy X + Y coordinates.

The offsets returned by this method are not scaled.

=cut

sub pattern {
  my $self = shift;
  if (@_) {
    @{ $self->{Pattern} } = @_;
  }
  return @{ $self->{Pattern} };
}

=item B<spattern>

Scaled form of the jiggle pattern, returned in the same format as used by
the C<pattern> method.

  @scaled = $jig->pattern;

=cut

sub spattern {
  my $self = shift;

  my @pattern = $self->pattern;
  my $scale = $self->scale || 1;

  my @scaled = map { [ map { $_ * $scale } @$_ ] } @pattern;
  return @scaled;
}

=item B<xy>

Return the jiggle pattern as references to two arrays of equal size
containg the X and Y coordinates separately.

 ($x, $y) = $jig->xy;

These values will respect the current scaling factor (see C<scale>).

=cut

sub xy {
  my $self = shift;

  my @spattern = $self->spattern;

  my (@x, @y);
  for my $pos (@spattern) {
    push(@x, $pos->[0]);
    push(@y, $pos->[1]);
  }

  return (\@x, \@y);
}

=item B<npts>

Returns the number of points in the jiggle pattern.

 $n = $jig->npts;

=cut

sub npts {
  my $self = shift;
  my @pattern = $self->pattern;
  return scalar(@pattern);
}

=head2 General Methods

=over 4

=item B<extent>

Returns the extent of the jiggle pattern. Scale factor is taken into account.

  ($xmin, $xmax, $ymin, $ymax) = $jig->extent;

=cut

sub extent {
  my $self = shift;

  my ($x, $y) = $self->xy;

  my $xmin = min( @$x );
  my $xmax = max( @$x );
  my $ymin = min( @$x );
  my $ymax = max( @$x );

  return ($xmin, $xmax, $ymin, $ymax);
}

=back

=begin __PRIVATE_METHODS__

=head2 Private Methods

=over 4

=item B<_import_file>

Read the hardware mapping from the supplied configuration file and configure
the object.

 $map->_import_file( $filename );

=cut

sub _import_file {
  my $self = shift;
  my $file = shift;

  # Open the file and read the contents
  open my $fh, "< $file" or croak "Error opening jiggle file $file : $!";
  local $/ = undef;
  my $contents = <$fh>;
  close($fh) or croak "Error closing jiggle file $file: $!";

  $self->_import_string( $contents );

}

=item B<_import_string>

Given the contents of a jiggle file as a single string, extract
the hardware mapping information and configure the object.

  $map->_import_string( $string );

=cut

sub _import_string {
  my $self = shift;
  my $string = shift;

  my @lines = split("\n",$string);

  my @pattern;
  for my $l (@lines) {
    next unless $l =~ /\d/;

    # clean up string
    $l =~ s/^\s+//;
    $l =~ s/\s+$//;

    my ($x, $y) = split(/\s+/, $l);
    push(@pattern, [ $x, $y]);
  }

  $self->pattern( @pattern );

  return;
}

=back

=end __PRIVATE_METHODS__

=head1 AUTHOR

Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>

=head1 COPYRIGHT

Copyright (C) 2005 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful,but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place,Suite 330, Boston, MA  02111-1307, USA

=cut

1;
