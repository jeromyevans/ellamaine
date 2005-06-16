#!/usr/bin/perl
# Written by Jeromy Evans
# Started 16 June 2005
# 
# Description:
#   Module that encapsulates the ConfigTable database component
#   Previously configuration was maintained in separate files - now its in a table
#
# History:
#   
#
# CONVENTIONS
# _ indicates a private variable or method
# ---CVS---
# Version: $Revision$
# Date: $Date$
# $Id$
#
package ConfigTable;
require Exporter;

use DBI;
use SQLClient;
use LoadProperties;

@ISA = qw(Exporter, SQLTable);


#@EXPORT = qw(&parseContent);

# -------------------------------------------------------------------------------------------------
# PUBLIC enumerations
#
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------

# Contructor for the ConfigTable - returns an instance of an ConfigTable object
# PUBLIC
sub new
{   
   my $sqlClient = shift;
   
   my $configTable = { 
      sqlClient => $sqlClient,
      tableName => "ConfigTable"
   }; 
      
   bless $configTable;   
   
   return $configTable;   # return this
}

# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# createTable
# attempts to create the configTable table in the database if it doesn't already exist
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
my $SQL_CREATE_TABLE_STATEMENT = "CREATE TABLE IF NOT EXISTS ConfigTable ".
   "(config VARCHAR(20) PRIMARY KEY NOT NULL, ".
    "parser TEXT NOT NULL, ".
    "state TEXT NOT NULL, ".
    "source TEXT NOT NULL, ".
    "url TEXT NOT NULL)";
      
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
         
         # load the configuration data
         $this->loadConfigurationTemplates();
      }
   }
   
   return $success;   
}

# -------------------------------------------------------------------------------------------------

# this is a quick method to load configuration data into the table
sub loadConfigurationTemplates
{
   my $this = shift;
   
   $configPath = "./configs";
   $fileListing = readDirectory($configPath);
   
   foreach (@$fileListing)
   {
      $configName = $_;
      $configProperties = loadProperties($configPath."/".$configName);
      
      if ($$configProperties{'loadproperties.error'})
      {
         # error reading properties - skip
      }
      else
      {  
         # remove the extension from the config
         $configName =~ s/.config$//gi;
         $configName =~ tr/[A-Z]/[a-z]/;   # convert to lowercase
         $$configProperties{'config'} = $configName;
         
         #DebugTools::printHash($configName, $configProperties);
         $this->addRecord($configProperties);
      }
   }
}

# -------------------------------------------------------------------------------------------------

# reads the contents of the specified directory 
#
# Parameters:
#  String Path
#
# Returns
#  Reference to list of files in the directories
#
sub readDirectory
{
   my $path = shift;
   # load the list of projects
   my @listing;
   opendir(DIR, $path);
   
   $files = 0;
   while ( defined ($file = readdir DIR) ) 
   {
      next if $file =~ /^\.\.?$/;     # skip . and ..
      # if this is a .config file...
      if ($file =~ /\.config$/)
      {
         # add this file...
         $listing[$files] = $file;
         $files++;
      }
     
   }
   closedir(BIN);
   
   return \@listing;
}

# -------------------------------------------------------------------------------------------------
# addRecord
# adds a record of data to the ConfigTable table
# 
# Purpose:
#  Storing information in the database
#
# Parameters:
#  string source name
#  reference to a hash containing the values to insert
#  string sourceURL
#  integer checksum
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
   
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $statementText;
   
   if ($sqlClient)
   {
      $statementText = "INSERT INTO ConfigTable ";
         
      @columnNames = keys %$parametersRef;
      
      # modify the statement to specify each column value to set 
      $appendString = "(";
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
      $appendString = "";
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
# attempts to drop the SuburbProfiles table 
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
my $SQL_DROP_TABLE_STATEMENT = "DROP TABLE ConfigTable";
        
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

sub fetchConfig

{
   my $this = shift;
   my $configName = shift;
   my $sqlClient = $this->{'sqlClient'};
   my $configData = undef;
   
   $configName = $sqlClient->quote($configName);
   $statementText = "select * FROM ConfigTable where config = $configName";
      
   $statement = $sqlClient->prepareStatement($statementText);
      
   if ($sqlClient->executeStatement($statement))
   {
      # get the array of rows from the table
      @selectResult = $sqlClient->fetchResults();
          
      foreach (@selectResult)
      {        
         # $_ is a reference to a hash
         $configData = $_;
         last;            
      }
   }
   return $configData;
}

# -------------------------------------------------------------------------------------------------
