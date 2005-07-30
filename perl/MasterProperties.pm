#!/usr/bin/perl
# Written by Jeromy Evans
# Started 5 December 2004
# 
# WBS: A.01.03.01 Developed On-line Database
# Version 0.1  
#
# Description:
#   Module that encapsulate the MasterProperties database component
# 
# History:
#  7 Dec 2004 - extended MasterProperties to include fields for the master associated property details with 
#    references to each of the components (property details can be associated from more than one source)
#             - added support for MasterPropertyComponentsXRef table that provides a cross-reference of properties 
#    to the source components (opposite of the componentOf relationship)
#  8 Dec 2004 - added code to calculate and set the master component fields of an entry in the MasterProperties
#    by looking up the components (via the XRef) and applying a selection algorithm.
#             - needed to use AdvertisedPropertyProfiles reference to lookup components (of workingview) - impacts
#    constructor
#  5 Jan 2004 - altered MasterProperties to include a field dateLastAdvertised which is the most recent of the
#   date entered or last encountered field for the components.  It's needed to to look for properties that 
#   have been recently advertised, otherwise all the components would need to be checked.
#  19 Jan 2005 - added index on address suburb|street|streetnumber (actually added before this date but included a typo
#   so would have failed on next create command) Now fixed.
#  22 Jun 2005 - renamed to MasterProperties from MasterPropertyTable (package and table)
#              - modified to support the format of the new workingView table
# CONVENTIONS
# _ indicates a private variable or method
# ---CVS---
# Version: $Revision$
# Date: $Date$
# $Id$
#
package MasterProperties;
require Exporter;

use DBI;
use SQLClient;
use AdvertisedPropertyProfiles;
use SQLTable;

@ISA = qw(Exporter, SQLTable);

# -------------------------------------------------------------------------------------------------
# PUBLIC enumerations
#
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------

# Contructor for the masterProperties - returns an instance of this object
# PUBLIC
sub new
{   
   my $sqlClient = shift;

   my $masterProperties = { 
      sqlClient => $sqlClient,
      tableName => "MasterProperties",
   }; 
      
   bless $masterProperties;     
   
   return $masterProperties;   # return this
}

# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# createTable
# attempts to create the MasterProperties table in the database if it doesn't already exist
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

my $SQL_CREATE_TABLE_PREFIX = "CREATE TABLE IF NOT EXISTS MasterProperties (";
my $SQL_CREATE_TABLE_BODY = 
   "MasterPropertyIndex INTEGER ZEROFILL PRIMARY KEY AUTO_INCREMENT, ".    
   "DateEntered DATETIME NOT NULL, ".
   "DateLastAdvertised DATETIME NOT NULL, ".
   "UnitNumber TEXT, ".                      
   "StreetNumber TEXT, ".                    
   "StreetName TEXT, ".                      
   "StreetType TEXT, ".                      
   "StreetSection TEXT, ".
   "SuburbName TEXT, ".
   "SuburbIndex INTEGER UNSIGNED ZEROFILL, ".  
   "State VARCHAR(3), ".
   "TypeSource INTEGER UNSIGNED ZEROFILL, ".     # REFERENCES WorkingView.Identifier
   "Type VARCHAR(10), ".
   "TypeIndex INTEGER,".                         # REFERENCES PropertyTypes.TypeIndex, ".       "BedroomsSource INTEGER UNSIGNED ZEROFILL, ".
   "BedroomsSource INTEGER UNSIGNED ZEROFILL, ". # REFERENCES WorkingView.Identifier
   "Bedrooms INTEGER, ".
   "BathroomsSource INTEGER UNSIGNED ZEROFILL, ".# REFERENCES WorkingView.Identifier
   "Bathrooms INTEGER, ".
   "LandAreaSource INTEGER UNSIGNED ZEROFILL, ".     # REFERENCES WorkingView.Identifier
   "LandArea DECIMAL(10,2), ".               
   "BuildingAreaSource INTEGER UNSIGNED ZEROFILL, ". # REFERENCES WorkingView.Identifier
   "BuildingArea INTEGER, ".                 
   "YearBuiltSource INTEGER UNSIGNED ZEROFILL, ".    # REFERENCES WorkingView.Identifier
   "YearBuilt INTEGER, ".                            
   "AdvertisedPriceSource INTEGER UNSIGNED ZEROFILL, ".      # REFERENCES WorkingView.Identifier
   "AdvertisedPriceLower DECIMAL(10,2), ".
   "AdvertisedPriceUpper DECIMAL(10,2), ".
   "AdvertisedWeeklyRentSource INTEGER UNSIGNED ZEROFILL, ". # REFERENCES WorkingView.Identifier
   "AdvertisedWeeklyRent DECIMAL(10,2),".       
   "PriceCode INTEGER DEFAULT 0, ".
   "ExceptionCode INTEGER DEFAULT 0, ".
   "INDEX (SuburbIndex, StreetSection(5), StreetType(5), StreetName(10), StreetNumber(5), UnitNumber(5)), INDEX (PriceCode), INDEX (ExceptionCode)";        
    
