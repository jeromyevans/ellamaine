#!/usr/bin/perl
# 2 Oct 04 - derived from multiple sources
#  Contains parsers for the Domain website to obtain advertised sales information
#
#  all parses must accept two parameters:
#   $documentReader
#   $htmlSyntaxTree
#
# The parsers can't access any other global variables, but can use functions in the WebsiteParser_Common module
# ---CVS---
# Version: $Revision: 262 $
# Date: $Date: 2006-02-05 16:53:12 +1100 (Sun, 05 Feb 2006) $
# $Id: WebsiteParser_Domain.pm 262 2006-02-05 05:53:12Z jeromy $
#
# 26 Oct 04 - significant re-architecting to return to the base page and clear cookies after processing each
#  region - the theory is that it will allow NSW to be completely processed without stuffing up the 
#  session on domain server.
# 27 Oct 04 - had to change the way suburbname is extracted by looking up name in the postcodes
#  list (only way it can be extracted from a sentance now).  
#   Loosened the way price is extracted to get the cache check working where price contained a string
# 8 November 2004 - updates the way the details page is parsed to catch some variations between pages
#   - descriptions over multiple text entries are concatinated
#   - improved the code extracting the address that sometimes got the wrong text
# 27 Nov 2004 - saves the HTML content that's used in the OriginatingHTML database and updates a CreatedBy foreign key 
#   pointing back to that OriginatingHTML record
# 5 December 2004 - adapted to use common AdvertisedPropertyProfiles instead of separate rentals and sales tables
# 22 January 2005  - added support for the StatusTable reporting of progress for the thread
#                  - added support for the SessionProgressTable reporting of progress of the thread
#                  - added check against SessionProgressTable to reject suburbs that appear 'completed' already
#  in the table.  Should prevent procesing of suburbs more than once if the server returns the same suburb under
#  multiple searches.  Note: completed indicates the propertylist has been parsed, not necessarily all the details.
# 25 April  2005   - modified parsing of search results to ignore 'related results' returned by the search engine
# 20 May 2005      - major change
#                  - modified to use new architecture that combines common sales and rentals processing
# 23 May 2005      - major change so that the parses don't have to do anything clever with the address string, 
#  price or suburbname - these are all processed in common code
# 24 June 2005     - added support for RecordsSkipped field in status table - to track how many records
#  are deliberately skipped because they're likely to be in the db already.
#  in theory: recordsEncountered = recordsSkipped+recordsParsed
# 25 June 2005     - added support for the parser dryRun flag
# 26 June 2005     - modified extraction function so it always defines local variables - was possible that 
#  the variables were set from a previous iteration
#                   - added support for the writeMethod parameter (a global parameter passed through the
#  documentReader) that can be set to 'add' or 'replace'.  When replace is set then the replaceRecord
#  method of AdvertisedPropertyProfiles is called instead of addRecord.  This is used when re-processing
#  old records again (ie. through an updated parser)
#                   - added support for the updateLastEncounteredIfExists function that replaces the
#  addEncounterRecord and checkIfResult exists functions - if an existing record is encountered again
#  it checks and updates the database - changes are propagated into the working view if they exist there
#  (ie. lastEncountered is propagated, and DateLastAdvertised in the MasterPropertiesTable)
# 28 June 2005     - added support for the new parser callback template that receives an HTTPClient
#  instead of just a URL.
# 3 July 2005      - found another legacy domain variant - made modifications to the extraction function (testcase18879)
#                  - changed the function for a replace writeMethod slightly - when the changed profile is 
#  generated now, values that are UNDEF in the new profile are CLEARed in the profile.  Previously they
#  were retain as-is - which meant corrupt values are retains.  Reparing from the source html should completely
#  clear existing invalid values.  This almost warrant reprocessing of all source records (urgh...)
# 28 Aug 2005      - Domain property details page has been redesigned slightly changing the way suburbname
#  has to be extracted.  Now performs an additional check to see if the page is the new variant
# 5 Feb 2006       - Modified to use the new crawler architecture - the crawler has been separated from the parser 
#   and a crawler warning system has been included.
#                  - Renamed to Crawler*
#                  - Moved Parsing code out to Parser*
package Parser_Domain;

