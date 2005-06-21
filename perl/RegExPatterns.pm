#!/usr/bin/perl
# Written by Jeromy Evans
# Started 27 November 2004
# 
# WBS: A.01.03.01 Developed On-line Database
# Version 0.0  
#
# Description:
#   Module that encapsulate the RegExPatterns database table
#
# History:
#   19 June 2005 - extended so the table contains patterns for extracting fields from a pattern as well as performing substitutions
#                - renamed to RegExPatterns (was RegExPatterns)
#
# CONVENTIONS
# _ indicates a private variable or method
# ---CVS---
# Version: $Revision$
# Date: $Date$
# $Id$
#
package RegExPatterns;
require Exporter;

use DBI;
use SQLClient;
use HTML::TreeBuilder;

@ISA = qw(Exporter, SQLTable);


#@EXPORT = qw(&parseContent);

# -------------------------------------------------------------------------------------------------
# PUBLIC enumerations
#
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------

# Contructor for the RegExPatterns - returns an instance of an RegExPatterns object
# PUBLIC
sub new
{   
   my $sqlClient = shift;
   
   my $fieldEnum = {
      1 => "SuburbName", 
      2 => "StreetName", 
      3 => "StreetNumber", 
      4 => "UnitNumber", 
      5 => "AdvertisedPriceString", 
      6 => "AddressString"
   };
   
   
   my $regExPatterns = { 
      sqlClient => $sqlClient,
      tableName => "RegExPatterns",
      exportPath => "./exports",
      exportFileName => "RegExPatterns.export", 
      fieldEnum => $fieldEnum
   }; 
      
   bless $regExPatterns;     
   
   return $regExPatterns;   # return this
}

# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# createTable
# attempts to create the RegExPatterns table in the database if it doesn't already exist
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
my $SQL_CREATE_TABLE_STATEMENT = "CREATE TABLE IF NOT EXISTS RegExPatterns ".
   "(DateEntered DATETIME NOT NULL, ".
   "PatternID INTEGER ZEROFILL PRIMARY KEY AUTO_INCREMENT, ".
   "FieldName TEXT, ".
   "RegEx TEXT, ".
   "Substitute TEXT, ".
   "APLIndex INTEGER, ".
   "APUIndex INTEGER, ".
   "AWRIndex INTEGER, ".
   "Description TEXT, ".
   "Flag INTEGER, ".
   "SequenceNo INTEGER DEFAULT 127)";
      
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
         
         # add default records - if the table already exists this section isn't entered, otherwise
         # duplicates would be created for these default patterns

         #$this->addRecord('SuburbName', '^Mt\W', 'Mount ', undef, undef, undef, 'Convert Mt to Mount');         
         #$this->addRecord('SuburbName', '\WUnder Offer', ' ', undef, undef, undef, 'Remove \'Under Offer\' from suburb name');
         #$this->addRecord('SuburbName', '\WOffers From', ' ', undef, undef, undef, 'Remove \'Offers From\' from the suburb name');
         #$this->addRecord('SuburbName', '\WOffer From', ' ', undef, undef, undef, 'Remove \'Offer From\' from the suburb name');
         #$this->addRecord('SuburbName', '\WOffers Above', ' ', undef, undef, undef, 'Remove \'Offers Above\' from the suburb name');
         #$this->addRecord('SuburbName', '\WDeposit Taken', ' ', undef, undef, undef, 'Remove \'Depoit Taken\' from the suburb name');
         #$this->addRecord('SuburbName', '\WSold\s', ' ', undef, undef, undef, 'Remove \'Sold-space\' from the suburb name');
         #$this->addRecord('SuburbName', '\WSold$', ' ', undef, undef, undef, 'Remove \'Sold\' from the end of the suburb name');
         #$this->addRecord('SuburbName', '\WOffers In Excess Of', ' ', undef, undef, undef, 'Remove \'Offers In Excess Of\' from the suburb name');
         #$this->addRecord('SuburbName', '\WPrice start From', ' ', undef, undef, undef, 'Remove \'Price start From\' from the suburb name');
         #$this->addRecord('SuburbName', '\WNegotiate', ' ', undef, undef, undef, 'Remove \'Negotiate\' from the suburb name');
         #$this->addRecord('SuburbName', '\WPriced From', ' ', undef, undef, undef, 'Remove \'Priced From\' from the suburb name');
         #$this->addRecord('SuburbName', '\WPrice From', ' ', undef, undef, undef, 'Remove \'Price From\' from the suburb name');
         #$this->addRecord('SuburbName', '\WBuyers From', ' ', undef, undef, undef, 'Remove \'Buyers From\' from the suburb name');
         #$this->addRecord('SuburbName', '\WBidding From', ' ', undef, undef, undef, 'Remove \'Bidding From\' from the suburb name');
         #$this->addRecord('SuburbName', '\WBids From', ' ', undef, undef, undef, 'Remove \'Bids From\' from the suburb name');
         #$this->addRecord('SuburbName', '\WApprox', ' ', undef, undef, undef, 'Remove \'Approx\' from the suburb name');
         #$this->addRecord('SuburbName', '\WFrom\s', ' ', undef, undef, undef, 'Remove \'From\' from the suburb name');
         #$this->addRecord('SuburbName', '\WFrom$', ' ', undef, undef, undef, 'Remove \'From\' from the end of suburb name');
