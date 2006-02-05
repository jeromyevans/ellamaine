#!/usr/bin/perl
# 28 Sep 04 - derived from multiple sources
#  Contains parsers for the REIWA website to obtain advertised sales information
#
#  all parses must accept two parameters:
#   $documentReader
#   $htmlSyntaxTree
#
# The parsers can't access any other global variables, but can use functions in the WebsiteParser_Common module
# History:
#  5 December 2004 - adapted to use common AdvertisedPropertyProfiles instead of separate rentals and sales tables
# 22 January 2005  - added support for the StatusTable reporting of progress for the thread
# 23 January 2005  - added support for the SessionProgressTable reporting of progress of the thread
#                  - added check against SessionProgressTable to reject suburbs that appear 'completed' already
#  in the table.  Should prevent procesing of suburbs more than once if the server returns the same suburb under
#  multiple searches.  Note: completed indicates the propertylist has been parsed, not necessarily all the details.
# 25 May 2005      - REIWA website has undergone significant redesign
# 24 June 2005     - added support for RecordsSkipped field in status table - to track how many records
#  are deliberately skipped because they're likely to be in the db already.
#  in theory: recordsEncountered = recordsSkipped+recordsParsed
# 25 June 2005     - added support for the parser druRun flag
# 26 June 2005     - modified extraction function so it always defines local variables - was possible that 
#  the variables were set from a previous iteration
#                  - improved support for legacy records by checking for the legacy URL pattern
#                   - added support for the writeMethod parameter (a global parameter passed through the
#  documentReader) that can be set to 'add' or 'replace'.  When replace is set then the replaceRecord
#  method of AdvertisedPropertyProfiles is called instead of addRecord.  This is used when re-processing
#  old records again (ie. through an updated parser)
#                   - added support for the updateLastEncounteredIfExists function that replaces the
#  addEncounterRecord and checkIfResult exists functions - if an existing record is encountered again
#  it checks and updates the database - changes are propagated into the working view if they exist there
#  (ie. lastEncountered is propagated, and DateLastAdvertised in the MasterPropertiesTable)
# 28 June 2005     - added support for the new parser callback template that receives an HTTPClient
#  instead of just a URL.  This change was essential for this parser to access session data.
# 3 July 2005      - changed the function for a replace writeMethod slightly - when the changed profile is 
#  generated now, values that are UNDEF in the new profile are CLEARed in the profile.  Previously they
#  were retain as-is - which meant corrupt values are retains.  Reparing from the source html should completely
#  clear existing invalid values.  This almost warrant reprocessing of all source records (urgh...)
# 12 July 2005     - fixed bug in the parseSearchList function that was resulting in an infinite loop
#  if the search list contained more than 2 pages (it was posting an incorrect id value for the start
#  of the next list (the value included the previous id(s) as well as the new one.
# 5 Feb 2006       - Modified to use the new crawler architecture - the crawler has been separated from the parser 
#   and a crawler warning system has been included.
#                  - Renamed to Crawler*
#                  - Moved Parsing code out to Parser*
# ---CVS---
# Version: $Revision: 262 $
# Date: $Date: 2006-02-05 16:53:12 +1100 (Sun, 05 Feb 2006) $
# $Id: WebsiteParser_Reiwa.pm 262 2006-02-05 05:53:12Z jeromy $
#
package Parser_Reiwa;

use PrintLogger;
use CGI qw(:standard);
use HTTPClient;
use Ellamaine::HTMLSyntaxTree;
use Ellamaine::DocumentReader;
use SQLClient;
use SuburbProfiles;
#use URI::URL;
use DebugTools;
use AdvertisedPropertyProfiles;
use PropertyTypes;
use WebsiteParserTools;
use Ellamaine::StatusTable;
use Ellamaine::SessionProgressTable;
use StringTools;

require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(parseREIWASearchList parseREIWASearchForm parseREIWASearchDetails parseREIWADisplayResponse);

