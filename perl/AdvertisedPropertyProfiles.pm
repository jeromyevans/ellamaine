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
#
# CONVENTIONS
# _ indicates a private variable or method
# ---CVS---
# Version: $Revision$
# Date: $Date$
# $Id$
#
package AdvertisedPropertyProfiles;
require Exporter;

use DBI;
use SQLClient;
use OriginatingHTML;
use Time::Local;
use PrettyPrint;
use PropertyTypes;
use StringTools;
use PrettyPrint;
use RegExPatterns;
use AgentProfiles;
use AgentContactProfiles;

@ISA = qw(Exporter SQLTable);

#@EXPORT = qw(&parseContent);

# -------------------------------------------------------------------------------------------------
# PUBLIC enumerations
#
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------

# Contructor for the AdvertisedPropertyProfiles - returns an instance of this object
# PUBLIC
sub new
{   
   my $sqlClient = shift;

   $tableName = 'AdvertisedPropertyProfiles';
   $originatingHTML = OriginatingHTML::new($sqlClient);
   $agentProfiles = AgentProfiles::new($sqlClient);
   $agentContactProfiles = AgentContactProfiles::new($sqlClient);
   
   my $advertisedPropertyProfiles = { 
      sqlClient => $sqlClient,
      tableName => $tableName,
      useDifferentTime => 0,
      dateEntered => undef,
      originatingHTML => $originatingHTML,
      regExPatterns => undef, 
      agentProfiles => $agentProfiles,
      agentContactProfiles => $agentContactProfiles
   }; 
      
   bless $advertisedPropertyProfiles;     
   
   return $advertisedPropertyProfiles;   # return this
}

# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# createTable
# attempts to create the advertisedSaleProfiles table in the database if it doesn't already exist
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

my $SQL_CREATE_TABLE_BODY = 
   "DateEntered DATETIME NOT NULL, ".
   "LastEncountered DATETIME, ".
   "SaleOrRentalFlag INTEGER,".                   
   "SourceName TEXT, ".
   "SourceID VARCHAR(20), ".
   "TitleString TEXT, ".
   "Checksum INTEGER, ".
   "State VARCHAR(3), ".   
   "SuburbName TEXT, ".
   "Type VARCHAR(10), ".
   "Bedrooms INTEGER, ".
   "Bathrooms INTEGER, ".
   "LandArea TEXT, ".   
   "BuildingArea TEXT, ".
   "YearBuilt VARCHAR(5), ".
   "AdvertisedPriceString TEXT, ".
   "StreetAddress TEXT, ".
   "Description TEXT, ".    
   "Features TEXT,".
   "OriginatingHTML INTEGER ZEROFILL,".       
   "AgencySourceID TEXT, ".
   "AgencyName TEXT, ".
   "AgencyAddress TEXT, ".   
   "SalesPhone TEXT, ".
   "RentalsPhone TEXT, ".
   "Fax TEXT, ".
   "ContactName TEXT, ".
   "MobilePhone TEXT, ".
   "Website TEXT";
   
sub createTable

