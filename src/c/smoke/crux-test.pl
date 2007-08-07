#!/usr/bin/perl -w

#$Log: not supported by cvs2svn $
#Revision 1.8  2007/08/07 18:05:13  cpark
#fixed some more bugs
#
#Revision 1.7  2006/12/19 01:12:06  cpark
#before change peptide freeing method
#
#Revision 1.6  2006/11/14 01:14:48  cpark
#hu..finished the parameter file system
#
#Revision 1.5  2006/09/13 22:11:34  cpark
#added smoke test for create-index
#
#Revision 1.4  2006/09/13 01:20:12  cpark
#add create index smoke test
#
#Revision 1.3  2006/07/28 01:49:59  aklammer
#*** empty log message ***
#
#Revision 1.2  2005/08/17 23:32:25  cegrant
#Scripts for testing crux software.
#
#Revision 1.1  2005/08/10 21:17:14  cegrant
#Added script for testing basic functionality of crux.
#
# Note: copied from Charles Grant's meme-test.pl

=head1 crux-test.pl

Usage: crux-test.pl [-u] <test list file>

The crux-test.pl script provides a framework for testing the overall 
functionality of programs in the crux distribution. It read a list of
tests from a '='-delimited file, one test per line. Each test is described
by 3 fields:

=over 4

=item o
the name of the test

=item o
the path to the file containing the known good output

=item o
the command line implementing the test

=back

The command line for each test is executed with the STDOUT
captured to a file. STDERR is written as is. 
The test output is compared to the known good
output contained in the file specified in the 2nd field. If the test
output matches the known good output the test succeeds, otherwise
it fails. The results are printed to the standard output. If the 
'-u' option is specified, the files containing the known good output
will be replaced by the output of the test. 

It is assumed that the command to be tested sends its output to
standard out.

=cut

use strict;
use Getopt::Std;
use File::Temp qw/ tempfile tempdir /;

# Handle the command line arguments.
my $usage = "Usage: crux-test.pl [-u] <file name>\n";
my (%options, $update);
if (!getopts('u', \%options)) {
  die($usage);
};
if (scalar @ARGV != 1) {
  die("Incorrect number of arguments.\n", $usage);
}
if (defined $options{'u'}) {
  $update = 1;
} else {
  $update = 0;
}

# Set an interrupt handler
my $caught_interrupt = 0;
$SIG{'INT'} = 'sigint_handler';

# Read each test from the file and execute it.
my ($line, @fields, $test_name, $standard_filename, $cmd, $result, $is_index);
my $num_tests = 0;
my $num_successful_tests = 0;
while ($line = <ARGV>) {

  if ($caught_interrupt) {
    die("Testing was interrupted.");
  }  

  # Parse the test parameters
  chomp $line;
  @fields = split "=", $line;
  $test_name = $fields[0];
  $standard_filename = $fields[1];
  $cmd = $fields[2];
  $is_index =  $fields[3];
  #chomp($is_index);

  # Execute the test
  print "\n----- Running test $test_name \n";
  my ($output_fh, $output_filename) = tempfile();
  if (!$output_filename) {
      die("Unable to create output file.\n");
  }
  # are we testing create_index?
  if($is_index eq " index"){
      $result = &test_cmd_index($cmd, $standard_filename, $output_filename);
  }
  elsif($is_index eq " analysis"){
      $result = &test_cmd_analysis($cmd, $standard_filename, $output_filename);
  }
  else{
      $result = &test_cmd($cmd, $standard_filename, $output_filename);
  }

  $num_tests++;
  if ($result == 0) {
      print "----- SUCCESS - test $test_name\n";
      $num_successful_tests++;
  } else {
      print "----- FAILURE - test $test_name\n";
  }    


  # Clean up
  close $output_fh;
  if ($update) {
    # If the update flag was given replace the existing standard with
    # with the current test ouput.
    system("cp $output_filename $standard_filename");
  }
  unlink $output_filename;

}

# Print the summary of the tests.
print "\n-------------------------------\n";
print "----- Successful Tests: $num_successful_tests\n";
my $num_failed_tests = $num_tests - $num_successful_tests;
print "----- Failed Tests: $num_failed_tests\n";
print "----- Total Tests: $num_tests\n";
print "-------------------------------\n\n";
exit($num_failed_tests);