# -------------------------------------------------------------------------------------------------
# extractREIWAProfile
# extracts property sale information from an HTML Syntax Tree
# assumes the HTML Syntax Tree is in a very specific format
#
# Purpose:
#  parsing document text
#
# Parameters:
#   DocumentReader 
#   HTMLSyntaxTree to parse
#   String URL
#
# Constraints:
#  nil
#
# Updates:
#  Nil
#
# Returns:
#   hash containing the suburb profile.
#      
sub extractREIWAProfile
{
   my $documentReader = shift;
   my $htmlSyntaxTree = shift;
   my $url = shift;
   my $parentLabel = shift;
   my $text;
   
   my %propertyProfile;  
   my $printLogger = $documentReader->getGlobalParameter('printLogger');

   my $tablesRef = $documentReader->getTableObjects();
   my $sqlClient = $documentReader->getSQLClient();
   
      # reset standard set of attributes
   my $sourceName = undef;
   my $saleOrRentalFlag = -1;
   my $state = undef;
   my $titleString = undef;
   my $suburbNameString = undef;
   my $addressString = undef;
   my $priceString = undef;
   my $sourceID = undef;
   my $type = undef;
   my $bedrooms = undef;
   my $bathrooms = undef;
   my $landArea = undef;
   my $buidingArea = undef;   
   my $description = undef;
   my $features = undef;
   my $agencySourceID = undef;
   my $agencyName = undef;
   my $agencyAddress = undef;
   my $salesNumberText = undef;
   my $salesNumber = undef;
   my $rentalsNumberText = undef;
   my $renalsNumber = undef;
   my $fax = undef;
   my $contactName = undef;
   my $mobileNumberText = undef;
   my $mobileNumber = undef;
   my $website = undef;
   
   # first, locate the pattern that identifies the source of the record as RealEstate.com
   if ($htmlSyntaxTree->containsTextPattern("REIWA Online"))
   {
      $sourceName = 'REIWA';
   }
   
   if ($sourceName) 
   {
      $propertyProfile{'SourceName'} = $sourceName;
   }
   
   # second, locate the pattern that identifies this as a SALE record or RENT record
   # 26 May 2005 - there is a bug in the REIWA website that displays the title 'Property for Sale' even
   # for a rental listing - have to work around it by simply using the url
   if ($url =~ /Lst-ResSale/gi)
   {
      $saleOrRentalFlag = 0;
   }
   elsif ($url =~ /Lst-ResRent/gi)
   {
      $saleOrRentalFlag = 1;
   }
   
   $propertyProfile{'SaleOrRentalFlag'} = $saleOrRentalFlag;
   
   # third, locate the STATE for the property 
   # this is hardcoded
   $propertyProfile{'State'} = 'WA';
   
   # --- extract the sourceID ---
  
     
   # 26June05 - REIWA initially had a bug here in that it specified the text
   # 'Property For Sale (nnn)' on both Sale and Rental records
   # it's now been modified to 'Property (nnn)'.  Backwards compatibility is
   # being maintained as some source ID's may need reprocessing
   # extract the sourceID from the the URL
   
   $htmlSyntaxTree->setSearchStartConstraintByTagAndClass('td', 'lst-NavBar-Title');
   $sourceID = $htmlSyntaxTree->getNextTextContainingPattern("Property");
   
   $sourceID =~ s/\D//gi;  # remove non-digits
   
   if ($sourceID) 
   {
      $propertyProfile{'SourceID'} = trimWhitespace($sourceID);
   }
   
   # --- extract the price string ---
   
   $htmlSyntaxTree->resetSearchConstraints();
   $htmlSyntaxTree->setSearchStartConstraintByTagAndClass('td', 'lstv-price');
   $priceString = $htmlSyntaxTree->getNextText();
      
   if ($priceString) 
   {
      $propertyProfile{'AdvertisedPriceString'} = trimWhitespace($priceString);
   }
   
   # --- for REIWA.com.au the titleString is the priceString prefixed by Sold or Under Offer if applicable ---
   $htmlSyntaxTree->resetSearchConstraints();
   $htmlSyntaxTree->setSearchStartConstraintByTagAndClass('td', 'lstv-maincolumn', 1);
   $tagHash = $htmlSyntaxTree->getNextTagMatchingPattern('img');
   $htmlSyntaxTree->setSearchEndConstraintByTag('/td');
   $title = $$tagHash{'title'};

   if ($title =~ /Sold/gi)
   {
      $titleString = "Sold ".trimWhitespace($priceString);
   }
   elsif ($title =~ /Under/gi)
   {
      # use only the pricesString for the title
      $titleString = "Under Offer ".trimWhitespace($priceString);   
   }
   else
   {
      # use only the pricesString for the title
      $titleString = $priceString;
   }
   
   if ($titleString) 
   {
      $propertyProfile{'TitleString'} = trimWhitespace($titleString);
   }
   
   # --- extract suburb name --- 
   $htmlSyntaxTree->resetSearchConstraints();
   $htmlSyntaxTree->setSearchStartConstraintByTagAndClass('td', 'lstv-suburb');
   $suburb = $htmlSyntaxTree->getNextText();
   
   if ($suburb) 
   {
      $propertyProfile{'SuburbName'} = trimWhitespace($suburb);
   }     
   
   # --- extract address  --- 

   $htmlSyntaxTree->setSearchStartConstraintByTagAndClass('td', 'lstv-address');
   $addressString = $htmlSyntaxTree->getNextText();
   
   if ($addressString) 
   {
      $propertyProfile{'StreetAddress'} = trimWhitespace($addressString);
   }     
   
   
   # --- extract year built --- 
   
   $htmlSyntaxTree->setSearchStartConstraintByTagAndClass('td', 'lstv-featurecolumn');
   $yearBuilt = $htmlSyntaxTree->getNextTextAfterPattern('Year');
   
   if ($yearBuilt) 
   {
      $propertyProfile{'YearBuilt'} = trimWhitespace($yearBuilt);
   }     
  
   # --- extract type --- 
   
   $type = $htmlSyntaxTree->getNextTextAfterPattern('Type');
   
   if ($type) 
   {
      $propertyProfile{'Type'} = trimWhitespace($type);
   }     
   

   # --- extract bedrooms --- 
   
   $bedrooms = $htmlSyntaxTree->getNextTextAfterPattern('Bedrooms');
   
   if ($bedrooms) 
   {
      $propertyProfile{'Bedrooms'} = parseNumber($bedrooms);
   }   
   
   # --- extract bedrooms --- 
   
   $bathrooms = $htmlSyntaxTree->getNextTextAfterPattern('Bathrooms');
   
   if ($bathrooms) 
   {
      $propertyProfile{'Bathrooms'} = parseNumber($bathrooms);
   }   

   # --- extract features ---
   ################*********************##################*****************################****
   
   $htmlSyntaxTree->resetSearchConstraints();
   $htmlSyntaxTree->setSearchStartConstraintByTagAndClass('td', 'lstv-featurehead');
   $htmlSyntaxTree->setSearchStartConstraintByText('Features');
   $htmlSyntaxTree->setSearchEndConstraintByTagAndClass('td', 'lstv-contactcolumn');
   
   $features = "";
   
   # this processing of features is a little coarse - looks for an instance of three non-digit items
   # in a row to identify the start of the feature list
   # ie. the first couple of lines are bedrooms, 2, bathrooms 1, etc...
   # the $extractingFeatures flag is set once the start is found.
   $lastLine = undef;
   $secondLastLine = undef;
   $extractingFeatures = 0;
   while ($thisLine = $htmlSyntaxTree->getNextText())
   {
      #print "this:'$thisLine' (last='$lastLine') (secondLast='$secondLastLine')\n";
      if (!$extractingFeatures)
      {
         # if this line is a number...
         if ($thisLine =~ /\d/g)
         {
            # ignore this line
         }
         else
         {
            # if second last line and last line are non-digits, we're in)
            if (($secondLastLine) && ($lastLine))
            {
               if (($secondLastLine =~ /\D/g) && ($lastLine =~ /\D/g))
               {
                  # found the start of the feature list
                  $extractingFeatures = 1;
                  $features = $secondLastLine.", ".$lastLine.", ".$thisLine;
               }
            }
         }
      }
      else
      {
         # current extracting features - append this line
         
         $features = $features.", ".$thisLine;
      }
      #print "   features=$features\n";
      
      # cycle through the 3 element queue
      $secondLastLine = $lastLine;
      $lastLine = $thisLine;
   }
      
   if ($features)
   {
      $propertyProfile{'Features'} = trimWhitespace($features);
   }
   
      
   # --- extract description ---
   $htmlSyntaxTree->resetSearchConstraints();
   $htmlSyntaxTree->setSearchStartConstraintByTagAndClass('td', 'lstv-descr');
   $htmlSyntaxTree->setSearchEndConstraintByTag('/td');
   
   # may be multiple lines - get all text and append it
   $description = "";
   while ($nextLine = $htmlSyntaxTree->getNextText())
   {
      $description = $description . " " . $nextLine;
   }
      
   if ($description)
   {
      $propertyProfile{'Description'} = trimWhitespace($description);
   }
     
   # --- extract agent details ---
   
   $htmlSyntaxTree->resetSearchConstraints();
   $htmlSyntaxTree->setSearchStartConstraintByTagAndClass('td', 'lstv-repname');
   $htmlSyntaxTree->setSearchEndConstraintByTag('/td');

   $contactName = $htmlSyntaxTree->getNextText();
   $mobilePhone = $htmlSyntaxTree->getNextText();
   if (!$mobilePhone)
   {
      $mobilePhone = $htmlSyntaxTree->getNextText();  
   }
   if ($contactName) 
   {
      $propertyProfile{'ContactName'} = trimWhitespace($contactName);
   }     
  
   if ($mobilePhone) 
   {
      $propertyProfile{'MobilePhone'} = trimWhitespace($mobilePhone);
   }
   
   # --- extract agency name ---

   $htmlSyntaxTree->resetSearchConstraints();
   $htmlSyntaxTree->setSearchStartConstraintByTagAndClass('td', 'lstv-agencyname');
   $htmlSyntaxTree->setSearchEndConstraintByTag('/td');

   $agencyName = $htmlSyntaxTree->getNextText();
   if ($agencyName) 
   {
      $propertyProfile{'AgencyName'} = trimWhitespace($agencyName);
   }     
     
   # --- extract agency phone number ---

   $htmlSyntaxTree->resetSearchConstraints();
   $htmlSyntaxTree->setSearchStartConstraintByTagAndClass('td', 'lstv-agencyphone');
   $htmlSyntaxTree->setSearchEndConstraintByTag('/td');

   $contactPhone = $htmlSyntaxTree->getNextText();
 
   if ($contactPhone) 
   {
      if ($salesOrRentalFlag == 0)
      {
         $propertyProfile{'SalesPhone'} = trimWhitespace($contactPhone);
      }
      elsif ($salesOrRentalFlag == 1)
      {
          $propertyProfile{'RentalsPhone'} = trimWhitespace($contactPhone);
      }
   }     
   
   # --- extract agency website ---

   $htmlSyntaxTree->resetSearchConstraints();
   $htmlSyntaxTree->setSearchStartConstraintByTagAndClass('td', 'lstv-agencyweb');
   $htmlSyntaxTree->setSearchEndConstraintByTag('/td');

   $website = $htmlSyntaxTree->getNextAnchorContainingPattern("Visit our Website");
   if ($website) 
   {
      $propertyProfile{'Website'} = trimWhitespace($website);
   }     
   
   populatePropertyProfileHash($sqlClient, $documentReader, \%propertyProfile);
   
   #DebugTools::printHash("PropertyProfile", \%propertyProfile);
   
   return \%propertyProfile;  
}

