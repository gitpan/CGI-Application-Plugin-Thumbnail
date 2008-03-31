package CGI::Application::Plugin::Thumbnail;
use strict;
use Carp;
use LEOCHARRE::DEBUG;
use warnings;
use Cwd;
use Exporter;
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);
our $VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /(\d+)/g;
@ISA = qw/ Exporter /;

@EXPORT_OK = (qw(
__thumbnail_style
_abs_thumbnail
_img
abs_image
abs_thumbnail
get_abs_image
set_abs_image
thumbnail_header_add
thumbnail_restriction
_thumbnail_rel_dir
__assure_thumb_dir
));

%EXPORT_TAGS = (
   'all' => \@EXPORT_OK,
);

sub set_abs_image {
   my($self,$arg) = @_; 
   defined $arg or confess('missing arg');
   $self->{_data_}->{_img} = undef;

   require File::PathInfo;
   my $f = new File::PathInfo;
   $f->set($arg) or return;
   $self->{_data_}->{_img} = $f;
   return 1;  
}

sub get_abs_image {
   my($self, $name) = @_;
   $name ||= 'rel_path';
   $self->{_data_}->{_img} = undef;
   
   $self->query->param($name) or return;
   my $abs = $ENV{DOCUMENT_ROOT}.'/'.$self->query->param($name);
   
   require File::PathInfo;   
   my $f = new File::PathInfo;
   $f->set($abs) or return;
   $self->{_data_}->{_img} = $f;
   return 1;
}

sub abs_image {
   my $self = shift;
   $self->_img or return;
   return $self->_img->abs_path;   
}


sub abs_thumbnail {
   my $self = shift;   
   $self->{_abs_thumbnail} ||= $self->_abs_thumbnail or return;
   return $self->{_abs_thumbnail};
}

# --------------

sub _img {
   my $self = shift;
   $self->{_data_}->{_img} or $self->get_abs_image or return;   
   return $self->{_data_}->{_img};
}

sub _thumbnail_rel_dir {
   my $self= shift;
   $self->{_thumbnail_rel_dir} ||= ( $self->param('thumbnail_rel_dir') || '.thumbnails' );
   
}

sub _abs_thumbnail {
   my $self = shift;
   
   $self->_img or return;

   my $tmbd =  $self->_thumbnail_rel_dir;
   
   my $abs_td = $ENV{DOCUMENT_ROOT} .'/'.$tmbd;
   my $abs_thumb = $abs_td . '/'. $self->thumbnail_restriction .'/'.$self->_img->rel_path;
   debug("$abs_thumb\n");

   # does it exist
   if (-f $abs_thumb){
      return $abs_thumb;
   }

   # THEN WE ARE CREATING ONE...

   $self->__assure_thumb_dir($abs_thumb);      
   my $abs_input =    $self->_img->abs_path;
   my $size = $self->thumbnail_restriction;
   $size or die('no size');
   $abs_input or die('no abs input');

   require Image::Thumbnail;

   my $thumb = new Image::Thumbnail(
      size        => $size,
      input       => $abs_input,
      outputpath  => $abs_thumb,
   );
   #my $thumb = $self->__create_a_thumbnail_object();   
   
   $self->__thumbnail_style($thumb); # optional user hook        
   $thumb->create;
   return $abs_thumb;
}


sub __assure_thumb_dir {
   my ($self, $abs_thumb) = @_;
   # ok. lets make up the path
   require File::Path;
   my $abs_loc = $abs_thumb;
   $abs_loc=~s/\/[^\/]+$// or die;
   unless( -d $abs_loc ){
      File::Path::mkpath($abs_loc) or die;
   }   
   return $abs_loc;
}

