#!/usr/bin/perl
# 28 Sep 04 - derived from multiple sources
#  Contains common website parser functions 
##
# The parsers can't access any other global variables, but can use functions in the WebsiteParser_Common module
# ---CVS---
# Version: $Revision$
# Date: $Date$
# $Id$
#
# History:
#  27Nov04 - renamed validateProfile to tidyRecord - still performs the exact  function as the previously 
#   but renamed to reflect changed intent - better validation occurs later in the processing thread now
#   and all changes are tracked, but this original process couldn't be removed as it would have reset
#   all existing cached records (they'd all differ if not tidied up before creating the record, resulting in 
#   near duplicates)
#  28Nov04 - started developing the validateRecord function that performs some sophisticated validation 
#   of records.  It uses the Validator_RegExSubstitutions table that specifies regex patterns to apply
#   to different fields in the records, plus performs some brute-force suburb name look-ups.
#  5 December 2004 - adapted to use common AdvertisedPropertyProfiles instead of separate rentals and sales tables
# 23 January 2005 - added function isSuburbNameInRange as this bit of code was commonly used by all parses to 
#  determine if the suburbname was in the letter-range specified though parameters
# 13 March 2005 - disabled use of PropertyTypes table (typeIndex) as it's being re-written to better support 
#  analysis.  It actually performed no role here (the mapPropertyType function returned null in all cases).
# 20 May 2005 - major update
#             - added populatePropertyProfileHash that includes common code for populating the hash, then tidying it
#  up and calculating the checksum.  This is needed for the re-architecting to combine sales and rentals.
# 16 June 2005 - renamed to WebsiteParserTools (for a moment decided to make this a superclass for WebsiteParsers
#   but have since decided that's not necessary)
# 18 June 2005 - migrated some functions that were related to fixing records over to the AdvertisedPropertyProfile
# package 
# 5 Feb 2006 - renamed to CrawlerTools.  Now only used by the crawlers in the new architecture.
package CrawlerTools;

use CGI qw(:standard);
use Ellamaine::HTMLSyntaxTree;
use Ellamaine::DocumentReader;
use HTTPClient;
use PrintLogger;
use SQLClient;
use SuburbProfiles;
use DebugTools;
use AdvertisedPropertyProfiles;
use StringTools;
use PrettyPrint;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(isSuburbNameInRange extractOnlyParentName);

# -------------------------------------------------------------------------------------------------

# this function compares the name to a range of letters and returns true if it's inside the range
# used when limiting the search to a letter-range
sub isSuburbNameInRange                     
{
   my $suburbName = shift;
   my $startLetter = shift;
   my $endLetter = shift;
   my $acceptSuburb = 1;
   
   #($firstChar, $restOfString) = split(//, $_->{'text'});
   #print $_->{'text'}, " FC=$firstChar ($startLetter, $endLetter) ";
   $acceptSuburb = 1;
   if ($startLetter)
   {                              
      # if the start letter is defined, use it to constrain the range of 
      # suburbs processed
      # if the first letter if less than the start then reject               
      if ($suburbName le $startLetter)
      {
         # out of range
         $acceptSuburb = 0;
         #print $_->{'text'}, " out of start range (start=$startLetter)\n";
      }                              
   }
              
   if ($endLetter)
   {               
      # if the end letter is defined, use it to constrain the range of 
      # suburbs processed
      # if the first letter is greater than the end then reject       
      if ($suburbName ge $endLetter)
      {
         # out of range
         $acceptSuburb = 0;
         #print "'", $_->{'text'}, "' out of end range (end='$endLetter')\n";
      }               
   }
   return $acceptSuburb;
}  
# -------------------------------------------------------------------------------------------------

# the parsers are given a string that represents its hierarchy in the processing chain
# this function returns the name of the parent only
sub extractOnlyParentName
{
   my $parentLabel = shift;
   my $parentName = undef;
   
   @splitLabel = split /\./, $parentLabel;
   $parentName = $splitLabel[$#splitLabel];  # extract the last name from the parent label

   return $parentName;
}
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
1;