{
   my $this = shift;
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $tableName = $this->{'tableName'};
   
   my $SQL_CREATE_TABLE_PREFIX = "CREATE TABLE IF NOT EXISTS $tableName (Identifier INTEGER ZEROFILL PRIMARY KEY AUTO_INCREMENT, ";
   my $SQL_CREATE_TABLE_SUFFIX = ", INDEX (SaleOrRentalFlag, SourceName(5), SourceID(10), TitleString(15), Checksum))";  # extended now that cacheview is dropped
   
   if ($sqlClient)
   {
      # append table prefix, original table body and table suffix
      $sqlStatement = $SQL_CREATE_TABLE_PREFIX.$SQL_CREATE_TABLE_BODY.$SQL_CREATE_TABLE_SUFFIX;
     
      $statement = $sqlClient->prepareStatement($sqlStatement);
      
      if ($sqlClient->executeStatement($statement))
      {
         $success = 1;
         
       # 21June05
      }
         # 27Nov04: create the corresponding change table
         $this->_createChangeTable();
         # 29Nov04: create the corresponding working view
         $this->_createWorkingViewTable();
         
         # create the originatingHTML table
         $originatingHTML = $this->{'originatingHTML'};
         $originatingHTML->createTable();
    #  }
     
   }
   
   return $success;   
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
# addRecord
# adds a record of data to the AdvertisedPropertyProfiles table
# OPERATES ON ALL VIEWS (working view is updated)
#
# Purpose:
#  Storing information in the database
#
# Parameters:
#  reference to a hash containing the values to insert
#  string sourceURL
#  htmlsyntaxtree - used to generating originatingHTML record
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
sub addRecord

{
   my $this = shift;
   my $parametersRef = shift;
   my $url = shift;
   my $htmlSyntaxTree = shift;
   
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $statementText;
   my $tableName = $this->{'tableName'};
   my $localTime;
   my $originatingHTML = $this->{'originatingHTML'};
   my $identifier = -1;
   
   if ($sqlClient)
   {
      $statementText = "INSERT INTO $tableName (DateEntered, ";
      
      @columnNames = keys %$parametersRef;
      
      # modify the statement to specify each column value to set 
      $appendString = join ',', @columnNames;
      
      $statementText = $statementText.$appendString . ") VALUES (";
      
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
      
      $appendString = "$localTime, ";
      $index = 0;
      foreach (@columnValues)
      {
         if ($index != 0)
         {
            $appendString = $appendString.", ";
         }
        
         $appendString = $appendString.$sqlClient->quote($_);
         $index++;
      }
      $statementText = $statementText.$appendString . ")";
      
      #print "statement = ", $statementText, "\n";
      $statement = $sqlClient->prepareStatement($statementText);
      
      if ($sqlClient->executeStatement($statement))
      {
         $success = 1;
         
         # 2 April 2005 - use lastInsertID to get the primary key identifier of the record just inserted
         $identifier = $sqlClient->lastInsertID();
                  
         # --- add the corresponding originatingHTML record ---
         if ($identifier)
         {
            # 27Nov04: save the HTML file entry that created this record
            $originatingHTML->addRecord($this->{'dateEntered'}, $identifier, $url, $htmlSyntaxTree, $tableName);
         }
      }
   }
   
   return $identifier;   
}

# -------------------------------------------------------------------------------------------------
# dropTable
# attempts to drop the AdvertisedxProfiles table 
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
        
sub dropTable

{
   my $this = shift;
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $tableName = $this->{'tableName'};
   
   if ($sqlClient)
   {
      $statementText = "DROP TABLE $tableName";
      $statement = $sqlClient->prepareStatement($statementText);
      
      if ($sqlClient->executeStatement($statement))
      {
         $success = 1;
         #$statementText = "DROP TABLE CacheView_$tableName";
         #$statement = $sqlClient->prepareStatement($statementText);
         
         #if ($sqlClient->executeStatement($statement))
         #{

            $statementText = "DROP TABLE ChangeTable_$tableName";
            $statement = $sqlClient->prepareStatement($statementText);
            
            if ($sqlClient->executeStatement($statement))
            { 
               
               $statementText = "DROP TABLE WorkingView_$tableName";
               $statement = $sqlClient->prepareStatement($statementText);
               
               if ($sqlClient->executeStatement($statement))
               {       
            
                  $success = 1;
                  
                  # create the originatingHTML table
                  $originatingHTML = $this->{'originatingHTML'};
                  $originatingHTML->dropTable();
               }
            }
         #}
      }
   }
   
   return $success;   
}

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


# -------------------------------------------------------------------------------------------------


# -------------------------------------------------------------------------------------------------
# checkIfResultExists
# checks whether the specified tuple exists in the table (part of this check uses a checksum)
#
# Purpose:
#  tracking data parsed by the agent
#
# Parameters:
#  saleOrRentalFlag
#  string sourceName
#  string sourceID
#  string titleString (the title of the record in the search results - if it changes, a new record is added) 

# Constraints:
#  nil
#
# Updates:
#  Nil
#
# Returns:
#   nil
sub checkIfResultExists
{   
   my $this = shift;
   my $saleOrRentalFlag = shift;
   my $sourceName = shift;      
   my $sourceID = shift;
   my $titleString = shift;
   my $statement;
   my $found = 0;
   my $statementText;
      
   my $sqlClient = $this->{'sqlClient'};
   my $tableName = $this->{'tableName'};
   
   if ($sqlClient)
   {       
      $quotedSource = $sqlClient->quote($sourceName);
      $quotedSourceID = $sqlClient->quote($sourceID);
      $quotedTitleString = $sqlClient->quote($titleString);

      $statementText = "SELECT unix_timestamp(dateEntered) as unixTimestamp, sourceName, sourceID, titleString FROM $tableName WHERE SaleOrRentalFlag = $saleOrRentalFlag AND sourceName = $quotedSource AND sourceID = $quotedSourceID AND titleString = $quotedTitleString";
      #print "checkIfResultExists: $statementText\n";
      $statement = $sqlClient->prepareStatement($statementText);
      if ($sqlClient->executeStatement($statement))
      {
         # get the array of rows from the table
         @resultList = $sqlClient->fetchResults();
                           
         foreach (@resultList)
         {
#            DebugTools::printHash("result", $_);
            # only check advertisedpricelower if it's undef (if caller hasn't set it because info wasn't available then don't check that field.           
            
            # $_ is a reference to a hash       
       #     print "   ", $$_{'sourceName'}, " == $sourceName) && (", $$_{'sourceID'}, " == $sourceID) && (", $$_{'titleString'}, " == $titleString)\n";
            if (($$_{'sourceName'} == $sourceName) && ($$_{'sourceID'} == $sourceID) && ($$_{'titleString'} == $titleString))            
            {
               # found a match
               # 5 June 2005 - BUT, make sure the dateEntered for the existing record is OLDER than the record being added
               # if it's not, added the new record  (only matters if useDifferentTime is SET)
               $dateEntered = $this->getDateEnteredEpoch();
        #       print "      (", $$_{'unixTimestamp'}, " <= $dateEntered) || (!", $this->{'useDifferentTime'},")\n";
               if (($$_{'unixTimestamp'} <= $dateEntered) || (!$this->{'useDifferentTime'}))
               { 
                  $found = 1;
         #         print "         found\n";
                  last;
               }
            }
         }                 
      }              
   }   
   return $found;   
}  



# -------------------------------------------------------------------------------------------------
# checkIfTupleExists
# checks whether the specified tuple exists in the table (part of this check uses a checksum)
#
# Purpose:
#  tracking data parsed by the agent
#
# Parameters:
#  saleOrRentalFlag
#  string sourceName
#  string sourceID
#  string checksum (ignored if undef)
#  string priceString (ignored if undef)

# Constraints:
#  nil
#
# Updates:
#  Nil
#
# Returns:
#   nil
sub checkIfTupleExists
{   
   my $this = shift;
   my $saleOrRentalFlag = shift;
   my $sourceName = shift;      
   my $sourceID = shift;
   my $checksum = shift;
   my $advertisedPriceString = shift;
   my $statement;
   my $found = 0;
   my $statementText;
      
   my $sqlClient = $this->{'sqlClient'};
   my $tableName = $this->{'tableName'};
   
   if ($sqlClient)
   {       
      $quotedSource = $sqlClient->quote($sourceName);
      $quotedSourceID = $sqlClient->quote($sourceID);
      
      if (defined $checksum)
      {
         if ($advertisedPriceLower)
         {
            $statementText = "SELECT unix_timestamp(dateEntered) as unixTimestamp, sourceName, sourceID, checksum, advertisedPriceString FROM $tableName WHERE SaleOrRentalFlag = $saleOrRentalFlag AND sourceName = $quotedSource and sourceID = $quotedSourceID and checksum = $checksum and advertisedPriceString = $advertisedPriceString";
         }
         else
         {
            $statementText = "SELECT unix_timestamp(dateEntered) as unixTimestamp, sourceName, sourceID, checksum FROM $tableName WHERE SaleOrRentalFlag = $saleOrRentalFlag AND sourceName = $quotedSource and sourceID = $quotedSourceID and checksum = $checksum";
         }
      }
      else
      {
         #print "   checkIfTupleExists:noChecksum\n";
         if ($advertisedPriceLower)
         {
            #print "   checkIfTupleExists:apl=$advertisedPriceLower\n";

            $statementText = "SELECT unix_timestamp(dateEntered) as unixTimestamp, sourceName, sourceID, advertisedPriceString FROM $tableName WHERE SaleOrRentalFlag = $saleOrRentalFlag AND sourceName = $quotedSource and sourceID = $quotedSourceID and advertisedPriceString = $advertisedPriceString";
         }
         else
         {
            #print "   checkIfTupleExists:no apl\n";

            $statementText = "SELECT unix_timestamp(dateEntered) as unixTimestamp, sourceName, sourceID FROM $tableName WHERE SaleOrRentalFlag = $saleOrRentalFlag AND sourceName = $quotedSource and sourceID = $quotedSourceID";
         }
      }
      
      #print "   checkIfTupleExistsSales: $statementText\n";      
      $statement = $sqlClient->prepareStatement($statementText);
      if ($sqlClient->executeStatement($statement))
      {
         # get the array of rows from the table
         @checksumList = $sqlClient->fetchResults();
         #DebugTools::printList("checksum", \@checksumList);                  
         foreach (@checksumList)
         {
            #DebugTools::printHash("result", $_);
            # only check advertisedpricelower if it's undef (if caller hasn't set it because info wasn't available then don't check that field.           
            if ($advertisedPriceLower)
            {
               # $_ is a reference to a hash
               
               if (($$_{'checksum'} == $checksum) && ($$_{'sourceName'} == $sourceName) && ($$_{'sourceID'} == $sourceID) && ($$_{'advertisedPriceString'} == $advertisedPriceString))            
               {
                  # found a match
                  # 5 June 2005 - BUT, make sure the dateEntered for the existing record is OLDER than the record being added
                  # if it's not, added the new record  (only matters if useDifferentTime is SET)
                  $dateEntered = $this->getDateEnteredEpoch();
                  if (($$_{'unixTimestamp'} <= $dateEntered) || (!$this->{'useDifferentTime'}))
                  { 
                     $found = 1;
                     last;
                  }
               }
            }
            else
            {
               # $_ is a reference to a hash
               if (($$_{'checksum'} == $checksum) && ($$_{'sourceName'} == $sourceName) && ($$_{'sourceID'} == $sourceID))            
               {
                  # found a match
                  # 5 June 2005 - BUT, make sure the dateEntered for the existing record is OLDER than the record being added
                  # if it's not, added the new record  (only matters if useDifferentTime is SET)
                  $dateEntered = $this->getDateEnteredEpoch();
                  if (($$_{'unixTimestamp'} <= $dateEntered) || (!$this->{'useDifferentTime'}))
                  { 
                     $found = 1;
                     last;
                  }
               }
            }
         }                 
      }              
   }   
   return $found;   
}  


# -------------------------------------------------------------------------------------------------
# checkIfProfileExists
# checks whether the specified profile already exists in the table (part of this check uses a checksum)
#
# Purpose:
#  tracking changed data parsed by the agent
#
# Parameters:
#  reference to the profile hash
#
# Constraints:
#  nil
#
# Updates:
#  Nil
#
# Returns:
#   true if found
#
sub checkIfProfileExists
{   
   my $this = shift;
   my $propertyProfile = shift;
   
   $found = $this->checkIfTupleExists($$propertyProfile{'SaleOrRentalFlag'}, $$propertyProfile{'SourceName'}, $$propertyProfile{'SourceID'}, $$propertyProfile{'Checksum'}, $$propertyProfile{'AdvertisedPriceString'});

   return $found;   
}

# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# addEncounterRecord
# records in the table that a unique tuple with has been encountered again
# (used for tracking how often unchanged data is encountered, parsed and rejected)
# 
# Purpose:
#  Logging information in the database
#
# Parameters: 
#  string sourceName
#  string sourceID
#  integer checksum  (ignored if undef)
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
sub addEncounterRecord

{
   my $this = shift;
   my $saleOrRentalFlag = shift;
   my $sourceName = shift;
   my $sourceID = shift;
   my $checksum = shift;
   
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};  
   my $tableName = $this->{'tableName'};
   my $statementText;
   my $localTime;
   
   if ($sqlClient)
   {
      $quotedSource = $sqlClient->quote($sourceName);
      $quotedSourceID = $sqlClient->quote($sourceID);
      $quotedUrl = $sqlClient->quote($url);
  
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
  
      if (defined $checksum)
      {
         $statementText = "UPDATE $tableName ".
           "SET LastEncountered = $localTime ".
           "WHERE (SaleOrRentalFlag = $saleOrRentalFlag AND sourceName = $quotedSource AND sourceID = $quotedSourceID AND checksum = $checksum)";
      }
      else
      {
         $statementText = "UPDATE $tableName ".
           "SET LastEncountered = $localTime ".
           "WHERE (SaleOrRentalFlag = $saleOrRentalFlag AND sourceName = $quotedSource AND sourceID = $quotedSourceID)";
      }
      
      #print "addEncounterRecord: $statementText\n";
      $statement = $sqlClient->prepareStatement($statementText);
      
      if ($sqlClient->executeStatement($statement))
      {
         $success = 1;
      }
      #print "addEncounterRecord: finished\n";
   }
   
   return $success;   
}

# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------

my $SQL_CREATE_WORKINGVIEW_TABLE_BODY = 
   "DateEntered DATETIME NOT NULL, ".
   "LastEncountered DATETIME, ".
   "SaleOrRentalFlag INTEGER,".                   
   "SourceName TEXT, ".
   "SourceID VARCHAR(20), ".
#   "TitleString TEXT, ".  NOT USED IN WORKING VIEW
#   "Checksum INTEGER, ".  NOT USED IN WORKING VIEW
   "State VARCHAR(3), ".   
   "SuburbName TEXT, ".
   "SuburbIndex INTEGER, ". # REFERENCES AusPostCodes.SuburbIndex, "
   "Type VARCHAR(10), ".
   "TypeIndex INTEGER,".    #REFERENCES PropertyTypes.TypeIndex, ".   
   "Bedrooms INTEGER, ".
   "Bathrooms INTEGER, ".
   "LandAreaText TEXT, ".                    # renamed
   "LandArea DECIMAL(10,2), ".               # derived
   "BuildingAreaText TEXT, ".                # renamed
   "BuildingArea INTEGER, ".                 # derived
   "YearBuiltText VARCHAR(5), ".
   "YearBuilt INTEGER, ".                    # derived
   "AdvertisedPriceString TEXT, ".
   "AdvertisedPriceLower DECIMAL(10,2), ".   # derived
   "AdvertisedPriceUpper DECIMAL(10,2), ".   # derived
   "AdvertisedWeeklyRent DECIMAL(10,2), ".   # derived
   "StreetAddress TEXT, ".
   "UnitNumber TEXT, ".                      # derived
   "StreetNumber TEXT, ".                    # derived
   "StreetName TEXT, ".                      # derived
   "StreetType TEXT, ".                      # derived
   "StreetSection TEXT, ".                   # derived
   "Description TEXT, ".    
   "Features TEXT,".
   "OriginatingHTML INTEGER ZEROFILL, ".     # REFERENCES OriginatingHTML.Identifier,".         
   #"AgencySourceID TEXT, ".                  # not used in working view
   #"AgencyName TEXT, ".                      # not used in working view
   #"AgencyAddress TEXT, ".                   # not used in working view
   #"SalesPhone TEXT, ".                      # not used in working view
   #"RentalsPhone TEXT, ".                    # not used in working view
   #"Fax TEXT, ".                             # not used in working view
   "AgencyIndex INTEGER ZEROFILL, ".         # REFERENCES AgencyList.AgencyIndex, ".  # this is new
   #"ContactName TEXT, ".                     # not used in working view
   #"MobilePhone TEXT, ".                     # not used in working view 
   "AgencyContactIndex INTEGER ZEROFILL, ".   # REFERENCES ContactList.ContactIndex, ".  # this is new
   #"Website TEXT".                           # not used in working view
   "ErrorCode INTEGER, ".                    # error code - 0 is good, undef is not checked
   "WarningCode INTEGER, ".                  # warning code - 0 is none, undef is not checked
   "OverridenValidity INTEGER DEFAULT 0, ".   # overriddenValidity set by human
   "ComponentOf INTEGER ZEROFILL";            # REFERENCES MasterPropertyTable.Identifier (foreign key to master property table)

# -------------------------------------------------------------------------------------------------
# _createWorkingViewTable
# attempts to create the WorkingView_AdvertisedSaleProfiles table in the database if it doesn't already exist
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

sub _createWorkingViewTable

{
   my $this = shift;
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $tableName = $this->{'tableName'};

   my $SQL_CREATE_WORKINGVIEW_TABLE_PREFIX = "CREATE TABLE IF NOT EXISTS WorkingView_$tableName (Identifier INTEGER ZEROFILL PRIMARY KEY AUTO_INCREMENT, ";
   my $SQL_CREATE_WORKINGVIEW_TABLE_SUFFIX = ", INDEX (SaleOrRentalFlag, sourceName(5), sourceID(10)))";   # 23Jan05 - index!
   
   if ($sqlClient)
   {
      # append change table prefix, original table body and change table suffix
      $sqlStatement = $SQL_CREATE_WORKINGVIEW_TABLE_PREFIX.$SQL_CREATE_WORKINGVIEW_TABLE_BODY.$SQL_CREATE_WORKINGVIEW_TABLE_SUFFIX;
      
      $statement = $sqlClient->prepareStatement($sqlStatement);
      
      if ($sqlClient->executeStatement($statement))
      {
         $success = 1;
      }
   }
   
   return $success;   
}


# -------------------------------------------------------------------------------------------------
# _workingView_updateRecordWithChangeHash
# alters a record of data in the WorkingView_AdvertisedPropertyProfiles table 
# it accepts a changedHash
# it does not update the change table - this function is called AFTER changing the changeTable
# 
# Purpose:
#  Storing information in the database
#
# Parameters:
#  reference to a hash containing the values to insert (only those that have changed)
#  integer sourceIdentifier
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
sub _workingView_updateRecordWithChangeHash

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
      $appendString = "UPDATE WorkingView_$tableName SET ";
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
      
      $statementText = $appendString." WHERE identifier=$sourceIdentifier";
      $statement = $sqlClient->prepareStatement($statementText);
      
      if ($sqlClient->executeStatement($statement))
      {
         $success = 1;
      }
   }
   
   return $success;   
}

# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# _workingView_addOrChangeRecord
# adds a record of data to the WorkingView_AdvertisedPropertyProfiles table
# This function UPDATES the change table if the record's identifier already exists
# in the working view - otherwise it adds a new record

# 
# Purpose:
#  Storing information in the database
#
# Parameters:
#  integer Identifier - this is the identifier of the original record (foreign key)
#   (the rest of the fields are obtained automatically using select syntax)
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
sub _workingView_addOrChangeRecord

{
   my $this = shift;
   my $parametersRef = shift;
   
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $statementText;
   my $tableName = $this->{'tableName'};
   my $localTime;
   my $identifier = -1;
   my $added = 0;
   my $changed = 0;
   
   if ($sqlClient)
   {   
      if ($parametersRef)
      {
         # first, determine if this is a NEW record or modification to an EXISTING record
         
         # modify the existing record
         $quotedIdentifier = $sqlClient->quote($$parametersRef{'Identifier'});
         @selectResults = $sqlClient->doSQLSelect("select * from WorkingView_$tableName where Identifier=$quotedIdentifier");
         
         # zero or one results returned - if one exists, it needs to be modified...
         $existingProfile = $selectResults[0];
         if ($existingProfile)
         {
            # a profile for this record already exists
            # calculate a difference hash...
            $profileChanged = 0;
            my %changedProfile;
            foreach (keys %$existingProfile)
            {
               if ($$existingProfile{$_})
               {
                  if ($$existingProfile{$_} == $$parametersRef{$_})
                  {
                     # note == is used instead of equals so that identical integers are detected
                     # eg. 584 == 00000584
                     # this field is identical
                  }
                  else
                  {
                     # a change occured
                     $changedProfile{$_} = $$parametersRef{$_};
                     $profileChanged = 1;
                  }
               }
               else
               {
                  if ($$parametersRef{$_})
                  {
                     # a change occured
                     $changedProfile{$_} = $$parametersRef{$_};
                     $profileChanged = 1;
                  }
               }
            }
            
            if ($profileChanged)
            {
               # add the changedProfile to the change table and modify the WorkingView table
               $success = $this->changeRecord(\%changedProfile, $$parametersRef{'Identifier'}, "auto");
               if ($success)
               {
                  $identifer = $$parametersRef{'Identifier'};
                  $changed = 1;
               }
            }
            else
            {
               # this change is identical to the last change - it achieves nothing
               $identifer = $$parametersRef{'Identifier'};
            }
         }
         else
         {
            # add a new record ot the table
            $statementText = "INSERT INTO WorkingView_$tableName (";
         
            @columnNames = keys %$parametersRef;
            
            # modify the statement to specify each column value to set 
            $appendString = "";
            $index = 0;
            foreach (@columnNames)
            {
               if ($index != 0)
               {
                  $appendString = $appendString.", ";
               }
              
               $appendString = $appendString . $_;
               $index++;
            }      
            
            $statementText = $statementText.$appendString . ") VALUES (";
            
            # modify the statement to specify each column value to set 
            $appendString = "";
            $index = 0;
            foreach (@columnNames)
            {
               if ($index != 0)
               {
                  $appendString = $appendString.", ";
               }
              
               $appendString = $appendString.$sqlClient->quote($$parametersRef{$_});
               
               $index++;
            }
            $statementText = $statementText.$appendString . ")";
                     
            $statement = $sqlClient->prepareStatement($statementText);
            
            if ($sqlClient->executeStatement($statement))
            {
               $identifer = $sqlClient->lastInsertID();
               $added = 1;
            }
         }
      }
   }
   
   return ($identifier, $changed, $added);   
}