=head2 test_cmd($cmd, $standard_filename, $output_filename)

Arguments:

$cmd                A string containing a shell command to execute.
$standard_filename  The name of a file containing the expected ouput
                    for the shell command.
$output_filename    The name of the file used to store the output of the
                    command.

The test_cmd function executes the command line passed in the $cmd variable
storing the output in $output_filename. If the return status indicates the
command was successful the output of the command is compared to the expected
output as stored in $standard_filename using diff. If there are differences
the output of diff is sent to standard out.

Returns 0 if the command executed successfully and the output exactly matched
the expected output, 1 otherwise.

=cut

sub test_cmd() {
  my ($cmd, $standard_filename, $output_filename) = @_;
  my ($diff_fh, $diff_filename) = tempfile();
  if (!$diff_filename) {
    die("unable to create diff file.\n");
  }
  $cmd .= " > $output_filename";
  my $result = system($cmd);
  if ($result == 0) {
    # The command was successful, now vet the output.
    my $diff_cmd = "diff  -I '# PROTEIN DATABASE' $standard_filename $output_filename > $diff_filename";
    $result = system($diff_cmd);
    if ($result == 0) {
      # The output of the command matches the expected output.
    } else {
      # The output of the command doesn't match the expected output.
      # Print the diff ouput.
      open(DIFF, $diff_filename) || die("Unable to read diff file.\n");
      my $diff_line;
      while ($diff_line = <DIFF>) {
        print $diff_line;
      }
      close DIFF;
      unlink $diff_filename;
    }
  } else {
    # The command was not succesful
    die("Testing failed.");
  }
  return $result;
}

sub sigint_handler {
  $caught_interrupt = 1;
}

sub test_cmd_index() {
    system("rm -rf test_crux_index");
    my ($cmd, $standard_filename, $output_filename) = @_;
    my ($diff_fh, $diff_filename) = tempfile();
    if (!$diff_filename) {
        die("unable to create diff file.\n");
    }
    my $index_result = system($cmd);
    if ($index_result == 0) {
       # The command was successful, now vet the output.
        
        #now try parsing the peptides
        my $parse_cmd = "../../../bin/generate_peptides --output-sequence --use-index T test.fasta > $output_filename";
        system($parse_cmd);
           
        #compare if the peptides parsed match
        my $diff_cmd = "diff -I '# PROTEIN DATABASE' $standard_filename $output_filename > $diff_filename";
        $result = system($diff_cmd);
        if ($result == 0) {
            # The output of the command matches the expected output.
        } else {
            # The output of the command doesn't match the expected output.
            # Print the diff ouput.
            open(DIFF, $diff_filename) || die("Unable to read diff file.\n");
            my $diff_line;
            while ($diff_line = <DIFF>) {
                print $diff_line;
            }
            close DIFF;
            unlink $diff_filename;
        }
    } else {
        # The command was not succesful
        die("Testing failed.");
    }
    system("rm -rf test_crux_index");
    return $result;
}

sub test_cmd_analysis() {    
    my ($cmd, $standard_filename, $output_filename) = @_;
    my ($diff_fh, $diff_filename) = tempfile();
    if (!$diff_filename) {
        die("unable to create diff file.\n");
    }
    my $index_result = system($cmd);
    if ($index_result == 0) {
       # The command was successful, now vet the output.
        
        #now try analysis
        my $analysis_cmd = "../../../bin/match_analysis --match-output-folder match_result --parameter-file smoke_params standard2.fasta > $output_filename";
        system($analysis_cmd);
        
        #compare if the peptides parsed match
        my $diff_cmd = "diff -I ITFSLEDVLL $standard_filename $output_filename > $diff_filename";
        $result = system($diff_cmd);
        if ($result == 0) {
            # The output of the command matches the expected output.
        } else {
            # The output of the command doesn't match the expected output.
            # Print the diff ouput.
            open(DIFF, $diff_filename) || die("Unable to read diff file.\n");
            my $diff_line;
            while ($diff_line = <DIFF>) {
                print $diff_line;
            }
            close DIFF;
            unlink $diff_filename;
        }
    } else {
        # The command was not succesful
        die("Testing failed.");
    }
    system("rm -rf match_result");
    return $result;
}
