#!/usr/bin/perl
# Written by Jeromy Evans
# Started 5 February 2006
#
# Description:
#   Module that encapsulate the CrawlerWarning database entity
#
# History:
# CONVENTIONS
# _ indicates a private variable or method
# ---CVS---
# Version: $Revision$
# Date: $Date$
# $Id$
#
package CrawlerWarning;
require Exporter;

use DBI;
use SQLClient;
use LoadProperties;

@ISA = qw(Exporter, SQLTable);


# -------------------------------------------------------------------------------------------------
# CONSTANTS


# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------

# Contructor for the CrawlerWarning - returns an instance of an CrawlerWarning object
# PUBLIC
sub new
{   
   my $sqlClient = shift;

   my $crawlerWarning = { 
      sqlClient => $sqlClient,
      tableName => "CrawlerWarning",
      CRAWLER_EXPECTED_FORM_NOT_FOUND => 1,
      CRAWLER_EXPECTED_LINK_NOT_FOUND => 2,
      CRAWLER_EXPECTED_FORM_ELEMENT_NOT_FOUND => 3,
      CRAWLER_EXPECTED_PATTERN_NOT_FOUND => 4
   }; 
      
   bless $crawlerWarning;  
   
   return $crawlerWarning;   # return this
}

# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# createTable
# attempts to create the CrawlerWarning table in the database if it doesn't already exist
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
   
my $SQL_CREATE_TABLE_STATEMENT = "CREATE TABLE IF NOT EXISTS CrawlerWarning ".
   "(ID INTEGER ZEROFILL PRIMARY KEY AUTO_INCREMENT, ".
    "DateEntered DATETIME NOT NULL, ".    
    "SourceName TEXT, ".
    "InstanceID TEXT, ".
    "Url TEXT, ".
    "WarningType INT, ".
    "WarningText TEXT, 
    Status INT)";   
      
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
# addRecord
# adds a record of data to the CrawlerWarning table
# also saves the content of the HTMLSyntaxTree to disk
# 
# Purpose:
#  Storing information in the database
#
# Parameters:
#  integer foreignIdentifier - foreign key to record that was created
#  string sourceURL   
#  HTMLSyntaxTree          - html content will be saved to disk
#  string foreignTableName -  name of the table that contains the created record.  It will be altered with the this new key
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
   my $sourceName = shift;
   my $instanceID = shift;
   my $url = shift;
   my $warningType = shift;
   my $warningText = shift;
   
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $statementText;
   my $identifier = -1;
   
   if ($sqlClient)
   {
      $statementText = "INSERT INTO CrawlerWarning (";
            
      # modify the statement to specify each column value to set 
      $appendString = "ID, DateEntered, SourceName, InstanceID, Url, WarningType, WarningText, Status";
      
      $statementText = $statementText.$appendString . ") VALUES (";
      
      # modify the statement to specify each column value to set
      
      $quotedSourceName = $sqlClient->quote($sourceName);
      $quotedInstanceID = $sqlClient->quote($instanceID);      
      $quotedUrl = $sqlClient->quote($url);
      $quotedWarningText = $sqlClient->quote($warningText);
            
      $appendString = "null, localtime(), $quotedSourceName, $quotedInstanceID, $quotedUrl, $warningType, $quotedWarningText, 0)";      

      $statementText = $statementText.$appendString;
      
      # prepare and execute the statement
      $statement = $sqlClient->prepareStatement($statementText);         
      if ($sqlClient->executeStatement($statement))
      {
         $success = 1;
         
         $identifier = $sqlClient->lastInsertID();                           
      }
   }
   
   return $identifier;   
}


# -------------------------------------------------------------------------------------------------

# dropTable
# attempts to drop the CrawlerWarning table 
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
my $SQL_DROP_TABLE_STATEMENT = "DROP TABLE CrawlerWarning";
        
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

# reports that an error has occured in the parser.  Used to report serious HTTP responses and
# changes in the structure of the source website
sub reportWarning

{
   my $this = shift;
   my $sourceName = shift;
   my $instanceID = shift;
   my $url = shift;
   my $warningType = shift;
   my $warningText = shift;
             
   $idenfitier = $this->addRecord($sourceName, $instanceID, $url, $warningType, $warningText);  
     
   return $identifier;
}

# -------------------------------------------------------------------------------------------------
1;