# -------------------------------------------------------------------------------------------------
# workingView_setSpecialField
# updates a record of data in the WorkingView directly bypassing the changeTable.  Use only
# for fields that don't appear in the change table at all (such as validityCode)
# 
# Purpose:
#  Storing information in the database
#
# Parameters:
#  integer sourceIdentifier
#  string fieldName
#  string fieldValue
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
sub workingView_setSpecialField

{
   my $this = shift;
   my $sourceIdentifier = shift;
   my $fieldName = shift;
   my $fieldValue = shift;
   my %specialHash;
   
   $specialHash{$fieldName} = $fieldValue;
   
   $this->_workingView_changeRecord(\%specialHash, $sourceIdentifier);
}

# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# _createChangeTable
# attempts to create the advertisedxProfiles table in the database if it doesn't already exist
# 21 June 2005 - the changeTable is based on the workingView format, not the sourceView
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

sub _createChangeTable

{
   my $this = shift;
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $tableName = $this->{'tableName'};
 
   my $SQL_CREATE_CHANGE_TABLE_PREFIX = "CREATE TABLE IF NOT EXISTS ChangeTable_$tableName (ChangeIndex INTEGER ZEROFILL PRIMARY KEY AUTO_INCREMENT, ";
   my $SQL_CREATE_CHANGE_TABLE_SUFFIX = ", ".
      "Identifier INTEGER ZEROFILL,". #REFERENCES $tableName(identifier), ".  # foreign key
      "ChangedBy TEXT,".                         # who/what changed it
      "INDEX (SaleOrRentalFlag, sourceName(5), sourceID(10)), INDEX (Identifier))";    # 23Jan05 - index!
      
   if ($sqlClient)
   {
      # append change table prefix, original table body and change table suffix
      $sqlStatement = $SQL_CREATE_CHANGE_TABLE_PREFIX.$SQL_CREATE_WORKINGVIEW_TABLE_BODY.$SQL_CREATE_CHANGE_TABLE_SUFFIX;
      
      $statement = $sqlClient->prepareStatement($sqlStatement);
      
      if ($sqlClient->executeStatement($statement))
      {
         $success = 1;
      }
   }
   
   return $success;   
}


# -------------------------------------------------------------------------------------------------
# changeRecord
# alters a record of data in the WorkingView_AdvertisedPropertiesProfiles table and records the changed
#  data transaction.   Note ONLY the WORKING VIEW and CHANGE TABLE is updated, not the source table 
# 
# Purpose:
#  Storing information in the database
#
# Parameters:
#  reference to a hash containing the CHANGED values to insert
#  integer sourceIdentifier
#  string ChangedBy
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
sub changeRecord

