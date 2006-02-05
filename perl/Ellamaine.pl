#!/usr/bin/perl
# 31 Mar 04
# Parses the detailed real-estate sales information to extract fields
#
#
# 16 May 04 - bugfixed algorithm checking search range
#           - bugfix parseSearchDetails - was looking for wrong keyword to identify page
#           - bugfix wasn't using parameters{'url'} as start URL
#           - added AgentStatusServer support to send status info over a TCP connection
#
#   9 July 2004 - Merged with LogTable to record encounter information (date last encountered, url, checksum)
#  to support searches like get records 'still advertised'
#  25 July 2004 - added support for instanceID and transactionNo parameters in parser callbacks
#  30 July 2004 - changed parseSearchDetails to only parse the page if it contains 'Property Details' - was encountering 
#   empty responses from the server that yielded an empty database entry.
#  21 August 2004 - changed parseSearchForm to set the main area to all of the state instead of just perth metropolitan.
#  21 August 2004 - added requirement to specify state as a parameter - used for postcode lookup
#  28 September 2004 - use the thread command to specify a threadID to continue from - this allows the URL stack and cookies
#   from a previous instance to be reused in the same 'thread'.  Implemented to support automatic restart of a thread in a loop and
#   automatic exit if an instance runs out of memory.  (exit, then restart from same point)
#  28 September 2004 - Combined multiple sources to publishedMaterialScanner instead of one for each type and source of adverisement in 
#   to leverage off common code instead of duplicating it
#                    - improved parameter parsing to support generic functions.  Generic configuration file for parameters, checking
#   and reporting of mandatory paramneters.
#  29 October 2004 - added support for DomainRegionsn table - needed to parse domain website
#  27 November 2004 - added support for the OriginatingHTML table - used to log the HTMLRecord that created a table entry
#    as part of the major change to support ChangeTables
#  28 November 2004 - added support for Validator_RegExSubstitutes table - used to store regular expressions and substitutions
#    for use by the validation functions.  The intent it is allow new substititions to be added dynamically without 
#    modifying the code (ie. from the exception reporting/administration page)
#  30 November 2004 - added support for the WorkingView and CacheView tables in the maintanence tasks.  The workingView is 
#   the baseview with aggregated changes applied.  The CacheView is a subset of fields of the original table used to 
#   improve the speed of queries during DataGathering (checkIfTupleExists).
#  7 December 2004 - added maintenance task supporting construction of the MasterPropertyComponentsXRef table from the
#   componentOf relationships in the workingView
#  19 January 2005 - added support for the StatusTable
#  13 March 2005 - added maintenance task for generating suburbAnalysisTable
#  20 May 2005   - modified to use AdvertisedPropertyProfiles (Common code for rental and sale records) 
#  14 June 2005  - renamed to Ellamaine (from PublishedMaterialScanner)
#  16 June 2005  - modified to load tableObjects from the tables.properties files (dynamic loading)
#                - modified to load parsers from the parsers.properties file (symblic references to callbacks)
#                  The above two changes greatly simplify the code by moving the implementation information into 
#                  configuration files.  (this is part of the process to make Ellamaine adaptable to other apps)
#                - added support for the ConfigTable that contains all of the configuration data for each instance
#  rather than having multiople.config files - the config is loaded from the database (but note, when the ConfigTable
#  is created, it reads the templates for data from the ./configs/*.config files
#  25 June 2005  - moved body of code to a package so Ellamaine can be started from another module
#  5 Feb 2006    - reads database configuration from local properties file
# To do:
#
#  - front page for monitoring progress
#  - warnings and error tracking
#
# ---CVS---
# Version: $Revision$
# Date: $Date$
# $Id$
#
use CGI qw(:standard);
use Ellamaine::DocumentReader;
use Ellamaine::HTMLSyntaxTree;
use Ellamaine::StatusTable;
use Ellamaine::Controller;
use ConfigTable;

