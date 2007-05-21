package JCMT::SMU::Jiggle;

=head1 NAME

JCMT::SMU::Jiggle - find out details of a JCMT SMU jiggle

=head1 SYNOPSIS

  use JCMT::SMU::Jiggle;

  my $smu = new JCMT::SMU::Jiggle( File => $file );


=head1 DESCRIPTION

This class enables easy access to jiggle parameters associated with a
particular jiggle configuration. This can include the actual offsets
and the number of jiggle positions.

=cut

use 5.006;
use strict;
use warnings;
use Carp;

use List::Util qw/ min max /;
use File::Basename qw/ basename /;
use Astro::Coords::Angle;
use Astro::Coords::Offset;

use vars qw/ $VERSION /;

$VERSION = sprintf("%d", q$Revision$ =~ /(\d+)/);

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new Jiggle object. Can be created from a filename.

  $jig = new JCMT::SMU::Jiggle( File => $file );

A blank object can be configured.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # Read the arguments
  my %args = @_;

  my $jig = bless {
		   FileName => undef,
		   PatternName => undef,
		   Pattern => [],
		   SYSTEM => 'TRACKING',
		   PosAng => new Astro::Coords::Angle(0, units => 'rad'),
		   ScaleFactor => 1,
		  };

  $jig->_import_file( $args{File} ) if exists $args{File};

  return $jig;

}

=head2 Accessor Methods

=over 4

=item B<name>

Name of the pattern file to be used (stripped of path).

Will be set automatically if filename() is invoked.

=cut

sub name {
  my $self = shift;
  if (@_) { $self->{PatternName} = shift; }
  return $self->{PatternName};
}

=item B<filename>

Full path to SMU jiggle file used to create this object. Not always
available.

=cut

sub filename {
  my $self = shift;
  if (@_) {
    $self->{FileName} = shift;
    $self->name( basename( $self->{FileName} ));
  }
  return $self->{FileName};
}

=item B<system>

Coordinate system associated with this pattern.

Usually one of "TRACKING", "AZEL", "MOUNT", "FPLANE".

=cut

sub system {
  my $self = shift;
  if (@_) {
    $self->{SYSTEM} = shift;
  }
  return $self->{SYSTEM};
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

=item B<posang>

The rotation angle to apply to this jiggle pattern. Defaults to
0 deg but must be in the form of an Astro::Coords::Angle object.

  $jig->posang( $pa );

=cut

sub posang {
  my $self = shift;
  if (@_) { 
    my $pa = shift;
    croak "posang must be Astro::Coords::Angle object\n"
      unless UNIVERSAL::isa( $pa, "Astro::Coords::Angle");
    $self->{PosAng} = $pa;
  }
  return $self->{PosAng};
}

=item B<pattern>

Retrieves (or sets) the jiggle pattern as a list of arrays containing
x,y pairs in the pattern.

  @pattern = $jig->pattern();

For the above, for a 9 position jiggle, C<@pattern> would contain 9 elements, each of which was a reference to an array containing two elements.

See the C<xy> method to get independent X + Y coordinates.

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

=item B<offsets>

Return the jiggle scaled jiggle pattern as a list of C<Astro::Coords::Offset>
objects.

  @offsets = $jig->offsets;

The objects will be configured as if the pattern * scale factor is in
tangent plane arcsec offsets.

=cut

sub offsets {
  my $self = shift;

  my $system = $self->system;

  # Really need to get the position angle in here
  my @offsets = map { new Astro::Coords::Offset( $_->[0], $_->[1],
						 system => $system,
					       )} $self->spattern;

  return @offsets;
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

=item B<has_origin>

Returns true if the jiggle pattern has a point at (0,0), otherwise
returns false.

=cut

sub has_origin {
  my $self = shift;
  my @pattern = $self->pattern;
  for my $p (@pattern) {
    return 1 if ($p->[0] == 0.0 && $p->[1] == 0.0);
  }
  return 0;
}

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
  $self->filename( $file );
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
