#!/usr/bin/perl
# Written by Jeromy Evans
# Started 21 June 2005
# 
# WBS: A.01.03.01 Developed On-line Database
# Version 0.1  
#
# Description:
#   Module that encapsulate the AgentProfiles database table - captures information on advertising agents
# 
# History:

# CONVENTIONS
# _ indicates a private variable or method
# ---CVS---
# Version: $Revision$
# Date: $Date$
# $Id$
#
package AgentProfiles;
require Exporter;

use DBI;
use SQLClient;
use Time::Local;
use PrettyPrint;
use StringTools;

@ISA = qw(Exporter SQLTable);

#@EXPORT = qw(&parseContent);

# -------------------------------------------------------------------------------------------------
# PUBLIC enumerations
#
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------

# Contructor for the AgentProfiles - returns an instance of this object
# PUBLIC
sub new
{   
   my $sqlClient = shift;

   $tableName = 'AgentProfiles';
 
   my $agentProfiles = { 
      sqlClient => $sqlClient,
      tableName => $tableName,
      useDifferentTime => 0,
      dateEntered => undef
   }; 
      
   bless $agentProfiles;     
   
   return $agentProfiles;   # return this
}

# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# createTable
# attempts to create the AgentProfiles table in the database if it doesn't already exist
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
   "AgencyIndex INTEGER ZEROFILL PRIMARY KEY AUTO_INCREMENT, ".    
   "DateEntered DATETIME NOT NULL, ".
   "LastEncountered DATETIME, ".
   "SourceName TEXT, ".
   "AgencySourceID TEXT, ".
   "AgencyName TEXT, ".
   "AgencyAddress TEXT, ".   
   "SalesPhone TEXT, ".
   "RentalsPhone TEXT, ".
   "Fax TEXT, ".
   "Website TEXT";
   
sub createTable

{
   my $this = shift;
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $tableName = $this->{'tableName'};
   
   my $SQL_CREATE_TABLE_PREFIX = "CREATE TABLE IF NOT EXISTS $tableName (";
   my $SQL_CREATE_TABLE_SUFFIX = ", INDEX (AgencyName(15), AgencyAddress(15)))";  
   
   if ($sqlClient)
   {
      # append table prefix, original table body and table suffix
      $sqlStatement = $SQL_CREATE_TABLE_PREFIX.$SQL_CREATE_TABLE_BODY.$SQL_CREATE_TABLE_SUFFIX;
     
      $statement = $sqlClient->prepareStatement($sqlStatement);
      
      if ($sqlClient->executeStatement($statement))
      {
         $success = 1;
      }
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
# adds a record of data to the AgentProfiles table
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
   
   my $sqlClient = $this->{'sqlClient'};
   my $tableName = $this->{'tableName'};
   my $statementText;
   my $agencyIndex = undef;
   
   if ($sqlClient)
   {      
      if ($$parametersRef{'AgencyName'})
      {
         # only inserts a new record if the agent doesn't already exist
         $quotedAgencyName = $sqlClient->quote($$parametersRef{'AgencyName'});
         
         if ($$parametersRef{'AgencyAddress'})
         {
            $quotedAgencyAddress = $sqlClient->quote($$parametersRef{'AgencyAddress'});
   
            $statementText = "SELECT AgencyIndex, unix_timestamp(LastEncountered) FROM $tableName WHERE AgencyName = $quotedAgencyName AND AgencyAddress = $quotedAgencyAddress";
         }
         else
         {
            $statementText = "SELECT AgencyIndex, unix_timestamp(LastEncountered) FROM $tableName WHERE AgencyName = $quotedAgencyName AND AgencyAddress is null";
         }
         
         @selectResults = $sqlClient->doSQLSelect($statementText);
         $noOfResults = @selectResults;
         
         # it's possible that zero or one  more results are returned
         if ($noOfResults > 0)
         {
            # for the purposes of associating records, only the index of the first result is used
            # (there shouldn't ever be more than one, but it's conceivable)
            $firstResult = $selectResults[0];
            $agencyIndex = $$firstResult{'AgencyIndex'};
            
            # update the lastEncountered field for this agent
            if (defined $$parametersRef{'DateEntered'})
            {
               # use a pre-defined time
               $localTime = $sqlClient->quote($$parametersRef{'DateEntered'});
            }
            else
            {
               # use internal function to set the time to now
               $localTime = "localtime()";
            } 
            $quotedAgencyIndex = $sqlClient->quote($agencyIndex);
            
            $statementText = "UPDATE $tableName SET LastEncountered = $localTime WHERE AgencyIndex = $quotedAgencyIndex";
            $statement = $sqlClient->prepareStatement($statementText);
            if ($sqlClient->executeStatement($statement))
            {
               $success = 1;
            }
         }
         else
         {
            # a new record needs to be added...
            
            $useLocalTime = 0;
            # if the date entered isn't set, use localtime()
            if (!defined $$parametersRef{'DateEntered'})
            {
               $$parametersRef{'DateEntered'} = "localtime()";
               $useLocalTime = 1;
            }
            
            # ignore the AgencyIndex = this is an auto_increment number that should not be set (the situations
            # where it may be set and needs to be deleted is recovery or import from a file)
            delete $$parametersRef{'AgencyIndex'};
           
            $statementText = "INSERT INTO $tableName (";
            
            @columnNames = keys %$parametersRef;
            
            # modify the statement to specify each column value to set 
            $appendString = join ',', @columnNames;
            
            $statementText = $statementText.$appendString . ") VALUES (";
            
            # modify the statement to specify each column value to set 
            $index = 0;
            
            $appendString = "";
            $index = 0;
            foreach (@columnNames)
            {
               if ($index != 0)
               {
                  $appendString = $appendString.", ";
               }
              
               # IMPORTANT - quote all values EXCEPT the call to localtime()
               if (($useLocalTime) && ($_ =~ /DateEntered/))
               {
                  # don't quote localtime()
                  $appendString = $appendString.$$parametersRef{$_};
               }
               else
               {
                  $appendString = $appendString.$sqlClient->quote($$parametersRef{$_});
               }
               $index++;
            }
            $statementText = $statementText.$appendString . ")";
            
     #       print "statement = ", $statementText, "\n";
            $statement = $sqlClient->prepareStatement($statementText);
           
            # prepare and execute the statement
            $statement = $sqlClient->prepareStatement($statementText);         
            if ($sqlClient->executeStatement($statement))
            {
               $success = 1;
               
               # use lastInsertID to get the primary key identifier of the record just inserted
               $agencyIndex = $sqlClient->lastInsertID();
            }
         }
      }
   }
      
   return $agencyIndex;   
}

# -------------------------------------------------------------------------------------------------
# dropTable
# attempts to drop the AgentProfiles table 
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
