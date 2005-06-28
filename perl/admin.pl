#!/usr/bin/perl 
#
# History:
#  
# Description
# This script provides administration and monitoring functions for Ellamaine.  It's intended to be operated
# through CGI.  It implements the Simple Model-View-Controller.
# 
# $Revision$
# $Id$
# Started 17 June 2005


use SimpleMVC;
use LoadProperties;
use DebugTools;
use Cwd;
use SQLClient;
use Ellamaine::StatusTable;
use RegExPatterns;
use StringTools;
use AdvertisedPropertyProfiles;
use Ellamaine::Controller;

# -------------------------------------------------------------------------------------------------
# define the actions available to the Simple model view controller    
my %supportedActions = (
      'main' => \&fetchStatus,
      'regex' => \&updateRegExPatterns,
      'exceptions' => \&fetchExceptions,
      'adview' => \&fetchProfile,
      'orightml' => \&loadOriginatingHTML,
      'browse' => \&browseProperties,
      'reparse' => \&reparseOriginatingHTML
);

# -------------------------------------------------------------------------------------------------
# define the actions available to the Simple model view controller    
my %supportedViews = (
      'main' => 'admin_main.html',
      'error' => 'admin_error.html',
      'regex' => 'admin_regex.html',
      'exceptions' => 'admin_exceptions.html',
      'adview' => 'admin_adview.html',
      'orightml' => 'admin_orightml.html',
      'browse' => 'admin_browse.html',
      'reparse' => 'admin_reparse.html'
      );

# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------

# load the properties for this application
$myProperties = loadProperties('ellamaine.properties');

# create a simpleMVC for acting on the parameters
my $simpleMVC = SimpleMVC::new(\%supportedActions, 'main', \%supportedViews, 'main');

# activiate the controller - the controller will call the necessary action
$response = $simpleMVC->controller($myProperties);

if ($response)
{
   print $response;
   
   if ($simpleMVC->hadError())
   {
      print "ERROR:", $$myProperties{'simplemvc.error.description'}."<br/>";

#      DebugTools::printHash("properties", $myProperties);
   }
}
else
{
   print CGI::header();
   print "<html><body>\n";
   # if the response is blank either there was an error initialising the controller, or
   # the controller encountered an error and there was no error view defined
   DebugTools::printHash("properties", $myProperties);
   print $$myProperties{'simplemvc.error.description'}."<br/>";
   print "</body></html>";
}

# -------------------------------------------------------------------------------------------------

# this is an action callback function for the simpleMVC
# it fetches the status of Ellamaine from the database and returns the properties:
#   statustable.allocated
#
# Parameters
#   Reference to hash of custom properties
#
# Returns
#   'main' View
#
sub fetchStatus
{
   my $customProperties = shift;
   my $sqlClient = SQLClient::new();
   my $statusTable = StatusTable::new($sqlClient);
   my $orderBy = 0;
   my $reverse = 0;
   
   # determine how to order the table 
   $orderByParam = CGI::param('orderby');
   if (($orderByParam >= 0) && ($orderByParam <= 4))
   {
      $orderBy = $orderByParam;
   }
   
   $reverse = CGI::param('reverse');
   if (!defined $reverse)
   {
      $reverse = 0;
   }
   setHtmlOrderBySelect($customProperties, $orderBy);
   setHtmlReverseSelect($customProperties, $reverse);
   
   # connect to the database...
   $sqlClient->connect();
   
   # if the clearTable command is set, do a clear table operation first
   $subAction = CGI::param('subAction');
   if ($subAction)
   {
      if ($subAction =~ /clear/i)
      {
         $statusTable->clearTable();
      }
   }
   
   # fetch the status of the allocated threads
   $allocatedThreads = $statusTable->lookupAllocatedThreads($orderBy, $reverse);
   
   # allocatedThreads is a reference to a list of hashes
   # this needs to be populated into the customproperties
   # use the SimpleMVC::populateTable helper
   SimpleMVC::populateTable($customProperties, 'statustable.allocated', $allocatedThreads);
   
   $sqlClient->disconnect();
   
  # DebugTools::printHash("cp", $customProperties);
   
   return 'main';
}