#sub __create_a_thumbnail_object {
#   my($self,$abs_thumb)
#   
# # THEN MAKE THE THUMB !!! .. uhm.. potentially...
#   require Image::Magick;
#   require Image::Magick::Thumbnail;
#   
#   my $img = new Image::Magick;
#   $img->Read( $self->_img->abs_path );
#
#   # how does it compare to the restriction request??
#   my $restriction = $self->thumbnail_restriction;
#   $restriction=~/(\d+)x(\d+)/ or die;
#   my ($h,$w) = ($1,$2);
#   my ($W,$H) = $img->Get('width','height');
#   if( $h >= $H and $w >= $W){
#      # IMAGE IS SMALLER THEN THUMB
#      debug(" h$h >= H$H or w$w >= W$W, image is smaller then thumb request\n");
#      return $self->_img->abs_path;   
#   }  
#      
#   my ($thumb,$x,$y) = Image::Magick::Thumbnail::create($img,$self->thumbnail_restriction);
#   return $thumb;   
#}


sub __thumbnail_style {
   my($self,$thumbnail_object) = @_;
   return 1;
}












# THE REST HERE DOWN IS NOT AFFECTED BY PATHS OF THUMB AND IMAGE

sub thumbnail_restriction {
   my $self = shift;
   $self->{_data_} ||={};
   unless( defined $self->{_data_}->{thumbnail_restriction}){

      my $tnr;

      # first via query string
      if ( defined $self->query->param('thumbnail_restriction') and $self->query->param('thumbnail_restriction')){
         my $_tnr = $self->query->param('thumbnail_restriction');
         unless( $_tnr=~/^\d+x\d+$/ ){
            warn("thumbnail restriction received via query string [$_tnr] is invalid");
            $_tnr = undef;
         }
         $tnr = $_tnr;         
      }

      # via constructor?
      elsif ( defined $self->param('thumbnail_restriction') and $self->param('thumbnail_restriction')){
         my $_tnr = $self->param('thumbnail_restriction');
         unless( $_tnr=~/^\d+x\d+$/ ){
            warn("thumbnail restriction received via param to constructor [$_tnr] is invalid");
            $_tnr = undef;
         }
         $tnr = $_tnr; 
      }   

      $tnr ||= '100x100';
      $self->{_data_}->{thumbnail_restriction} = $tnr;
   }   

   return  $self->{_data_}->{thumbnail_restriction};
}

sub thumbnail_header_add {
   my $self = shift;
   
   $self->_img or debug('no _img') and return;
   my $ext = $self->_img->ext or debug('no _img ext') and return;

   debug($ext);
   my $mime =
   $ext=~/jpe?g$/i ? 'image/jpeg' :
      $ext=~/gif$/i ? 'image/gifg' :
         $ext=~/png$/i ? 'image/png' : undef;
   
   $mime or debug('no mime') and return;

   $self->header_add(
      -type => $mime,
      -attachment => $self->_img->filename,
   );
   return 1;      
}


1;

__END__


=pod

=head1 NAME

CGI::Application::Plugin::Thumbnail - have a runmode that makes thumbnails

=head1 DESCRIPTION

These methods allow your cgi app to have a runmmode that makes a thumbnail

=head1 SYNOPSIS

   use CGI::Application::Plugin::Thumbnail ':all';
   use CGI::Application::Plugin::Stream 'stream_file';


   sub thumbnail : Runmode {
	   my $self = shift;

      # was an original image requested, and did it exist on disk?
      $self->get_abs_image('rel_path') or return;
         
      # get the corresponding abs pathto the thumbnail, create if not exists
      $self->abs_thumbnail or return;
      
      # stream the thumbnail image
      $self->stream_file( $self->abs_thumbnail ) 
         or warn("cant stream");
         
      return;
   }

=head1 METHODS


=head2 get_abs_image()

optional argument is what query string param will hold the relative path to the image we want to make a thumb for.
if none specified, uses 'rel_path'
returns boolean, if it found something or not.
calling this method is optional

   $self->get_abs_image('rel_path');   

=head2 set_abs_image()

optional argument is absolute path to original image
if none provided, will resolve with get_rel_path()
calling this method is optional

   $self->set_abs_image('/home/myself/images/image1.jpg');   

=head2 abs_image()

