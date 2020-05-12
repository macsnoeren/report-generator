package Report;

$VERSION = v0.0.1;

# TODO - Reading of data, should also be done by a plugin based method.

use warnings;
use strict;

use DBI;
use Cwd;
use Text::CSV;
use File::Basename;
use Text::Unidecode;

use Data::Dumper;

use Class::AccessorMaker {
  report => "report",  

  tplDir => "",

  dataDir => "",

  dbh => undef,

  tpl    => undef,

}, "new_init";

sub init {
  my ($self) = @_;

  my $dbfile = "../database/" . $self->{report} . ".dat";

  print "Using database '$dbfile' and template directory '" . $self->{tplDir} . "'\n";

  my $isNewDatabase = ! -e $dbfile;

  $self->{dbh} = DBI->connect("dbi:SQLite:dbname=$dbfile","","");

  # Load the Template Library file.
  my $tplLibFile = $self->{tplDir} . "/lib/Template.pm";
  my $tplLibDir  = $self->{tplDir} . "/lib";

  if ( ! -e $tplLibFile ) {
    print "ERROR: Could not locate the Template Library '$tplLibFile'\n";
    die;
  }
  
  print "Loading Template library of the template '$tplLibFile' (use lib '$tplLibDir';).\n";
  if ( -e $tplLibFile ) {
    print "- Found library file '$tplLibFile'\n";
    eval("use lib '$tplLibDir';");
    eval("use Template;");

    my $tpl = Template->new( report    => $self->{report},
			     tplDir    => $self->{tplDir},
			     dbh       => $self->{dbh},
			     dataDir   => $self->{dataDir},
			  );

    $self->{tpl} = $tpl;

    if ( $isNewDatabase ) {
      print "New report database, so create the new database\n";
      $self->{tpl}->initDB();

    } else{
      print "Report does already exists, so no new database is created.\n";
    }
  }
}

sub readCSVFiles {
  my ( $self ) = @_;

  $self->{tpl}->readCSVFiles();
}

###################################
## TEMPLATE PROCESSIGN FUNCTIONS ##
###################################

sub processTemplate {
  my ( $self ) = @_;

  print "Processing the template: '" . $self->{tplDir} . "'\n";

  my $dirCurrent = getcwd();

  if ( !chdir( $self->{tplDir} ) ) {
    print "processTemplate: Could not enter the template directory\n";
    return;
  }

  # Process the template pl files in the main directory and the chapters directory
  
  my @mainPl     = <*.pl>;
  my @chaptersPl = <chapters/*.pl>;

  foreach my $pl ( @mainPl ) {
    print "Processing the main template file '$pl'\n";
    $self->processTemplateFile( $pl );
  }

  foreach my $pl ( @chaptersPl ) {
    print "Processing the chapter template file '$pl'\n";
    $self->processTemplateFile( $pl );
  }

  chdir($dirCurrent);
}

sub processTemplateFile {
  my ( $self, $file ) = @_;

  my $contents = "";

  if ( -e $file ) {
    if ( open( FILE, $file ) ) {
      while ( my $line = <FILE> ) {
	$contents .= $line;
      }

      close FILE;

      eval($contents);

      if ( $@ ) {
	print "ERROR TEMPLATE: $@\n";
      }

    } else {
      print "processTemplateFile: Could not open the file '$file'\n";
    }


  } else {
    print "processTemplateFile: Could not find the file '$file'\n";
  } 
}

1;
