#!/usr/bin/perl
# Written by Jeromy Evans
# Started 13 March 2004
# 
# WBS: A.01.03.01 Developed On-line Database
# Version 0.1  
#
# Description:
#   Module that encapsulate the AdvertisedxProfiles database tables
# 
# History:
#   18 May 2004 - fixed bug in addRecord that failed to properly quote every
#     variable (it addded quotes, but didn't call use the sqlclient quote method
#     to escape quotes contained inside the value.
#
#   9 July 2004 - Merged with LogTable to record encounter information (date last encountered, url, checksum)
#  to support searches like get records 'still advertised'
#   25 July 2004 - added support for instance ID and transactionNo
#   22 August 2004 - added support for State column
#                  - renamed suburbIdentifier to suburbIndex
#   12 September 2004 - added support to specify the DateEntered field instead of using the current time.  This
#     is necessary to support the database recovery function (which uses the time it was logged instead of
#     now)
#   27 November 2004 - added the createdBy field to the table which is a foreign key back to the 
#     OriginatingHTML recordadded function changeRecord() and modified table format to support tracking of changes
#     to records.  Impacts the createTable function, and created createChangeTable
#   29 November 2004 - added support for the WorkingView table - table is created with the main one and
#     updated to the aggregation of changes whenever changeRecord is used
#   30 November 2004 - added support for the CacheView table - table is created with the main one and 
#     updated whenever a record is added to the main, but contains only a subset of fields to improve access time
#     for the cache comparisons
#                    - changed checkIfTupleExists to operate on the CacheView for query speed improvement
#   5 December 2004 - adapted to support both sales and rentals instead of two separete files with duplicated code
#   2 April 2005 - updated all insert functions to use $sqlClient->lastInsertID(); to get the identifier of the
#    last record inserted instead of performing a select function to find out.  This is MUCH faster.
#   8 May 2005 - major change to database structure to include unit number, agentindex, rename some fields and
#     remove unused fields, AND combine sale and rental advertisements into one table
#              - removed cacheview
#              - added checkIfProfileExists - that uses a hash instead of individual parameters
#              - completely removed concept of whether its a sale or rental table - always up to the individual 
#     methods to specify what data they're handling (when appropriate)
#  23 May 2005 - another significant change - modified the table so that the parsers don't need to perform processing
#     of address or price strings - instead the advertisedpropertyprofiles table contains the original unprocessed
#     data.  Later, the working view will include the processed derived data (like decomposed address, indexes etc)
#  26 May 2005 - modified addRecord so it creates the OriginatingHTML record (specify url and htmlsyntaxtree)
#              - modified handling of localtime so it uses localtime(time) instead of the mysql in-built function
#     localtime().  Improved support for overriding the time, and added support for the exact same timestamp
#     to be used in the changetable and originating html
#   5 June 2005 - important change - when checking if a tuple already exists, the dateentered field of the 
#    existing profile is compared against the current timestamp (which may be overridden) to confirm that the 
#    existing profile is actually OLDER than the new one.  This is necessary when processing log files, which
#    can be encountered out of time order.  Without it, the dateentered and lastencountered fields could
#    be corrupted (last encountered older than date entered), aslo impacting the estimates of how long a property
#    was advertised if the dateentered is the wrong field.  NOW, a record is always added if it is deemed 
#    older than the existing record - this may arise in duplicates in the database (except date) but these
#    are fixed later in the batch processing/association functions.
#  21 June 2005 - while developing the new transferToWorkingView function added support for AgentProfiles and
#    AgentContactProfiles tables - these tables contain the information on advertising agents
#  25 June 2005 - added functions to lookup profiles by exception codes (eg. if suburbname is null) and
#    added indexes to the tables to support these lookups.   Also added functions to get the count of the
#    number of exceptions.  These functions are used by the administration tools.
#  26 June 2005 - added function replaceRecord that's used to update a record in the source view.  It's 
#    purpose is for re-processing of OriginatingHTML after updating a parser.  As a consequence several
#    other modifications are included: - when a replace is performed, the working view is checked to
#    see if the replace needs to be propated it it (transferToWorkingView is updated), and subsequently
#    if the workingView record is in the MasterProperties, then the master property needs to be recalculated
#              - added lookup function for finding source records by their originatingHTML reference (another
#    index is added to AdvertisedPropertyProfiles
#              - renamed column in OverridenValidity to OverriddenValidity
#              - created functon calculateChangeProfile that compares to profiles and generates a hash
#    containing the differences.  It handles both integer and string comparison automatically (at a 
#    performance loss) and has two methods for handling undef in the new hash (clear value, or inherit value)
#              - significant change - removed functions 'checkIftupleExists' etc and replaced with the
#    function 'updateLastEncounteredIfExists'.  This function combines the lookup and the addEncounter
#    functions to centralise the changes - so that changes to the last encountered value in the source
#    record is propagated into the working view and master properties (if exists).  This change impacts
#    the software architecture of all parsers
# 30 June 2005 - added function lookupOriginatingHTMLFromSourceProfiles that fetches a list of OriginatingHTML 
#    identifiers from the source profiles applying an optional WHERE clause.  Used for reparsing of originating html
# 2 July 2005  - added function lookupIdentifiersWhere that fetches a list of identifiers from the WORKING VIEW
#    where the specified constraint is true.  Added for the reparseWorkingView utility
# 3 July 2005 - added function calculateChangeProfileRentainVitals that compares two profiles and returns a hash
#   of the changed elements AND the VITAL elements from the original profile (regardless of whether these are changed or not)
#   Used in for the replace writeMethod so that invalid values in the source record can be cleared while retaining 
#   the important bits (which aren't known by the parser processing the html, but are still vital to maintain the 
#   record. eg Identifier, DateEntered, LastEncountered and OriginatingHTML)
# 4 July 2005 - added index to the workingview based on ErrorCode and WarningCode - for faster exception lookup functions
# 11 July 2005 - added index to the working view based on State and SuburbName - for faster exception lookup functions
#              - fixed bug in the repairSuburbName function that was preventing one of the passes from ever succeeeding
#  (searching for a suburb name anywhere in the string).  Now fixed (need to reparse data though.
# 12 July 2005 - added indexes to AusPostCodes for faster operation of matchSuburbName and matchUniqueSuburbName
#    INDEX (state(3), locality(10)) and INDEX (Locality(10), Comments(10))
#              - added support for Locality name substitutions in the repairSuburbName function - replaces the 
#   locality name with the correct name for certain patterns (eg. Walsh Bay NSW is actually The Rocks)
# 4 August 2005 - modified the repairStreetAddress function to set StreetSection and StreetType to blank "" instead
#   of undef to work-around defect #44 - that the mysql index on the masterProperties table is not working for
#   the where criteria 'streetsection is null' (instead using streetsection = "null").  Likewise for StreetType (which is 
#   rarer).  (Originally set value to "" but this is interpreted the same as null in some code)
#  5 August 2005 - upgraded mysql server to 4.1.x to fix defect #44.  Undo of changes of 4Aug05.
# 11 September 2005 - found bug in assessRecordValidity that referenced 'AdvertisedWeeklRent' (typo) when checking
#  if the price was valid.  Caused all workingview rental records to be marked invalid, prevent them from 
#  ever being transferred into MasterProperties.
# 24 September 2005 - created support for the MostRecent table.  This table contains only the MostRecent advertisement
#  for a property appearing in the WorkingView.  Unlike the MasterProperties table that guarantees uniqueness by address, 
#  the MostRecent table attempts to get close-to-uniqueness using the SourceName, SourceID and the address if available.
#  If there's no address, the property is still listed in the MostRecent table but uniquess can't be guaranteed
#  (if there's mutliple sources in the databases).  The MostRecent table can be used as another source of analysis
#  data (as the datapoints are more plentiful than master properties)
# 25 September 2005 - bugfix to previous change - it was replacing records in the MostRecent table if they
#  were in the same suburb and had no address - even if they had different sourceID's.  Now the content
#  of the address is completely ignored.  
#                   - also added an index to the MostRecent table on DateEntered to see if this speeds
#  up the functions
#                   - added index to the WorkingVew on DateEntered so records in the WorkingView table
#  can be selected that are NEWER than the MostRecent record in the MostRecent table.  This supports
#  incremental batch transfer from the WorkingView to the MostRecent table
# 30 Jan 06 - added support for the AdvertisementCache.  This cache functions much like the old one, but its
#  justification now is to separate crawling from parsing.  The crawler only uses the cache and generates 
#  OriginatingHTML for parsing.
#  5 Feb 06 - renamed to AdvertisementCache in accordance with the new architecture.  Now only used by the 
# Crawler.  All redundant methods removed.
#           - now uses the AdvertisementRepository instead of the OriginatingHTML repository
#
# CONVENTIONS
# _ indicates a private variable or method
# ---CVS---
# Version: $Revision$
# Date: $Date$
# $Id$
#
package AdvertisementCache;
require Exporter;