use LoadProperties;
use PrintLogger;
use SQLTable;
use HTTPClient;
use DebugTools;

# -------------------------------------------------------------------------------------------------    
my %parameters = undef;
my %myTableObjects;
my %myParsers;

# load the properties...
my $myProperties = loadProperties("ellamaine.properties");
   
# initialise the SQL client
$sqlClient = SQLClient::new($$myProperties{'sql.database.name'}, $$myProperties{'sql.user.name'}, $$myProperties{'sql.user.password'});

print("Connecting to database...\n");
$sqlClient->connect();

# load/read parameters for the application
($parseSuccess, $parameters) = parseParameters($sqlClient);

if ($parseSuccess)
{
   $ellamaineController = Controller::new($sqlClient, $parameters);
   $parseSuccess = $ellamaineController->start();
   $ellamaineController->releaseSessionHistory();
}

$sqlClient->disconnect();

print "Finished.\n";

# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------


# parses the parameters mandatory for the specified command
sub parseMandatoryParameters
{
   my $parametersHashRef = shift;
   my $mandatoryParametersRef = shift;
   my $success = 1;
   
   # mandatory parameters
   foreach (@$mandatoryParametersRef)
   {
      # if the parameter is on the command line, get it
      
      $newValue = param("$_");
      if (defined $newValue)
      {
         $$parametersHashRef{$_} = $newValue;
      }
         
      # check if the mandatory parameter is set (either previously from the config file or now through command line)
      if (!defined $$parametersHashRef{$_})
      {
         # missing parameter
         $success = 0;
         # report missing option name
         $$parametersHashRef{'missingOptions'} .= "$_ ";
      }
   }
   
   return $success;   
}

# -------------------------------------------------------------------------------------------------
# parses the optional parameters applicable to one or more command
sub parseOptionalParameters
{
   my $parametersHashRef = shift;
   my @optionalParameters = ('startrange', 'endrange', 'statusPort', 'proxy');
   my $success = 1;
 
   # optional parameters
   foreach (@optionalParameters)
   {
      # if the parameter is on the command line, get it
      $newValue = param($_);
      if (defined $newValue)
      {
         $$parametersHashRef{$_} = $newValue;
      }
   }
   
   return $success;
}