returns absolute path to image we want to make a thumb of
if you set via set_abs_image() or specified query param via get_abs_image() , will mirror this.
you will likely call this method in your thumbnail runmode

   $self->abs_image or warn("you did not ask for an image or that image does not exist");
   
=head2 abs_thumbnail()

returns absolute path to thumbnail
if it did not exist, we would try to make it, if we could not make it, returns undef and warns
this is the minimum method you need to call, to stream the image

   $self->abs_thumbnail or warn("no thumbnail was made or no image requested");


=head1 CHANGING THUMBNAIL BEFORE SAVING

What if you want to provide your own funky style to the thumbnail before saving??

then override __thumbnail_style()

Example:


   use CGI::Application::Plugin::Thumbnail;
   use CGI::Application::Plugin::Stream;


   sub __thumbnail_style {
      my ($self,$thumb) = @_;
      
      $thumb->Quantize( colorspace => 'gray' ); 
		$thumb->Set( compression => '8' );
      return 1;   
   }




   sub thumbnail : Runmode {
	   my $self = shift;
      $self->get_abs_image('rel_path') or return;   
      
      $self->abs_thumbnail or return;  
   
      $self->stream_file( $self->abs_thumbnail ) 
         or warn("thumbnail runmode: could not stream thumb ".$self->abs_thumbnail);
      return;
   }

=head2 __thumbnail_style()

Does nothing. You can override this to change your thumbnail
it is called when a thumbnail is creted, 
*after* the original is resized, but *before* it is saved.
receives $thumb image magick object.
You do not need to return the object. See L<CHANGING THUMBNAIL BEFORE SAVING>

=cut

=head1 PARAMS TO CONSTRUCTOR

   new My::Cgiapp(
      PARAMS => {       
         thumbnail_rel_dir => '.thumbnails',                  
         thumbnail_restriction => '100x100',
      },   
   );


You do not have to provide parameters. Defaults are provided.

=head2 WHAT PICTURE?

What you tell the runmode thumbnail is not what thumbnail you want, but what original picture you want a thumbnail *of*.

The way you tell it is via the query string, if you want a thumbnail of /home/me/public_html/img/one.jpg, then the query 
string would read one of these:

   ?rm=thumbnail&rel_path=img/one.jpg
   ?rm=thumbnail&rel_path=/img/one.jpg

=head2 THUMBNAIL DOCROOT

You can define where the thumbnails are stored via parameter to constructor.
We attempt to create if not there.

   new My::Cgiapp(
      PARAMS => { 
         thumbnail_rel_dir => '/.thumbnails' },
   );

Default is shown above.

=head2 THUMBNAIL RESTRICTION, DIMENSIONS

We define dimensions as maximum width and maximum height.
If you do not define dimensions, default is 100x100.
You may also defined dimmensions via the query string:

   ?rm=thumbnail&rel_path=img/one.jpg&thumbnail_restriction=100x100

We store thumbs by dimension for example these are requests and their destinations
Keep in mind that if the thumbnail dimensions are larger then the image, no thumbnail is made, 
the original is streamed back.

   ?rm=thumbnail&rel_path=img/one.jpg
   DOCUMENT_ROOT/.thumbnails/100x100/img/one.jpg
   
   ?rm=thumbnail&rel_path=img/one.jpg&thumbnail_restriction=100x100
   DOCUMENT_ROOT/.thumbnails/100x100/img/one.jpg

   ?rm=thumbnail&rel_path=img/one.jpg&thumbnail_restriction=600x600
   DOCUMENT_ROOT/.thumbnails/600x600/img/one.jpg

=head1 CHANGES

Since version 1.03, instead of using Image::Magick::Thumbnail, we use Image::Thumbnail.

Requested by Lyle.

=head1 REVISION

$Revision: 1.3 $

=head1 CAVEATS & BUGS

Still a work in progress.
If you want any changes in this module, please contact the AUTHOR.

   
=head1 AUTHOR

Leo Charre leocharre at cpan dot org.

=cut