use DBI;
use SQLClient;
use AdvertisementRepository;
use Time::Local;

@ISA = qw(Exporter SQLTable);

#@EXPORT = qw(&parseContent);

# -------------------------------------------------------------------------------------------------
# PUBLIC enumerations
#
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------

# Contructor for the AdvertisementCache - returns an instance of this object
# PUBLIC
sub new
{   
   my $sqlClient = shift;

   $tableName = 'AdvertisementCache';
   $advertisementRepository = AdvertisementRepository::new($sqlClient);
      
   my $advertisementCache = { 
      sqlClient => $sqlClient,
      tableName => $tableName,
      useDifferentTime => 0,
      dateEntered => undef,
      advertisementRepository => $advertisementRepository 
   }; 
      
   bless $advertisementCache;     
   
   return $advertisementCache;   # return this
}

# -------------------------------------------------------------------------------------------------
# overrideDateEntered
# sets the dateEntered field to use for the next add (instead of the current time)
# use when adding old data back into a database
#
# Purpose:
#  Storing information in the database
#
# Parameters:
#  timestamp to use (in SQL DATETIME format YYYY-MM-DD HH:MM:SS)
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
sub overrideDateEntered

{
   my $this = shift;
   my $timestamp = shift;
   
   $this->{'dateEntered'} = $timestamp;
   $this->{'useDifferentTime'} = 1;
}

