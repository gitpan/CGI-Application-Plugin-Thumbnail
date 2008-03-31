use ExtUtils::MakeMaker;
WriteMakefile(
   NAME => 'CGI::Application::Plugin::Thumbnail',
   VERSION_FROM => 'lib/CGI/Application/Plugin/Thumbnail.pm',
   PREREQ_PM => {
      'LEOCHARRE::DEBUG' => '1.02',
      'File::Path' => 0,
      'Image::Thumbnail' => '0.63',
      'File::PathInfo' => 0,
      'CGI::Application::Plugin::Stream' => 0,
   },
);


