#!/usr/bin/perl
# Written by Jeromy Evans
# Started 19 January 2005
# 
# WBS: A.01.03.01 Developed On-line Database
# Version 0.1  
#
# Description:
#   Module that encapsulate the StausTable database table.  The statusTable is used to show the progress of all
# the currently running and recently run PublishedMaterialScanner instances and is used for automatic recovery
# of a session.  Previously recover information was maintained in a text file and suffered to conditions where
# multiple different sessions could have the same ID (preventing correct recovery)
# 
# History:
# 16 June 2005 - Modified so that housekeeping is performed every run - threads that haven't been active
#  for more than 24 hours are released
#              - Modified the statement that allocates a thread to this instance to check that the
#  selected threadID hasn't been snatched by another instance in a race-condition. If it has been 
#  snatched then it simply tries again
# CONVENTIONS
# _ indicates a private variable or method
# ---CVS---
# Version: $Revision$
# Date: $Date$
# $Id$
#
package StatusTable;
require Exporter;

use DBI;
use SQLClient;
use Ellamaine::SessionProgressTable;
use Ellamaine::SessionURLStack;

@ISA = qw(Exporter);

$ORDER_BY_THREAD_ID = 0;
$ORDER_BY_STARTED   = 1;
$ORDER_BY_LAST_ACTIVE  = 2;
$ORDER_BY_INSTANCE_ID  = 3; 

#@EXPORT = qw(&parseContent);

# -------------------------------------------------------------------------------------------------
# PUBLIC enumerations
#
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------

# Contructor for the StatusTable - returns an instance of this object
# PUBLIC
sub new
{   
   my $sqlClient = shift;
   
   my $statusTable = { 
      sqlClient => $sqlClient,
      tableName => "StatusTable"
   }; 
      
   bless $statusTable;     
   
   return $statusTable;   # return this
}

# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# createTable
# attempts to create the statusTable table in the database if it doesn't already exist - also
# populates the table with the default set of thread ID's.
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

my $SQL_CREATE_STATUS_TABLE = 
   "ThreadID INTEGER PRIMARY KEY, ".
   "Created DATETIME, ".
   "LastActive DATETIME, ".
   "Allocated INTEGER, ".
   "InstanceID TEXT, ".
   "Restarts INTEGER, ".
   "RecordsEncountered INTEGER, ".
   "RecordsParsed INTEGER, ".
   "RecordsAdded INTEGER, ".
   "LastURL TEXT";
 
sub createTable

{
   my $this = shift;
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $tableName = $this->{'tableName'};
 
   my $SQL_CREATE_TABLE_PREFIX = "CREATE TABLE IF NOT EXISTS $tableName (";
   my $SQL_CREATE_TABLE_SUFFIX = ")";
   
   if ($sqlClient)
   {
      # append table prefix, original table body and table suffix
      $sqlStatement = $SQL_CREATE_TABLE_PREFIX.$SQL_CREATE_STATUS_TABLE.$SQL_CREATE_TABLE_SUFFIX;
      
      $statement = $sqlClient->prepareStatement($sqlStatement);
      
      if ($sqlClient->executeStatement($statement))
      {
         $success = 1;
         
         # populate the table with 127 default threads
         for ($threadID = 1; $threadID < 128; $threadID++)
         {
            
            $statementText = "INSERT INTO ".$this->{'tableName'}.
                             "(threadID, created, lastActive, allocated, instanceID, restarts, recordsEncountered, recordsParsed, recordsAdded, lastURL) VALUES ".
                             "($threadID, null, null, 0, null, 0, 0, 0, 0, null)";
            
            $statement = $sqlClient->prepareStatement($statementText, { RaiseError => 0, PrintError => 0, Warn => 0, AutoCommit => 1});
            
            if ($sqlClient->executeStatement($statement))
            {
            }
         }
      }
   }
   
   return $success;   
}


# -------------------------------------------------------------------------------------------------
# requestNewThread
# allocates one of the threads in the status table to a new session instance
#
# Purpose:
#  Storing information in the database
#
# Parameters:
#  string instanceID
#  
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
sub requestNewThread

