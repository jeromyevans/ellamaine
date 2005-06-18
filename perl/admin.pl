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

# -------------------------------------------------------------------------------------------------
# define the actions available to the Simple model view controller    
my %supportedActions = (
      'main' => \&fetchStatus
);

# -------------------------------------------------------------------------------------------------
# define the actions available to the Simple model view controller    
my %supportedViews = (
      'main' => 'admin_main.html',
      'error' => 'admin_error.html'
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

