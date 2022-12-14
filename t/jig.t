# -*-perl-*-

use Test::More tests => 8;
use File::Spec;

require_ok( "JCMT::SMU::Jiggle" );


my $jigfile = File::Spec->catfile( "t", "data", "smu_3x3.dat" );

my $jig = new JCMT::SMU::Jiggle( File => $jigfile );
isa_ok( $jig, "JCMT::SMU::Jiggle" );

is( $jig->npts, 9, "Count number of points");

$jig->scale( 3 );

my (@minmax) = $jig->extent;

is($minmax[0], -3, "X min");
is($minmax[1],  3, "X max");
is($minmax[2], -3, "Y min");
is($minmax[3],  3, "Y max");

ok( $jig->has_origin, "Has an origin");