#       
         #$this->addRecord('Street', '\WRd$',  ' Road ', undef, undef, undef, 'Convert Rd to Road');                
         #$this->addRecord('Street', '\WSt$',  ' Street ', undef, undef, undef, 'Convert St to Street');         
         #$this->addRecord('Street', '\WAve$', ' Avenue ', undef, undef, undef, 'Convert Ave to Avenue');         
         #$this->addRecord('Street', '\WAv$', ' Avenue ', undef, undef, undef, 'Convert Av to Avenue');         
         #$this->addRecord('Street', '\WPl$',  ' Place ', undef, undef, undef, 'Convert Pl to Place');         
         #$this->addRecord('Street', '\WDr$',  ' Drive ', undef, undef, undef, 'Convert Dr to Drive');         
         #$this->addRecord('Street', '\WDve$',  ' Drive ', undef, undef, undef, 'Convert Dve to Drive');         
         #$this->addRecord('Street', '\WHwy$',  ' Highway ', undef, undef, undef, 'Convert Hwy to Highway');         
         #$this->addRecord('Street', '\WCt$',  ' Court ', undef, undef, undef, 'Convert Ct to Court');         
         #$this->addRecord('Street', '\WCl$',  ' Close ', undef, undef, undef, 'Convert Cl to Close');         
         #$this->addRecord('Street', '\WPd$',  ' Parade ', undef, undef, undef, 'Convert Pd to Parade');         
         #$this->addRecord('Street', '\WPde$',  ' Parade ', undef, undef, undef, 'Convert Pde to Parade');         
         #$this->addRecord('Street', '\WWy$',  ' Way ', undef, undef, undef, 'Convert Wy to Way');         
         #$this->addRecord('Street', '\WCres$',  ' Crescent ', undef, undef, undef, 'Convert Cres to Crescent');         
         #$this->addRecord('Street', '\WCresent$',  ' Crescent ', undef, undef, undef, 'Correct spelling of Crescent');         
         #$this->addRecord('Street', '\WCrt$',  ' Court ', undef, undef, undef, 'Convert Ctr to Court');         
         #$this->addRecord('Street', '\WCir$',  ' Circle ', undef, undef, undef, 'Convert Cir to Circle');         
         #$this->addRecord('Street', '^Cnr\s', ' Corner ', undef, undef, undef, 'Convert Cnr to Corner');         
         #$this->addRecord('Street', '\WBlvd$', ' Boulevard ', undef, undef, undef, 'Convert Blvd to Boulevard');         
         #$this->addRecord('Street', '\WBlvde$', ' Boulevard ', undef, undef, undef, 'Convert Bvlde to Boulevard');         
         #$this->addRecord('Street', '\WGrds$', ' Gardens ', undef, undef, undef, 'Convert Grds to Gardens');         
         #$this->addRecord('Street', '\WPkwy$', ' Parkway ', undef, undef, undef, 'Convert Pkwy to Parkway');         
         #$this->addRecord('Street', '\WTce$', ' Terrace ', undef, undef, undef, 'Convert Tce to Terrace');         
         #$this->addRecord('Street', '[\W]*Under Offer', ' ', undef, undef, undef, 'Remove Under Offer from street name');         
         #$this->addRecord('Street', '[\W]*Sale By Negotiation', ' ', undef, undef, undef, 'Remove Sale By Negotiation from street name');         
         #$this->addRecord('Street', '[\W]*Price On Application', ' ', undef, undef, undef, 'Remove Price On Application from street name');         
         #$this->addRecord('Street', '[\W]*Sale By Negotiation', ' ', undef, undef, undef, 'Remove Sale By Negotiation from street name');         
         #$this->addRecord('Street', '[\W]*Auction', ' ', undef, undef, undef, 'Remove Auction from street name');         
         #$this->addRecord('Street', '[\W]*Bedrooms', ' ', undef, undef, undef, 'Remove Bedrooms from street name');         
         #$this->addRecord('Street', '[\W]*Bathrooms', ' ', undef, undef, undef, 'Remove Bathrooms from street name');         
         #$this->addRecord('Street', '[\W]*Add To Shortlist', ' ', undef, undef, undef, 'Remove Add To Shortlist from street name');         