# -------------------------------------------------------------------------------------------------
# getDateEnteredEpoch
# gets the current dateEntered field (used for the next add if set with overrideDateEntered)
# as an epoch value (seconds since 1970
#
# Purpose:
#  Storing information in the database
#
# Parameters:
#  timestamp to use (in SQL DATETIME format)
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
sub getDateEnteredEpoch

{
   my $this = shift;
   
   if ($this->{'useDifferentTime'})
   {
      $timestamp = $this->{'dateEntered'};
      ($year, $mon, $mday, $hour, $min, $sec) = split(/-|\s|:/, $timestamp);
      $epoch = timelocal($sec, $min, $hour, $mday, $mon-1, $year-1900);
   }
   else
   {
      $epoch = -1;
   }
      
   return $epoch;
}

# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------

my $SQL_CREATE_CACHE_TABLE_BODY = 
   "ID INTEGER ZEROFILL PRIMARY KEY AUTO_INCREMENT, ".
   "DateEntered DATETIME NOT NULL, ".
   "LastEncountered DATETIME, ".
   "SaleOrRentalFlag INTEGER,".                   
   "SourceName TEXT, ".
   "SourceID VARCHAR(20), ".
   "TitleString TEXT, ".
   "RepositoryID INTEGER ZEROFILL";     # REFERENCES AdvertisementRepository.ID,".           

# -------------------------------------------------------------------------------------------------
# createTable
# attempts to create the AdvertisementCacheTable table in the database if it doesn't already exist
# Also creates the AdvertisementRepository table
# 
# Purpose:
#  Initialising a new database
#
#
# Returns:
#   TRUE (1) if successful, 0 otherwise
#   

sub createTable

{
   my $this = shift;
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $tableName = $this->{'tableName'};

   my $SQL_CREATE_CACHE_TABLE_PREFIX = "CREATE TABLE IF NOT EXISTS $tableName (";
   
   my $SQL_CREATE_CACHE_TABLE_SUFFIX = ", INDEX (SaleOrRentalFlag, sourceName(5), sourceID(10)), INDEX(DateEntered), INDEX(RepositoryID))"; 
   
   if ($sqlClient)
   {
      # append change table prefix, original table body and change table suffix
      $sqlStatement = $SQL_CREATE_CACHE_TABLE_PREFIX.$SQL_CREATE_CACHE_TABLE_BODY.$SQL_CREATE_CACHE_TABLE_SUFFIX;
      
      $statement = $sqlClient->prepareStatement($sqlStatement);
      
      if ($sqlClient->executeStatement($statement))
      {
         $success = 1;          
      
         # create the AdvertisementRepository table
         $advertisementRepository = $this->{'advertisementRepository'};
         $advertisementRepository->createTable();
      }
   }
   
   return $success;   
}

