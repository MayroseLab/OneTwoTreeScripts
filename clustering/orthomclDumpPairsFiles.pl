#!/usr/bin/perl

# a version of orthomclDumpPairsFiles with output directory as a parameter

use DBI;
use FindBin;
#use lib "$FindBin::Bin/../lib/perl";

use strict;

my $configFile = $ARGV[0];
my $outDir = $ARGV[1];
my $LibPath;
BEGIN {
  $LibPath = $ARGV[2];
}

#use lib "/share/apps/orthomclSoftware-v2.0.3/lib/perl";
use lib $LibPath;

use OrthoMCLEngine::Main::Base;




&usage() unless $configFile;

my $base = OrthoMCLEngine::Main::Base->new($configFile);
my $dbh = $base->getDbh();

my $orthologTable = $base->getConfig("orthologTable");
my $inParalogTable = $base->getConfig("inParalogTable");
my $coOrthologTable = $base->getConfig("coOrthologTable");

my $dir = "$outDir/pairs";

die "dir '$dir' already exists" if -e $dir;

mkdir($dir);

printOrthologsFile($dbh, $orthologTable, "$dir/orthologs.txt");

printInparalogsFile($dbh, $inParalogTable, "$dir/inparalogs.txt");

printOrthologsFile($dbh, $coOrthologTable, "$dir/coorthologs.txt");

printMclAbcFile($dbh, $orthologTable, $inParalogTable, $coOrthologTable,
	       "$outDir/mclInput");


################# subroutines #########################

sub printInparalogsFile {
  my ($dbh, $inparalogTable, $fileName) = @_;

  my $sql = "
select taxon_id, sequence_id_a, sequence_id_b, normalized_score
from $inparalogTable
order by taxon_id, sequence_id_a, sequence_id_b asc
";

  my $stmt = $dbh->prepare($sql) or die DBI::errstr;
  $stmt->execute();
  open(F, ">$fileName") || die "Can't open '$fileName' for writing";
  while (my ($taxonId, $sourceIdA, $sourceIdB, $score) = $stmt->fetchrow_array()) {
    $score = int($score * 1000 + .5)/1000;
    print F "$sourceIdA\t$sourceIdB\t$score\n";
  }
  close(F);
}

sub printOrthologsFile {
  my ($dbh, $table, $fileName) = @_;

  my $sql = "
select taxon_id_a, taxon_id_b, sequence_id_a, sequence_id_b, normalized_score
from $table
order by taxon_id_a, taxon_id_b, sequence_id_a, sequence_id_b asc
";

  my $stmt = $dbh->prepare($sql) or die DBI::errstr;
  $stmt->execute();
  open(F, ">$fileName") || die "Can't open '$fileName' for writing";
  while (my ($taxonIdA, $taxonIdB, $sourceIdA, $sourceIdB, $score) = $stmt->fetchrow_array()) {
    $score = int($score * 1000 + .5)/1000;
    print F "$sourceIdA\t$sourceIdB\t$score\n";
  }
  close(F);
}

sub printMclAbcFile {
  my ($dbh, $orthologTable, $inParalogTable, $coOrthologTable, $fileName) = @_;

  my $sql = "
  select sequence_id_a, sequence_id_b, normalized_score
  from $inParalogTable
  union
  select sequence_id_a, sequence_id_b, normalized_score
  from $orthologTable
  union
  select sequence_id_a, sequence_id_b, normalized_score
  from $coOrthologTable
";

  my $stmt = $dbh->prepare($sql) or die DBI::errstr;
  $stmt->execute() or die DBI::errstr;
  open(F, ">$fileName") || die "Can't open '$fileName' for writing";
  while (my ($queryId, $subjectId, $score) = $stmt->fetchrow_array()) {
    $score = int($score * 1000 + .5)/1000;
    print F "$queryId\t$subjectId\t$score\n";
  }
  close(F);
  if(-z $fileName){
    print("\n\nDebug: File $fileName is empty\n\n");
   } else{
   print("\n\nDebug: File is not empty\n\n");
   }


}

sub usage {
  print "
Dump files from the database produced by the orthomclPairs program.

usage: orthomclDumpPairsFiles config_file

where:
  config_file : see below (you can use the same file given to orthomclPairs)

Database Input:
  - InParalog, Ortholog, CoOrtholog tables - populated by orthomclPairs

Output files:
  orthomclMclInput                       - file required by the mcl program
  pairs/                                 - dir holding relationship files
    potentialOrthologs.txt               - ortholog relationships
    potentialInparalogs.txt              - inparalog relationships
    potentialCoorthologs.txt             - coortholog relationships

The pairs/ files contain the pairs found by the orthomclPairs tables, and their
average normalized scores.  This is the same information as in the
orthomclMclInput file, but segregated by relationship type.  These are
candidate relationships (edges) that will subsequently be grouped (clustered)
by the mcl program to form the OrthoMCL ortholog groups.  These files contain
more sensitive and less selective relationships then the final ortholog groups.

Standard Error:
  - logging info

EXAMPLE: orthomclSoftware/bin/orthomclDumpPairsFile my_orthomcl_dir/orthomcl.config 

Sample Config File:

dbVendor=oracle  (or mysql)
dbConnectString=dbi:Oracle:orthomcl
dbLogin=my_db_login
dbPassword=my_db_password
orthologTable=Ortholog
inParalogTable=InParalog
coOrthologTable=CoOrtholog
";
  exit(1);
}