#         
         #$this->addRecord('StreetNumber', 'Prop[\d|\s]*', ' ', undef, undef, undef, 'Remove Prop<number> from Street number');
      }
   }
   
   return $success;   
}

# -------------------------------------------------------------------------------------------------
# addRecord
# adds a record of data to the RegExPatterns table
# 
# Purpose:
#  Storing information in the database
#
# Parameters:
#  string FieldName   
#  string RegEx       - pattern to match
#  string Substitute  - pattern to substitute
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
      # special - check if the fieldName is simple an enumeration - if it is convert it to text
      $textFieldName = $this->mapFieldNameFromEnum($$parametersRef{'FieldName'});
      if ($textFieldName)
      {
         $$parametersRef{'FieldName'} = $textFieldName;
      }
      
      # 19 June 2005 - only inserts a new record if the pattern doesn't already exist
      $quotedFieldName = $sqlClient->quote($$parametersRef{'FieldName'});
      $quotedRegEx = $sqlClient->quote($$parametersRef{'RegEx'});
      
      $statementText = "SELECT PatternID, FieldName, RegEx, APLIndex, APUIndex, AWRIndex, SequenceNo FROM RegExPatterns WHERE FieldName = $quotedFieldName AND RegEx = $quotedRegEx";
      @selectResults = $sqlClient->doSQLSelect($statementText);
      $noOfResults = @selectResults;
      if ($noOfResults > 0)
      {
         
         $firstResult = $selectResults[0];
         # check the other attributes of the pattern to see if it matches (note some fields are ignored (such as description)
         if (($$firstResults{'APLIndex'} == $$parametersRef{'APLIndex'}) &&
             ($$firstResults{'APUIndex'} == $$parametersRef{'APUIndex'}) &&
             ($$firstResults{'AWRIndex'} == $$parametersRef{'AWRIndex'}) &&
             ($$firstResults{'SequenceNo'} == $$parametersRef{'SequenceNo'}))
         {
            # this pattern already exists - REPLACE the existing record (delete the existing one)
         
            $success = $this->deletePattern($$firstResult{'PatternID'});
         }
         else
         {
            $success = 1;
         }
      }
      else
      {
         $success = 1;
      }
      
      if ($success)
      {
      
         $useLocalTime = 0;
         # if the date entered isn't set, use localtime()
         if (!defined $$parametersRef{'DateEntered'})
         {
            $$parametersRef{'DateEntered'} = "localtime()";
            $useLocalTime = 1;
         }
         
         # ignore the PatternID = this is an auto_increment number
         delete $$parametersRef{'PatternID'};
        
         $statementText = "INSERT INTO RegExPatterns (";
         
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
         }
      }
   }
   
   return $success;   
}