# -------------------------------------------------------------------------------------------------

# addCacheRecord
# adds a record of data to the Advertisement Cache table
#
# Parameters:
#  reference to a hash containing the values to insert
#
# Returns:
#   The ID of the record inserted
#        
sub addAdvertisementCacheRecord

{
   my $this = shift;
   my $saleOrRentalFlag = shift;
   my $sourceName = shift;
   my $sourceID = shift;
   my $titleString = shift;   
   
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $statementText;
   my $tableName = $this->{'tableName'};
   my $localTime;
 
   my $identifier = -1;
   
   if ($sqlClient)
   {
      $statementText = "INSERT INTO $tableName (DateEntered, SaleOrRentalFlag, SourceName, SourceID, TitleString) VALUES (";
      
      # modify the statement to specify each column value to set 
      @columnValues = values %$parametersRef;
      $index = 0;
      
      if (!$this->{'useDifferentTime'})
      {
         # determine the current time
         ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
         $this->{'dateEntered'} = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);
         $localTime = $sqlClient->quote($this->{'dateEntered'});
      }
      else
      {
         # use the specified date instead of the current time
         $localTime = $sqlClient->quote($this->{'dateEntered'});
         $this->{'useDifferentTime'} = 0;  # reset the flag
      }      
      
      $quotedSource = $sqlClient->quote($sourceName);
      $quotedSourceID = $sqlClient->quote($sourceID);
      $quotedTitleString = $sqlClient->quote($titleString);
      
      $appendString = "$localTime, $saleOrRentalFlag, $quotedSource, $quotedSourceID, $quotedTitleString";
      
      $statementText = $statementText.$appendString . ")";
      
      #print "statement = ", $statementText, "\n";
      $statement = $sqlClient->prepareStatement($statementText);
      
      if ($sqlClient->executeStatement($statement))
      {
         $success = 1;
         
         # 2 April 2005 - use lastInsertID to get the primary key identifier of the record just inserted
         $identifier = $sqlClient->lastInsertID();                           
      }
   }
   
   return $identifier;   
}

# -------------------------------------------------------------------------------------------------
# replaceAdvertisementCacheRecord
# updates the specified cache record of data using the changedProfile hash
#
#
# Parameters:
#  reference to a hash containing the CHANGED values to insert
#  INTEGER ID
#
# Returns:
#   TRUE (1) if successful, 0 otherwise
#        
sub replaceAdvertisementCacheRecord

{
   my $this = shift;
   my $parametersRef = shift;   
   my $sourceIdentifier = shift;
   
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $statementText;
   my $localTime;
   my $tableName = $this->{'tableName'};
   
   if ($sqlClient)
   {      
      @changeList = keys %$parametersRef;
      $noOfChanges = @changeList;
      if ($noOfChanges > 0)
      {
         $appendString = "UPDATE $tableName SET ";
         # modify the statement to specify each column value to set 
         $index = 0;
         while(($field, $value) = each(%$parametersRef)) 
         {
            if ($index > 0)
            {
               $appendString = $appendString . ", ";
            }
            
            $quotedValue = $sqlClient->quote($value);
            
            $appendString = $appendString . "$field = $quotedValue ";
            $index++;
         }      
         
         $statementText = $appendString." WHERE ID=$sourceIdentifier";
         # print "$statementText\n";
         $statement = $sqlClient->prepareStatement($statementText);
         
         if ($sqlClient->executeStatement($statement))
         {
            $success = 1;                       
         }
      }
   }
   
   return $success; 
}