{
   my $this = shift;
   my $parametersRef = shift;
   my $sourceIdentifier = shift;
   my $changedBy = shift;
   
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $statementText;
   my $localTime;
   my $tableName = $this->{'tableName'};
   
   if ($sqlClient)
   {
      # --- get the last change record for this identifier to ensure this isn't an accidental duplicate ---
      
      $statementText = "SELECT DateEntered, ";
      # note DateEntered isn't used but is obtained for information - confirm it was infact the last entry that
      # was matched (only used in debugging)
      @columnNames = keys %$parametersRef;
      
      $appendString ="";
      $index = 0;
      foreach (@columnNames)
      {
         if ($index != 0)
         {
            $appendString = $appendString.", ";
         }
        
         $appendString = $appendString . $_;
         $index++;
      }      
      
      $statementText = $statementText.$appendString . " FROM ChangeTable_$tableName WHERE "; 
      
      # modify the statement to specify each column value to set 
      @columnValues = values %$parametersRef;
      $index = 0;
      
      $appendString = "Identifier = $sourceIdentifier AND ";
      while(($field, $value) = each(%$parametersRef)) 
      {
         if ($index != 0)
         {
            $appendString = $appendString." AND ";
         }
        
         $appendString = $appendString."$field = ".$sqlClient->quote($value);
         $index++;
      }
      # order by reverse data limit 1 to get the last entry
      $statementText = $statementText.$appendString;

      @selectResults = $sqlClient->doSQLSelect($statementText);
      $noOfResults = @selectResults;
      if ($noOfResults > 0)
      {
         # that record already exists as the last entry in the table!!!
         #print "That change already exists as the last entry (MATCHED=$noOfResults)\n";
         $success = 0;
      }
      else
      {
         # ------------------------------------
         # --- insert the new change record ---
         # ------------------------------------
         $statementText = "INSERT INTO ChangeTable_$tableName (";
         
         @columnNames = keys %$parametersRef;
         
         # modify the statement to specify each column value to set 
         $appendString = "DateEntered, ChangeIndex, Identifier, ChangedBy, ";
         $index = 0;
         foreach (@columnNames)
         {
            if ($index != 0)
            {
               $appendString = $appendString.", ";
            }
           
            $appendString = $appendString . $_;
            $index++;
         }      
         
         $statementText = $statementText.$appendString . ") VALUES (";
         
         # modify the statement to specify each column value to set 
         @columnValues = values %$parametersRef;
         $index = 0;
         $quotedIdentifier = $sqlClient->quote($sourceIdentifier);
         $quotedChangedBy = $sqlClient->quote($changedBy);
   
         if (!$this->{'useDifferentTime'})
         {
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
         
         $appendString = "$localTime, null, $quotedIdentifier, $quotedChangedBy, ";
         foreach (@columnValues)
         {
            if ($index != 0)
            {
               $appendString = $appendString.", ";
            }
           
            $appendString = $appendString.$sqlClient->quote($_);
            $index++;
         }
         $statementText = $statementText.$appendString . ")";
         
         #print "statement = ", $statementText, "\n";
         
         $statement = $sqlClient->prepareStatement($statementText);
         
         if ($sqlClient->executeStatement($statement))
         {
            $success = 1;
            
            # --- now update the working view ---
            $this->_workingView_updateRecordWithChangeHash($parametersRef, $sourceIdentifier); 
         }
      }
   }
   
   return $success;   
}


# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# lookupRegExPatterns
# Looks up a set of patterns that are used for regular expression substitutions for repairing
# various fields
# NOTE: the patterns are deliberately not cached so the patterns can be changed at run-time
#
# Parameters:
#  nil
#
# Updates:
#  regExPatterns
#
# Returns:
#   reference to a list of hashes containing substitution information
#    
sub lookupRegExPatterns
{
   my $this = shift;
   
   my $sqlClient = $this->{'sqlClient'};

   # load the table of validator substitutions defined in the database
   $regExPatterns = RegExPatterns::new($sqlClient);
   
   $regExResults = $regExPatterns->lookupPatterns();
   
   return $regExResults;
}


# -------------------------------------------------------------------------------------------------

# searches the postcode list for a suburb matching the name specified
sub matchSuburbName
{   
   my $this = shift;
   my $suburbName = shift;
   my $state = shift;
   my %matchedSuburb;
   my $sqlClient = $this->{'sqlClient'};
   
   if (($sqlClient) && ($suburbName))
   {       
      $quotedSuburbName = $sqlClient->quote($suburbName);
      $quotedState = $sqlClient->quote($state);
      $statementText = "SELECT locality, postcode, SuburbIndex FROM AusPostCodes WHERE locality like $quotedSuburbName and state like $quotedState order by postcode limit 1";
            
      @suburbList = $sqlClient->doSQLSelect($statementText);
      
      if ($suburbList[0])
      {
         $matchedSuburb{'SuburbName'} = $suburbList[0]{'locality'};
         $matchedSuburb{'postcode'} = $suburbList[0]{'postcode'};              
         $matchedSuburb{'SuburbIndex'} = $suburbList[0]{'SuburbIndex'};
      }                    
   }   
   return %matchedSuburb;
}  

# -------------------------------------------------------------------------------------------------
      
# repairSuburbName
# applies patterns to extact the correct suburbname from the parameter and lookup matched suburbIndex
#
# Purpose:
#  validation of the repositories
#
# Parameters:
#  reference to profile
#  reference to regEx substititions hash
#
# Returns:
#  list containing validated suburbname and suburb index
#    
sub repairSuburbName

{
   my $this = shift;
   my $profileRef = shift;
   my $regExSubstitutionsRef = $this->lookupRegExPatterns();
    
   my $suburbName = $$profileRef{'SuburbName'};
   
   #print "suburbName='$suburbName'";

   foreach (@$regExSubstitutionsRef)
   {
      if ($$_{'FieldName'} =~ /SuburbName/i)
      {
         $regEx = $$_{'RegEx'};
         $substitute = $$_{'Substitute'};
                  #print "regEx='$regEx', substitute='$substitute'\n";
   
         $suburbName =~ s/$regEx/$substitute/egi;
      }
   }
   
   # try to remove non-alpha characters (- and ' and whitespace are allowed)
   $suburbName =~ s/[^(\w|\-|\'|\s)]/ /gi;
   
   $suburbName = prettyPrint($suburbName, 1);
   
   if ($suburbName ne $$profileRef{'SuburbName'})
   {
      
      # match the suburb name to a recognised suburb name
      %matchedSuburb = $this->matchSuburbName($suburbName, $$profileRef{'State'});
        
      if (%matchedSuburb)
      {
         $changedSuburbName = prettyPrint($matchedSuburb{'SuburbName'}, 1);    # change the name
         $changedSuburbIndex = $matchedSuburb{'SuburbIndex'};
         #print "   NEW suburbIndex=", $changedProfile{'SuburbIndex'}, "\n";
         $fixedSuburbs++;
         $matched = 1;
         #print "BadSuburbs=$badSuburbs FixedSuburbs = $fixedSuburbs\n";
      }
   }
   
   if (!$matched)
   {
      # still haven't matched the suburb name - try searching for a close match on the assumption the suburbname is followed by crud
      @wordList = split(/ /, $suburbName);
      $noOfWords = @wordList;
      $currentWord = $noOfWords;
      $matched = 0;
      # loop through the series of words (from last to first)
      while ((!$matched) && ($currentWord > 0))
      {
         # concatenate the words of the string up to the current index
         $currentString = "";
         for ($index = 0; $index < $currentWord; $index++)
         {
            if ($index > 0)
            {
               $currentString .= " ";
            }  
            $currentString .= $wordList[$index];
         }
         
         # match the suburb name to a recognised suburb name
         
         %matchedSuburb = $this->matchSuburbName($currentString, $$profileRef{'State'});
     
         if (%matchedSuburb)
         {
            $changedSuburbName = prettyPrint($matchedSuburb{'SuburbName'}, 1);    # change the name
            $changedSuburbIndex = $matchedSuburb{'SuburbIndex'};
            #print "   OLD=", $$profileRef{'SuburbName'}, " NEW suburbName='", $changedProfile{'SuburbName'}, "'    NEW suburbIndex=", $changedProfile{'SuburbIndex'}, "\n";
            $matched = 1;
            $fixedSuburbs++;
         }
         else
         {
            # go back a word and try the series again
            $currentWord--;
         }
      }
   }
   
   if (!$matched)
   {
      #print "   OLD=", $$profileRef{'SuburbName'}, " NEW suburbName='$suburbName' STILL INVALID SUBURBNAME - UNCHANGED\n";
      
      
      # still haven't matched the suburb name - try searching for a close match on the assumption the suburbname is SOMEWHERE 
      # in the string
      @wordList = split(/ /, $suburbName);
      $noOfWords = @wordList;
      $currentWord = 0;
      $matched = 0;
      # loop through the series of words (from left to right)
      while ((!$matched) && ($currentWord < $noOfWords))
      {
         # match the suburb name to a recognised suburb name
         %matchedSuburb = $this->matchSuburbName($_, $$profileRef{'State'});
     
         if (%matchedSuburb)
         {
            $changedSuburbName = prettyPrint($matchedSuburb{'SuburbName'}, 1);    # change the name
            $changedSuburbIndex = $matchedSuburb{'SuburbIndex'};

            $matched = 1;
            $fixedSuburbs++;
            #print "   OLD=", $$profileRef{'SuburbName'}, " NEW suburbName='", $changedProfile{'SuburbName'}, "'    NEW suburbIndex=", $changedProfile{'SuburbIndex'}, "\n";
         }
         else
         {
            # try the next word in the list
            $currentWord++;
         }
      }      
   }
   if (!$matched)
   {
      #print "   OLD=", $$profileRef{'SuburbName'}, " NEW suburbName='", $suburbName, "' FAILED\n";
   }
   
   return ($changedSuburbName, $changedSuburbIndex);
}

# -------------------------------------------------------------------------------------------------

# repairTypeName
# applies patterns to extract the correct type from the parameter and lookup matched typeIndex
#
# Purpose:
#  validation of the repositories
#
# Parameters:
#  reference to profile
#  reference to regEx substititions hash
#
# Returns:
#  list containing validated suburbname and suburb index
#    
sub repairTypeName

{
   my $this = shift;
   my $profileRef = shift;
   my $regExSubstitutionsRef = $this->lookupRegExPatterns();
  
   my $typeName = $$profileRef{'Type'};
   
   my $propertyTypes = PropertyTypes::new();
   
   # apply the pre-defined regular expressions to the type
   
   foreach (@$regExSubstitutionsRef)
   {
      if ($$_{'FieldName'} =~ /Type/i)
      {
         $regEx = $$_{'RegEx'};
         $substitute = $$_{'Substitute'};
   
         $typeName =~ s/$regEx/$substitute/egi;
      }
   }
   
   # try to remove non-alpha characters
   $typeName =~ s/[\W]//gi;
   
   $typeName = prettyPrint($typeName, 1);
   
   $typeIndex = $propertyTypes->mapPropertyType($typeName);
   
   return ($typeName, $typeIndex);
}

# -------------------------------------------------------------------------------------------------   
# repairLandArea
# attempt to convert the land area string into a decimal value (in square meters)
#
# Purpose:
#  validation of the repositories
#
# Parameters:
#  reference to profile
#  reference to regEx substititions hash
#
# Returns:
#  DECIMAL land area
#    
sub repairLandArea
{
   my $this = shift;
   my $landAreaText = shift;
   my $landArea = undef;
   
   if ($landAreaText)
   {
      # look for patterns like 570.00 sqm, 570.00m2, 570.00 square meters, 570.00 sq.m, 570.00 square m*, 570.00 sq meters, 570.00 sq *
      if (($landAreaText =~ /(.*)sqm/i) || ($landAreaText =~ /(.*)m2/i) || ($landAreaText =~ /(.*)sq\.m/i) || ($landAreaText =~ /(.*)square\sm/i) || ($landAreaText =~ /(.*)sq\sm/i))
      {
         $landArea = $1;
         # landArea now should contain a number
         $landArea = trimWhitespace($landArea);
         $landArea = parseNumberSomewhereInString($landArea);
      }
      # look for a value in squares (sqs, squares, or just sq at the end or sq's) 
      elsif (($landAreaText =~ /(.*)sqs/i) || ($landAreaText =~ /(.*)squares/i) || ($landAreaText =~ /(.*)sq$/i) || ($landAreaText =~ /(.*)sq\'s/i))
      {
         # value is in squares - convert it
         $landArea = $1;
         # landArea now should contain a number
         $landArea = trimWhitespace($landArea);
         $landArea = parseNumberSomewhereInString($landArea);
         
         # convert landArea from squares to square meters
      }
      # look for a value in acres
      elsif (($landAreaText =~ /(.*)acres/i))
      {
         # value is in squares - convert it
         $landArea = $1;
         # landArea now should contain a number
         $landArea = trimWhitespace($landArea);
         $landArea = parseNumberSomewhereInString($landArea);
         
         # convert landArea from acres to square meters
      }
      # look for a value in hectares (hectares or H or Ha at the end)
      elsif (($landAreaText =~ /(.*)hectares/i) || ($landAreaText =~ /(.*)H$/i) || ($landAreaText =~ /(.*)Ha$/i)) 
      {
         # value is in squares - convert it
         $landArea = $1;
         # landArea now should contain a number
         $landArea = trimWhitespace($landArea);
         $landArea = parseNumberSomewhereInString($landArea);
         
         # convert landArea from hectares to square meters
      }
      # getting desparate - does it contain the word metres? or metres
      elsif (($landAreaText =~ /(.*)metres/i) || ($landAreaText =~ /(.*)meters/i))
      {
         $landArea = $1;
         # landArea now should contain a number
         $landArea = trimWhitespace($landArea);
         $landArea = parseNumberSomewhereInString($landArea);
      }
      else
      {
         # couldn't convert it!
      }
   }
   return $landArea;
}


# -------------------------------------------------------------------------------------------------   
# repairYearBuilt
# attempt to convert the year built into an integer
#
# Purpose:
#  validation of the repositories
#
# Parameters:
#  reference to profile
#  reference to regEx substititions hash
#
# Returns:
#  INTEGER land area
#    
sub repairYearBuilt
{
   my $this = shift;
   my $yearBuiltText = shift;
   my $yearBuilt = undef;
   
   if ($yearBuiltText)
   {
      $yearBuilt = parseNumberSomewhereInText($yearBuiltText);
   }
   return $yearBuilt;
}

# -------------------------------------------------------------------------------------------------   
# repairAdvertisedPrice
# attempt to convert the advertised price string into decimal values for lower and upper price
#
# Purpose:
#  validation of the repositories
#
# Parameters:
#  STRING advertisedPriceString
#  BOOL SaleOrRentalFlag
#
# Returns:
#  LIST (lowerPrice, upperPrice, weeklyRent)
#    
sub repairAdvertisedPrice
{
   my $this = shift;
   my $advertisedPriceString = shift;
   my $saleOrRentalFlag = shift;
   my $regExSubstitutionsRef = $this->lookupRegExPatterns();
   my $advertisedPriceLower = undef;
   my $advertisedPriceUpper = undef;
   my $advertisedWeeklyRent = undef;
   
   if ($advertisedPriceString)
   {
#      print "INPUT : $advertisedPriceString\n";
 
      # loop through the regular expressions defined for the AdvertisedPriceString
      foreach (@$regExSubstitutionsRef)
      {
         if ($$_{'FieldName'} =~ /AdvertisedPriceString/i)
         {
            $regEx = $$_{'RegEx'};
            
            if (defined $$_{'Substitute'})
            {
               # run the substitution
               $advertisedPriceString =~ s/$regEx/$substitute/egi;

            }
            else
            {
               if ($advertisedPriceString =~ /$regEx/)
               {
                  $f[1] = $1;
                  $f[2] = $2;
                  $f[3] = $3;
                  $f[4] = $4;
                  $f[5] = $5;

                  $aplIndex = $$_{'APLIndex'};
                  $apuIndex = $$_{'APUIndex'};
                  $awrIndex = $$_{'AWRIndex'};
                  $flag = $$_{'Flag'};

                  if ($saleOrRentalFlag == 0)
                  {
                     if ($aplIndex)
                     {
                        $advertisedPriceLower = strictNumber($f[$aplIndex]);
                     }
                     if ($apuIndex)
                     {
                        $advertisedPriceUpper = strictNumber($f[$apuIndex]);
                     }
                     
                     if ($flag)
                     {
                        if ($flag == 1)  # APU = APL + 20%
                        {
                           $advertisedPriceUpper = $advertisedPriceLower * 1.2;
                        }
                     }
                  }
                  else
                  {
                     # rental flag
                     if ($awrIndex)
                     {
                        $advertisedWeeklyRent = strictNumber($f[$awrIndex]);
                        
                        # SCALING - if the rent is VERY LARGE it is probably an annual value
                        if ($advertisedWeeklyRent > 10000)
                        {
                           # probably an annual figure
                           $advertisedWeeklyRent = $advertisedWeeklyRent / 52;
                        }
                        # SCALING - probably a monthly figure
                        elsif ($advertiedWeeklyRent > 2000)
                        {
                           # probably an annual figure
                           $advertisedWeeklyRent = $advertisedWeeklyRent * 12 / 52;
                        }
                        
                     }
                  }
                  
                  if (($advertisedPriceLower) || ($advertisedPriceUpper) || ($advertisedWeeklyRent))
                  {
                     last;  # finished processing
                  }
               }
            }
         }
      }
      # print "OUTPUT: ($advertisedPriceLower, $advertisedPriceUpper, $advertisedWeeklyRent)\n";
   }
   return ($advertisedPriceLower, $advertisedPriceUpper, $advertisedWeeklyRent);
}

# -------------------------------------------------------------------------------------------------   
# -------------------------------------------------------------------------------------------------   
# repairStreetAddress
# attempt to convert the street address string into its components
#
# Purpose:
#  validation of the repositories
#
# Parameters:
#  STRING streetAddress
#
# Returns:
#  LIST of Strings (unitNumber, streetNumber, streetName, streetType, streetSection)
#    
sub repairStreetAddress
{
   my $this = shift;
   my $addressString = shift;
   my $suburbName = shift;
   my $unitNumber = undef;
   my $streetNumber = undef;
   my $streetName = undef;
   my $streetType = undef;
   my $streetSection = undef;
   my $regExSubstitutionsRef = $this->lookupRegExPatterns();
   
   if ($addressString)
   {
      # PASS 0: Make sure the addressString doesn't contain the suburb name at the end
      if ($addressString =~ /$suburbName$/gi)
      {
         $addressString =~ s/$suburbName$//gi;
         $addressString = trimWhitespace($addressString);
      }
      
      # PASS 1: apply substitutions
      # loop through the regular expressions defined for the AddressString
      foreach (@$regExSubstitutionsRef)
      {
         if ($$_{'FieldName'} =~ /AddressString/i)
         {
            $regEx = $$_{'RegEx'};
            
            if (defined $$_{'Substitute'})
            {
               # run the substitution
               $addressString =~ s/$regEx/$substitute/egi;

            }
         }
      }
      
      #print "   PASS1: addressString='$addressString'...\n";

      
      # PASS 2: separate the street number from the street name
      
      # if the street name contains any numbers, grab a copy of that subset of the street name - it may be
      # possible to transfer it into the street number instead
      
      if ($addressString =~ /\d/g)
      {
       #  print "Extracting Numbers from AddressString ('$addressString')...\n";
   
         # extract numbers  - breakup word by word until the first number, get everything until the last number
         
         $prefix = "";
         $suffix = "";
         @wordList = split(/ /, $addressString);   # parse one word at a time (words are used as a valid number can include letters. eg. "21a / 14-24"
   
         $index = 0;
         $lastNumeralIndex = -1;
         $firstNumeralIndex = -1;
         $length = @wordList;
         $state = 0;  # searching for first number
         foreach (@wordList)
         {
            if ($_)
            {
               # if this word contains a numeral
               if ($_ =~ /\d/g)
               {
                  if ($state == 0)
                  {
                     # this is the first part of the number
                     $firstNumeralIndex = $index;
                     $lastNumeralIndex = $index;
                     $state = 1;  # searching for last number
                  }
                  else
                  {
                     if ($state == 1)
                     {
                        # this is another part of the number - append it
                        $lastNumeralIndex = $index;
                     }
                  }
               }
               else
               {
                  # this word doesn't contain a numeral - keep searching right though
               }
            }
            $index++;
         }
         
         $streetNumber = undef;
         # at this point first and lastNumeralIndex specify the range of valid number data
         # if lastNumeralIndex is set then the street number can be split from the street name
         if ($lastNumeralIndex >= 0)
         {
            $streetNumber = "";
            # transfer all the words in the number section to the streetNumber
            for ($index = 0; $index <= $lastNumeralIndex; $index++)
            {
               $streetNumber .= $wordList[$index]." ";
            }
            
            $streetName = "";
            # the remainder of words are transferred to the streetName
            for ($index = $lastNumeralIndex+1; $index < $length; $index++)
            {
               $streetName .= $wordList[$index]." ";
            }
         }
         else
         {
            # no street number encountered - keep allocated entirely to street name
            $streetNumber = undef;
         }
         
         $streetNumber = trimWhitespace($streetNumber);
         $streetName = trimWhitespace($streetName);
         #print "   PASS2: unitNumber='$unitNumber' streetNumber='$streetNumber' streetName='$streetName'  streetType='$streetType'...\n";
      }
      else
      {
         # no street number 
         $streetName = $addressString;
      }
      
      # remove anything after a comma
      if ($streetName =~ /\,/g)
      {
         #print "Removing post-comma text from street name ('$streetName', '$streetNumber')...\n";
   
         ($firstHalf, $rest) = split(/\,/, $streetName, 2);
         if ($firstHalf)
         {
            $streetName = $firstHalf;
         }
         #print "   PASS3: unitNumber='$unitNumber' streetNumber='$streetNumber' streetName='$streetName'  streetType='$streetType'...\n";
      }
      
      if ($streetNumber)
      {
         # --- split the streetNumber into unitNumber and street number ---
         
         # this processing is done with regular expressions
         # loop through the regular expressions defined for the AddressString
         foreach (@$regExSubstitutionsRef)
         {
            if ($$_{'FieldName'} =~ /StreetNumber/i)
            {
               $regEx = $$_{'RegEx'};
               if ($streetNumber =~ /$regEx/)
               {
                  $f[1] = $1;
                  $f[2] = $2;
                  $f[3] = $3;
                  $f[4] = $4;
                  $f[5] = $5;
   
                  $unitIndex = $$_{'APLIndex'};
                  $streetIndex = $$_{'APUIndex'};
                  $flag = $$_{'Flag'};
   
                  if ($unitIndex)
                  {
                     $unitNumber = trimWhitespace($f[$unitIndex]);
                  }
                  
                  if ($streetIndex)
                  {
                     $streetNumber = trimWhitespace($f[$streetIndex]);
                  }    
                  
                  last;
               }
            }
         }
         #print "   PASS5: unitNumber='$unitNumber' streetNumber='$streetNumber' streetName='$streetName' streetType='$streetType'...\n";
      }
     
      # try to remove LEADING non alpha characters from the street number
      if ($streetNumber)
      {
         # replace leading non alpha-numeric characters (eg.  encounters may be , - )
         $streetNumber =~ s/^(\W*)//gi;
      }
      
      #$streetNumber = prettyPrint($streetNumber, 1);
      #$streetName = prettyPrint($streetName, 1);
       
      if ($streetName)
      {
         # Special - if the street name ends on a section (North/South/East/West) then 
         # extract it now
         if ($streetName =~ /(East|West|North|South)$/gi)
         {
            # special - if there's any text after the street type this may indicate a
            # section.  eg. Road East
            $streetSection = trimWhitespace($1);
            # remove the section from the street name before further processing
            $streetName =~ s/$streetSection$//gi;
            $streetName = trimWhitespace($streetName);
         }
         
          # if the streetname contains numbers it's still invalid
         if ($streetName =~ /\d/g)
         {
            #print "Removing numbers from street name ('$streetName', '$streetNumber')...\n";
      
            $streetName =~ s/\d/ /g;
            #print "   StreetName='$streetName'\n";
         }
      
         # try to remove non-alpha characters (- and ' and whitespace are allowed) from street name
         $streetName =~ s/[^(\w|\-|\'|\s)]/ /gi;
      
         # the purpose of this iteration is to allow the regular expressions to be applied multiple
         # times if a match continues to fail, each time trying variations of the street name
         # see below for more details
         # iterationComplete is set when a StreetType is defined (which INCLUDE a special blank street type)
         $candidateStreetName = $streetName;
         $candidateStreetType = $streetType;
         $iterationComplete = 0;
         while (!$iterationComplete)
         {
            # apply regular expression substitions to the street name (now that the string has been repaired)
            foreach (@$regExSubstitutionsRef)
            {
               if ($$_{'FieldName'} =~ /StreetName/i)
               {
                  $regEx = $$_{'RegEx'};
                  
                  if (defined $$_{'Substitute'})
                  {
                     # run the substitution
                     $candidateStreetName =~ s/$regEx/$substitute/egi;
                  }
               }
            }
            
            # attempt to split the street name into its name, type and section components
            
            # apply regular expression substitions to the street name (now that the string has been repaired)
            foreach (@$regExSubstitutionsRef)
            {
               if ($$_{'FieldName'} =~ /StreetName/i)
               {
                  $regEx = $$_{'RegEx'};
                  
                  if ($candidateStreetName =~ /$regEx/)
                  {
                     $f[1] = $1;
                     $f[2] = $2;
                     $f[3] = $3;
                     $f[4] = $4;
                     $f[5] = $5;
      
                     $streetNameIndex = $$_{'APLIndex'};
                     $streetTypeIndex = $$_{'APUIndex'};
                     $flag = $$_{'Flag'};
      
                     if (!$flag)
                     {
                        if ($streetNameIndex)
                        {
                           $streetName = trimWhitespace($f[$streetNameIndex]);
                        }
                        
                        if ($streetTypeIndex)
                        {
                           $streetType = trimWhitespace($f[$streetTypeIndex]);
                        }
                     }
                     else
                     {
                        # street is the complete string - there is no applicable street type (but it's also not null)
                        # eg. The Avenue, The Esplanade, The Rise 
                        $streetType = "";
                     }
                     
                     # processing is finished - a regular expression has been matched
                     $iterationComplete = 1;
                     last;
                  }
               }
            }
         
            # exception handling - if the streetname wasn't set, then maybe the address accidentaly includes 
            # other text after the street type.  This is a little brutal, but worth the experiment - delete the
            # last word and retry the regular expressions
            if (!$iterationComplete)
            {
               @words = split(/\s/, $candidateStreetName);
               $noOfWords = @words;
               if ($noOfWords > 1)
               {
                  # remove the last word from the candidateStreetName and redo the iteration to see
                  # if the regular expressions apply
                  $lastWord = $words[$noOfWords-1];
                  $candidateStreetName =~ s/$lastWord$//g;
                  $candidateStreetName = trimWhitespace($candidateStreetName);
               }
               else
               {
                  # no words left to drop off - fail
                  $iterationComplete = 1;
               }
            }
         }
      }
      
      #$streetNumber = prettyPrint($streetNumber, 1);
      #$streetName = prettyPrint($streetName, 1);
       
      if ($unitNumber)
      {      
         # apply regular expression substitions to the unit number (now that the string has been repaired)
         foreach (@$regExSubstitutionsRef)
         {
            if ($$_{'FieldName'} =~ /UnitNumber/i)
            {
               $regEx = $$_{'RegEx'};
               
               if (defined $$_{'Substitute'})
               {
                  # run the substitution
                  $streetName =~ s/$regEx/$substitute/egi;
               }
            }
         }
         
         # apply regular expression substitions to the unit number (now that the string has been repaired)
         foreach (@$regExSubstitutionsRef)
         {
            if ($$_{'FieldName'} =~ /UnitNumber/i)
            {
               $regEx = $$_{'RegEx'};
               
               if ($unitNumber =~ /$regEx/)
               {
                  $f[1] = $1;
                  $f[2] = $2;
                  $f[3] = $3;
                  $f[4] = $4;
                  $f[5] = $5;
   
                  $unitNumberIndex = $$_{'APLIndex'};
                  $flag = $$_{'Flag'};
   
                  if ($unitNumberIndex)
                  {
                     $unitNumber = trimWhitespace($f[$unitNumberIndex]);
                  }
                 
                  last;
               }
            }
         }
         #print "   PASS6: unitNumber='$unitNumber' streetNumber='$streetNumber' streetName='$streetName' streetType='$streetType'...\n";
      }
      #print "   END : unitNumber='$unitNumber' streetNumber='$streetNumber' streetName='$streetName' streetType='$streetType' streetSection='$streetSection'.\n";
      
      # if the street type isn't set, then this could be a bad address
      # if there's also no unit number or street number, it's definitely a bad address
      # all other combinations are accepted - exept they may generate warnings.
      # (although no streetName is always a failure and all fields are cleared)
      if (((!defined $streetType) && ((!defined $unitNumber) && (!defined $streetNumber))) || (!defined $streetName))
      {
         $streetName = undef;
         $unitNumber = undef;
         $streetNumber = undef;
         $streetSection = undef;
      }
   }
   
   return ($unitNumber, $streetNumber, $streetName, $streetType, $streetSection);  
}

# -------------------------------------------------------------------------------------------------   
# assessRecordValidity
# attempts to determine if the record is valid and returns a status flag indicating validity
# a value of 0 indicates it's valid, anything greater than 1 indicates invalidity (bin encoding)
# a value of 1 implies it hasn't been validated.
#
# Purpose:
#  validation of the repositories
#
# Parameters:
#  reference to profile
#
# Returns:
#  boolean
#    
sub assessRecordValidity

{
   my $this = shift;
   my $profileRef = shift;
   
   # calculate the error code
   # Error Codes
   #  0: this is a good record
   #  1: suburb is not recognised (suburbIndex is null
   #  2: streetname is not set
   #  4: streetnumber and unitnumber not set
   #  8: streetType is not set
   # 16: price is not set (lower or weekly rent)
   $errorCode = 0;
 
   if (!$$profileRef{'SuburbIndex'})
   {
      $errorCode |= 1;
   }
   
   if (!$$profileRef{'StreetName'})
   {
      $errorCode |= 2;
   }
   
   if ((!$$profileRef{'UnitNumber'}) && (!$$profileRef{'StreetNumber'}))
   {
      $errorCode |= 4;
   }
   
   if (!$$profileRef{'StreetType'})
   {
      $errorCode |= 8;
   }
   
   if ((($$profileRef{'SaleOrRentalFlag'} == 0) && (!$$profileRef{'AdvertisedPriceLower'})) ||
       (($$profileRef{'SaleOrRentalFlag'} == 1) && (!$$profileRef{'AdvertisedWeeklRent'})))
   {
      $errorCode |= 16;
   }
   
   # Warning Codes
   #  1: typeIndex is unknown
   #  2: streetNumber is not set (but unit number is)
   $warningCode = 0;

   if (!$$profileRef{'TypeIndex'})
   {
      $warningCode |= 1;
   }
   
   if (($$profileRef{'UnitNumber'}) && (!$$profileRef{'StreetNumber'}))
   {
      $warningCode |= 2;
   }
   
   return ($errorCode, $warningCode);
}


# -------------------------------------------------------------------------------------------------
# mergeChanges
# merges the changes in the changedProfileHash into the original hash
#
# Purpose:
#  construction of the repositories
#
# Parameters:
#  changedProfileRef
#  originalProfileRef

# Updates:
#  database
#
# Returns:
#  validated sale profile
#    
sub mergeChanges
{
   my $changedProfileRef = shift;
   my $originalProfileRef = shift;
   
   %mergedProfile = %$originalProfileRef;
   
   while (($key, $value) =each(%$changedProfileRef))
   {
      # apply the change
      $mergedProfile{$key} = $value;
   }
   
   return %mergedProfile;
}

# -------------------------------------------------------------------------------------------------
# transferToWorkingView
# validates the fields in the property advertisement and generates a workingView record
#
# OPERATES ON THE SOURCE DATA
#
# Purpose:
#  construction of the repositories
#
# Parameters:
#  HASHREF advertisedPropertyProfile

# Updates:
#  database
#
# Returns:
#  validated WorkingView profile
#    
sub transferToWorkingView
{
   my $this = shift;
   my $profileRef = shift;
   my $changed = 0;
   my $success = 0;

   my %newProfile;
   my %contactProfile;
   my %agencyProfile;
   
   my $sqlClient = $this->{'sqlClient'};
      
   # first - transfer the simple constant fields
   $newProfile{'Identifier'} = $$profileRef{'Identifier'};
   $newProfile{'DateEntered'} = $$profileRef{'DateEntered'};
   $newProfile{'LastEncountered'} = $$profileRef{'LastEncountered'};
   $newProfile{'SaleOrRentalFlag'} = $$profileRef{'SaleOrRentalFlag'};
   $newProfile{'SourceName'} = $$profileRef{'SourceName'};
   $newProfile{'SourceID'} = $$profileRef{'SourceID'};
   # TitleString is not transferred
   # Checksum is not transferred
   $newProfile{'State'} = $$profileRef{'State'};
 
   # SuburbName needs to be validated - check the SuburbIndex
   # lookup the suburbindex (and repair suburbName if necessary)
   ($suburbName, $suburbIndex) = $this->repairSuburbName($profileRef);
   if (($suburbName) && ($suburbIndex))
   {
      $newProfile{'SuburbName'} = $suburbName;
      $newProfile{'SuburbIndex'} = $suburbIndex;
   }
   else
   {   
      $newProfile{'SuburbName'} = $$profileRef{'SuburbName'};   # suburb index is not set (bad record)
   }
   
   # type needs to be transfered and TypeIndex identified
   ($typeName, $typeIndex) = $this->repairTypeName($profileRef);
   $newProfile{'Type'} = $typeName;
   $newProfile{'TypeIndex'} = $typeIndex;
   
   # transfer bedrooms and bathrooms
   $newProfile{'Bedrooms'} = $$profileRef{'Bedrooms'};
   $newProfile{'Bathrooms'} = $$profileRef{'Bathrooms'};
   
   # the land area is transferred to the text value
   $newProfile{'LandAreaText'} = $$profileRef{'LandArea'};
   $newProfile{'LandArea'} = $this->repairLandArea($$profileRef{'LandArea'});
  
   # the building area is transferred to the text value
   $newProfile{'BuildingAreaText'} = $$profileRef{'BuildingArea'};
   $newProfile{'BuildingArea'} = $this->repairLandArea($$profileRef{'BuildingArea'});
  
   # the YearBuilt needs to be converted from a string to an integer
   $newProfile{'YearBuiltText'} = $$profileRef{'YearBuilt'};
   $newProfile{'YearBuilt'} = $this->repairYearBuilt($$profileRef{'YearBuiltText'});
  
   # parse the AdvertisedPrice string - derive the upper and lower prices
   $newProfile{'AdvertisedPriceString'} = $$profileRef{'AdvertisedPriceString'};
   ($newProfile{'AdvertisedPriceLower'}, $newProfile{'AdvertisedPriceUpper'}, $newProfile{'AdvertisedWeeklyRent'}) = $this->repairAdvertisedPrice($$profileRef{'AdvertisedPriceString'}, $$profileRef{'SaleOrRentalFlag'});
   
   $newProfile{'StreetAddress'} = $$profileRef{'StreetAddress'};
   ($newProfile{'UnitNumber'}, $newProfile{'StreetNumber'}, $newProfile{'StreetName'}, $newProfile{'StreetType'}, $newProfile{'StreetSection'}) = $this->repairStreetAddress($$profileRef{'StreetAddress'}, $$profileRef{'SuburbName'});
   
   # no processing of Description or Features
   $newProfile{'Description'} = $$profileRef{'Description'};
   $newProfile{'Features'} = $$profileRef{'Features'};

   # reference to OriginatingHTML is retained
   $newProfile{'OriginatingHTML'} = $$profileRef{'OriginatingHTML'};

   # agency details - # popoulate the AgencyDetailsTable and get the index in return
   $agencyProfile{'SourceName'} = $$profileRef{'SourceName'};
   $agencyProfile{'AgencySourceID'} = $$profileRef{'AgencySourceID'};
   $agencyProfile{'AgencyName'} = $$profileRef{'AgencyName'};
   $agencyProfile{'AgencyAddress'} = $$profileRef{'AgencyAddress'};
   $agencyProfile{'SalesPhone'} = $$profileRef{'SalesPhone'};
   $agencyProfile{'RentalsPhone'} = $$profileRef{'RentalsPhone'};
   $agencyProfile{'Fax'} = $$profileRef{'Fax'};
   $agencyProfile{'Website'} = $$profileRef{'Website'};
   $agencyIndex = $agentProfiles->addRecord(\%agencyProfile);
   
   $contactProfile{'AgencyIndex'} = $agencyIndex;
   $contactProfile{'ContactName'} = $$profileRef{'ContactName'};
   $contactProfile{'MobilePhone'} = $$profileRef{'MobilePhone'};

   $contactIndex = $agentContactProfiles->addRecord(\%contactProfile);
   
   # retain the index references for the working view
   $newProfile{'AgencyIndex'} = $agencyIndex;
   $newProfile{'AgencyContactIndex'} = $contactIndex;
   
   # no other parameters are set - they're either default or undef
   ($errorCode, $warningCode) = $this->assessRecordValidity(\%newProfile);
   $newProfile{'ErrorCode'} = $errorCode;
   $newProfile{'WarningCode'} = $warningCode;
   
   # add a new record (or change existing)
   ($identifier, $changed, $added) = $this->_workingView_addOrChangeRecord(\%newProfile);
    
   return ($identifier, $changed, $added, $newProfile{'ErrorCode'}, $newProfile{'WarningCode'});
}

# -------------------------------------------------------------------------------------------------