# -------------------------------------------------------------------------------------------------

# converts the enumeration into a text field name
sub mapFieldNameFromEnum

{
   my $this = shift;
   my $fieldValue = shift;
   my $fieldName = undef;
   my $fieldEnum = $this->{'fieldEnum'};
   
   foreach (keys %$fieldEnum)
   {
      if ($fieldValue == $_)
      {
         # found a match
         $fieldName = $$fieldEnum{$_};
         last;
      }
   }
   
   return $fieldName;
}
      

# -------------------------------------------------------------------------------------------------

# makes sure the fieldName is valid
sub checkFieldName

{
   my $this = shift;
   my $fieldValue = shift;
   my $okay = 0;
   
   my $fieldEnum = $this->{'fieldEnum'};
   
   foreach (keys %$fieldEnum)
   {
      if ($fieldValue eq $$fieldEnum{$_})
      {
         # found a match
         $okay = 1;
         last;
      }
   }
   
   return $okay;
}
      

# -------------------------------------------------------------------------------------------------
# lookupPatterns
# get the full list of patterns
# 
# Purpose:
#
# Parameters:
#   Nil
#
# Updates:
#  nil
#
# Returns:
#   reference to a list of hashes
#     
sub lookupPatterns

{
   my $this = shift;
   my $fieldValue = shift;
   my $sqlClient = $this->{'sqlClient'};
   my $whereConstraint = "";
   
   if ($sqlClient)
   {
      if ($fieldValue)
      {
         
         $fieldName = $this->mapFieldNameFromEnum($fieldValue);
         if ($fieldName)
         {
            $whereConstraint = "WHERE FieldName = '$fieldName'";
         }
         else
         {
            if ($this->checkFieldName($fieldValue))
            {
               # no mapping - use fieldValue
               $whereConstraint = "WHERE FieldName = '$fieldValue'";
            }
         }
      }

      # load the table of validator substitutions defined in the database
      @selectResults = $sqlClient->doSQLSelect("select * from RegExPatterns $whereConstraint ORDER BY SequenceNo");
      
      $regExPatterns = \@selectResults;
   }
   
   return $regExPatterns;   
}

# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------

# clearTable
# deletes all table contents
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
my $SQL_CLEAR_TABLE_STATEMENT = "DELETE FROM RegExPatterns";
        
sub clearTable

{
   my $this = shift;
   my $success = 0;
   my $sqlClient = $this->{'sqlClient'};
   
   if ($sqlClient)
   {
      $statement = $sqlClient->prepareStatement($SQL_CLEAR_TABLE_STATEMENT);
      
      if ($sqlClient->executeStatement($statement))
      {
	      $success = 1;
      }
   }
   
   return $success;   
}


# -------------------------------------------------------------------------------------------------
# dropTable
# attempts to drop the RegExPatterns table 
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
# deletePattern
# deletes the specified pattern from the database
# 
# Purpose:
#
# Parameters:
#   Nil
#
# Updates:
#  nil
#
# Returns:
#   reference to a list of hashes
#  
      
sub deletePattern

