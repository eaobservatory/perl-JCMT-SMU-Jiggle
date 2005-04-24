# -*-perl-*-

use Test::More tests => 7;
use File::Spec;

require_ok( "JCMT::SMU::JigPattern" );


my $jigfile = File::Spec->catfile( "t", "data", "smu_3x3.dat" );

my $jig = new JCMT::SMU::JigPattern( File => $jigfile );
isa_ok( $jig, "JCMT::SMU::JigPattern" );

is( $jig->npts, 9, "Count number of points");

$jig->scale( 3 );

my (@minmax) = $jig->extent;

is($minmax[0], -3, "X min");
is($minmax[1],  3, "X max");
is($minmax[2], -3, "Y min");
is($minmax[3],  3, "Y max");