# -------------------------------------------------------------------------------------------------
# extractLegacyREIWAProfile
# extracts property sale information from an HTML Syntax Tree
# assumes the HTML Syntax Tree is in a very specific format
#
# Purpose:
#  parsing document text
#
# Parameters:
#   DocumentReader 
#   HTMLSyntaxTree to parse
#   String URL
#
# Constraints:
#  nil
#
# Updates:
#  Nil
#
# Returns:
#   hash containing the suburb profile.
#      
sub extractLegacyREIWAProfile
{
   my $documentReader = shift;
   my $htmlSyntaxTree = shift;
   my $url = shift;
   my $text;
   my $CONTACT_NAME = 0;
   my $AGENCY_NAME = 1;
   my $PHONE_NUMBER = 2;
   my $MOBILE_NUMBER = 3;
   my $EMAIL = 4;
   my $WEBSITE = 5;
   
   my %propertyProfile;   
   # reset standard set of attributes
   my $sourceName = undef;
   my $saleOrRentalFlag = -1;
   my $state = undef;
   my $titleString = undef;
   my $suburbNameString = undef;
   my $addressString = undef;
   my $priceString = undef;
   my $sourceID = undef;
   my $type = undef;
   my $bedrooms = undef;
   my $bathrooms = undef;
   my $landArea = undef;
   my $buidingArea = undef;   
   my $description = undef;
   my $features = undef;
   my $agencySourceID = undef;
   my $agencyName = undef;
   my $agencyAddress = undef;
   my $salesNumberText = undef;
   my $salesNumber = undef;
   my $rentalsNumberText = undef;
   my $renalsNumber = undef;
   my $fax = undef;
   my $contactName = undef;
   my $mobileNumberText = undef;
   my $mobileNumber = undef;
   my $website = undef;
   
   # first, locate the pattern that identifies the source of the record as RealEstate.com
   if ($htmlSyntaxTree->containsTextPattern("1st Place ILS"))
   {
      $sourceName = 'REIWA';
   }
   
   if ($sourceName) 
   {
      $propertyProfile{'SourceName'} = $sourceName;
   }

   # second, locate the pattern that identifies this as a SALE record or RENT record
   # if the RENT is specified in the initial sections, then assume it's a rental record   
   $htmlSyntaxTree->setSearchEndConstraintByText("Email For More Information");
   if ($htmlSyntaxTree->containsTextPattern('Rent'))
   {
      $saleOrRentalFlag = 1;
   }
   else
   {
      $saleOrRentalFlag = 0;
   }
   
   $propertyProfile{'SaleOrRentalFlag'} = $saleOrRentalFlag;
   
   # --- set start constraint to the 3rd table (table 2) on the page - this is table
   # --- across the top that MAY contain a title and description
               
   $htmlSyntaxTree->resetSearchConstraints();
   $htmlSyntaxTree->setSearchConstraintsByTable(2);
   $htmlSyntaxTree->setSearchEndConstraintByTag("td"); # until the next table
                    
   $IDSuburbPrice = $htmlSyntaxTree->getNextText();    # always set
   
   #--- followed by optional 'under offer' - ignored
   
   $htmlSyntaxTree->setSearchStartConstraintByTag("tr");  # next row of table   
   $htmlSyntaxTree->setSearchEndConstraintByTag("table");    
   $title = $htmlSyntaxTree->getNextText();            # sometimes undef     
   
   $description = $htmlSyntaxTree->getNextText();      # sometimes undef
  
   if ($description)
   {
      $propertyProfile{'Description'} = $description;
   }
  
   ($sourceID, $suburb, $priceString) = split(/\-/, $IDSuburbPrice, 3);
   
   if ($sourceID)
   {
      $propertyProfile{'SourceID'} = trimWhitespace($sourceID);
   }
   
   if ($suburb) 
   {
      $propertyProfile{'SuburbName'} = $suburb;
   }
     
   if ($priceString) 
   {
      $propertyProfile{'AdvertisedPriceString'} = trimWhitespace($priceString);
   }
   
   $titleString = $priceString;
   if ($titleString) 
   {
      $propertyProfile{'TitleString'} = trimWhitespace($titleString);
   }
   
   
   # --- set start constraint to the 4th table on the page - this is table
   # --- to the right of the image that contains parameters for the property   
   $htmlSyntaxTree->setSearchConstraintsByTable(3);
   $htmlSyntaxTree->setSearchEndConstraintByTag("table"); # until the next table
   
   $type = $htmlSyntaxTree->getNextText();             # always set
   
   if ($type)
   {
      $propertyProfile{'Type'} = $type;
   }
   
   $bedrooms = $htmlSyntaxTree->getNextTextContainingPattern("Bedrooms");    # sometimes undef     
   if ($bedrooms)
   {
      $propertyProfile{'Bedrooms'} = parseNumber($bedrooms);
   }
   
   $bathrooms = $htmlSyntaxTree->getNextTextContainingPattern("Bath");       # sometimes undef
   if ($bathrooms)
   {
      $propertyProfile{'Bathrooms'} = parseNumber($bathrooms);
   }
   
   $land = $htmlSyntaxTree->getNextTextContainingPattern("sqm");             # sometimes undef
   ($crud, $land) = split(/:/, $land);   
   if ($land)
   {
      $propertyProfile{'LandArea'} = $land;
   }
   
   $yearBuilt = $htmlSyntaxTree->getNextTextContainingPattern("Age:");      # sometimes undef
   ($crud, $yearBuilt) = split(/:/, $yearBuilt);
   
   if ($yearBuilt)
   {
      $propertyProfile{'YearBuilt'} = trimWhitespace($yearBuilt);
   }
   
   # --- set the start constraint back to the top of the page and tje "for More info" label
   $htmlSyntaxTree->resetSearchConstraints();
            
   $addressString = $htmlSyntaxTree->getNextTextAfterPattern("Address:");
   
   if ($addressString)
   {
      $propertyProfile{'StreetAddress'} = $addressString;
   }
   
   # --- extract features ---
   $htmlSyntaxTree->setSearchStartConstraintByTag("blockquote");
   $htmlSyntaxTree->setSearchEndConstraintByText("For More Information");
   
   # may be multiple lines - get all text and append it   
     
   $features = "";
   $firstLine = 1;
   while ($nextLine = $htmlSyntaxTree->getNextText())
   {
      if (!$firstLine)
      {
          $features .= ", ";
      }
      else
      {
         $firstLine = 0;
      }
      $features .= $nextLine;
   }
      
   if ($features)
   {
      $propertyProfile{'Features'} = trimWhitespace($features);
   }

   $propertyProfile{'State'} = 'WA';  
   
    # --- set the start constraint back to the top of the page and tje "for More info" label
   $htmlSyntaxTree->resetSearchConstraints();
   if ($htmlSyntaxTree->setSearchStartConstraintByText("For More Information Contact:"))
   {
   
      # run a simple state machine to get the parameters
      $state = $CONTACT_NAME;
      $finished = 0;
      # loop until all lines are processed, or the website is extracted
      # text will be skipped if it doesn't look right
      while (($thisText = $htmlSyntaxTree->getNextText()) && (!$finished))
      {
         #print "$state: $thisText\n";
         $usedThisText = 0;
         if ($state == $CONTACT_NAME)
         {
            $contactName = $thisText;
            
            $state = $AGENCY_NAME;
            $usedThisText = 1;    
         }
         if (($state == $AGENCY_NAME) && (!$usedThisText))
         {
            $agencyName = $thisText;
            $usedThisText = 1;
            $state = $PHONE_NUMBER;
         }
         if (($state == $PHONE_NUMBER) && (!$usedThisText))
         {
            # if this text contains numbers
            if ($thisText =~ /\d/g)
            {
               $phoneNumber = $thisText;
               $phoneNumber =~ s/\D//g;        # remove non-digits
               $usedThisText = 1;
               $state = $MOBILE_NUMBER;
            }
            else
            {
               # this isn't a phone number...is it email?
               $state = $EMAIL;
            }
         }
         if (($state == $MOBILE_NUMBER) && (!$usedThisText))
         {
            # if this text contains numbers
            if ($thisText =~ /\d/g)
            {
               $mobileNumber = $thisText;
               $mobileNumber =~ s/\D//g;        # remove non-digits
               $usedThisText = 1;
               $state = $EMAIL;
            }
            else
            {
               # this isn't a phone number...is it email?
               # drop through to next check
            }
         }
            
         # Note the OR for entry into this check
         # Will not enter if state=EMAIL and usedThisText is set
         if ((($state == $EMAIL) && (!$usedThisText)) || (!$usedThisText))
         {
            # if this text contains numbers
            if ($thisText =~ /\@/g)
            {
               $email = $thisText;
               $usedThisText = 1;
               $state = $WEBSITE;
            }
            else
            {
               # this isn't an email....is it website?
               # drop through to next check
            }
         }
         
         # Note the OR for entry into this check    
         # Will not enter if state=WEBSITE and usedThisText is set
         if ((($state == $WEBSITE) && (!$usedThisText)) || (!$usedThisText))
         {
            # if this text contains numbers
            if ($thisText =~ /\.com/g)
            {
               $website = $thisText;
               $usedThisText = 1;
               $finished = 1;
            }
            else
            {
               # this isn't a website - skip this line
            }
         }
         
      }
   }
   
   if ($contactName)
   {
      $propertyProfile{'ContactName'} = $contactName;
   }
   
   if ($agencyName)
   {
      $propertyProfile{'AgencyName'} = $agencyName;
   }
   
   if ($phoneNumber)
   {
      if ($saleOrRentalFlag == 1)
      {
         $propertyProfile{'RentalsPhone'} = $phoneNumber;
      }
      else
      {
         $propertyProfile{'SalesPhone'} = $phoneNumber;
      }
   }
   
   if ($mobileNumber)
   {
      $propertyProfile{'MobilePhone'} = $mobileNumber;
   }
   
   if ($website)
   {
      $propertyProfile{'Website'} = $website;
   }
   
   
   populatePropertyProfileHash($sqlClient, $documentReader, \%propertyProfile);
   #DebugTools::printHash("PropertyProfile", \%propertyProfile);
        
   return \%propertyProfile;  
}