# -------------------------------------------------------------------------------------------------

#sets the property html.orderby.select
sub setHtmlOrderBySelect
{
   my $customProperties = shift;
   my $orderBy = shift;   
   
   my @selected;
   
   # clear selected flag for all options, then set for the orderby state
   for ($i = 0; $i < 4; $i++)
   {
      $selected[$i] = "";
   }
   $selected[$orderBy] = "selected";

   $propertyValue =  "<select name='orderby'>".
                     "<option value='0' ".$selected[0].">Thread ID</option>".
                     "<option value='1' ".$selected[1].">Time started</option>".
                     "<option value='2' ".$selected[2].">Time last active</option>".
                     "<option value='3' ".$selected[3].">Instance ID</option></select>";
      
   $$customProperties{'html.orderby.select'} = $propertyValue;
}

# -------------------------------------------------------------------------------------------------


#sets the property html.reverse.select
sub setHtmlReverseSelect
{
   my $customProperties = shift;
   my $reverse = shift;   
   
   my @selected;
   # clear selected flag for all options, then set for the reverse state
   for ($i = 0; $i < 2; $i++)
   {
      $selected[$i] = "";
   }
   $selected[$reverse] = "selected";

   $propertyValue =  "<select name='reverse'>".
                     "<option value='0' ".$selected[0].">Ascending</option>".
                     "<option value='1' ".$selected[1].">Descending</option></select>";
      
   $$customProperties{'html.reverse.select'} = $propertyValue;
}


# -------------------------------------------------------------------------------------------------

