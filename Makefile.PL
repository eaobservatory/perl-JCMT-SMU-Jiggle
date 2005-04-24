use ExtUtils::MakeMaker;
WriteMakefile(
  'NAME'         => 'JCMT::SMU::JigPattern',
  'VERSION_FROM' => 'JigPattern.pm',
  'dist'         => { COMPRESS => "gzip -9f" }
  ); 