my $SQL_CREATE_TABLE_SUFFIX = ")";
           
sub createTable

{
   my $this = shift;
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   
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
# lookupMasterPropertyIndex
# Returns the MasterPropertyIndex of the property matching the specified address if it exists already
#
# Parameters:
#   reference to a hash of the profile to match
#
# Returns:
#   INTEGER MasterIndexID or -1 
#
sub lookupMasterPropertyIndex

{
   my $this = shift;
   my $parametersRef = shift;
   
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $statementText;
   my $tableName = $this->{'tableName'};
   my $localTime;
   
   my $masterPropertyIndex = -1;

   if ($sqlClient)
   {
      $suburbIndex = $$parametersRef{'SuburbIndex'};

      $whereClause = "";
      
      if ($$parametersRef{'StreetSection'})
      {
         $whereClause .= " AND StreetSection like ". $sqlClient->quote($$parametersRef{'StreetSection'});
      }
      else
      {
         $whereClause .= " AND StreetSection is null";
      }
      
      if ($$parametersRef{'StreetType'})                           
      {
         $whereClause .= " AND StreetType like ". $sqlClient->quote($$parametersRef{'StreetType'});
      }
      else
      {
         $whereClause .= " AND StreetType is null";
      }
      
      if ($$parametersRef{'StreetName'})
      {
         $whereClause .= " AND StreetName like ". $sqlClient->quote($$parametersRef{'StreetName'});
      }
      else
      {
         $whereClause .= " AND StreetName is null";
      }
         
      if ($$parametersRef{'StreetNumber'})
      {
         $whereClause .= " AND StreetNumber like ". $sqlClient->quote($$parametersRef{'StreetNumber'});
      }
      else
      {
         $whereClause .= " AND StreetNumber is null";
      }
      
      if ($$parametersRef{'UnitNumber'})
      {
         $whereClause .= " AND UnitNumber like ". $sqlClient->quote($$parametersRef{'UnitNumber'});
      }
      else
      {
         $whereClause .= " AND UnitNumber is null";
      }
      
      $sqlStatement = "SELECT MasterPropertyIndex FROM $tableName WHERE SuburbIndex=$suburbIndex $whereClause";
      @selectResults = $sqlClient->doSQLSelect($sqlStatement);
     
      # only ZERO or ONE result should be returned 
      $hashRef = $selectResults[0];
      $masterPropertyIndex = $$hashRef{'MasterPropertyIndex'};

      if (!defined $masterPropertyIndex)
      {
         $masterPropertyIndex = -1;
      }
   }
   
   return $masterPropertyIndex;
}


# -------------------------------------------------------------------------------------------------
# lookupMasterPropertyProfile
# Returns the a reference to the hash containing the profile for the specified MasterPropertyIndex
#
# Parameters:
#   INTEGER MasterIndexID or -1
#
# Returns:
#   reference to a hash of the profile to match
#
sub lookupMasterPropertyProfile

{
   my $this = shift;
   my $masterPropertyIndex = shift;
   
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $tableName = $this->{'tableName'};
  
   if ($sqlClient)
   {
      @selectResults = $sqlClient->doSQLSelect("SELECT * FROM $tableName WHERE MasterPropertyIndex=$masterPropertyIndex");
     
      # only ZERO or ONE result should be returned 
      $hashRef = $selectResults[0];
      
   }
   
   return $hashRef;
}

# -------------------------------------------------------------------------------------------------
# associatedRecord
# associates a record of data in a WorkingView table to an entry in the MasterProperties table
# if a property isn't already defined at the specified address a new MasterProperty will be created
#
# Parameters:
#  reference to a PropertyProfile hash
#
# Returns:
#   LIST (INTEGER MasterPropertyIndex, BOOL Added, BOOL Modified)
#
sub associateRecord

{
   my $this = shift;
   my $parametersRef = shift;
   
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $statementText;
   my $tableName = $this->{'tableName'};
   my $advertisedPropertyProfiles = AdvertisedPropertyProfiles::new($sqlClient);
   
   my $masterPropertyIndex = -1;
   my $added = 0;
   my $changed = 0;
  
   if ($sqlClient)
   {
      # check if the property already exists for the specified address...
      $masterPropertyIndex = $this->lookupMasterPropertyIndex($parametersRef);
      
      if ($masterPropertyIndex >= 0)
      {
         # that property record already exists - the identifier can be returned as-as
         #print "   property($identifier) already created.\n";
         
         # lookup & (re)calculate the master components for the property
         if ($this->_calculateMasterComponents($masterPropertyIndex))
         {
            # set the componentOf relationship for the source record
            $advertisedPropertyProfiles->workingView_setSpecialField($$parametersRef{'Identifier'}, 'ComponentOf', $masterPropertyIndex);
            
            $changed = 1;
         }
      }
      else
      {
         # transfer records from the source profile to the new master profile 
         $masterProfile{'DateEntered'} = $$parametersRef{'DateEntered'};         # use the date of the first record
         $masterProfile{'DateLastAdvertised'} = $$parametersRef{'DateEntered'};  # only one component so this is ok
         # copy the address
         $masterProfile{'UnitNumber'} = $$parametersRef{'UnitNumber'};
         $masterProfile{'StreetNumber'} = $$parametersRef{'StreetNumber'};
         $masterProfile{'StreetName'} = $$parametersRef{'StreetName'};
         $masterProfile{'StreetType'} = $$parametersRef{'StreetType'};
         $masterProfile{'StreetSection'} = $$parametersRef{'StreetSection'};
         $masterProfile{'SuburbName'} = $$parametersRef{'SuburbName'};
         $masterProfile{'SuburbIndex'} = $$parametersRef{'SuburbIndex'};
         $masterProfile{'State'} = $$parametersRef{'State'};
         
         # copy other properties
         $masterProfile{'TypeSource'} = $$parametersRef{'Identifier'};
         $masterProfile{'Type'} = $$parametersRef{'Type'};
         $masterProfile{'TypeIndex'} = $$parametersRef{'TypeIndex'};   
         $masterProfile{'BedroomsSource'} = $$parametersRef{'Identifier'};
         $masterProfile{'Bedrooms'} = $$parametersRef{'Bedrooms'};
         $masterProfile{'BathroomsSource'} = $$parametersRef{'Identifier'};
         $masterProfile{'Bathrooms'} = $$parametersRef{'Bathrooms'};
         $masterProfile{'LandAreaSource'} = $$parametersRef{'Identifier'};
         $masterProfile{'LandArea'} = $$parametersRef{'LandArea'};
         $masterProfile{'BuildingAreaSource'} = $$parametersRef{'Identifier'};
         $masterProfile{'BuildingArea'} = $$parametersRef{'BuildingArea'};
         $masterProfile{'YearBuiltSource'} = $$parametersRef{'Identifier'};
         $masterProfile{'YearBuilt'} = $$parametersRef{'YearBuilt'};
         $masterProfile{'AdvertisedPriceSource'} = $$parametersRef{'Identifier'};
         $masterProfile{'AdvertisedPriceLower'} = $$parametersRef{'AdvertisedPriceLower'};
         $masterProfile{'AdvertisedPriceUpper'} = $$parametersRef{'AdvertisedPriceUpper'};
         $masterProfile{'AdvertisedWeeklyRentSource'} = $$parametersRef{'Identifier'};
         $masterProfile{'AdvertisedWeeklyRent'} = $$parametersRef{'AdvertisedWeeklyRent'};

         # insert the record into the table
         

         $statementText = "INSERT INTO $tableName (";
      
         @columnNames = keys %masterProfile;
         
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
           
            $appendString = $appendString.$sqlClient->quote($masterProfile{$_});
            
            $index++;
         }
         $statementText = $statementText.$appendString . ")";
                   
         $statement = $sqlClient->prepareStatement($statementText);
         
         if ($sqlClient->executeStatement($statement))
         {
            $masterPropertyIndex = $sqlClient->lastInsertID();
            $added = 1;
          
            # set the componentOf relationship for the source record
            $advertisedPropertyProfiles->workingView_setSpecialField($$parametersRef{'Identifier'}, 'ComponentOf', $masterPropertyIndex);   
         }
      }
   }
   
   return ($masterPropertyIndex, $added, $changed);
}

