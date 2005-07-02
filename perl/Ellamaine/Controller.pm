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
#                - added support to load all parsers if the parser=all property is set
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
package Controller;

use CGI qw(:standard);
use Ellamaine::DocumentReader;
use Ellamaine::HTMLSyntaxTree;
use Ellamaine::StatusTable;
use ConfigTable;

use LoadProperties;
use PrintLogger;
use SQLTable;
use HTTPClient;
use DebugTools;

# -------------------------------------------------------------------------------------------------    

# -------------------------------------------------------------------------------------------------
# new
# contructor for Ellamaine controller
#
#
# Parameters:
#  sqlClient
#  reference to a hash of parameters
#
# Returns:
#  Ellamaine controller object
#    
sub new
{
   my $sqlClient = shift;
   my $parameters = shift;
   my $parseSuccess = 1; 
   
   # prepare to initialise the controller
   my $controller = { 
      sqlClient => $sqlClient,
      parameters => $parameters
   };               
   
   bless $controller;     

   # continue initialisation...
   
   # first, initialise a printLogger to use
   my $printLogger = PrintLogger::new($$parameters{'agent'}, $$parameters{'instanceID'}.".stdout", 1, $$parameters{'useText'}, $$parameters{'useHTML'});
   $$parameters{'printLogger'} = $printLogger;
   $controller->{'printLogger'} = $printLogger;
   
   $printLogger->printHeader("\n");
   
   # load the properties...
   my $customProperties = loadProperties("ellamaine.properties");

   # if custom properties where defined...
   if (($customProperties) && ($sqlClient))
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
            $tableName = $_;
            $packageName = $$tableProperties{$tableName};
            $printLogger->print("   Loading package $tableName (", $packageName, ".pm)...\n");
            # load the module (require the module)
            require "$packageName.pm";
            $packageName->import();   # this probably isn't necessary, but safe (import the module's exports)
            # use a symbolic reference to call new in the package and include the returned object in the
            # myTableObjects hash
            $myTableObjects{$tableName} = ($packageName . "::new")->($sqlClient);
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
          
            # if the parser name 'all' is specified, then all parsers will be loaded.  This would
            # be an unusual case
            if ($parserName =~ /all/i)
            {
               # load all of the defined parsers               
               @parserList = keys %parserHash;
            }
            else
            {
               # get the reference to the inner hash for this configuration
               @parserList = ($parserName);
            }
            
            # load all of the specified parsers (usually just one)
            foreach (@parserList)
            {
               $parserName = $_;
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
   }
   else
   {
      $parseSuccess = 0;
   }
  
   if (($parseSuccess) && (!($$parameters{'command'} =~ /maintenance/i)))
   {   
      $printLogger->print("Instantiating DocumentReader...\n");
      my $myDocumentReader = DocumentReader::new($$parameters{'agent'}, $$parameters{'instanceID'}, $$parameters{'url'}, $sqlClient, 
         \%myTableObjects, \%myParsers, $printLogger, $$parameters{'thread'}, $parameters, $$parameters{'dryRun'});
         
      $controller->{'documentReader'} = $myDocumentReader;
   }
   
   $controller->{'parseSuccess'} = $parseSuccess;
         
   return $controller;   # return this
}

# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------

# This is the main function for Ellamaine.  It instructs Ellamaine to commence parsing
# It performs the following sequence of operations:
#  - creates a printLogger
#  - loads the ellamaine.properties
#  - loads packages and parsers
#  - creates a documentReader
#  - starts the documentReader
sub start

{
   my $this = shift;

   my $parameters = $this->{'parameters'};
   my $sqlClient = $this->{'sqlClient'};
   my $printLogger = $this->{'printLogger'};
   
   # start the document reader...
   if ($this->{'documentReader'})
   {  
      $myDocumentReader = $this->{'documentReader'};
      
      $printLogger->print("Starting DocumentReader...\n");
      $myDocumentReader->run($$parameters{'command'});
   }

   return $parseSuccess;   
}

# -------------------------------------------------------------------------------------------------

# release the session progress table, thread in status table etc
sub releaseSessionHistory
{
   my $this = shift;
   
   $documentReader = $this->{'documentReader'};
   $documentReader->releaseSessionHistory();
}

1;