use PrintLogger;
use CGI qw(:standard);
use HTTPClient;
use SQLClient;
use SuburbProfiles;
#use URI::URL;
use DebugTools;
use Ellamaine::HTMLSyntaxTree;
use Ellamaine::DocumentReader;
use AdvertisedPropertyProfiles;
use PropertyTypes;
use WebsiteParserTools;
use OriginatingHTML;
use Ellamaine::StatusTable;
use Ellamaine::SessionProgressTable;
use StringTools;
use PrettyPrint;
use CrawlerWarning;

require Exporter;
@ISA = qw(Exporter);


# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# extractDomainProfile
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
sub extractDomainProfile
{
   my $documentReader = shift;
   my $htmlSyntaxTree = shift;
   my $url = shift;
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
   
   # first, locate the pattern that identifies the source of the record as DOMAIN
   # 20 May 05
   if ($htmlSyntaxTree->containsTextPattern("domain\.com\.au"))
   {
      $sourceName = 'Domain';
   }
   
   if ($sourceName) 
   {
      $propertyProfile{'SourceName'} = $sourceName;
   }
   
   # determine if these are RENT or SALE results
   # This needs to be obtained from one of the URLs in the page
   $anchorList = $htmlSyntaxTree->getAnchorsContainingPattern("Back to Search Results");
   $anchor = $$anchorList[0];
   if ($anchor)
   {
      # the state follows the state= parameter in the URL
      # matched pattern is returned in $1;
      $anchor =~ /mode=(\w*)\&/gi;
      $mode=$1;

      # convert to uppercase as it's used in an index in the database
      $mode =~ tr/[a-z]/[A-Z]/;
      if ($mode eq 'BUY')
      {
         $saleOrRentalFlag = 0;
      }
      elsif ($mode eq 'RENT')
      {
         $saleOrRentalFlag = 1;
      }
      else
      {
         # SOMETIMES it's blank!  Try the pattern below
      }
   }
   if ($saleOrRentalFlag == -1)
   {
      # 27 June 2005 - legacy records don't have this link
      if (($htmlSyntaxTree->containsTextPattern("Property For Sale")) || ($htmlSyntaxTree->containsTextPattern("Auction")))
      {
         $saleOrRentalFlag = 0;
      }
      else
      {
         if ($htmlSyntaxTree->containsTextPattern("For Rent"))
         {
            $saleOrRentalFlag = 1;
         }
      }
   }
   
   $propertyProfile{'SaleOrRentalFlag'} = $saleOrRentalFlag;
   
   # third, locate the STATE for the property 
   # This ALSO needs to be obtained from one of the URLs in the page
   $backURL = $$anchorList[0];
   if ($backURL)
   {
      # the state follows the state= parameter in the URL
      # matched pattern is returned in $1;
      $backURL =~ /\&state=(\w*)\&/gi;
      $state=$1;

      # convert to uppercase as it's used in an index in the database
      $state =~ tr/[a-z]/[A-Z]/;
   }
   else
   {
      # some legacy records contain no indication of the state in the text or urls
      # it appears in some javascript but that's not available for parsing.
      # later, the agency address may give an indication...
   }
 
   if ($state)
   {
      $propertyProfile{'State'} = $state;
   }
   
   # --- extract the title string ---- 
   # (this is used to match searchresults)
   
   # get the suburb name out of the <h1> heading
   #first word(s) is suburb name, then price or
   $htmlSyntaxTree->resetSearchConstraints();
   #Ella45 28August05 - The domain site has been redesigned to place the suburb name within 
   # a div after a section that provides search information - it's no longer the first h1 on the page.   
   if ($htmlSyntaxTree->setSearchStartConstraintByTagAndClass("div", "propdetails-address"))
   {      
      # next text is the titlestring (which contains suburbName)
   }
   else
   {
      # original variant - first h1 on the page is the suburb name
      $htmlSyntaxTree->setSearchStartConstraintByTag("h1");
   }
   $titleString = $htmlSyntaxTree->getNextText();
   
   if ($titleString)
   {
      $propertyProfile{'TitleString'} = trimWhitespace($titleString);
   }
   
   # --- extract the suburb name ---   
   # get the suburb name out of the <h1> heading
   $suburbAndPriceString = $titleString;
   
   # remove any price information from the string...
   ($suburbNameString, $crud) = split(/\$/, $suburbAndPriceString, 2);
   $suburbNameString = trimWhitespace($suburbNameString);
    
   if ($suburbNameString) 
   {
      $propertyProfile{'SuburbName'} = $suburbNameString;
   }
   
   # ---- extract the address ----
   
   $htmlSyntaxTree->resetSearchConstraints();
   if ($htmlSyntaxTree->setSearchStartConstraintByTag("h2"))
   {
   
      $firstLine = $htmlSyntaxTree->getNextText();            # usually suburb and price string (used above)
      $addressString = $firstLine;
      
      # if the address contains the text bedrooms, bathrooms, car spaces or Add to Shortlist then reject it
      # if the address is blank, sometimes the next pattern is variable
      if ($addressString =~ /Bedrooms|Bathrooms|Car Spaces|Add to shortlist/i)
      {
         $addressString = undef;
      }
   }    
   
   if ($addressString) 
   {
      $propertyProfile{'StreetAddress'} = $addressString;
   }
   
   # --- extract price ---
   
   $htmlSyntaxTree->resetSearchConstraints();
   if (!$htmlSyntaxTree->setSearchStartConstraintByTag("h2"))
   {
      # 3 July 05: try a different variant - after the 'Property For x' text
      $htmlSyntaxTree->setSearchStartConstraintByText("Property For");
   }
   if (!$htmlSyntaxTree->setSearchEndConstraintByText("Latest Auction"))
   {
      # 3 July 05: try a different variant that uses the copyright message at the bottom of the page
      $htmlSyntaxTree->setSearchEndConstraintByText("Copyright");
   }
   
   # if this is a SALE record...
   if ($saleOrRentalFlag == 0)
   {
      $priceString = $htmlSyntaxTree->getNextTextAfterPattern("Price:");
   }
   else
   {
      if ($saleOrRentalFlag == 1)
      {
         $priceString = $htmlSyntaxTree->getNextTextAfterPattern("Rent:");      
      }
   }

   $priceString = trimWhitespace($priceString);      

   
   if ($priceString) 
   {
      $propertyProfile{'AdvertisedPriceString'} = $priceString;
   }
   
   # --- extract source ID ---

   $sourceID = trimWhitespace($htmlSyntaxTree->getNextTextAfterPattern("Property ID:"));
   
   if ($sourceID)
   {
      $propertyProfile{'SourceID'} = $sourceID;
   }
   else
   {
      # if the sourceID couldn't be obtained from the page, it's possible this is a LEGACY domain record
      # (only encountered when parsing archives).  Attempt to get the sourceID from the url
      $sourceID = $url;
      # extract from the adid=nnn parameter if possible
      $sourceID =~ /adid=(\d*)/gi;
      $sourceID = $1;
      
      if ($sourceID)
      {
         $propertyProfile{'SourceID'} = $sourceID;
      }
   }
   
   # --- extract property type ---
   
   #3 July 2005 - introduced a while loop here to try a few lines to get the type

   # sometimes there's other information before the type
   # TYPE is assumed to be the FIRST USEFUL information after PRICE and Property ID 
   $typeSet = 0;
   $noOfTries = 0;
   
   while ((!$typeSet) && ($noOfTries < 5))
   {
      $type = trimWhitespace($htmlSyntaxTree->getNextText());  # always set (contains at least TYPE)
   
      # look for the next type: line
      if ($type =~ /(.+)\:/g)
      {   
         $type = $1;
         # 27 June 2005: if type is 'Land Area' type is "Land"
         if ($type =~ /Land\sarea/i)
         {
            $type = 'land';
         }
         $typeSet = 1;
      }
      # always break out if unsuccessful after a few tries
      $noOfTries++;
   }
   
   if ($type)
   {
      $propertyProfile{'Type'} = $type;
   }
   
   # --- extract bedrooms and bathrooms ---
   
   $infoString = trimWhitespace($htmlSyntaxTree->getNextText());
   $bedroomsString = undef;
   $bathroomsString = undef;
   
   @wordList = split(/ /, $infoString);
   # 'x' bedrooms
   # 'y' bathrooms
   $index = 0;
   foreach (@wordList)
   {
      if ($_)
      {
         # if this is the bedrooms word, the preceeding word is the number of them
         if ($_ =~ /bedroom/i)
         {
            if ($index > 0)
            {              
               $bedroomsString = $wordList[$index-1];
            }
         }
         else
         {
            # if this is the bedrooms word, the preceeding word is the number of them
            if ($_ =~ /bathroom/i)
            {
               if ($index > 0)
               {
                  $bathroomsString = $wordList[$index-1];
               }
            }
         }
      }
      $index++;
   }
   
   $bedrooms = strictNumber(parseNumber($bedroomsString));
   $bathrooms = strictNumber(parseNumber($bathroomsString));

   # 3Jul05: another frigg'n domain variation - the bedrooms is sometimes after the text 'Bedrooms:'
   if (!$bedrooms)
   {
      $htmlSyntaxTree->resetSearchConstraints();
      $htmlSyntaxTree->setSearchEndConstraintByText("Description");
      $bedText = $htmlSyntaxTree->getNextTextAfterPattern("Bedrooms:");
      $bedrooms = strictNumber(parseNumber($bedText));
   }
   
   # 3Jul05: another frigg'n domain variation - the bathrooms is sometimes after the text 'Bathrooms:'
   if (!$bathrooms)
   {
      $htmlSyntaxTree->resetSearchConstraints();
      $htmlSyntaxTree->setSearchEndConstraintByText("Description");

      $bathText = $htmlSyntaxTree->getNextTextAfterPattern("Bathrooms:");
      $bathrooms = strictNumber(parseNumber($bathText));
   }
   
   if ($bedrooms)
   {
      $propertyProfile{'Bedrooms'} = $bedrooms;
   }
   
   if ($bathrooms)
   {
      $propertyProfile{'Bathrooms'} = $bathrooms;
   }
   
   # --- extract land area ---
   $htmlSyntaxTree->resetSearchConstraints();
   $landArea = $htmlSyntaxTree->getNextTextAfterPattern("area:");  # optional
   
   if ($landArea)
   {
      $propertyProfile{'LandArea'} = $landArea;
   }
      
   # --- extract building area ---

   if ($buidingArea)
   {
      $propertyProfile{'BuildingArea'} = $buildingArea;
   }
   
   # --- extract description ---
   
   # 8 Nov 04 - concatenate description (same as done for features)
   $htmlSyntaxTree->resetSearchConstraints();
   
   if ($htmlSyntaxTree->setSearchStartConstraintByText("Description"))
   {
      # 26 June 05 - this is the contraint in the current design - it also apears in the
      # legacy design though, so its applied first...
      if ($htmlSyntaxTree->setSearchEndConstraintByTagAndClass("div", "propdetails-emailagentbox"))
      {
         # then try the second constraint as well (it'll only work if it's before the one above)
         # (this is based on the legacy design of the page)
         $htmlSyntaxTree->setSearchEndConstraintByTagAndClass("div", "auction-results");
      }
      else
      {
         # another legacy variation - simply stop at the end of the table following the description
         $htmlSyntaxTree->setSearchEndConstraintByTag("/table");
      }
      
      # append all text in the features section
      $description = undef;
      while ($nextPara = $htmlSyntaxTree->getNextText())
      {
         if ($description)
         {
            $description .= " ";
         }
         
         $description .= $nextPara;
      }
      $description = trimWhitespace($description);   
   }
  
   if ($description)
   {
      $propertyProfile{'Description'} = $description;
   }
   
   # --- extract features ---
   
   $htmlSyntaxTree->resetSearchConstraints();
   if (($htmlSyntaxTree->setSearchStartConstraintByText("Features")) && ($htmlSyntaxTree->setSearchEndConstraintByText("Description")))
   {
      # append all text in the features section
      $features = undef;
      while ($nextFeature = $htmlSyntaxTree->getNextText())
      {
         if ($features)
         {
            $features .= ", ";
         }
         
         $features .= $nextFeature;
      }
      $features = trimWhitespace($features);
      
   }
   
   if ($features)
   {
      $propertyProfile{'Features'} = $features;
   }     
   
   # --- extract agent details ---- 
   
   $htmlSyntaxTree->resetSearchConstraints();
   
   # ------- get company name and link to the main page --------
   
   $anchorList = $htmlSyntaxTree->getAnchorsAndTextByID('_ctl0__ctl0_Advertiserdetails1_hlnkAgency');
   if ($anchorList)
   {
      $agentDetailsHRef = $$anchorList[0]{'href'};
      $agencyName = $$anchorList[0]{'string'};
      $agencySourceID = $agentDetailsHRef;
      $agencySourceID =~ /\&agencyid=(\w*)\&/gi;
      $agencySourceID = $1;
      
      #print "agentDetailsHRef:$agentDetailsHRef\n";
      #print "agencyName:$agencyName\n";
      #print "agencySourceID = $agencySourceID\n"; 
   }   
     

   # ------- Get ADDRESS and PHONE NUMBERS ------
   my $ADDRESS = 0;
   my $SALES_NUMBER = 1;
   my $RENTALS_NUMBER = 2;
   my $MOBILE_NUMBER = 3;
   my $CONTACT = 4;

   $htmlSyntaxTree->resetSearchConstraints();
   $agencyAddress="";
   if (($htmlSyntaxTree->setSearchStartConstraintByTagAndID('span', '_ctl0__ctl0_Advertiserdetails1_lblAgencyAddress')) &&
       ($htmlSyntaxTree->setSearchEndConstraintByTag('/span')))
   {
      
      $currentState = $ADDRESS;   # fetching address
      while ($text = $htmlSyntaxTree->getNextText())
      {
#         print "$text\n";
         if ($text =~ /Sales\:/gi)
         {
            $currentState = $SALES_NUMBER;
            $salesNumberText = $text;
            $salesNumberText =~ s/\D//gi;         # delete non-digits
         }
         elsif ($text =~ /Rentals\:/gi)
         {
            $currentState = $RENTALS_NUMBER;
            $rentalsNumberText = $text;
            $rentalsNumberText =~ s/\D//gi;    # delete non-digits
         }
         
         if ($currentState == $ADDRESS)
         {
            $agencyAddress = $agencyAddress ." ". $text;
         }
      }
      $agencyAddress = trimWhitespace($agencyAddress);
      
#      print "agencyAddress:$agencyAddress\n";
#      print "salesNo:$salesNumberText\n";
#      print "rentalsNo:$rentalsNumberText\n";
   }
   
   # -------- Get more agent contact details -------
   
   $htmlSyntaxTree->resetSearchConstraints();
   $contactName = "";
   if (($htmlSyntaxTree->setSearchStartConstraintByTagAndID('table', '_ctl0__ctl0_Advertiserdetails1_dlContacts')) &&
       ($htmlSyntaxTree->setSearchEndConstraintByTag('/table')))
   {  
      $currentState = $CONTACT;   # fetching address
      while ($text = $htmlSyntaxTree->getNextText())
      {
#         print "$text\n";
         if ($text =~ /Contact/gi)
         {
            $text = "";   # skip
         }
         elsif ($text =~ /Mobile\:/gi)
         {
            $currentState = $MOBILE_NUMBER;
            $mobileNumberText = $text;
            $mobileNumberText =~ s/\D//gi;         # delete non-digits
         }
         elsif ($text =~ /Sales\:|Rentals\:|Phone\:/gi)
         {
            $text = "";  # skip
         }
         
         if ($currentState == $CONTACT)
         {
            $contactName = $contactName ." ". $text;
         }
      }
      $contactName = trimWhitespace($contactName);
      
#      print "contactName:$contactName\n";
#      print "mobileNo:$mobileNumberText\n";
   }
 
   if ($agencySourceID)
   {
      $propertyProfile{'AgencySourceID'} = $agencySourceID;
   }
   
   if ($agencyName)
   {
      $propertyProfile{'AgencyName'} = $agencyName;
   }
   
   if ($agencyAddress)
   {
      $propertyProfile{'AgencyAddress'} = $agencyAddress;
   }
   
   if ($salesNumberText)
   {
      $propertyProfile{'SalesPhone'} = $salesNumberText;
   }
   
   if ($rentalsNumberText)
   {
      $propertyProfile{'RentalsPhone'} = $rentalsNumberText;
   }
   
   if ($fax)
   {
      $propertyProfile{'Fax'} = $fax;
   }
   
   if ($contactName)
   {
      $propertyProfile{'ContactName'} = $contactName;
   }
   
   if ($mobileNumberText)
   {
      $propertyProfile{'MobilePhone'} = $mobileNumberText;
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
# parseDomainPropertyDetails
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
sub parseDomainPropertyDetails

{	
   my $documentReader = shift;
   my $htmlSyntaxTree = shift;
   my $httpClient = shift;
   my $instanceID = shift;
   my $transactionNo = shift;
   my $threadID = shift; 
   my $parentLabel = shift;
   my $dryRun = shift;
   my $url = $httpClient->getURL();

   my $sqlClient = $documentReader->getSQLClient();
   my $tablesRef = $documentReader->getTableObjects();
   my $printLogger = $documentReader->getGlobalParameter('printLogger');
   my $sourceName = $documentReader->getGlobalParameter('source');

   my $advertisedPropertyProfiles = $$tablesRef{'advertisedPropertyProfiles'};
   my $originatingHTML = $$tablesRef{'originatingHTML'};  # 27Nov04
   
   $statusTable = $documentReader->getStatusTable();

   $printLogger->print("in Domain:parsePropertyDetails ($parentLabel)\n");
     
   if ($htmlSyntaxTree->containsTextPattern("Property Details"))
   {                                         
      # parse the HTML Syntax tree to obtain the advertised sale information
      $propertyProfile = extractDomainProfile($documentReader, $htmlSyntaxTree, $url);
          
      # CRITICAL - if the sourceID isn't set, then it's probable that this is an LEGACY DOMAIN record
      # it can't be parsed in this version
      if (($$propertyProfile{'SourceID'}) && ($$propertyProfile{'SourceName'}))
      {
      
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
               $printLogger->print("   parsePropertyDetails: 'writeMethod'($writeMethod) not recognised\n");
            }
         }
         else
         {
            $printLogger->print("   parsePropertyDetails:", $sqlClient->lastErrorMessage(), "\n");
         }
      }
      else
      {
         $printLogger->print("   parsePropertyDetails: FAILED to parse DOMAIN record at $url\n");
      }
   }
   else
   {
      $printLogger->print("   parsePropertyDetails:property details not found.\n");      
   }
   
   
   # return an empty list
   return @emptyList;
}

# -------------------------------------------------------------------------------------------------