# -------------------------------------------------------------------------------------------------
# _updateMasterPropertyWithChangeHash
# alters a record of data in the MasterProperties table 
# it accepts an index and changeHash (values that have changed)
# 
# Parameters:
#  integer MasterPropertyIndex
#  reference to a hash containing the values to insert (only those that have changed)
#
# Returns:
#   TRUE (1) if successful, 0 otherwise
#        
sub _updateMasterPropertyWithChangeHash

{
   my $this = shift;
   my $masterPropertyIndex = shift;
   my $parametersRef = shift;   
   
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $statementText;
   my $tableName = $this->{'tableName'};
   
   if ($sqlClient)
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
      
      $statementText = $appendString." WHERE MasterPropertyIndex=$masterPropertyIndex";
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
# attempts to drop the MasterProperties table 
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
my $SQL_DROP_TABLE_STATEMENT = "DROP TABLE MasterProperties";
my $SQL_DROP_XREF_TABLE_STATEMENT = "DROP TABLE MasterPropertyComponentsXRef";
        
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
         $statement = $sqlClient->prepareStatement($SQL_DROP_XREF_TABLE_STATEMENT);
      
         if ($sqlClient->executeStatement($statement))
         {
             $success = 1;
         }
      }
   }
   
   return $success;   
}

# -------------------------------------------------------------------------------------------------

