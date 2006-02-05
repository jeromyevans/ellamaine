#!/usr/bin/perl
# Written by Jeromy Evans
# Started 12 July 2005 as a wrapper for the pre-existing AusPostCodes table
# 
# Description:
#   Module that encapsulate the AusPostCodes database table
#
# History:
#  12 July 2005 - previously the table existed without the need for a wrapper package.  This package has now been created
# because it's necessary to include fuctions to manually add entries to the AusPostCodes tables for localities that
# are not strictly defined by Australia Post.
#  eg. Flinders Island is not a locality (it contains it's own localities) but this name is regularly used
#
# CONVENTIONS
# _ indicates a private variable or method
# ---CVS---
# Version: $Revision$
# Date: $Date$
# $Id$
#
package AusPostCodes;
require Exporter;

use DBI;
use SQLClient;
use HTML::TreeBuilder;
use StringTools;
@ISA = qw(Exporter, SQLTable);


#@EXPORT = qw(&parseContent);

# -------------------------------------------------------------------------------------------------
# PUBLIC enumerations
#
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------

# Contructor for the AusPostCodes - returns an instance of an AusPostCodes object
# PUBLIC
sub new
{   
   my $sqlClient = shift;
   
   my $ausPostCodes = { 
      sqlClient => $sqlClient,
      tableName => "AusPostCodes",
      importPath => "./import",
      csvFileName => "pc-full_20050708.csv", 
      exportPath => "./exports",
      exportFileName => "AusPostCodes.export",
      fieldEnum => $fieldEnum
   }; 
      
   bless $ausPostCodes;     
   
   return $ausPostCodes;   # return this
}

# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# createTable
# attempts to create the AusPostCodes table in the database if it doesn't already exist
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
my $SQL_CREATE_TABLE_STATEMENT = "CREATE TABLE IF NOT EXISTS AusPostCodes ".
   "(SuburbIndex INTEGER ZEROFILL PRIMARY KEY AUTO_INCREMENT, ".  # VITAL THAT THIS NEVER CHANGES (FOREIGN KEY)
   "PostCode INTEGER, ".
   "Locality TEXT, ".
   "State TEXT, ".
   "Comments TEXT, ".
   "DeliveryOffice TEXT, ".
   "PresortIndicator INTEGER, ".
   "ParcelZone TEXT, ".
   "BSPnumber INTEGER, ".
   "BSPname TEXT, ".
   "Category TEXT, ".
   "INDEX (State(3), Locality(10)), ".
   "INDEX (Locality(10), Comments(10)))";
      
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
# adds a record of data to the AusPostCodes table
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
      # 19 June 2005 - only inserts a new record if the pattern doesn't already exist
      $quotedState = $sqlClient->quote($$parametersRef{'State'});
      $quotedPostCode = $sqlClient->quote($$parametersRef{'PostCode'});
      $quotedLocality = $sqlClient->quote($$parametersRef{'Locality'});
      $quotedComments = $sqlClient->quote($$parametersRef{'Comments'});
      
      $statementText = "SELECT * FROM AusPostCodes WHERE";
      if ($$parametersRef{'State'})
      {
         $statementText .= " State=$quotedState";
      }
      else
      {
         $statementText .= " State is null";
      }
      
      if ($$parametersRef{'PostCode'})
      {
         $statementText .= " AND PostCode=$quotedPostCode";
      }
      else
      {
         $statementText .= " AND PostCode is null";
      }
      
      if ($$parametersRef{'Locality'})
      {
         $statementText .= " AND Locality=$quotedLocality";
      }
      else
      {
         $statementText .= " AND Locality is null";
      }
      
      if ($$parametersRef{'Comments'})
      {
         $statementText .= " AND Comments=$quotedComments";
      }
      else
      {
         $statementText .= " AND Comments is null";
      }
      
      @selectResults = $sqlClient->doSQLSelect($statementText);
      $noOfResults = @selectResults;
      if ($noOfResults > 0)
      {
         # a record already exists - we absolutely do not want to add a new one
         # if the SuburbIndex is changed the whole database is corrupted.         
      }
      else
      {
        
         
         # ignore the SuburbIndex if set = this is an auto_increment number
         delete $$parametersRef{'SuburbIndex'};
        
         $statementText = "INSERT INTO AusPostCodes (";
         
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
           
            $appendString = $appendString.$sqlClient->quote($$parametersRef{$_});
            
            $index++;
         }
         $statementText = $statementText.$appendString . ")";
         
         #print "statement = ", $statementText, "\n";
        
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
my $SQL_CLEAR_TABLE_STATEMENT = "DELETE FROM AusPostCodes";
        
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
# attempts to drop the AusPostCodes table 
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
# deleteSuburbIndex
# deletes the specified suburb from the database
# 
# Parameters:
#   INTEGER SuburbIndex
#
# Returns:
#   BOOL success
#  
      