{
   my $this = shift;
   my $instanceID = shift;
   
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $statementText;
   my $tableName = $this->{'tableName'};
   my $localTime;
   my $threadID = 0;
   my $threadIDSet = 0;
   my $triedCleanup = 0;
   my $triedHardCleanup = 0;
      
   if ($sqlClient)
   {
       print "   StatusTable:(housekeeping) cleaning up threads inactive more than 1 day...\n";
      # This was originally intended for when the table was full (no threads available), but
      # no reason not to do housekeeping regularly...
      $triedCleanup = 1;
      $statementText = "update $tableName set allocated=0 where lastActive < date_add(now(), interval -1 day)";
      
      $statement = $sqlClient->prepareStatement($statementText);
            
      if ($sqlClient->executeStatement($statement))
      {       
         $success = 1;
      }
               
      while (!$threadIDSet)
      {
         print "   StatusTable:requesting new threadID...";

         # select the threadID of the least-recently used unallocated thread
         $sqlStatement = "select threadID from $tableName where allocated=0 order by lastActive desc limit 1";
          
         @selectResults = $sqlClient->doSQLSelect($sqlStatement);
           
         # only zero or one result should be returned - if there's more than one, then we have a problem, to avoid it always take
         # the last entry in the list due to the 'order by' command
         $length = @selectResults;
         if ($length > 0)
         {
            $lastRecordHashRef = $selectResults[$#selectResults];
            $threadID = $$lastRecordHashRef{'threadID'};
            
            $quotedInstanceID = $sqlClient->quote($instanceID);
            # 16Jun05 - note: the last part of the where 'allocated=0' is used to detect if another instance took this
            # threadID since the select above - it's a feeble attempt to reduce the likelihood of this event
            $statementText = "UPDATE ".$this->{'tableName'}." ".
                             "set created=now(), lastActive=now(), allocated=1, instanceID=$quotedInstanceID, restarts=0, recordsEncountered=0, recordsParsed=0, recordsAdded=0, lastURL=null ".
                             "WHERE threadID = $threadID AND allocated=0";
            
            $statement = $sqlClient->prepareStatement($statementText);
      
            if ($sqlClient->executeStatement($statement))
            {
               # 16Jun05 - get the number of rows affected
               if ($sqlClient->rows() == 0)
               {
                  print "threadID $threadID snatched by another instance...retrying\n";
               }
               else
               {
                  print "ok (new $threadID)\n";
                  $threadIDSet = 1;
                  # IMPORTANT - clear the session information for this previous use of this thread, if still defined
                  # otherwise it might think it needs to recover from a previous position
                  $sessionProgressTable = SessionProgressTable::new($sqlClient);
                  $sessionProgressTable->releaseSession($threadID);
                  
                  # IMPORTANT - clear the URLstack previously used for this thread, if still defined
                  # otherwise it might think it needs to recover from that position
                  $sessionURLStack = SessionURLStack::new($sqlClient);
                  $sessionURLStack->releaseSession($threadID);
               }
            
            }
            else
            {
               print " initialisation for new thread $threadID failed\n";
               $threadIDSet = 1;
               $threadID = -1;
            }
         }
         else
         {
            if (!$triedHardCleanup)
            {
               print " cleaning up threads inactive more than 1 hour...\n";
               # there's no unallocated threads - this is probably because they've all exited abnormally.  Clean up
               # the table instead
               $triedHardCleanup = 1;
               $statementText = "update $tableName set allocated=0 where lastActive < date_add(now(), interval -2 hour)";
               
               $statement = $sqlClient->prepareStatement($statementText);
                     
               if ($sqlClient->executeStatement($statement))
               {       
                  $success = 1;
               }
            }
            else
            {
               # abort - can't imagine it every getting here, but possible... the return a threadID of -1
               # to indicate failure
               print " failed again.  Aborting.\n";
               $threadID = -1;
               $threadIDSet = 1;
            }
         }      
      }
   }
   
   return $threadID;   
}

# -------------------------------------------------------------------------------------------------
# continueThread
# re-allocates the specified thread in the status table to a new session instance
#
# Purpose:
#  Storing information in the database
#
# Parameters:
#  integer threadID
#  string instanceID
#  
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
sub continueThread

{
   my $this = shift;
   my $threadID = shift;
   my $instanceID = shift;
   
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $statementText;
   my $tableName = $this->{'tableName'};
   my $localTime;
 
      
   if ($sqlClient)
   {

      $quotedInstanceID = $sqlClient->quote($instanceID);
      
      print "   StatusTable:requesting continuation of threadID $threadID...";
      $statementText = "update $tableName set allocated=1,instanceID=$quotedInstanceID,restarts=restarts+1 where threadID=$threadID";
               
      $statement = $sqlClient->prepareStatement($statementText);
            
      if ($sqlClient->executeStatement($statement))
      {       
         $success = 1;
         print "ok\n";
      }
      else
      {
         print "failed (update)\n";  
      }

   }
   
   return $success;   
}

# -------------------------------------------------------------------------------------------------
# releaseThread
# releases allocation of the specified thread in the status table 
#
# Purpose:
#  Storing information in the database
#
# Parameters:
#  integer threadID
#  string instanceID
#  
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
sub releaseThread

{
   my $this = shift;
   my $threadID = shift;
   
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $statementText;
   my $tableName = $this->{'tableName'};
   my $localTime;
 
      
   if ($sqlClient)
   {      
      print "   StatusTable:requesting release of threadID $threadID...";
      $statementText = "update $tableName set allocated=0 where threadID=$threadID";
               
      $statement = $sqlClient->prepareStatement($statementText);
            
      if ($sqlClient->executeStatement($statement))
      {       
         $success = 1;
         print "ok\n";
      }
      else
      {
         print "failed (update)\n";  
      }
   
   }
   
   return $success;   
}


# -------------------------------------------------------------------------------------------------
# lookupInstance
# returns the current instance name of the specified thread
#
# Purpose:
#  Storing information in the database
#
# Parameters:
#  string instanceID
#  
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
sub lookupInstance

{
   my $this = shift;
   my $threadID = shift;
   
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $statementText;
   my $tableName = $this->{'tableName'};
   my $localTime;
   my $instanceID = undef;
      
   if ($sqlClient)
   {
     
      print "   StatusTable:requesting last instance for thread $threadID...\n";

      # select the threadID of the least-recently used unallocated thread
      $sqlStatement = "select instanceID from $tableName where threadID=$threadID";
       
      @selectResults = $sqlClient->doSQLSelect($sqlStatement);
        
      # only zero or one result should be returned - if there's more than one, then we have a problem, to avoid it always take
      # the last entry in the list due to the 'order by' command
      $length = @selectResults;
      if ($length > 0)
      {
         $lastRecordHashRef = $selectResults[$#selectResults];
         $instanceID = $$lastRecordHashRef{'instanceID'};
      }
      
       print "               last instanceID was '$instanceID'.\n";
   }
   
   return $instanceID;
}        

# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# addToRecordsEncountered
# increments the number of records encountered by this thread by the number specified
#
# Purpose:
#  Storing information in the database
#
# Parameters:
#  integer threadID
#  integer recordsEncountered
#  string lastURL
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
sub addToRecordsEncountered

{
   my $this = shift;
   my $threadID = shift;
   my $recordsAdded = shift;
   my $lastURL = shift;
   
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $statementText;
   my $tableName = $this->{'tableName'};
  
      
   if ($sqlClient)
   {
      # update the recordsEncounted value
      $triedCleanup = 1;
      $quotedURL = $sqlClient->quote($lastURL);
      $statementText = "update $tableName set lastActive=now(), recordsEncountered=recordsEncountered+$recordsAdded, lastURL=$quotedURL where threadID = $threadID";
      
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
# addToRecordsParsed
# increments the number of records parsed and records added by this thread by the numbers specified
#
# Purpose:
#  Storing information in the database
#
# Parameters:
#  integer threadID
#  integer recordsParsed
#  integer recordsAdded
#  string lastURL
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
sub addToRecordsParsed

{
   my $this = shift;
   my $threadID = shift;
   my $recordsParsed = shift;
   my $recordsAdded = shift;
   my $lastURL = shift;
   
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $statementText;
   my $tableName = $this->{'tableName'};
  
      
   if ($sqlClient)
   {
      # update the recordsParsed and Added values
      $triedCleanup = 1;
      $quotedURL = $sqlClient->quote($lastURL);
      $statementText = "update $tableName set lastActive=now(), recordsParsed=recordsParsed+$recordsParsed, recordsAdded=recordsAdded+$recordsAdded, lastURL=$quotedURL where threadID = $threadID";
      
      $statement = $sqlClient->prepareStatement($statementText);
            
      if ($sqlClient->executeStatement($statement))
      {       
         $success = 1;
      }
   }
   
   return $success;   
}

# -------------------------------------------------------------------------------------------------
# dropTable
# attempts to drop the StatusTable table 
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



# -------------------------------------------------------------------------------------------------
# lookupAllocatedThreads
# returns information on all of the threads that are currently allocated
#
# Purpose:
#  Storing information in the database
#
# Parameters:
#  Enumeration to specify how to order the information
#  BOOL reverseFlag (order in reverse order if set)
#
# Returns:
#   reference to a list of hashes
#        
sub lookupAllocatedThreads

{
   my $this = shift;
   my $orderByEnum = shift;
   my $reverse = shift;

   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $statementText;
   my $tableName = $this->{'tableName'};
   my $localTime;
   my $instanceID = undef;
   my $orderBy = "ThreadID";
   
   if ($sqlClient)
   {
      if ($orderByEnum == $ORDER_BY_THREAD_ID)
      {
         $orderBy = "ThreadID";
      }
      elsif ($orderByEnum == $ORDER_BY_STARTED)
      {
         $orderBy = "Created";
      }
      elsif ($orderByEnum == $ORDER_BY_LAST_ACTIVE)
      {
         $orderBy = "LastActive";
      }
      elsif ($orderByEnum == $ORDER_BY_INSTANCE_ID)
      {
         $orderBy = "InstanceID";
      }
      else
      {
         $orderBy = "ThreadID";
      }
      
      # if reverse is set, add desc suffice
      if ($reverse)
      {
         $orderBy .= " DESC";
      }
    
      # select the threadID of the least-recently used unallocated thread
      $sqlStatement = "SELECT * FROM $tableName WHERE Allocated=1 ORDER BY $orderBy";
       
      @selectResults = $sqlClient->doSQLSelect($sqlStatement);
    
   }
   
   return \@selectResults;
}        

# -------------------------------------------------------------------------------------------------