# -------------------------------------------------------------------------------------------------
# updateAdvertisementCache
# determine if the property exists in the cache or not - if it does, updates the LastEncountered 
# field only, but if it doesn't creates a new cache entry
#
# Parameters:
#  saleOrRentalFlag
#  string sourceName
#  string sourceID
#  string titleString
#
# Returns:
#   The identifier of the new CacheRecord, or Zero if a CacheHit occured (already exists)
#
sub updateAdvertisementCache
{   
   my $this = shift;
   my $saleOrRentalFlag = shift;
   my $sourceName = shift;      
   my $sourceID = shift;
   my $titleString = shift; 
   my $statement;
   my $found = 0;
   my $statementText;
   my $identifier;
   
   my $sqlClient = $this->{'sqlClient'};
   my $tableName = $this->{'tableName'};
   my @identifierList;
   my $matches;
   
   if ($sqlClient)
   {  
      $quotedSource = $sqlClient->quote($sourceName);
      $quotedSourceID = $sqlClient->quote($sourceID);
      $quotedTitleString = $sqlClient->quote($titleString);

      $constraint = "SaleOrRentalFlag = $saleOrRentalFlag AND sourceName = $quotedSource and sourceID = $quotedSourceID";     
      if ($titleString)
      {
         $constraint .= " AND TitleString = $quotedTitleString";
      }
      
      # this additional constraint allows records that never completely processed (didn't get details loaded
      # into the repository) to be run again
      $constraint .= " and RepositoryID > 0";
                        
      $statementText = "SELECT * FROM $tableName WHERE $constraint";         
      
      @selectResults = $sqlClient->doSQLSelect($statementText);
      
      if (!$this->{'useDifferentTime'})
      {
         # determine the current time
         $currentTime = time();
         # (correct formatting performed below)
      }
      else
      {
         # use the specified date instead of the current time
         $currentTime = $this->getDateEnteredEpoch();
      }   
      
      foreach (@selectResults)
      {         
         # there are 1 or more matches...update them
         
         # make sure the lastEncountered/dateEntered for the existing record is OLDER than the record being added       
         $dateEntered = $sqlClient->unix_timestamp($$_{'DateEntered'});
         
         # if last encountered is set
         if ($$_{'LastEncountered'})
         {
            $lastEncountered = $sqlClient->unix_timestamp($$_{'LastEncountered'});
            if ($currentTime > $lastEncountered)
            {
               # this record needs to be updated
               push @identifierList, $$_{'ID'};
            }            
         }
         else
         {
            if ($currentTime > $dateEntered)
            {
               # this record needs to be updated
               push @identifierList, $$_{'ID'};
            }            
         }
      }
       
      $matches = @identifierList;
      if ($matches > 0)
      {
         # finally, iterate through the list of identifiers that need to be modified and apply the changes
         my %changedCacheRecord;
         
         ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($currentTime);
         $sqlTime = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);
         
         foreach (@identifierList)
         {
            $identifier = $_;
            $changedCacheRecord{'LastEncountered'} = $sqlTime;
                       
            # apply the change 
            $this->replaceAdvertisementCacheRecord(\%changedCacheRecord, $identifier);
            $found = 1;
         }
      }
      else
      {
         # the record does not exist in the cache - create a new record
         my %cacheRecord;
         
         $identifier = $this->addAdvertisementCacheRecord($saleOrRentalFlag, $sourceName, $sourceID, $titleString);
      }
   }   
   
   if ($found)
   {
      return 0;  # zero means a cache hit occured
   }
   else
   {
      return $identifier;  # the identifier of the new cache record
   }   
}  


# -------------------------------------------------------------------------------------------------
# storeInAdvertisementRepository
# Enters the content of the advertisement into the repository for the specified CacheID item
# Triggers an update of the Cache to reference to AdvertisementRepository ID too.
#
# Parameters:
#  cacheID
#  string url
#  htmlsyntaxtree
#
# Returns:
#   Nil
#
sub storeInAdvertisementRepository
{   
   my $this = shift;
   my $cacheID = shift;
   my $url = shift;
   my $htmlSyntaxTree = shift;   
     
   my $tableName = $this->{'tableName'};
   my $currentTime;
                       
   if (!$this->{'useDifferentTime'})
   {
      # determine the current time      
      ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time());
      $sqlTime = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);         
   }
   else
   {
      # use the specified date instead of the current time
      $currentTime = $this->getDateEnteredEpoch();
   }   
             
   # --- store the originatingHTML in the repository  - in turn this will update the ID reference in the Cache ---
   if ($cacheID)
   {         
      $advertisementRepository->addRecordToRepository($sqlTime, $cacheID, $url, $htmlSyntaxTree, $tableName);     
   }                  
}  

