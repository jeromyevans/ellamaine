#!/usr/bin/perl
# Written by Jeromy Evans
# Started 27 November 2004
# 
# WBS: A.01.03.01 Developed On-line Database
# Version 0.0  
#
# Description:
#   Module that encapsulate the AdvertisementRepository database component
#
# History:
# 19 Feb 2005 - hardcoded absolute log directory temporarily 
# 19 Apr 2005 - modified storage path to stop using flat directory - it was getting too big (too many files) to manage
#   now sorts into directory (1000 files per directory)
#             - added basePath function that returns the base path used for OriginatingHTML files
#             - added targetPath function that returns the target path for a specified OriginatingHTML file
# 21 Apr 2005 - modified saveHTMLContent to prefix each file with a header that identifies the source and timestamp
#   This information is needed for reconstruction from the originatingHTML file
# 22 Apr 2005 - added override basepath function for setting where to output originatingHTML files (used for recovery)
# 23 May 2005 - changed createdBy field in AdvertisedPropertyProfiles to originatingHTML
#             - modified to use sqlClient->lastInsertID instead of a select to get identifier
# 26 May 2005 - modified readHTMLContent to include an optional flag to specify that the header should be removed
#   from the content.  This is used when upgrading the header format
#             - modified saveHTMLContent to use a text based (sql TIMESTAMP) format instead of unixtime - it provides
#   better visual comparison to the database
#             - modified saveHTMLContent to place url and timestamp in single quotes
#             - modified addRecord to allow the timestamp to be specified
# 5 June 2005 - added function readHTMLContentWithHeader that extracts the fields from the originatingHTML header
#   while reading the file.  It returns the content, url and timestamp in an array.  The readHTMLContent function
#   now just calls readHTMLContentWithHEader but discards the unused unformation.  The stripHeader flag is still
#   used by both functions.
# 2 July 2005 - Directory for logging of OriginatingHTML is now specified in ellamaine.properties
# 30 Jan 2006 - added support for separation of the Crawler from the Parser - new method to add OriginatinghTML
#  that updates the Cache
#             - removed the CreatesRecord field from OriginatingHTML.  One OriginatingHTML can create multiple
#  cache entries now
# 5 Feb 2006  - renamed from OriginatingHTML to AdvertisementRepository in accordance with the new architecture
#             - the name OriginatingHTML is still stored in the generated repository files and in the 
#  default path to the repository (for backwards compatibility with the existing repository) 
# 21 Aug 2008 - added year, month, day columns for faster indexing
# CONVENTIONS
# _ indicates a private variable or method
# ---CVS---
# Version: $Revision$
# Date: $Date$
# $Id$
#
package AdvertisementRepository;
require Exporter;

use DBI;
use SQLClient;
use LoadProperties;

@ISA = qw(Exporter, SQLTable);


# -------------------------------------------------------------------------------------------------
# CONSTANTS
# -------------------------------------------------------------------------------------------------
my $DEFAULT_LOG_PATH = "./originatinghtml";
# -------------------------------------------------------------------------------------------------

# -------------------------------------------------------------------------------------------------
# This variable is populated with a reference to a hash of properties for the AdvertisementRepository that
# are read from disk by the first constructor
my $localProperties = undef;
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------

# Contructor for the AdvertisementRepository - returns an instance of an AdvertisementRepositoryTable object
# PUBLIC
sub new
{   
   my $sqlClient = shift;

   # initialise local properties for the httpclient (from the properties file if it exists)
   if (!$localProperties)
   {
      $localProperties = loadProperties("ellamaine.properties");
      
      if (!$localProperties)
      {
         $$localProperties{'originatinghtml.log.path'} = $DEFAULT_LOG_PATH;
      }
   } 
   
   my $advertisementRepository = { 
      sqlClient => $sqlClient,
      tableName => "AdvertisementRepository",
      basePath => $$localProperties{'originatinghtml.log.path'}, 
      useFlatPath => 0
   }; 
      
   bless $advertisementRepository;  
   
   return $advertisementRepository;   # return this
}

# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# createTable
# attempts to create the AdvertisementRepository table in the database if it doesn't already exist
# 
# Purpose:
#  Initialising a new database
#
# Parameters:
#  nil
#
# Constraints:
#  nil
#
# Uses:
#  sqlClient
#
# Updates:
#  nil
#
# Returns:
#   TRUE (1) if successful, 0 otherwise
#
my $SQL_CREATE_TABLE_STATEMENT = "CREATE TABLE IF NOT EXISTS AdvertisementRepository ".
   "(ID INTEGER ZEROFILL PRIMARY KEY AUTO_INCREMENT, ".
   "DateEntered DATETIME NOT NULL, ".   
   "SourceURL TEXT, ".
   "Datestamp DATE, ".
   "Year INTEGER, ".
   "Month INTEGER, ".
   "Day INTEGER".
   ")";
      
sub createTable

{
   my $this = shift;
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   
   if ($sqlClient)
   {
      $statement = $sqlClient->prepareStatement($SQL_CREATE_TABLE_STATEMENT);
      
      if ($sqlClient->executeStatement($statement))
      {
	 $success = 1;
      }
   }
   
   return $success;   
}

# -------------------------------------------------------------------------------------------------
# addRecordToRepository
# adds a record of data to the AdvertisementRepository table
# also saves the content of the HTMLSyntaxTree to disk
# uses the new Cache table architecture 
# (SUPERCEEDS addRecord)
#
# Purpose:
#  Storing information in the database
#
# Parameters:
#  integer foreignIdentifier - foreign key to record that was created
#  string sourceURL   
#  HTMLSyntaxTree          - html content will be saved to disk
#  string foreignTableName - name of the table that contains the created record.  It will be altered with the this new key
#
# Constraints:
#  nil
#
# Uses:
#  sqlClient
#
# Updates:
#  nil
#
# Returns:
#   TRUE (1) if successful, 0 otherwise
#  
      
sub addRecordToRepository

{
   my $this = shift;
   my $timestamp = shift;
   my $foreignIdentifier = shift;
   my $url = shift;
   my $htmlSyntaxTree = shift;
   my $foreignTableName = shift;
   
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $statementText;
   my $identifier = -1;
   
   if ($sqlClient)
   {
      $statementText = "INSERT INTO AdvertisementRepository (";
            
      # modify the statement to specify each column value to set 
      $appendString = "ID, DateEntered, sourceurl";
      
      $statementText = $statementText.$appendString . ") VALUES (";
      
      # modify the statement to specify each column value to set 
      $index = 0;
      $quotedUrl = $sqlClient->quote($url);
      $quotedForeignIdentifier = $sqlClient->quote($foreignIdentifier);
      $quotedTimestamp = $sqlClient->quote($timestamp);

      # convert timestamp back to date components (yyyy-MM-dd hh:hh:ss)
      $datestamp = substr($timestamp, 0, index($timestamp, ' '));
      ($year, $month, $day) = split('-', $datestamp);             
      $quotedDatestamp = $sqlClient->quote($datestamp);

      $appendString = "null, $quotedTimestamp, $quotedUrl, $quotedDatestamp, $year, $month, $day)";

      $statementText = $statementText.$appendString;
      
      # prepare and execute the statement
      $statement = $sqlClient->prepareStatement($statementText);         
      if ($sqlClient->executeStatement($statement))
      {
         $success = 1;
       
         # 25 May 2005 - use lastInsertID to get the primary key identifier of the record just inserted
         $identifier = $sqlClient->lastInsertID();
                  
         if ($identifier >= 0)
         {
            #print "altering foreign key in $foreignTableName identifier=$foreignIdentifier createdBy=$identifier\n";
            # alter the foreign record - add this primary key as the CreatedBy foreign key - completing the relationship
            # between the two tables (in both directions)
            $sqlClient->alterForeignKey($foreignTableName, 'ID', $foreignIdentifier, 'repositoryID', $identifier);
            
            $timeStamp = time();
            
            # save the HTML content to disk using the primarykey as the filename
            $this->saveHTMLContent($identifier, $htmlSyntaxTree->getContent(), $url, $timestamp);
         }
      }
   }
   
   return $identifier;   
}


