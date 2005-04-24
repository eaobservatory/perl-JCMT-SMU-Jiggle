use ExtUtils::MakeMaker;
WriteMakefile(
  'NAME'         => 'JCMT::SMU::Jiggle',
  'VERSION_FROM' => 'Jiggle.pm',
  'dist'         => { COMPRESS => "gzip -9f" }
  ); 