# -------------------------------------------------------------------------------------------------
# countEntries
# returns the number of properties in the database
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
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------

# _calculateMasterComponents
# determines which components to use as the master components for the specified property

# Parameters:
#  integer propertyIdentifier
#
# Returns:
#   TRUE (1) if successful, 0 otherwise
#
sub _calculateMasterComponents

{
   my $this = shift;
   my $masterPropertyIndex = shift;
   
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   my $advertisedPropertyProfiles = AdvertisedPropertyProfiles::new($sqlClient);
   my %changeProfile;
      
   if ($sqlClient)
   {
      # get the properties of the existing master property profile
      $masterProfile = $this->lookupMasterPropertyProfile($masterPropertyIndex);
      
      # get a list of profiles associated with this masterProperty
      $selectResults = $advertisedPropertyProfiles->lookupProfilesByComponentOf($masterPropertyIndex);

      # --- apply association/master component selection algorithms ---
      
      # determine which is the newest profile
      $dateLastEncountered = 0;
      $newestProfile = undef;
      foreach (@$selectResults)
      {
         # determine if the date this component was last encountered is newer than the previous component
         $dateEntered = $sqlClient->unix_timestamp($$_{'DateEntered'});
         $lastEncountered = $sqlClient->unix_timestamp($$_{'LastEncountered'});
         
         # check the lastEncountered field - see if it's the newest
         if ($lastEncountered)
         {
            if ($lastEncountered > $dateLastEncountered)
            {
               $dateLastEncountered = $lastEncountered;
               $newestProfile = $_;   # remember this profile for later
               # record the date last advertised
               $changeProfile{'DateLastAdvertised'} = $$_{'LastEncountered'};
            }
         }
         else
         {
            # use the dateEntered parameter - lastEncountered isn't set
            if ($dateEntered > $dateLastEncountered)
            {
               $dateLastEncountered = $lastEncountered;
               $newestProfile = $_;    # remember this profile for later
               # record the date last advertised
               $changeProfile{'DateLastAdvertised'} = $$_{'DateEntered'};
            }
         }
      }
      
      # transfer the fields from the relevant newestProfile to the master profile
      
      # clear all exceptions
      $inconsistentTypeException = 0;
      $inconsistentBedroomsException = 0;
      $inconsistentBathroomsException = 0;
      $inconsistentLandAreaException = 0;
      $inconsistentBuildingAreaException = 0;
      $inconsistentYearBuiltException = 0;
      
      # SECOND PASS
      # loop through all the profiles and transfer the components are are
      # expected to be identical for all records (except some may be undef)
      
      foreach (@$selectResults)
      {
         #print "CID:", $$_{'Identifier'}, "\n";
         ### This code could be shortend using a list of the fields
         # that need to be checked (its the same code for each field)
         # only reason they're separate at the moment is for simplicity of debugging
         # and because Type sets additional fields compared to the others (TypeIndex)
         
         # if the master type isn't set yet and this component has type, use it
         # Note: all components should have the same type (or undef)
         if ($$_{'Type'})
         {
            # if the master type isn't set, use this one
            if (!$$masterProfile{'Type'})
            {
               $changeProfile{'TypeSource'} = $$_{'Identifier'};
               $changeProfile{'TypeType'} = $$_{'Type'};
               $changeProfile{'TypeIndex'} = $$_{'TypeIndex'};
            }
            else
            {
               # exception reporting - the this type differs from the master, 
               # then a inconsistent type exception is set
               
               if ($$masterProfile{'TypeIndex'} != $$_{'TypeIndex'})
               {
                  $inconsistentTypeException = 1;
               }
            }
         }  
         
         # if the master bedrooms isn't set yet and this component has bedrooms, use it
         # Note: all components should have the same bedrooms (or undef)
         if ($$_{'Bedrooms'})
         {
            # if the master bedrooms isn't set, use this one
            if (!$$masterProfile{'Bedrooms'})
            {
               $changeProfile{'BedroomsSource'} = $$_{'Identifier'};
               $changeProfile{'Bedrooms'} = $$_{'Bedrooms'};
            }
            else
            {
               # exception reporting - the this bedrooms differs from the master, 
               # then a inconsistent bedrooms exception is set
               
               if ($$masterProfile{'Bedrooms'} != $$_{'Bedrooms'})
               {
                  $inconsistentBedroomsException = 1;
               }
            }
         }      
         
         # if the master bathrooms isn't set yet and this component has bathrooms, use it
         # Note: all components should have the same bathrooms (or undef)
         if ($$_{'Bathrooms'})
         {
            # if the master bathrooms isn't set, use this one
            if (!$$masterProfile{'Bathrooms'})
            {
               $changeProfile{'BathroomsSource'} = $$_{'Identifier'};
               $changeProfile{'Bathrooms'} = $$_{'Bathrooms'};
            }
            else
            {
               # exception reporting - the this bathrooms differs from the master, 
               # then a inconsistent bathrooms exception is set
               
               if ($$masterProfile{'Bathrooms'} != $$_{'Bathrooms'})
               {
                  $inconsistentBathroomsException = 1;
               }
            }
         }         
          
         # if the master landArea isn't set yet and this component has landArea, use it
         # Note: all components should have the same landArea (or undef)
         if ($$_{'LandArea'})
         {
            # if the master landArea isn't set, use this one
            if (!$$masterProfile{'LandArea'})
            {
               $changeProfile{'LandAreaSource'} = $$_{'Identifier'};
               $changeProfile{'LandArea'} = $$_{'LandArea'};
            }
            else
            {
               # exception reporting - the this landArea differs from the master, 
               # then a inconsistent landArea exception is set
               
               if ($$masterProfile{'LandArea'} != $$_{'LandArea'})
               {
                  $inconsistentLandAreaException = 1;
               }
            }
         }      
      
         # if the master buildingArea isn't set yet and this component has buildingArea, use it
         # Note: all components should have the same buildingArea (or undef)
         if ($$_{'BuildingArea'})
         {
            # if the master buildingArea isn't set, use this one
            if (!$$masterProfile{'BuildingArea'})
            {
               $changeProfile{'BuildingAreaSource'} = $$_{'Identifier'};
               $changeProfile{'BuildingArea'} = $$_{'BuildingArea'};
            }
            else
            {
               # exception reporting - the this buildingArea differs from the master, 
               # then a inconsistent buildingArea exception is set
               
               if ($$masterProfile{'BuildingArea'} != $$_{'BuildingArea'})
               {
                  $inconsistentBuildingAreaException = 1;
               }
            }
         }      
      
         # if the master yearBuilt isn't set yet and this component has yearBuilt, use it
         # Note: all components should have the same yearBuilt (or undef)
         if ($$_{'YearBuilt'})
         {
            # if the master yearBuilt isn't set, use this one
            if (!$$masterProfile{'YearBuilt'})
            {
               $changeProfile{'YearBuiltSource'} = $$_{'Identifier'};
               $changeProfile{'YearBuilt'} = $$_{'YearBuilt'};
            }
            else
            {
               # exception reporting - the this yearBuilt differs from the master, 
               # then a inconsistent yearBuilt exception is set
               
               if ($$masterProfile{'YearBuilt'} != $$_{'YearBuilt'})
               {
                  $inconsistentYearBuiltException = 1;
               }
            }
         }      
      }
      
      # this final pass is used to calculate the AdvertisedPrice components
      #
      # the AdvertisedPrices are permitted to change between components 
      # the NEWEST price record is always used
      # an exception is set if there's differences in the price
      $priceDecreasedException = 0;
      $priceIncreasedException = 0;
      $rentDecreasedException = 0;
      $rentIncreasedException = 0;
      # get the newest record - this was found earlier
      if ($newestProfile)
      {
         if ($$newestProfile{'AdvertisedPriceLower'})
         {
            if ($$masterProfile{'AdvertisedPriceLower'})
            {
               # check if the advertisedPriceLower has increased
               if (($$newestProfile{'AdvertisedPriceLower'}) > $$masterProfile{'AdvertisedPriceLower'})
               {
                  # price has INCREASED - use the newer price AND report an exception
                  $changeProfile{'AdvertisedPriceSource'} = $$newestProfile{'Identifier'};
                  $changeProfile{'AdvertisedPriceLower'} = $$newestProfile{'AdvertisedPriceLower'};
                  $priceIncreasedException = 1;
               }
               # check if the advertisedPriceLower has decreased
               elsif (($$newestProfile{'AdvertisedPriceLower'}) < $$masterProfile{'AdvertisedPriceLower'})
               {
                  # price has DECREASED - use the newer price AND report an exception
                  $changeProfile{'AdvertisedPriceSource'} = $$newestProfile{'Identifier'};
                  $changeProfile{'AdvertisedPriceLower'} = $$newestProfile{'AdvertisedPriceLower'};
                  $priceDecreasedException = 1;
               }
               else
               {
                  # no change in price - nothing to do here
               }
            }
            else
            {
               # the master profile didn't have this field set - set it now (no exception)
               $changeProfile{'AdvertisedPriceSource'} = $$newestProfile{'Identifier'};
               $changeProfile{'AdvertisedPriceLower'} = $$newestProfile{'AdvertisedPriceLower'};
            }
         }
         
         # same algorithm, applied to the upper price
         if ($$newestProfile{'AdvertisedPriceUpper'})
         {
            if ($$masterProfile{'AdvertisedPriceUpper'})
            {
               # check if the advertisedPriceUpper has increased
               if (($$newestProfile{'AdvertisedPriceUpper'}) > $$masterProfile{'AdvertisedPriceUpper'})
               {
                  # price has INCREASED - use the newer price AND report an exception
                  $changeProfile{'AdvertisedPriceSource'} = $$newestProfile{'Identifier'};
                  $changeProfile{'AdvertisedPriceUpper'} = $$newestProfile{'AdvertisedPriceUpper'};
                  $priceIncreasedException = 1;
               }
               # check if the advertisedPriceUpper has decreased
               elsif (($$newestProfile{'AdvertisedPriceUpper'}) < $$masterProfile{'AdvertisedPriceUpper'})
               {
                  # price has DECREASED - use the newer price AND report an exception
                  $changeProfile{'AdvertisedPriceSource'} = $$newestProfile{'Identifier'};
                  $changeProfile{'AdvertisedPriceUpper'} = $$newestProfile{'AdvertisedPriceUpper'};
                  $priceDecreasedException = 1;
               }
               else
               {
                  # no change in price - nothing to do here
               }
            }
            else
            {
               # the master profile didn't have this field set - set it now (no exception)
               $changeProfile{'AdvertisedPriceSource'} = $$newestProfile{'Identifier'};
               $changeProfile{'AdvertisedPriceUpper'} = $$newestProfile{'AdvertisedPriceUpper'};
            }
         }
      
         # same algorithm but different exception applied to the rental price
         if ($$newestProfile{'AdvertisedWeeklyRent'})
         {
            if ($$masterProfile{'AdvertisedWeeklyRent'})
            {
               # check if the advertisedWeeklyRent has increased
               if (($$newestProfile{'AdvertisedWeeklyRent'}) > $$masterProfile{'AdvertisedWeeklyRent'})
               {
                  # price has INCREASED - use the newer price AND report an exception
                  $changeProfile{'AdvertisedWeeklyRentSource'} = $$newestProfile{'Identifier'};
                  $changeProfile{'AdvertisedWeeklyRent'} = $$newestProfile{'AdvertisedWeeklyRent'};
                  $rentIncreasedException = 1;
               }
               # check if the advertisedWeeklyRent has decreased
               elsif (($$newestProfile{'AdvertisedWeeklyRent'}) < $$masterProfile{'AdvertisedWeeklyRent'})
               {
                  # price has DECREASED - use the newer price AND report an exception
                  $changeProfile{'AdvertisedWeeklyRentSource'} = $$newestProfile{'Identifier'};
                  $changeProfile{'AdvertisedWeeklyRent'} = $$newestProfile{'AdvertisedWeeklyRent'};
                  $rentDecreasedException = 1;
               }
               else
               {
                  # no change in price - nothing to do here
               }
            }
            else
            {
               # the master profile didn't have this field set - set it now (no exception)
               $changeProfile{'AdvertisedWeeklyRentSource'} = $$newestProfile{'Identifier'};
               $changeProfile{'AdvertisedWeeklyRent'} = $$newestProfile{'AdvertisedWeeklyRent'};
            }
         }
      }
      
      # update exceptions in the master

      $priceCode = 0;
      if ($priceDecreasedException)
      {
         $priceCode |= 1;
      }
      if ($priceIncreasedException)
      {
         $priceCode |= 2;
      }
      if ($rentDecreasedException)
      {
         $priceCode |= 4;
      }
      if ($rentIncreasedException)
      {
         $priceCode |= 8;
      }
      
      # determine if the exception code has changed
      if ($$masterProfile{'PriceCode'} != $priceCode)
      {
         $changeProfile{'PriceCode'} = $priceCode;
      }
      
      # --- exception codes ---
      $exceptionCode = 0;
      if ($inconsistentTypeException)
      {
         $exceptionCode |= 1;
      }
      
      if ($inconsistentBedroomsException)
      {
         $exceptionCode |= 2;
      }
      if ($inconsistentBathroomsException)
      {
         $exceptionCode |= 4;
      }
      if ($inconsistentLandAreaException)
      {
         $exceptionCode |= 8;
      }
      if ($inconsistentBuildingAreaException)
      {
         $exceptionCode |= 16;
      }
      if ($inconsistentYearBuiltException)
      {
         $exceptionCode |= 32;
      }
            
      # determine if the exception code has changed
      if ($$masterProfile{'ExceptionCode'} != $exceptionCode)
      {
         $changeProfile{'ExceptionCode'} = $exceptionCode;
      }
     
      # apply the changes (if any) to the MasterProperty
      @changes = keys %changeProfile;
      $noOfChanges = @changes;
      if ($noOfChanges > 0)
      {
         DebugTools::printHash("changeMaster", \%changeProfile);
         $success = $this->_updateMasterPropertyWithChangeHash($masterPropertyIndex, \%changeProfile);
      }
   }
   
   return $success;   
}

# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------

1;