# -------------------------------------------------------------------------------------------------
# parseREIWASearchDetails
# parses the htmlsyntaxtree to extract advertised sale information and insert it into the database
#
# Purpose:
#  construction of the repositories
#
# Parameters:
#  DocumentReader
#  HTMLSyntaxTree to use
#  String URL
#
# Constraints:
#  nil
#
# Updates:
#  database
#
# Returns:
#  a list of HTTP transactions or URL's.
#    

sub parseREIWASearchDetails

{	
   my $documentReader = shift;
   my $htmlSyntaxTree = shift;
   my $httpClient = shift;
   my $instanceID = shift;
   my $transactionNo = shift;
   my $threadID = shift;
   my $parentLabel = shift;
   my $dryRun = shift;
   my $useLegacyExtraction = 0;
   my $url = $httpClient->getURL();

   my $sqlClient = $documentReader->getSQLClient();
   my $tablesRef = $documentReader->getTableObjects();
   
   my $advertisedPropertyProfiles = $$tablesRef{'advertisedPropertyProfiles'};
   my $originatingHTML = $$tablesRef{'originatingHTML'};  # 27Nov04

   my $sourceName = $documentReader->getGlobalParameter('source');
   my $printLogger = $documentReader->getGlobalParameter('printLogger');
   $statusTable = $documentReader->getStatusTable();

   $printLogger->print("in REIWA:parseSearchDetails ($parentLabel)\n");
   # 3July tighter check for legacy REIWA (see test case 17155 - previously used "map' which is optional on the page) 
   if (($url =~ /searchdetails\.cfm/) && ($htmlSyntaxTree->containsTextPattern("Save")) && 
       (($htmlSyntaxTree->containsTextPattern("Suburb Profile")) || ($htmlSyntaxTree->containsTextPattern("Map")) || ($htmlSyntaxTree->containsTextPattern("Print"))))
   {
      # this is a legacy REIWA record - a different extraction process needs to be followed
      $useLegacyExtraction = 1;
   }
   
   # two possible entry patterns - NEW and LEGACY
   if (($htmlSyntaxTree->containsTextPattern("View Property Details")) || ($useLegacyExtraction))
   {
      # extract parameters from the page
      
      if (!$useLegacyExtraction)
      {
         # --- now extract the property information for this page ---
         # parse the HTML Syntax tree to obtain the advertised sale information
         $propertyProfile = extractREIWAProfile($documentReader, $htmlSyntaxTree, $url, $parentLabel);
      }
      else
      {
         $propertyProfile = extractLegacyREIWAProfile($documentReader, $htmlSyntaxTree, $url, $parentLabel);
      }

      if ($sqlClient->connect())
      {		 	
         # 26 June 2005 - check the DocumentReader parameters to see whether the parser
         # should ADD new records or REPLACE old records
         $writeMethod = $documentReader->getGlobalParameter('writeMethod');
     
         if ($writeMethod =~ /add/i)
         {
            # the following functions write to the database - only call if not in a dryRun
            if (!$dryRun)
            {
               # check if this profile already exists - if it does, update the LastEncountered timestamp
               # if it doesn't exist, then add a new record
             
               if ($advertisedPropertyProfiles->updateLastEncounteredIfExists($$propertyProfile{'SaleOrRentalFlag'}, $$propertyProfile{'SourceName'}, $$propertyProfile{'SourceID'}, $$propertyProfile{'Checksum'}, $$propertyProfile{'TitleString'}, $$propertyProfile{'AdvertisedPriceString'}))
               {
                  $printLogger->print("   parseSearchDetails: updated LastEncountered for existing record.\n");
                  $statusTable->addToRecordsParsed($threadID, 1, 0, $url);
               }
               else
               {
                  $printLogger->print("   parseSearchDetails: adding new record.\n");
                  $identifier = $advertisedPropertyProfiles->addRecord($propertyProfile, $url, $htmlSyntaxTree);
                  $statusTable->addToRecordsParsed($threadID, 1, 1, $url);
               }   
            }
         }
         elsif ($writeMethod =~ /replace/i)
         {
            # the REPLACE record writemethod is set - 
            $originatingHTMLID = $documentReader->getGlobalParameter('identifier');
            if ($originatingHTMLID)
            {
               # get the identifier for the record created by the originating HTML
               $existingProfile = $advertisedPropertyProfiles->lookupSourcePropertyProfileByOriginatingHTML($originatingHTMLID);
               
               $identifier = $$existingProfile{'Identifier'};
               if ($identifier)
               {
                  $printLogger->print("   parseSearchDetails: replacing record (id:$identifier).\n");  
                
                  %changeProfile = $advertisedPropertyProfiles->calculateChangeProfileRetainVitals($existingProfile, $propertyProfile);
                  if (!$dryRun)
                  {
                     # a record has been specified to replace with this profile
                     if (!$advertisedPropertyProfiles->replaceRecord(\%changeProfile, $identifier))
                     {
                        $printLogger->print("      parseSearchDetails: no changes necessary.\n");
                     }
                  }
               }
               else
               {
                  $printLogger->print("   parseSearchDetails: replace requested but can't find record created by originatingHTML (id:$identifier).\n");  
               }
            }
            else
            {
               $printLogger->print("   parseSearchDetails: 'writeMethod' REPLACE requested but 'identifier' not specified\n");
            }
         }
         else
         {
            $printLogger->print("   parseSearchDetails: 'writeMethod'($writeMethod) not recognised\n");
         }
      }
      else
      {
         $printLogger->print("   parseSearchDetails:", $sqlClient->lastErrorMessage(), "\n");
      }
   }
   else
   {
      $printLogger->print("   parseSearchDetails: page identifier not found\n");
   }
   
   # return an empty list
   return @emptyList;
}

# -------------------------------------------------------------------------------------------------

