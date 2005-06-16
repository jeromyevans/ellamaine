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
#
# To do:
#
#  RUN PARSERS IN A SEPARATE PROCESS | OR RUN DECODER (eg. htmlsyntaxtree) in separate process - need way to pass data in and out of the
#   process though
#  USE DATABASE TO SPECIFY PARSERS AND RECOVERY POINTS
#   NEED TO GET AGENT NAME
#  - front page for monitoring progress
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

use LoadProperties;
use PrintLogger;
use SQLTable;
use HTTPClient;
use DebugTools;

#use AdvertisedPropertyProfiles;
#use AgentStatusServer;
#use PropertyTypes;
#use WebsiteParser_Common;
#use WebsiteParser_REIWA;
#use WebsiteParser_REIWASuburbs;
#use WebsiteParser_RealEstate;
#use WebsiteParser_Domain;
#use DomainRegions;
#use Validator_RegExSubstitutes;
#use MasterPropertyTable;
#use SuburbAnalysisTable;
#use SuburbProfiles;


# -------------------------------------------------------------------------------------------------    
my %parameters = undef;
my %myTableObjects;
my %myParsers;

# initialise the SQL client
$sqlClient = SQLClient::new();

# load/read parameters for the application
($parseSuccess, $parameters) = parseParameters();
my $printLogger = PrintLogger::new($$parameters{'agent'}, $$parameters{'instanceID'}.".stdout", 1, $$parameters{'useText'}, $$parameters{'useHTML'});
$$parameters{'printLogger'} = $printLogger;

$printLogger->printHeader("\n");

# load the properties...
my $customProperties = loadProperties("ellamaine.properties");

# if custom properties where defined...
if (($parseSuccess) && ($customProperties))
{
   $printLogger->print("Initialising SQL table objects (", $$customProperties{'tables.properties.file'}, ")...\n");
   # load the list of tables to be supported by Ellamaine - the tables can be accessed directly in the parsers
   $tableProperties = loadProperties($$customProperties{'tables.properties.file'});
   
   if ($$tableProperties{'loadproperties.error'})
   {
      $printLogger->print("   ", $$parserProperties{'loadproperties.error.description'}, "\n");
      $parseSuccess = 0;
   }
   else
   {
      # initialise the tables - load the modules
      foreach (keys %$tableProperties)
      {
         no strict 'refs';  # allow symbolic references
         # load the module
         $packageName = $$tableProperties{$_};
         $printLogger->print("   Loading package $_ (", $packageName, ".pm)...\n");
         # load the module (require the module)
         require "$packageName.pm";
         $packageName->import();   # this probably isn't necessary, but safe (import the module's exports)
         
         # use a symbolic reference to call new in the package and include the returned object in the
         # myTableObjects hash
         $myTableObjects{$_} = ($packageName . "::new")->($sqlClient);
      }
   }
   
   if ($parseSuccess)
   {
      $printLogger->print("Initialising parsers (", $$customProperties{'parsers.properties.file'}, ")...\n");
      
      # load the list of patterns and parsers parsers 
      $parserProperties = loadProperties($$customProperties{'parsers.properties.file'});
      
      if ($$parserProperties{'loadproperties.error'})
      {
         $printLogger->print("   ", $$parserProperties{'loadproperties.error.description'}, "\n");
         $parseSuccess = 0;
      }
      else
      {
         
         my %parserHash;

         # first run - split the parser properties up by configuration
         # this generates a hash of hashes:
         #   the keys of the greater hash are the configuration names and their
         #    values are a refernce to a hash
         #   Each inner hash contains the properties for that configuration
         foreach (keys %$parserProperties)
         {
            # split the key into the config name and remainder
            ($configName, $newKey) = split(/\./, $_, 2);
            
            # determine if this configuration is new
            if (!defined $parserHash{$configName})
            {
               # instantate a new hash for this configuration 
               my %newHash;
               $parserHash{$configName} = \%newHash;
            }
            
            # the inner hash is defined for this configuration - get its reference
            $innerHash = $parserHash{$configName};
            
            # assign to the new key and property value to inner hash for this configuration
            $$innerHash{$newKey}=$$parserProperties{$_};
         }
            
         # --- initialise the parsers for the selected configuration ---
         my %packageList;  # this hash is used to track which parser modules have been loaded already
         
         $parserName = $$parameters{'parser'};
         # get the reference to the inner hash for this configuration
         $innerHash = $parserHash{$parserName};
         
         if ($innerHash)
         {
            
            $printLogger->print("   Initialising '$parserName' parser...\n");
            # loop through all of the keys of the inner hash to extract the parsers
            foreach (keys %$innerHash)
            {
               $propertyName = $_;
               if ($propertyName =~ /parser\./)
               {
                  # this is a parser definition
                  $parserDefinition = $$innerHash{$propertyName};
                  
                  # split the parser definition up into its components
                  ($regex, $packageName, $functionName) = split(/::/, $parserDefinition, 3);
                  
                  # determine if this package has been loaded - if not load it now
                  if (!exists $packageList{$packageName})
                  {  
                     $printLogger->print("      Loading package $packageName...\n");
                     # load the package required for this parser
                     require "$packageName.pm";
                     $packageName->import();
          
                     ($packageName . "::parseDomainPropertyDetails")->($sqlClient);
                     
                     # record which packages have already been loaded - don't need to do multiple times
                     $packageList{$packageName} = 1;
                  }
                                    
                  # store the symbolic reference for the parser function - this is used by Ellamaine::DocumentReader
                  $myParsers{$regex} = $packageName."::".$functionName;
               }
            }
         }
         else
         {
            # if a parser has been defined, then report an error that it couldn't be found - if there's no parser then okay
            if ($parserName)
            {
               $printLogger->print("      ERROR: parser '$parserName' is not defined in ", $$customProperties{'parsers.properties.file'}, ".\n");
               $parseSuccess = 0;
            }
         }
      }
   }
}