sub deleteSuburbIndex

{
   my $this = shift;
   my $suburbIndex = shift;
   my $sqlClient = $this->{'sqlClient'};
   my $success = 0;
   
   if ($sqlClient)
   {
      if ($suburbIndex)
      {
         
         $quotedSuburbIndex = $sqlClient->quote($suburbIndex);
         # load the table of validator substitutions defined in the database
         $statementText = "delete from AusPostCodes where SuburbIndex = $quotedSuburbIndex";
         
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
      @selectResults = $sqlClient->doSQLSelect("select * from AusPostCodes");
      
      $exportPath = $this->{'exportPath'};
      $exportFile = $this->{'exportFileName'};

      mkdir $exportPath, 0755;       	      
      open(SESSION_FILE, ">$exportPath/$exportFile"); 
      print SESSION_FILE "<!-- NOTE: The values in this file were html-escaped before writing using the following regular expression substitutions : \n";
      print SESSION_FILE '$data =~ s/\'/\&\#39\;/g;', "\n", '$data =~ s/"/\&quot\;/g;', "\n", '$data =~ s/</\&lt\;/g;', "\n", '$data =~ s/>/\&gt\;/g;', "\n", '$data =~ s/\n/<br\>/g;', "\n";
      print SESSION_FILE "eg. convert < into &lt etc.  Ensure they are unescaped before importing the values (reverse the substitutions) -->\n";
      
      print SESSION_FILE "<ellamaine_table name='AusPostCodes'>\n";      
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

# -------------------------------------------------------------------------------------------------
# overrideCSVFilename
# specifies the name of the CSV file containing the Australia Post Data 
# 
# Parameters:
#  STRING filename
#
# Returns:
#   Nil
#
        
sub overrideCSVFilename

{
   my $this = shift;
   my $filename = shift;
 
   $this->{'csvFileName'} = $filename;
   
}

# -------------------------------------------------------------------------------------------------
# getImportPath
# returns the name of the directory that contains import data
# 
# Parameters:
#  Nil
#
# Returns:
#   STRING directoryName
#
        
sub getImportPath

{
   my $this = shift;
 
   $importPath = $this->{'importPath'};
   
   return $importPath;   
}


# -------------------------------------------------------------------------------------------------
# importCSV
# import the content of a CSV file containing the information from Australia Post
#
# The assumed format of the file is:
#
# Fields terminated by Comma
# Fields quoted by "
# Lines terminated by \n
#
# PostCode, Locality, State, Comments, DeliveryOffice, Presort Indicator, ParcelZone, BSPnumber, BSPname, Category
#
# Parameters:
#   Nil
#
# Returns:
#   Nil
#  
sub importCSV
{
   my $this = shift;
   my $sqlClient = $this->{'sqlClient'};
   my %rowHash = undef;
   my $content = "";
   my $success = 0;
   my $firstLine = 1;
   
   if ($sqlClient)
   {    
      $importPath = $this->{'importPath'};
      $importFile = $this->{'csvFileName'};

      # read the source file...
      open(RECOVERY_FILE, "<$importPath/$importFile"); 
      # loop through the content of the file
      while (<RECOVERY_FILE>) # read a line into $_
      {
         if ($firstLine)
         {
            # skip the first line
            $thisLine = $_;
            @fieldNames = split(/,/, $thisLine);
            $firstLine = 0;
            $index = 0;
            foreach (@fieldNames)
            {
               # remove leading and trailing quotes
               $_ =~ s/^\"//g;
               $_ =~ s/\"$//g;
               $fieldNames[$index] = trimWhitespace($_);
               $index++;
            }
         }
         else
         {
            $thisLine = $_;
            @fieldValues = split(/,/, $thisLine);
            
            $index = 0;
            foreach (@fieldValues)
            {
               # remove leading and trailing quotes
               $_ =~ s/^\"//g;
               $_ =~ s/\"$//g;
               $fieldValues[$index] = trimWhitespace($_);
               $index++;
            }
            
            my %parameters;
            # transfer the field values into a hash for insertion
            $index = 0;
            foreach (@fieldNames)
            {
               $fieldName = $_;
               
               # HACK: some of the field names are hardcoded to clearer column names
               if ($fieldName =~ /Pcode/gi)
               {
                  $fieldName = "PostCode";
               }
               
               # assign the value into the hash
               $parameters{$fieldName} = $fieldValues[$index];
               $index++;
            }
            
            # the parameters hash contains all the values for insertion.  
            $this->addRecord(\%parameters);
         }
      }

      close(RECOVERY_FILE); 
      $success = 1;
   }
   
   return $success;
}



# -------------------------------------------------------------------------------------------------
# lookupPostCodes
#  Fetches a list of postcode data
#
# Parameters:
#  INTEGER OrderByEnum - enumeration specifying how to order the records
#  BOOL Reverse   - enumeration specifiy whether or not to reverse the order of the results
#  INTEGER offset  - start at Offset 
#  INTEGER limit    - limit results to Limit records
#
# Returns:
#   reference to a list of hashes of records
#        
sub lookupPostCodes

{
   my $this = shift;
   my $orderByEnum = shift;
   my $reverse = shift;
   my $offset = shift;
   my $limit = shift;
   
   my $sqlClient = $this->{'sqlClient'};
   my $tableName = $this->{'tableName'};
   my $resultRef = undef;
   
   if ($sqlClient)
   {   
      
      if ($orderByEnum == 0)
      {
         $orderBy = "SuburbIndex";
         
         # if reverse is set, add desc suffice
         if ($reverse)
         {
            $orderBy .= " DESC";
         }
      }
      elsif ($orderByEnum == 1)
      {
         $orderBy = "State, Locality";
         # if reverse is set, use desc suffix instead
         if ($reverse)
         {
            $orderBy = " State DESC, Locality";
         }
      }
      elsif ($orderByEnum == 2)
      {
         $orderBy = "Locality";
         # if reverse is set, add desc suffice
         if ($reverse)
         {
            $orderBy .= " DESC";
         }
      }
      elsif ($orderByEnum == 3)
      {
         $orderBy = "PostCode";
         # if reverse is set, add desc suffice
         if ($reverse)
         {
            $orderBy .= " DESC";
         }
      }
      else
      {
         $orderBy = "SuburbIndex";
         # if reverse is set, add desc suffice
         if ($reverse)
         {
            $orderBy .= " DESC";
         }
      }
          
      # select the threadID of the least-recently used unallocated thread
      $statementText = "SELECT * FROM $tableName ORDER BY $orderBy LIMIT $limit OFFSET $offset";
       
      # fetch the profile
      @selectResults = $sqlClient->doSQLSelect($statementText);
      $resultRef = \@selectResults;
   }
   return $resultRef;
}

1;