{
   my $this = shift;
   my $patternID = shift;
   my $sqlClient = $this->{'sqlClient'};
   my $success = 0;
   
   if ($sqlClient)
   {
      if ($patternID)
      {
         
         $quotedPatternID = $sqlClient->quote($patternID);
         # load the table of validator substitutions defined in the database
         $statementText = "delete from RegExPatterns where PatternID = $quotedPatternID";
         
         # prepare and execute the statement
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
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------


# -------------------------------------------------------------------------------------------------
# exportTable
# export the content of the table into a psuedo-style xml file
# 
# Parameters:
#   Nil
#
# Returns:
#   Nil
#  
sub exportTable
{
   my $this = shift;
   my $sqlClient = $this->{'sqlClient'};
   my $success = 0;
   
   if ($sqlClient)
   {  
      @selectResults = $sqlClient->doSQLSelect("select * from RegExPatterns");
      
      $exportPath = $this->{'exportPath'};
      $exportFile = $this->{'exportFileName'};

      mkdir $exportPath, 0755;       	      
      open(SESSION_FILE, ">$exportPath/$exportFile"); 
      print SESSION_FILE "<!-- NOTE: The values in this file were html-escaped before writing using the following regular expression substitutions : \n";
      print SESSION_FILE '$data =~ s/\'/\&\#39\;/g;', "\n", '$data =~ s/"/\&quot\;/g;', "\n", '$data =~ s/</\&lt\;/g;', "\n", '$data =~ s/>/\&gt\;/g;', "\n", '$data =~ s/\n/<br\>/g;', "\n";
      print SESSION_FILE "eg. convert < into &lt etc.  Ensure they are unescaped before importing the values (reverse the substitutions) -->\n";
      
      print SESSION_FILE "<ellamaine_table name='RegExPatterns'>\n";      
      foreach (@selectResults)
      {
         $rowHash = $_;
         @tableColumns = keys %$rowHash;
         print SESSION_FILE "<ellamaine_row>";
         # loop through all the values in this column
         foreach (@tableColumns)
         {
            $columnName = $_;
            $escapedValue = escapeHTML($$rowHash{$columnName});
            # note: the name= attribute is included so that the case of the letters is protected - the import
            # function converts tagnames to lowercase so this avoids it - not the best approach though
            print SESSION_FILE "<$columnName name='$columnName'>", $escapedValue,"</$columnName>"; 
         }
         print SESSION_FILE "</ellamaine_row>\n";
      }
            
      print SESSION_FILE "</ellamaine_table>\n";
      close(SESSION_FILE);

      $success = 1;
   }
   
   return $success;
}

# -------------------------------------------------------------------------------------------------

my $_currentInstance;

# -------------------------------------------------------------------------------------------------

sub escapeHTML
{
   my $data = shift;
   
   $data =~ s/'/\&\#39\;/g;
   $data =~ s/"/\&quot\;/g;
   $data =~ s/</\&lt\;/g;
   $data =~ s/>/\&gt\;/g;
   $data =~ s/\n/<br\>/g;
   
   return $data;
}

# -------------------------------------------------------------------------------------------------

sub unescapeHTML
{
   my $data = shift;
   
   $data =~ s/\&\#39\;/'/g;  
   $data =~ s/\&quot\;/"/g;
   $data =~ s/\&lt\;/</g;
   $data =~ s/\&gt\;/>/g;
   $data =~ s/<br\>/\n/g;
   
   return $data;
}

# -------------------------------------------------------------------------------------------------
# importTable
# import the content of a psuedo-style xml file into the table
# 
# Parameters:
#   Nil
#
# Returns:
#   Nil
#  
sub importTable
{
   my $this = shift;
   my $sqlClient = $this->{'sqlClient'};
   my %rowHash = undef;
   my $content = "";
   my $success = 0;
   
   if ($sqlClient)
   {    
      $exportPath = $this->{'exportPath'};
      $exportFile = $this->{'exportFileName'};

      # read the source file...
      open(RECOVERY_FILE, "<$exportPath/$exportFile"); 
      # loop through the content of the file
      while (<RECOVERY_FILE>) # read a line into $_
      {
         $content .= $_;
      }

      close(RECOVERY_FILE); 
      
      if ($content)
      {
         my $treeBuilder = HTML::TreeBuilder->new();
         $treeBuilder->implicit_tags(0);    # disable implicit tags (this isn't an html file)
         $treeBuilder->ignore_unknown(0);   # enable non-html tags

         $treeBuilder->parse($content);
         
         # the currentInstance is used by the callback function as the callback
         # isn't within this object instance 
         $_currentInstance = $this;   
   
         # start traversing the tags in the file
         $treeBuilder->traverse(\&_importer_callBack, 0);
            
         # detroy the tree builder - it includes self-references that won't be garbage collected!
         $treeBuilder->delete;
         
         $success = 1;
      }
   }
   
   return $success;
}

# -------------------------------------------------------------------------------------------------
# call back function for the importer operation.  This method is called once for
# each element in input file
# accepts an HTML::Element, boolean startFlag and a integer depth
# PRIVATE
sub _importer_callBack
{
   my $currentElement = shift;  # reference to HTML::Element, or just a string
   my $startFlag = shift;       # true if entering an element
   my $depth = shift;           # depth within the tree
   my $isTag = 1;
   my $traverseChildElements = 1;
   my $href = undef;         # set for anchors
   my $tagName;
   my $textIndex;
   
   # TODO 22/2/04 this will cause problems under multithreading - instead need
   # to create an instance of the callback for this object instance (this is sharing
   # a global variable for this package)
   my $this = $_currentInstance;
   
   # first thing to do is query the reference to determine if this
   # is a tag or text
   if (!ref($currentElement))
   {
      # this isn't an element reference - it's actual text
      $isTag = 0;      
   }
   
   if ($isTag)
   {
      # this element is a tag...
      #   record the tag name, a reference to the HTML::Element and the current index      
      $tagName = $currentElement->tag();
      if ($tagName =~ /ellamaine_table/)
      {
         if ($startFlag)
         {
            $this->{'inTableFlag'} = 1;
            $this->{'importTableName'} = $currentElement->attr('name');
         }
         else
         {
            $this->{'inTableFlag'} = 0;
         }
      }
      elsif ($tagName =~ /ellamaine_row/)
      {
         if ($startFlag)
         {
            # this is the start of a new row
            my %newHash;
            $this->{'currentRowHash'} = \%newHash;  # clear the current row data
         }
         else
         {
            if ($this->{'inTableFlag'})
            {
               # this is the end of a row - add to the table
              #DebugTools::printHash("addRow", $this->{'currentRowHash'});
              $currentRowHash = $this->{'currentRowHash'};
              
              # add this record to the database              
              $success = $this->addRecord($currentRowHash);   
            }
         }
      }
      else
      {
         if ($startFlag)
         {
            $this->{'inColumnFlag'} = 1;
            $this->{'importColumnName'} = $currentElement->attr("name");
         }
         else
         {
            $this->{'inColumnFlag'} = 0;
            if ($this->{'importColumnName'})
            {
               $currentRowHash = $this->{'currentRowHash'};
               $$currentRowHash{$this->{'importColumnName'}} = $this->{'importColumnValue'};
               #print $currentRowHash{$this->{'importColumnName'}},"=",$this->{'importColumnValue'},"\n";
               # clear values
               $this->{'importColumnName'} = "";
               $this->{'importColumnValue'} = "";
            }
         }
      }
   }
   else
   {
      # this is text - probably a column value
      $text = $currentElement;
      if (($this->{'inTableFlag'}) && ($this->{'inColumnFlag'}))
      {
         # prepare to include this value in the row hash
         $this->{'importColumnValue'} = unescapeHTML($text);
      }
   }
      
   return $traverseChildElements;    
}

1;