# -------------------------------------------------------------------------------------------------

# dropTable
# attempts to drop the AdvertisementRepository table 
# 
# Purpose:
#  Initialising a new database
#
# Parameters:
#  nil
#
# Constraints:
#  nil
#
# Uses:
#  sqlClient
#
# Updates:
#  nil
#
# Returns:
#   TRUE (1) if successful, 0 otherwise
#
my $SQL_DROP_TABLE_STATEMENT = "DROP TABLE AdvertisementRepository";
        
sub dropTable

{
   my $this = shift;
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   
   if ($sqlClient)
   {
      $statement = $sqlClient->prepareStatement($SQL_DROP_TABLE_STATEMENT);
      
      if ($sqlClient->executeStatement($statement))
      {
	      $success = 1;
      }
   }
   
   return $success;   
}

# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
#
# returns the base path used for the AdvertisementRepository files
#
sub basePath
{
   my $this = shift;
   
   return $this->{'basePath'};
}

# -------------------------------------------------------------------------------------------------
#
# returns the path to be used for the AdvertisementRepository with the specified identifier
sub targetPath
{
   my $this = shift;
   my $identifier = shift;
 
   if (!$this->{'useFlatPath'})
   {
      # this is the normal case - use subdirectories
      $targetDir = int($identifier / 1000);   
      $basePath = $this->basePath();
      $targetPath = $basePath."/$targetDir";
   }
   else
   {
      $basePath = $this->basePath();
      $targetPath = $basePath;
   }
   return $targetPath;
}


# -------------------------------------------------------------------------------------------------
#
#
sub overrideBasePath
{
   my $this = shift;
   my $newBasePath = shift;
   
   $this->{'basePath'} = $newBasePath; 
}


# -------------------------------------------------------------------------------------------------

sub useFlatPath
{
   my $this = shift;
   
   $this->{'useFlatPath'} = 1; 
}

# -------------------------------------------------------------------------------------------------



# -------------------------------------------------------------------------------------------------
# saveHTMLContent
#  saves to disk the html content for the specified record
# 
# Purpose:
#  Debugging
#
# Parameters:
#  integer identifier (primary key of the AdvertisementRepository)
#
# Constraints:
#  nil
#
# Updates:
#  $this->{'requestRef'} 
#  $this->{'responseRef'}
#
# Returns:
#   nil
#
sub saveHTMLContent ($ $ $ $)

{
   my $this = shift;
   my $identifier = shift;
   my $content = shift;
   my $sourceURL = shift;
   my $timeStamp = shift;
   my $writeHeader = 0;
   
   my $sessionFileName = $identifier.".html";
   my $header;
   
   $logPath = $this->targetPath($identifier);
   
   if (($timeStamp) && ($sourceURL))
   {
      $header = "<!---- OriginatingHTML -----\n".
                "sourceurl='$sourceURL'\n".
                "localtime='$timeStamp'\n".
                "--------------------------->\n";
      $writeHeader = 1;
   }
   
   mkdir $basePath, 0755;       	      
   mkdir $logPath, 0755;       	      
   open(SESSION_FILE, ">$logPath/$sessionFileName") || print "Can't open file: $!";
   if ($writeHeader)
   {
      print SESSION_FILE $header;
   }
   print SESSION_FILE $content;
   close(SESSION_FILE);      
}

# -------------------------------------------------------------------------------------------------


# -------------------------------------------------------------------------------------------------
# readHTMLContentWithHeader
#  reads from disk the html content for the specified record as well as extacting the 
# fields in the header
# 
# Purpose:
#  Debugging
#
# Parameters:
#  integer identifier (primary key of the AdvertisementRepository)
#  optional integer flag stripHeader - if set, the AdvertisementRepository header is removed from the content
# Constraints:
#  nil
#
# Updates:
#
# Returns:
#   content
#   string sourceurl
#   string timestamp
#
sub readHTMLContentWithHeader

