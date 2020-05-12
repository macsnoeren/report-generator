#!/usr/bin/perl

BEGIN { # Make sure we end up in the directory of the application
  use File::Basename;
  chdir( dirname($0) );
#  chdir(".."); 
}

use lib '../lib';

use strict;
use warnings;

use Getopt::Long qw (GetOptions);

use Data::Dumper;

use Report;

main();

exit;

sub main {
  my ( $reportName, $dataDir, $template, $noDelete, $help );

  Getopt::Long::Configure qw(gnu_getopt);
  GetOptions(
	     'name|n=s'        => \$reportName,
	     'data|d=s'        => \$dataDir,
	     'template|r=s'    => \$template,
	     'nodelete'        => \$noDelete,
	     'help|h'          => \$help,
	    ) or help();
  
  my $delete = 1;
  if ( $noDelete ) {
    $delete = 0;
  }
  
  if ( $help ) {
    help();
    return;
  }

  if ( !$reportName ) {
    help();
    return;
  }

  my $tplDir    = "../report/$reportName";
  my $reportTpl = (defined($template) ? "../template/$template" : "../template/default");

  print "Using report template: '$reportTpl'\n";

  if ( ! -e $reportTpl && ! -d $reportTpl ) {
    print "Error: Could not find the report template '$reportTpl'!\n";
    return;
  }

  if ( $delete ) {
    print "Cleaning up and create new report...\n";
    print `rm -v ../database/$reportName.dat`;

    print `rm -Rv ../report/$reportName`;
    print `mkdir ../report/$reportName`;
    print `mkdir ../report/$reportName/evidence`;
  }

  print `cp -Rv $reportTpl/* ../report/$reportName/.`;

  my $evidencePath = "$dataDir/evidence/";

  if ( $delete ) {
    print "Processing the images...\n";

    if ( -d $evidencePath && opendir(D, $evidencePath) ) {
      while (my $f = readdir(D)) {
	if ( $f ne '.' && $f ne '..' ) {
	  if ( $f =~ /png$|gif$|jpg$|jpeg$/i ) { # Check for images
	    print "Converting and copying image file '$f'.\n";
	    print `convert '$evidencePath/$f' -resize 500x500 '../report/$reportName/evidence/$f'`;

	    if ( $f =~ /jpg$|jpeg$/i ) { # Fix the rotation
	      print `./exifautotran '../report/$reportName/evidence/$f'`;
	    }

	  } else { # No image, just copy
	    print "Copying evidence file '$f'.\n";
	    print `cp '$evidencePath/$f' '../report/$reportName/evidence/$f'`;
	  }
	}
      }
      closedir(D);

    } else {
      print "WARNING: Evidence files not found and not processed..";
    }

  } else {
    print "Not deleting the template and the images, everything left as it was!\n";
  }

  print "Ready..\n";

  my $report    = Report->new( report      => $reportName,
			       tplDir      => $tplDir,
			       dataDir     => $dataDir || "",
			     );

  $report->readCSVFiles();

  $report->processTemplate();
}

sub help {
  print "Usage: $0 -n <report-name> [options]\n\n";

  print "Example: report.pl -n name -e images_dir -o input.csv -t targets.csv -b book.csv\n";
  print "         cd report/name; pdflatex report.tex; cd ../..\n";
  
  print " --name <name>\n";
  print "  -n <name>                Name of the report that is used to create the database and template files.\n\n";

  print " --data <dir>\n";
  print "  -d <dir>                 Directory where all the data files are located. Evidence files located in evidence folder in this dir.\n\n";

  print " --template <dir>\n";
  print "  -r <dir>                 The directory of the base report template that should be used to generate the report.\n\n";

  print " --nodelete                Do not delete and copy the template files and process the evidence images\n\n";

  print " --help\n";
  print "  -h                       Shows this screen.\n\n";
}