# start the document reader...
if (($parseSuccess) && (!($$parameters{'command'} =~ /maintenance/i)))
{   
   $printLogger->print("Connecting to database...\n");
   $sqlClient->connect();
   
   $printLogger->print("Starting DocumentReader...\n");
   my $myDocumentReader = DocumentReader::new($$parameters{'agent'}, $$parameters{'instanceID'}, $$parameters{'url'}, $sqlClient, 
      \%myTableObjects, \%myParsers, $printLogger, $$parameters{'thread'}, $parameters);
      
   $myDocumentReader->run($$parameters{'command'});
   
   $sqlClient->disconnect();
 
}
else
{
   if ($parameters{'command'} =~ /maintenance/i)
   {
      #doMaintenance($printLogger, \%parameters);
   }
   else
   {
      $printLogger->print("   main: exit due to parameter error\n");
   }
}

$printLogger->printFooter("Finished\n");

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
   my $parameters;  # reference to a hash
   my $success = 0;
   my @startCommands = ('url', 'state', 'source', 'parser');
   my @continueCommands = ('state', 'source', 'parser');
   my @maintenanceCommands = ('action');   
   # this hash of lists defines the commands supported and mandatory options for each command
   my %mandatoryParameters = (
      'start' => \@startCommands,
      'continue' => \@continueCommands,
      'create' => undef,
      'drop' => undef,
      'maintenance' => \@maintenanceCommands
   );   
   my %commandDescription = (
         'help' => "Display this information",
         'start' => "start a new session to download advertisements",
         'continue' => "continue an existing session downloading advertisements from the last recovery position",
         'create' => "create the database tables",
         'drop' => "drop the database tables (and all data)",
         'maintenance' => "run maintenance option on the database"
   );
      
   if (CGI::param("config"))
   {
      # fetch the configuration fromt the ConfigTable... 
      # load the specified configuration file
      print "Loading configuration '", CGI::param("config"), ".config'...\n";
      $parameters = loadProperties(CGI::param("config").".config");
      
      if ($$parameters{'loadconfiguration.error'})
      {
         print "   ", $$parameters{'loadconfiguration.error.description'}, "\n";
      }
   }
   else
   {
      my %newHash;
      $parameters = \%newHash;  # initialise reference to empty hash 
   }
   
   # see which command is specified
   $$parameters{'command'} = CGI::param("command");
   $$parameters{'config'} = CGI::param("config");

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