{
   my $this = shift;
   my $identifier = shift;
   my $stripHeader = shift;
   my $fileName = $identifier.".html";
   my @body;
   my $content = undef;
   my $SEEKING_HEADER = 0;
   my $IN_HEADER = 1;
   my $sourceurl = undef;
   my $timestamp = undef;
   
   $sourcePath = $this->targetPath($identifier);
   $lineNo = 0;
   if (open(SESSION_FILE, "<$sourcePath/$fileName"))
   {
      # read the content.
      while (<SESSION_FILE>)
      {
         $thisLine = $_;
         $thisLineIsHeader = 0;
         
         # originating HTML header processing
         if ($stripHeader)
         {
            if ($lineNo < 10)
            {
               $line = $thisLine;
               chomp $line;
               if ($state == $SEEKING_HEADER)
               {
                  if ($line =~ /OriginatingHTML/gi)
                  {
                     $state = $IN_HEADER;
                     $thisLineIsHeader = 1;
                  }
               }
               
               if ($state == $IN_HEADER)
               {
                  if ($line =~ /sourceurl=/gi)
                  {
                     # extract the sourceurl header element
                     ($label, $sourceurl) = split(/=/, $line, 2);
                     $sourceurl =~ s/\'//g;   # remove single quotes
                     
                     $thisLineIsHeader = 1;
                  }
                  elsif ($line =~ /localtime=/gi)
                  {
                     # extract the timestamp header element
                     ($label, $timestamp) = split(/=/, $line, 2);
                     $timestamp =~ s/\'//g;   # remove single quotes
               
                     $thisLineIsHeader = 1;
                  }
                  elsif ($line =~ /---\>/gi)
                  {
                     $thisLineIsHeader = 1;
                     $state = $SEEKING_HEADER;
                  }
               }
            }
         }
         #  if this line is part of the header, only add it to the content if the stripHeader flag is clear
         #  if this line is not part of the header, always add it
         if ((!$stripHeader) || (!$thisLineIsHeader))
         {  
            # add this line to the content
            $body[$lineNo] = $_;
            $lineNo++;
         }
      }
      
      if ($lineNo > 0)
      {
         $content = join '', @body;
      }
   }
   else
   {
      $content = undef;
   }
   
   close(SESSION_FILE);
   
   
   return ($content, $sourceurl, $timestamp);
}

# -------------------------------------------------------------------------------------------------
# readHTMLContent
#  reads from disk the html content for the specified record
#  NOTE: this function calls readHTMLContentWithHeader but simply discards the header information
#
# Purpose:
#  maintenance
#
# Parameters:
#  integer identifier (primary key of the AdvertisementRepository)
#  optional integer flag stripHeader - if set, the AdvertisementRepository header is removed from the content
# Constraints:
#  nil
#
# Updates:
#
# Returns:
#   content
#
sub readHTMLContent

{
   my $this = shift;
   my $identifier = shift;
   my $stripHeader = shift;
   
   ($content, $sourceurl, $timestamp) = $this->readHTMLContentWithHeader($identifier, $stripHeader);
   
   return $content;
}

# -------------------------------------------------------------------------------------------------

# -------------------------------------------------------------------------------------------------
# lookupAdvertisementRepositoryIdentifiers
#  Returns a list of ALL the identifiers in the AdvertisementRepository table
#
# Parameters:
#  OPTIONAL INTEGER Limit  - maximum number of records to return
#  OPTIONAL INTEGER Offset - start at this index
#
# Returns:
#   reference to a hash of properties
#        
sub lookupAdvertisementRepositoryIdentifiers

{
   my $this = shift;
   my $limit = shift;
   my $offset = shift;
   
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $tableName = $this->{'tableName'};
   my $profileRef = undef;
   my @selectResults;
   my $constraint;
   
   if ($sqlClient)
   {
      $constraint = "";
      if ($limit)
      {
         $constraint .= " LIMIT $limit";
      }
      if ($offset)
      {
         $constraint .= " OFFSET $offset";
      }
      $statementText = "select Identifier from $tableName".$constraint;
      
      @selectResults = $sqlClient->doSQLSelect($statementText);
   }
   return \@selectResults;
}

# -------------------------------------------------------------------------------------------------
1;