# this is an action callback function for the simpleMVC
# it fetches the list of RegExPatterns and provides utilies to add new patterns
#
#   regexpatterns
#
# Parameters
#   Reference to hash of custom properties
#
# Returns
#   'regex' View
#
sub updateRegExPatterns
{
   my $customProperties = shift;
   my $sqlClient = SQLClient::new();
   my $regExPatterns = RegExPatterns::new($sqlClient);
   my @patternIDList;
   my %parametersHash;
   
   # check the CGI parameter
   $fieldValue = CGI::param('fieldName');
   $description = trimWhitespace(CGI::param('description'));
   $regEx = trimWhitespace(CGI::param('regEx'));
   $substitution = CGI::param('substitution');
   $aplIndex = CGI::param('aplIndex');
   $apuIndex = CGI::param('apuIndex');
   $awrIndex = CGI::param('awrIndex');
   $flag = CGI::param('flag');
   $sequenceNo = CGI::param('order');
   $subAction = CGI::param('subAction');
   
   # important: if the regEx includes the / / at the ends then strip them off
   if ($regEx =~ /^\//)
   {
      $regEx =~ s/^\///;
      
   }
   # note: for the last character, only strip of / if it isn't escaped with \
   # ie. the first patch of this expression matches any other character than \ before a / at the end
   if ($regEx =~ /[^\\]\/$/)
   {
      # this substitution is different from the check above because we don't want to replace
      # the second last letter with blank
      $regEx =~ s/\/$//g;
   }
   
   if (!$sequenceNo)
   {
      $sequenceNo = 127;  # default value
   }
   
   @parameters = CGI::param();      
   # loop through all the parameters to extract all of the patternID values 
   foreach (@parameters)
   {
      if ($_ =~ /patternID/)
      {
         push @patternIDList, CGI::param($_);
      }
   }
   
   $$customProperties{"admin.regex.msg"} = "";
   $$customProperties{"admin.error.description"} = "";

   $sqlClient->connect();

   if ($subAction =~ /add/i)
   {
      # add a new regular expression...
      if ($fieldValue)
      {
         if ($description)
         {
            if ($regEx)
            {
               $parametersHash{'FieldName'} = $fieldValue;
               $parametersHash{'RegEx'} = $regEx;
               $parametersHash{'Substitute'} = $substitution;
               $parametersHash{'APLIndex'} = $aplIndex;
               $parametersHash{'APUIndex'} = $apuIndex;
               $parametersHash{'AWRIndex'} = $awrIndex;
               $parametersHash{'Description'} = $description;
               $parametersHash{'Flag'} = $flag;
               $parametersHash{'SequenceNo'} = $sequenceNo;

               $success = $regExPatterns->addRecord(\%parametersHash);   
               if (!$success)
               {
                  $$customProperties{"admin.error"} = 1;
                  $$customProperties{"admin.error.description"} = "Failed to add the regex";
               }
               else
               {
                   $$customProperties{"admin.regx.msg"} = "record added successfully";
               }
            }
            else
            {
               $$customProperties{"admin.error"} = 1;
               $$customProperties{"admin.error.description"} = $$myProperties{'error.admin.regex.add.pattern.not.defined'};
            }
         }
         else
         {
            $$customProperties{"admin.error"} = 1;
            $$customProperties{"admin.error.description"} = $$myProperties{'error.admin.regex.add.description.not.defined'};
         }
      }
      else
      {
         $$customProperties{"admin.error"} = 1;
         $$customProperties{"admin.error.description"} = $$myProperties{'error.admin.regex.add.field.not.defined'};
      }
   }
   elsif ($subAction =~ /del/i)
   {
      $noOfPatterns = @patternIDList;
      if ($noOfPatterns > 0)
      {
         # delete selected patterns (if any)
         $recordsDeleted = 0;
         foreach (@patternIDList)
         {
            $deleted = $regExPatterns->deletePattern($_);
            if ($deleted)
            {
               $recordsDeleted++;
            }
         }
         
         $$customProperties{"admin.regx.msg"} = "$recordDeleted patterns deleted";
      }
      else
      {
         $$customProperties{"admin.error"} = 1;
         $$customProperties{"admin.error.description"} = $$myProperties{'error.admin.regex.del.patternid.not.defined'};
      }
   }
   elsif ($subAction =~ /export/i)
   {
      $success = $regExPatterns->exportTable();
      
      if ($success)
      {  
         $$customProperties{"admin.regex.msg"} = "Table exported successfully";
      }
      else
      {
         $$customProperties{"admin.error"} = 1;
         $$customProperties{"admin.error.description"} = $$myProperties{'error.admin.regex.export.failed'};
      }
   }
   elsif ($subAction =~ /import/i)
   {
      $success = $regExPatterns->importTable();
      
      if ($success)
      {  
         $$customProperties{"admin.regex.msg"} = "Table imported successfully";
      }
      else
      {
         $$customProperties{"admin.error"} = 1;
         $$customProperties{"admin.error.description"} = $$myProperties{'error.admin.regex.import.failed'};
      }
   }
   elsif ($subAction =~ /create/i)
   {
      $success = $regExPatterns->createTable();
      
      if ($success)
      {  
         $$customProperties{"admin.regex.msg"} = "Table created successfully";
      }
      else
      {
         $$customProperties{"admin.error"} = 1;
         $$customProperties{"admin.error.description"} = $$myProperties{'error.admin.regex.create.failed'};
      }
   }
   elsif ($subAction =~ /clear/i)
   {
      $success = $regExPatterns->clearTable();
      
      if ($success)
      {  
         $$customProperties{"admin.regex.msg"} = "Table cleared successfully";
      }
      else
      {
         $$customProperties{"admin.error"} = 1;
         $$customProperties{"admin.error.description"} = $$myProperties{'error.admin.regex.clear.failed'};
      }
   }
   elsif ($subAction =~ /drop/i)
   {
      $success = $regExPatterns->dropTable();
      
      if ($success)
      {  
         $$customProperties{"admin.regex.msg"} = "Table dropped successfully";
      }
      else
      {
         $$customProperties{"admin.error"} = 1;
         $$customProperties{"admin.error.description"} = $$myProperties{'error.admin.regex.drop.failed'};
      }
   }
   else
   {
      if ($subAction)
      {
         $$customProperties{"admin.error"} = 1;
         $$customProperties{"admin.error.description"} = $$myProperties{'error.admin.regex.subaction.not.recognised'};
      }
   }
   
   setHtmlRegExSelectFieldName($customProperties, $fieldValue);
      
   
   # fetch the status of the allocated threads
   $selectResults = $regExPatterns->lookupPatterns($fieldValue);
  
   # allocatedThreads is a reference to a list of hashes
   # this needs to be populated into the customproperties
   # use the SimpleMVC::populateTable helper
   SimpleMVC::populateTable($customProperties, 'regexpatterns', $selectResults);
   
   $sqlClient->disconnect();
   
  # DebugTools::printHash("cp", $customProperties);
   
   return 'regex';
}


# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------

#sets the property html.regex.fieldname.select
sub setHtmlRegExSelectFieldName
{
   my $customProperties = shift;
   my $fieldValue = shift;
   
   my @selected;
   
   # clear selected flag for all options, then set for the orderby state
   for ($i = 0; $i < 7; $i++)
   {
      $selected[$i] = "";
   }
   if (!defined $fieldValue)
   {
      $fieldValue = 0;
   }
   $selected[$fieldValue] = "selected";

   $propertyValue =  "<select name='fieldName'>".
                     "<option value='0' ".$selected[0].">All</option>".
                     "<option value='1' ".$selected[1].">SuburbName</option>".
                     "<option value='2' ".$selected[2].">StreetName</option>".
                     "<option value='3' ".$selected[3].">StreetNumber</option>".
                     "<option value='4' ".$selected[4].">UnitNumber</option>".
                     "<option value='5' ".$selected[5].">AdvertisedPriceString</option>".
                     "<option value='6' ".$selected[6].">AddressString</option></select>";
   $$customProperties{'html.regex.select.fieldname'} = $propertyValue;
}

# -------------------------------------------------------------------------------------------------

# this is an action callback function for the simpleMVC
# it fetches the exceptions reported in the database
#
#   
#
# Parameters
#   Reference to hash of custom properties
#
# Returns
#   'exceptions' View
#
sub fetchExceptions
{
   my $customProperties = shift;
   my $sqlClient = SQLClient::new();
   my $advertisedPropertyProfiles = AdvertisedPropertyProfiles::new($sqlClient);
   my %parametersHash;
   
   # check the CGI parameters
   $table = CGI::param('table');
   $offset = CGI::param('offset');
   $limit = CGI::param('limit');
   
   if ((!defined $offset) || ($offset < 1))
   {
      $offset = 0;
   }
   
   if ((!defined $limit) || ($limit < 1))
   {
      $limit = 50;
   }
  
   # process lists   
   @parameters = CGI::param();      
   # loop through all the parameters to extract all of the patternID values 
   foreach (@parameters)
   {
      if ($_ =~ /patternID/)
      {
         push @patternIDList, CGI::param($_);
      }
   }
   
   $$customProperties{"admin.exceptions.msg"} = "";
   $$customProperties{"admin.error.description"} = "";
   $$customProperties{'exceptions.table.total.rows'} = 0;
   
   $sqlClient->connect();
   $selectResults = undef;
   
   $$customProperties{'exceptions.missing.suburb.name.count'} = $advertisedPropertyProfiles->countExceptions(0);
   $$customProperties{'exceptions.missing.sale.or.rental.flag.count'} = $advertisedPropertyProfiles->countExceptions(1);
   $$customProperties{'exceptions.unknown.suburb.name.count'} = $advertisedPropertyProfiles->countExceptions(2);
   
   $$customProperties{'exceptions.selected.table.name'} = "";
   $$customProperties{'exceptions.selected.table.abbr'} = "";
   # table is to list of missing suburb names
   if ($table =~ /msn/i)
   {
      $$customProperties{'exceptions.selected.table.name'} = "Index of Missing Suburb Names";
      $$customProperties{'exceptions.selected.table.abbr'} = "msn";
      $selectResults = $advertisedPropertyProfiles->lookupProfilesByException(0, $offset, $limit);
      $$customProperties{'exceptions.table.total.rows'} = $$customProperties{'exceptions.missing.suburb.name.count'};
   }
   elsif ($table =~ /msorf/i)
   {
      $$customProperties{'exceptions.selected.table.name'} = "Index of Missing Sale or Rental Flag";
      $$customProperties{'exceptions.selected.table.abbr'} = "msorf";

      $selectResults = $advertisedPropertyProfiles->lookupProfilesByException(1, $offset, $limit);
      $$customProperties{'exceptions.table.total.rows'} = $$customProperties{'exceptions.missing.sale.or.rental.flag.count'};
   }
   elsif ($table =~ /usn/i)
   {
      $$customProperties{'exceptions.selected.table.name'} = "Index of Unknown Suburb Names";
      $$customProperties{'exceptions.selected.table.abbr'} = "usn";
      
      # fetch the status of the allocated threads
      $selectResults = $advertisedPropertyProfiles->lookupProfilesByException(2, $offset, $limit);
      $$customProperties{'exceptions.table.total.rows'} = $$customProperties{'exceptions.unknown.suburb.name.count'};
   }
   else
   {
      if ($table)
      {
         $$customProperties{"admin.error"} = 1;
         $$customProperties{"admin.error.description"} = $$myProperties{'error.admin.exceptions.table.not.recognised'};
      }
   }
   
   $$customProperties{'exceptions.table.first'} = $offset;
   $$customProperties{'exceptions.table.last'} = ($offset+$limit-1);
   $$customProperties{'exceptions.table.limit'} = $limit;
   $$customProperties{'exceptions.table.next.offset'} = $offset+$limit;
   $$customProperties{'exceptions.table.prev.offset'} = ($offset-$limit >= 0 ? $offset-$limit : 0); 

   # populate the table into the customproperties
   SimpleMVC::populateTable($customProperties, 'exceptions.table', $selectResults);
   $sqlClient->disconnect();
   
  # DebugTools::printHash("cp", $customProperties);
   
   return 'exceptions';
}

# -------------------------------------------------------------------------------------------------

# fetchProfile
# this is an action callback function for the simpleMVC
# it fetches the data for a selected profile from the AdvertisedPropertyProfiles table
#
# Parameters
#   Reference to hash of custom properties
#
# Returns
#   'adview' View
#
sub fetchProfile
{
   my $customProperties = shift;
   my $sqlClient = SQLClient::new();
   my $advertisedPropertyProfiles = AdvertisedPropertyProfiles::new($sqlClient);
   my %parametersHash;
   
   # check the CGI parameters
   $identifier = CGI::param('identifier');
   
   $$customProperties{"admin.adview.msg"} = "";
   $$customProperties{"admin.error.description"} = "";
   
   if ($identifier)
   {
      $sqlClient->connect();
      
      # lookup source data
      
      $profileRef = $advertisedPropertyProfiles->lookupSourcePropertyProfile($identifier);
    
      # transfer the profile into the custom properties
      foreach (keys %$profileRef)
      {
         $$customProperties{"SourceView.".$_} = $$profileRef{$_};
      }
      
      # lookup working view data
      
      $profileRef = $advertisedPropertyProfiles->lookupPropertyProfile($identifier);
    
      # transfer the profile into the custom properties
      foreach (keys %$profileRef)
      {
         $$customProperties{"WorkingView.".$_} = $$profileRef{$_};
      }
      
      $sqlClient->disconnect();
   }
   
  # DebugTools::printHash("cp", $customProperties);
   
   return 'adview';
}


# -------------------------------------------------------------------------------------------------

# loadOriginatingHTML
# this is an action callback function for the simpleMVC
# it fetches an OriginatingHTML file for display
#
# Parameters
#   Reference to hash of custom properties
#
# Returns
#   'orightml' View
#
sub loadOriginatingHTML
{
   my $customProperties = shift;
   my $sqlClient = SQLClient::new();
   my $originatingHTML = OriginatingHTML::new($sqlClient);
   my %parametersHash;
   
   # check the CGI parameters
   $identifier = CGI::param('identifier');
   
   # convert identifier to an integer (from a string with leading zeros)
   $originatingHTMLID = sprintf("%d", $identifier);
   
   $$customProperties{"admin.orightml.msg"} = "";
   $$customProperties{"admin.error.description"} = "";
   
   if ($identifier)
   {
      $sqlClient->connect();
      $originatingHTML->overrideBasePath("f:\\projects\\changeeffect\\originatinghtml");
      ($content, $sourceURL, $timeStamp) = $originatingHTML->readHTMLContentWithHeader($originatingHTMLID, 1);
    
      $$customProperties{'originatinghtml.identifier'} = $identifier;
      if ($content)
      {
         # transfer the content into the custom properties
         $$customProperties{'originatinghtml.content'} = $content;
         $$customProperties{'originatinghtml.sourceurl'} = $sourceURL;
         $$customProperties{'originatinghtml.timestamp'} = $timeStamp;
      }
      else
      {
         $$customProperties{"admin.error.description"} = "Failed loading OriginatingHTML file. Check path and permissions to '".$originatingHTML->targetPath($identifier)."'";
      }
      
      $sqlClient->disconnect();
   }
   
  # DebugTools::printHash("cp", $customProperties);
   
   return 'orightml';
}


# -------------------------------------------------------------------------------------------------
# browseProperties
# this is an action callback function for the simpleMVC
# it fetches the tables of properties from the database (no conditions)
#
# Parameters
#   Reference to hash of custom properties
#
# Returns
#   'browse' View
#
sub browseProperties
{
   my $customProperties = shift;
   my $sqlClient = SQLClient::new();
   my $advertisedPropertyProfiles = AdvertisedPropertyProfiles::new($sqlClient);
   my %parametersHash;
   
   # check the CGI parameters
   $offset = CGI::param('offset');
   $limit = CGI::param('limit');
   $orderByParam = CGI::param('orderby');
   $reverse = CGI::param('reverse');

   if ((!defined $offset) || ($offset < 1))
   {
      $offset = 0;
   }
   
   if ((!defined $limit) || ($limit < 1))
   {
      $limit = 50;
   }
      
   $$customProperties{"admin.exceptions.msg"} = "";
   $$customProperties{"admin.error.description"} = "";
   $$customProperties{'browse.table.total.rows'} = 0;
   
   # determine how to order the table 
   if (($orderByParam >= 0) && ($orderByParam <= 4))
   {
      $orderBy = $orderByParam;
   }
   
   if (!defined $reverse)
   {
      $reverse = 0;
   }
   
   setHtmlBrowseOrderBySelect($customProperties, $orderBy);
   setHtmlBrowseReverseSelect($customProperties, $reverse);
   
   $sqlClient->connect();
   $selectResults = undef;
   
   $$customProperties{'browse.table.name'} = "Advertised Property Profiles";
   $$customProperties{'browse.table.abbr'} = "app";
   $$customProperties{'browse.table.total.rows'} = $advertisedPropertyProfiles->countEntries();
   
   $selectResults = $advertisedPropertyProfiles->lookupSourcePropertyProfiles($orderBy, $reverse, $offset, $limit);

   $sqlClient->disconnect();
   
   $$customProperties{'browse.table.first'} = $offset;
   $$customProperties{'browse.table.last'} = ($offset+$limit-1);
   $$customProperties{'browse.table.limit'} = $limit;
   $$customProperties{'browse.table.next.offset'} = $offset+$limit;
   $$customProperties{'browse.table.prev.offset'} = ($offset-$limit >= 0 ? $offset-$limit : 0); 

   # populate the table into the customproperties
   SimpleMVC::populateTable($customProperties, 'browse.table', $selectResults);
      
   return 'browse';
}

# -------------------------------------------------------------------------------------------------

#sets the property html.browse.orderby.select
sub setHtmlBrowseOrderBySelect
{
   my $customProperties = shift;
   my $orderBy = shift;   
   
   my @selected;
   
   # clear selected flag for all options, then set for the orderby state
   for ($i = 0; $i < 5; $i++)
   {
      $selected[$i] = "";
   }
   $selected[$orderBy] = "selected";

   $propertyValue =  "<select name='orderby'>".
                     "<option value='0' ".$selected[0].">Identifier</option>".
                     "<option value='1' ".$selected[1].">Date Entered</option>".
                     "<option value='2' ".$selected[2].">Last Encountered</option>".
                     "<option value='3' ".$selected[3].">Source</option>".
                     "<option value='4' ".$selected[4].">Suburb</option></select>";
      
   $$customProperties{'html.browse.orderby.select'} = $propertyValue;
}

# -------------------------------------------------------------------------------------------------


#sets the property html.reverse.select
sub setHtmlBrowseReverseSelect
{
   my $customProperties = shift;
   my $reverse = shift;   
   
   my @selected;
   # clear selected flag for all options, then set for the reverse state
   for ($i = 0; $i < 2; $i++)
   {
      $selected[$i] = "";
   }
   $selected[$reverse] = "selected";

   $propertyValue =  "<select name='reverse'>".
                     "<option value='0' ".$selected[0].">Ascending</option>".
                     "<option value='1' ".$selected[1].">Descending</option></select>";
      
   $$customProperties{'html.browse.reverse.select'} = $propertyValue;
}


# -------------------------------------------------------------------------------------------------

# reparseOriginatingHTML
# this is an action callback function for the simpleMVC
# it performs a dry-run of the website parser for the specified originating html
#
# Parameters
#   Reference to hash of custom properties
#
# Returns
#   'reparse' View
#
sub reparseOriginatingHTML
{
   my $customProperties = shift;
   my $sqlClient = SQLClient::new();
   my $originatingHTML = OriginatingHTML::new($sqlClient);
   my %parametersHash;
   my $ellamaineController;
  
   # check the CGI parameters
   $identifier = CGI::param('identifier');
   
   # convert identifier to an integer (from a string with leading zeros)
   $originatingHTMLID = sprintf("%d", $identifier);
   
   $$customProperties{"admin.reparse.msg"} = "";
   $$customProperties{"admin.error.description"} = "";
   
   if ($identifier)
   {
      $parametersHash{'agent'} = 'admin';
      $parametersHash{'instanceID'} = 'admin';
      $parametersHash{'useText'} = 0;
      $parametersHash{'useHTML'} = 1;
      $parametersHash{'command'} = 'parse';
      $parametersHash{'parser'} = 'all';
      $parametersHash{'type'} = 'originatinghtml';
      $parametersHash{'identifier'} = $originatingHTMLID;
      $parametersHash{'basepath'} = "f:\\projects\\changeeffect\\originatinghtml";
      $parametersHash{'dryRun'} = 1;
      $ellamaineController = Controller::new($sqlClient, \%parametersHash);
      
      # IMPORTANT: override the timestamp
      #$tableObjects = $ellamaineController->getTableObjects();
      #$advertisedPropertyProfikles = $table
      $ellamaineController->start();
      
      $sqlClient->disconnect();
   }
   
  # DebugTools::printHash("cp", $customProperties);
   
   return 'orightml';
}


# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------