# -------------------------------------------------------------------------------------------------
# parses any specified command-line parameters
# MUST specify 'command' on the command line
#  optional 'configFile' of additional parameters
# and MANDATORY parameters for 'command'
# and OPTIONAL parameters for 'command'
sub parseParameters
{      
   my $sqlClient = shift;
   my $parameters;  # reference to a hash
   my $success = 0;
   my @startCommands = ('url', 'state', 'source', 'parser', 'writeMethod');
   my @continueCommands = ('state', 'source', 'parser', 'writeMethod');
   my @maintenanceCommands = ('action');   
   my @parseCommands = ('type', 'parser', 'writeMethod');   
   
   # this hash of lists defines the commands supported and mandatory options for each command
   my %mandatoryParameters = (
      'start' => \@startCommands,
      'continue' => \@continueCommands,
      'create' => undef,
      'drop' => undef,
      'maintenance' => \@maintenanceCommands,
      'parse' => \@parseCommands
   );   
   my %commandDescription = (
         'help' => "Display this information",
         'start' => "start a new session to download advertisements",
         'continue' => "continue an existing session downloading advertisements from the last recovery position",
         'create' => "create the database tables",
         'drop' => "drop the database tables (and all data)",
         'maintenance' => "run maintenance option on the database",
         'parse' => "run a once-only parser on a specified document"
   );
      
   if (CGI::param("config"))
   {
      # fetch the configuration from the ConfigTable...
      print "Fetching configuration '", CGI::param("config"), "' from database...\n";
      $configTable = ConfigTable::new($sqlClient);
      $parameters = $configTable->fetchConfig(CGI::param("config"));
     
      if (!$parameters)
      {
         print "   failed to fetch configuration.\n";
      }
     
      # load the specified configuration file
      #print "Loading configuration '", CGI::param("config"), ".config'...\n";
      #$parameters = loadProperties(CGI::param("config").".config");
      #
      #if ($$parameters{'loadconfiguration.error'})
      #{
      #   print "   ", $$parameters{'loadconfiguration.error.description'}, "\n";
      #}
   }
   else
   {
      my %newHash;
      $parameters = \%newHash;  # initialise reference to empty hash 
   }
   
   # see which commands are specified on the command line or via CGI:
   @CGIparamerters = CGI::param();
   print "Other parameters:\n";
   foreach (@CGIparamerters)
   {
      $$parameters{$_} = CGI::param($_);
      print "   $_=", $$parameters{$_}, "\n";
   }
   #$$parameters{'command'} = CGI::param("command");
   #$$parameters{'config'} = CGI::param("config");

   if ($$parameters{'command'})
   {
      # if a command has been specified, parse the parameters
      if (exists $mandatoryParameters{$$parameters{'command'}})
      {
         $success = parseMandatoryParameters($parameters, $mandatoryParameters{$$parameters{'command'}});
            
         if (!$success)
         {
            print "   main: At least one mandatory parameter for command '".$$parameters{'command'}."' is missing.\n";
            print "   main:   missing parameters: ".$$parameters{'missingOptions'}."\n";
         }
      }
      else
      {
         print "   main: command '".$$parameters{'command'}."' not recognised\n"; 
      }
   }
   else
   {      
      if (!$$parameters{'command'})
      {
         print "main: command not specified\n";
      }
      else
      {
         print "main: config not specified\n";
      }
      print "   USAGE: $0 command=a&config=b&mandatoryParams[&optionalParams]\n";
      print "   where a=\n";
      foreach (keys (%commandDescription))
      {
         print "      $_: ".$commandDescription{$_}."\n";
      }
      print "   and b is an identifier for this parser configuration to use (as defined in parers.properties).\n"
      
   }

   # if successfully read the mandatory parameters, now get optional ones...
   if ($success)
   {
      # set the special parameter 'agent' that's derived from multiple other variables
      if (($$parameters{'startrange'}) || ($$parameters{'endrange'}))
      {
         if ($$parameters{'startrange'})
         {
            if ($$parameters{'endrange'})
            {
               $$parameters{'agent'} = "Ellamaine_".$$parameters{'config'}."_".$$parameters{'startrange'}."-".$$parameters{'endrange'};
            }
            else
            {
               $$parameters{'agent'} = "Ellamaine_".$$parameters{'config'}."_".$$parameters{'startrange'}."-ZZZ"
            }
         }
         else
         { 
            $$parameters{'agent'} = "Ellamaine_".$$parameters{'config'}."_AAA-".$$parameters{'endrange'};
         }     
      }
      else
      {
         if ($$parameters{'config'})
         {
            $$parameters{'agent'} = "Ellamaine_".$$parameters{'config'};
         }
         else
         {
            $$parameters{'agent'} = "Ellamaine";         
         }
      }
      
      # parse the optional parameters
      parseOptionalParameters(\%parameters);
      
      # temporary hack so the useText command doesn't have to be explicit
      if (!$$parameters{'useHTML'})
      {
         $$parameters{'useText'} = 1;
      }
      # 25 July 2004 - generate an instance ID based on current time and a random number.  The instance ID is 
      # used in the name of the logfile
      my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
      $year += 1900;
      $mon++;
      my $randNo = rand 1000;
      my $instanceID = sprintf("%s_%4i%02i%02i%02i%02i%02i_%04i", $$parameters{'agent'}, $year, $mon, $mday, $hour, $min, $sec, $randNo);
      $$parameters{'instanceID'} = $instanceID;
     
   }
   
   return ($success, $parameters);   
}