# -------------------------------------------------------------------------------------------------
# addReferenceToAdvertisementRepository
# Updates the specified cache entry to reference the AdvertisementRepository specified
# This is used when one AdvertisementRepository generates several cache entries.
#
# Parameters:
#  cacheID
#  string url
#  htmlsyntaxtree
#
# Returns:
#   Nil
#
sub addReferenceToAdvertisementRepository
{   
   my $this = shift;
   my $cacheID = shift;
   my $advertisementRepositoryId = shift;    
     
   my $tableName = $this->{'tableName'};                          
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $statementText;
   my $identifier = -1;
   
   if (($sqlClient) && ($cacheID) && ($advertisementRepositoryId))
   {                                 
      #print "altering foreign key in $foreignTableName identifier=$foreignIdentifier createdBy=$identifier\n";
      # alter the foreign record - add this primary key as the CreatedBy foreign key - completing the relationship
      # between the two tables (in both directions)
      $sqlClient->alterForeignKey($tableName, 'ID', $cacheID, 'repositoryID', $advertisementRepositoryId);
   }
}  

# -------------------------------------------------------------------------------------------------
# dropTable
# attempts to drop the AdvertisementCache and AdvertisementRepository table 
# 
# Purpose:
#  Initialising a new database
#
# Parameters:
#  nil
#
# Returns:
#   TRUE (1) if successful, 0 otherwise
#
        
sub dropTable

{
   my $this = shift;
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $tableName = $this->{'tableName'};
   my $advertisementRepository;
   
   if ($sqlClient)
   {
      $statementText = "DROP TABLE $tableName";
      $statement = $sqlClient->prepareStatement($statementText);
      
      if ($sqlClient->executeStatement($statement))
      {
         $success = 1;
         
                  
         # drop the advertisement repository table
         $advertisementRepository = $this->{'advertisementRepository'};
         $advertisementRepository->dropTable();          
      }
   }
   
   return $success;   
}

# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# lookupAdvertisementCacheEntry
#  Fetches the details from the AdvertisementCache the specified identifier
#
# Parameters:
#  integer Identifier - this is the identifier of the record
#
# Returns:
#   reference to a hash of properties
#        
sub lookupAdvertisementCacheEntry

{
   my $this = shift;
   my $identifier = shift;
   
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $tableName = $this->{'tableName'};
   my $profileRef = undef;
   
   if ($sqlClient)
   {   
      if ($identifier)
      {         
         # fetch the profile
         @selectResults = $sqlClient->doSQLSelect("select * from $tableName where Identifier=$identifier");
         $profileRef = $selectResults[0];
      }     
   }
   return $profileRef;
}

# -------------------------------------------------------------------------------------------------
# lookupAdvertisementRepositoryFromAdvertisementCache
#  Fetches a list of AdvertisementRepository identifiers from the AdvertisementCache applying the
# specified WHERE clause
#
# Parameters:
#  OPTIONAL STRING WhereClause 
#  
# Returns:
#   reference to a hash of AdvertisementRepository identifiers
#        
sub lookupAdvertisementRepositoryFromAdvertisementCache

{
   my $this = shift;
   my $whereClause = shift;
   
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $tableName = $this->{'tableName'};
   my $profileRef = undef;
   my @selectResults;
   
   if ($sqlClient)
   {   
      if ($whereClause)
      {         
         $statementText = "SELECT RepositoryID FROM $tableName WHERE $whereClause";
      }
      else
      {
         $statementText = "SELECT RepositoryID FROM $tableName";
      }
      
      # fetch the profile
      @selectResults = $sqlClient->doSQLSelect($statementText);
   }
   return \@selectResults;
}

# -------------------------------------------------------------------------------------------------

# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# countEntries
# returns the number of advertisements in the database
#
# Purpose:
#  status information
#
# Parameters:
#  nil
#
# Constraints:
#  nil
#
# Updates:
#  Nil
#
# Returns:
#   nil
sub countEntries
{   
   my $this = shift;      
   my $statement;
   my $found = 0;
   my $noOfEntries = 0;
   
   my $sqlClient = $this->{'sqlClient'};
   my $tableName = $this->{'tableName'};
   
   if ($sqlClient)
   {       
      $quotedUrl = $sqlClient->quote($url);      
      my $statementText = "SELECT count(DateEntered) FROM $tableName";
   
      $statement = $sqlClient->prepareStatement($statementText);
      
      if ($sqlClient->executeStatement($statement))
      {
         # get the array of rows from the table
         @selectResult = $sqlClient->fetchResults();
                           
         foreach (@selectResult)
         {        
            # $_ is a reference to a hash
            $noOfEntries = $$_{'count(DateEntered)'};
            last;            
         }                 
      }                    
   }   
   return $noOfEntries;   
}  


