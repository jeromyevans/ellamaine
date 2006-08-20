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
# Version: $Revision$
# Date: $Date$
# $Id$
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
#                  - Modified to use the AdvertisementCache instead of AdvertisedPropertyProfiles
# 20 Aug 2006      - Modified crawler for changes to the Domain website.  Most changes were superficial (same urls)
#   except for some restructuring in the results page
#
package Crawler_Domain;

use PrintLogger;
use CGI qw(:standard);
use HTTPClient;
use SQLClient;
use DebugTools;
use Ellamaine::HTMLSyntaxTree;
use Ellamaine::DocumentReader;
use Ellamaine::StatusTable;
use Ellamaine::SessionProgressTable;
use CrawlerTools;
use AdvertisementCache;
use AdvertisementRepository;
use CrawlerWarning;
use StringTools;

require Exporter;
@ISA = qw(Exporter);


# -------------------------------------------------------------------------------------------------

# global variable used for display purposes - indicates the current region being processed
my $currentRegion = 'Nil';

# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# extractDomainPropertyAdvertisement
# Parses the HTML syntax tree  to extract sufficient information for the cache
# and submits the record to the cache and repository
#
# Purpose:
#  construction of the repositories
#
# Parameters:
#  DocumentReader
#  HTMLSyntaxTree to use
#  String URL
#
# Returns:
#  a list of HTTP transactions or URL's.
#    
sub extractDomainPropertyAdvertisement

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
   my $sourceName =  $documentReader->getGlobalParameter('source');
   my $crawlerWarning = CrawlerWarning::new($sqlClient);
   
   my $advertisementCache = $$tablesRef{'advertisementCache'};
   my $printLogger = $documentReader->getGlobalParameter('printLogger');
   $statusTable = $documentReader->getStatusTable();

   $printLogger->print("in extractDomainPropertyAdvertisement ($parentLabel)\n");

   # IMPORTANT: extract the cacheID from the parent label   
   @splitLabel = split /\./, $parentLabel;
   $cacheID = $splitLabel[$#splitLabel];  # extract the cacheID from the parent label
   
   if ($htmlSyntaxTree->containsTextPattern("Property Details"))
   {
      if ($cacheID)
      {
         if ($sqlClient->connect())
         {		 	          
            $printLogger->print("   extractAdvertisement: storing record in repository for CacheID:$cacheID.\n");
            $identifier = $advertisementCache->storeInAdvertisementRepository($cacheID, $url, $htmlSyntaxTree);
            $statusTable->addToRecordsParsed($threadID, 1, 1, $url);                
         }
         else
         {
            $printLogger->print("   extractAdvertisement:", $sqlClient->lastErrorMessage(), "\n");
         }
      }
      else
      {
         $printLogger->print("   extractAdvertisement: cannot proceed. CacheID not set (record not added to repository)\n");
      }
   }
   else
   {
      $printLogger->print("   extractAdvertisement: page identifier not found\n");
      $crawlerWarning->reportWarning($sourceName, $instanceID, $url, $crawlerWarning->{'CRAWLER_EXPECTED_PATTERN_NOT_FOUND'}, "extractAdvertisement: page identifier not found");
   }
   
   
   # return an empty list
   return @emptyList;
}

# -------------------------------------------------------------------------------------------------
# parseSearchResults
# parses the htmlsyntaxtree that contains the list of properties generated in response 
# to to the search query
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
sub parseDomainSearchResults

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

   my @urlList;   # DO NOT SET TO UNDEF - it'll break the union later
   my @anchorList;   
   my $firstRun = 1;
   my $printLogger = $documentReader->getGlobalParameter('printLogger');
   my $sourceName = $documentReader->getGlobalParameter('source');
   my $suburbName;
   my $statusTable = $documentReader->getStatusTable();
   my $recordsEncountered = 0;
   my $recordsSkipped = 0;
   my $sessionProgressTable = $documentReader->getSessionProgressTable();

   my $crawlerWarning = CrawlerWarning::new($documentReader->getSQLClient());
   
   my $ignoreNextButton = 0;
   my $sqlClient = $documentReader->getSQLClient();
   my $tablesRef = $documentReader->getTableObjects();
   my $advertisementCache = $$tablesRef{'advertisementCache'};
   my $saleOrRentalFlag = -1;
   my $cachedID;
   
   # --- now extract the property information for this page ---
   $printLogger->print("inParseSearchResults ($parentLabel):\n");
   
   
   #$htmlSyntaxTree->printText();
   # Domain redesigned August 2006 - mostly superficial changes
   if (($htmlSyntaxTree->containsTextPattern("Search Results")) || ($htmlSyntaxTree->containsTextPattern("Refine Your Search")))
   {         
        
      # report that a suburb has started being processed...
      $suburbName = extractOnlyParentName($parentLabel);
      $sessionProgressTable->reportRegionOrSuburbChange($threadID, undef, $suburbName);   
    
      
      if ($sqlClient->connect())
      {
      
         # 25Apr05 - if zero results were found, it returns the results of a broader search - these
         # aren't wanted, so discard the page if it contains this pattern
         if (!$htmlSyntaxTree->containsTextPattern("A broader search of the same"))
         {
         
            # determine if these are RENT or SALE results
            # This needs to be obtained from one of the URLs in the page
            $anchorList = $htmlSyntaxTree->getAnchorsContainingPattern("New Search");
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
            }
            
            
            $htmlSyntaxTree->setSearchStartConstraintByText("results in");  # 20Aug06
            $htmlSyntaxTree->setSearchEndConstraintByText("Listing price or ad type");     # 20Aug06
         
            # get the suburbname from the page - used tfor tracking progress...
            $regionName = $htmlSyntaxTree->getNextText();  # 20Aug06
            $crud = $htmlSyntaxTree->getNextText();  # 20Aug06
            $suburbName = $htmlSyntaxTree->getNextText();  # 20Aug06
            
            $htmlSyntaxTree->resetSearchConstraints();
            
            # 20Aug06
            # each entry is in it's own div of class "zeussearchResult" 
            # the suburb name and price are in an H4 tag
            # the next non-image anchor href attribute contains the unique ID
            while ($htmlSyntaxTree->setSearchStartConstraintByTagAndClass('div', 'zeussearchResultHeader'))
            {               
               #$htmlSyntaxTree->setSearchStartConstraintByTag('h4');               

               # title string is in a span after the suburbname
               # but sometimes its proceeded by link text (eg. to virtual tour)
               # loop until the suburb name (zero or one iteration normally)
               $nextText = $htmlSyntaxTree->getNextText();
               $count = 0;
               while (($count < 2) && (!($nextText =~ /$suburbName/gi))) 
               {
                  $nextText = $htmlSyntaxTree->getNextText(); 
                  $count++;
               }               
               $titleString = $htmlSyntaxTree->getNextText();
               if ($titleString =~ /Property Type/) 
               {
                  $titleString = "";  # blank title
               }

               $printLogger->print("   crud= $crud\n");
               $printLogger->print("   titleString= $titleString\n");
               
               $htmlSyntaxTree->setSearchStartConstraintByTagAndClass('div', 'zeussearchResultMainImage');               
                              
               $sourceURL = $htmlSyntaxTree->getNextAnchor();            
                                             
               # not sure why this is needed - it shifts it onto the next property, otherwise it finds the same one twice. 
               #$htmlSyntaxTree->setSearchStartConstraintByTag('dl');               
               
               # remove non-numeric characters from the string occuring after the question mark
               ($crud, $sourceID) = split(/\?/, $sourceURL, 2);
               $sourceID =~ s/[^0-9]//gi;
               $sourceURL = new URI::URL($sourceURL, $url)->abs()->as_string();      # convert to absolute

               $printLogger->print("   saleOrRentalFlag= $saleOrRentalFlag\n");
               $printLogger->print("   suburbName      = $suburbName\n");
               $printLogger->print("   title           = $titleString\n");
               $printLogger->print("   sourceURL       = $sourceURL\n");
               $printLogger->print("   sourceId        = $sourceID\n");                              
               
               # check if the cache already contains a profile matching this source ID and title           
               $cacheID = $advertisementCache->updateAdvertisementCache($saleOrRentalFlag, $sourceName, $sourceID, $titleString);
               if ($cacheID == 0)
               {                                 
                  $printLogger->print("   parserSearchResults: record already in advertisement cache.\n");
                  $recordsSkipped++;
               }
               else
               {
                  $printLogger->print("   parseSearchResults: adding anchor id ", $sourceID, " (cacheID:$cacheID)...\n");                               
                  # IMPORTANT: pass the CachedID through to the details page parser
                  my $httpTransaction = HTTPTransaction::new($sourceURL, $url, $parentLabel.".".$cacheID);                                               
                                          
                  push @urlList, $httpTransaction;
               }
               $recordsEncountered++;  # count records seen
               
               # 23Jan05:save that this suburb has had some progress against it
               $sessionProgressTable->reportProgressAgainstSuburb($threadID, 1);
            }
            $statusTable->addToRecordsEncountered($threadID, $recordsEncountered, $recordsSkipped, $url);
         }
         else
         {
            $printLogger->print("   parserSearchResults: zero matching results returned\n");
            $ignoreNextButton = 1;
         }
      }
      else
      {
         $printLogger->print("   parseSearchResults:", $sqlClient->lastErrorMessage(), "\n");
      }         
         
     
      # now get the anchor for the NEXT button if it's defined 
      $nextButton = $htmlSyntaxTree->getNextAnchorContainingPattern("Next");
          
      # ignore the next button if this flag is set (because these are 'related' results)
      if (($nextButton) && (!$ignoreNextButton))
      {            
         $printLogger->print("   parseSearchResults: list includes a 'next' button anchor...\n");
         $httpTransaction = HTTPTransaction::new($nextButton, $url, $parentLabel);                  
         @anchorsList = (@urlList, $httpTransaction);
      }
      else
      {            
         $printLogger->print("   parseSearchResults: list has no 'next' button anchor...\n");
         @anchorsList = @urlList;
         # 23Jan05:save that this suburb has (almost) completed - just need to process the details
         $sessionProgressTable->reportSuburbCompletion($threadID);
      }
      
        
      $length = @anchorsList;         
      $printLogger->print("   parseSearchResults: following $length properties...\n");               
   }	  
   else
   {
      $printLogger->print("   parseSearchResults: pattern not found\n");   
      $crawlerWarning->reportWarning($sourceName, $instanceID, $url, $crawlerWarning->{'CRAWLER_EXPECTED_PATTERN_NOT_FOUND'}, "parseSearchResults: pattern not found");
   }
   
   # return the list or anchors or empty list   
   if ($length > 0)
   {      
      return @anchorsList;
   }
   else
   {      
      # 23Jan05:save that this suburb has (almost) completed - just need to process the details
      $sessionProgressTable->reportSuburbCompletion($threadID);
      
      $printLogger->print("   parseSearchList: returning empty anchor list.\n");
      return @emptyList;
   }   
     
}

# -------------------------------------------------------------------------------------------------
# parseDomainChooseSuburbs
# parses the htmlsyntaxtree to post form information to select suburbs
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
#  nil
#
# Returns:
#  a list of HTTP transactions or URL's.
#    
sub parseDomainChooseSuburbs
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

   my $htmlForm;
   my $actionURL;
   my $httpTransaction;
   my @transactionList;
   my $noOfTransactions = 0;
   my $printLogger = $documentReader->getGlobalParameter('printLogger');
   my $startLetter = $documentReader->getGlobalParameter('startrange');
   my $endLetter =  $documentReader->getGlobalParameter('endrange');
   my $state = $documentReader->getGlobalParameter('state');
   my $sessionProgressTable = $documentReader->getSessionProgressTable();
      
   my $sourceName =  $documentReader->getGlobalParameter('source');
   my $crawlerWarning = CrawlerWarning::new($documentReader->getSQLClient());
   my $acceptSuburb;
   my $useThisSuburb;
   
   $printLogger->print("in parseChooseSuburbs ($parentLabel)\n");

   # extract the current region name
   #@splitLabel = split /\./, $parentLabel;
   # set global variable for tracking that this instance has been run before
   # $currentRegion = $splitLabel[$#splitLabel];    
   # $sessionProgressTable->reportRegionOrSuburbChange($threadID, $currentRegion, 'Nil');
   
 #  parseDomainSalesDisplayResponse($documentReader, $htmlSyntaxTree, $url, $instanceID, $transactionNo);
 
   # 20Aug2006 - Domain site has  been redesigned - must changes are superficial 
   if (($htmlSyntaxTree->containsTextPattern("Advanced Search")) || (($htmlSyntaxTree->containsTextPattern("Search by state"))))
   {                    
      # get the HTML Form instance
      $htmlForm = $htmlSyntaxTree->getHTMLForm("__aspnetForm");
       
      if ($htmlForm)
      {               
         # for all of the suburbs defined in the form, create a transaction to get it
         if (($startLetter) || ($endLetter))
         {
            $printLogger->print("   parseChooseSuburbs: Filtering suburb names between $startLetter to $endLetter...\n");
         }
         $optionsRef = $htmlForm->getSelectionOptions('_ctl0:listboxSuburbs');
         if ($optionsRef)
         {         
            # recover the state, region, suburb combination from the recovery file for this thread

            $sessionProgressTable->prepareSuburbStateMachine($threadID);     

            # loop through the list of suburbs in the form...
            foreach (@$optionsRef)
            {  
               $acceptSuburb = 0;
               $value = $_->{'value'};   # this is the suburb name...           
               # check if the last suburb has been encountered - if it has, then start processing from this point
               $useThisSuburb = $sessionProgressTable->isSuburbAcceptable($value);
               
               if ($useThisSuburb)
               {
                  if ($value =~ /All Suburbs/i)
                  {
                     # ignore 'all suburbs' option                    
                  }
                  else
                  {
                     # determine if the suburbname is in the specific letter constraint
                     $acceptSuburb = isSuburbNameInRange($_->{'text'}, $startLetter, $endLetter);
                  }
               }
                                           
               if ($acceptSuburb)
               {         
                  # 23 Jan 05 - another check - see if the suburb has already been 'completed' in this thread
                  # if it has been, then don't do it again (avoids special case where servers may return
                  # the same suburb for multiple search variations)
                  if (!$sessionProgressTable->hasSuburbBeenProcessed($threadID, $value))
                  {  
                  
                     #$printLogger->print("  $currentRegion:", $_->{'text'}, " '", $_->{'value'}, "'\n");

                     # set the suburb name in the form   
                     $htmlForm->setInputValue('_ctl0:listboxSuburbs', $_->{'value'});            

                     #$htmlForm->printForm();
                     
                     my $newHTTPTransaction = HTTPTransaction::new($htmlForm, $url, $parentLabel.".".$_->{'text'});
          
                     #print $_->{'value'},"\n";
                     #print($newHTTPTransaction->getEscapedParameters(), "\n");
                     
                     # add this new transaction to the list to return for processing
                     $transactionList[$noOfTransactions] = $newHTTPTransaction;
                     $noOfTransactions++;

                     $htmlForm->clearInputValue('_ctl0:listboxSuburbs');
                  }
                  else
                  {
                     $printLogger->print("   ParseChooseSuburbs:suburb ", $_->{'text'}, " previously processed in this thread.  Skipping...\n");
                  }                                                         
               }
            }
         }
         $printLogger->print("   ParseChooseSuburbs:Created requests for $noOfTransactions suburbs in '$currentRegion'...\n");                             
      }	  
      else       
      {
         $printLogger->print("   parseChooseSuburbs:Search form not found.\n");
         $crawlerWarning->reportWarning($sourceName, $instanceID, $url, $crawlerWarning->{'CRAWLER_EXPECTED_FORM_NOT_FOUND'}, "parseChooseSuburbs: Search form not found");         
      }
   }
   else
   {
      # as this server uses ASP.NET the action for the form above actually comes back to the same page, but returns
      # a STATUS 302 object has been moved message, pointing to an alternative page. 
      # This code detects the object not found message and follows the alternative URL
      if ($htmlSyntaxTree->containsTextPattern("Object moved"))
      {
         $printLogger->print("   parseChooseSuburbs: following object moved redirection...\n");
         $anchor = $htmlSyntaxTree->getNextAnchorContainingPattern("here");
         if ($anchor)
         {
            $printLogger->print("   following anchor 'here'\n");
            
            $httpTransaction = HTTPTransaction::new($anchor, $url, $parentLabel);
            
            $transactionList[$noOfTransactions] = $httpTransaction;
            $noOfTransactions++;
         }
         
      }
      else
      {
         $printLogger->print("   parseChooseSuburbs: 'object moved' pattern not found\n");         
         {
            $crawlerWarning->reportWarning($sourceName, $instanceID, $url, $crawlerWarning->{'CRAWLER_EXPECTED_PATTERN_NOT_FOUND'}, "parseChooseSuburbs: 'object moved' pattern not found");
         }
      }
   }
   
   if ($noOfTransactions > 0)
   {      
      return @transactionList;
   }
   else
   {      
      $printLogger->print("   parseChooseSuburbs:returning zero transactions.\n");
      return @emptyList;
   }   
}


# -------------------------------------------------------------------------------------------------
# parseDomainSalesChooseRegions
# parses the htmlsyntaxtree to select the regions to follow
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
#  nil
#
# Returns:
#  a list of HTTP transactions or URL's.
#    
sub parseDomainSalesChooseRegions

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

   my $htmlForm;
   my $actionURL;
   my $httpTransaction;
   my $anchor;
   my @transactionList;
   my $noOfTransactions = 0;
   my $printLogger = $documentReader->getGlobalParameter('printLogger');
   my $sessionProgressTable = $documentReader->getSessionProgressTable();
   
   my $sourceName =  $documentReader->getGlobalParameter('source');
   my $crawlerWarning = CrawlerWarning::new($documentReader->getSQLClient());
   
   $printLogger->print("in parseChooseRegions ($parentLabel)\n");    
    
   if ($htmlSyntaxTree->containsTextPattern("Select Region"))
   {
      
      # if this page contains a form to select whether to proceed or not...
      $htmlForm = $htmlSyntaxTree->getHTMLForm();
           
      #$htmlSyntaxTree->printText();     
      if ($htmlForm)
      {       
         $actualAction = $htmlForm->getAction();
         $actionURL = new URI::URL($htmlForm->getAction(), $parameters{'url'})->abs()->as_string();
          
         # get all of the checkboxes and set them
         $checkboxListRef = $htmlForm->getCheckboxes();
    
         $sessionProgressTable->prepareRegionStateMachine($threadID, $currentRegion);     

         #print "restartLastRegion:$restartLastRegion($lastRegion) startFirstRegion:$startFirstRegion continueNextRegion:$continueNextRegion (cr=$currentRegion)\n";

         # loop through all the regions defined in this page - the flags are used to determine 
         # which one to set for the transaction
         $regionAdded = 0;
         foreach (@$checkboxListRef)
         {
            # use the state machine to determine if this region should be processed
            $useThisRegion = $sessionProgressTable->isRegionAcceptable($_->getValue(), $currentRegion);
            
            #print "   ", $_->getValue(), ":useThisRegion:$useThisRegion useNextRegion:$useNextRegion\n";
            
            # if this flag has been set in the logic above, a transaction is used for this region
            if ($useThisRegion)
            {      
               # $_ is a reference to an HTMLFormCheckbox
               # set this checkbox input to true
               $htmlForm->setInputValue($_->getName(), $_->getValue());            
               
               # set global variable for tracking that this instance has been run before
               $currentRegion = $_->getValue();
               
               my $newHTTPTransaction = HTTPTransaction::new($htmlForm, $url, $parentLabel.".".$_->getValue());
               # add this new transaction to the list to return for processing
               $transactionList[$noOfTransactions] = $newHTTPTransaction;
               $noOfTransactions++;

               $htmlForm->clearInputValue($_->getName());
               # record which region was last processed in this thread
               # and reset to the first suburb in the region
               $sessionProgressTable->reportRegionOrSuburbChange($threadID, $currentRegion, 'Nil');
               
               $regionAdded = 1;
               last;   # break out of the checkbox loop
            }
         } # end foreach

         if (!$regionAdded)
         {
            # no more regions to process - finished
            $sessionProgressTable->reportRegionOrSuburbChange($threadID, 'Nil', 'Nil');     
         }
         else
         {
            # add the home directory as the second transaction to start a new session for the next region
            ##### NEED TO RESET COOKIES HERE?
            my $newHTTPTransaction = HTTPTransaction::new('http://www.domain.com.au/Public/advancedsearch.aspx?mode=buy', undef, 'base');
            
            # add this new transaction to the list to return for processing
            $transactionList[$noOfTransactions] = $newHTTPTransaction;
            $noOfTransactions++;
         }
         
         $printLogger->print("   parseChooseRegions: returning $noOfTransactions GET transactions (next region and home)...\n");
            
      }	  
      else 
      {
         $printLogger->print("   parseChooseRegions: regions form not found\n");
         $crawlerWarning->reportWarning($sourceName, $instanceID, $url, $crawlerWarning->{'CRAWLER_EXPECTED_FORM_NOT_FOUND'}, "parseChooseRegions: regions form not found");
      }
   }
   else
   {
      # for some dodgy reason the action for the form above actually comes back to the same page, put returns
      # a STATUS 302 object has been moved message, pointing to an alternative page.  Seems like a hack
      # to overcome a problem with their server.  I don't know why they don't just post to a different address, but anyway,
      # this code detects the object not found message and follows the alternative URL
      if ($htmlSyntaxTree->containsTextPattern("Object moved"))
      {
         $printLogger->print("   parseChooseRegions: following object moved redirection...\n");
         $anchor = $htmlSyntaxTree->getNextAnchorContainingPattern("here");
         if ($anchor)
         {
            $printLogger->print("   following anchor 'here'\n");
            $httpTransaction = HTTPTransaction::new($anchor, $url, $parentLabel);
       
            $transactionList[$noOfTransactions] = $httpTransaction;
            $noOfTransactions++;
         }         
         
         #$htmlSyntaxTree->printText();
      }
      else
      {
         $crawlerWarning->reportWarning($sourceName, $instanceID, $url, $crawlerWarning->{'CRAWLER_EXPECTED_PATTERN_NOT_FOUND'}, "parseChooseRegions: 'object moved' pattern not found");
      }
   }
   
   if ($noOfTransactions > 0)
   {
      return @transactionList;
   }
   else
   {      
      $printLogger->print("   parseChooseRegions: returning empty list\n");
      return @emptyList;
   }   
}


# -------------------------------------------------------------------------------------------------
# parseDomainRentalChooseRegions
# parses the htmlsyntaxtree to select the regions to follow
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
#  nil
#
# Returns:
#  a list of HTTP transactions or URL's.
#    
sub parseDomainRentalChooseRegions

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

   my $htmlForm;
   my $actionURL;
   my $httpTransaction;
   my $anchor;
   my @transactionList;
   my $noOfTransactions = 0;
   my $printLogger = $documentReader->getGlobalParameter('printLogger');
   my $sessionProgressTable = $documentReader->getSessionProgressTable();

   my $sourceName =  $documentReader->getGlobalParameter('source');
   my $crawlerWarning = CrawlerWarning::new($documentReader->getSQLClient());
   
   $printLogger->print("in parseChooseRegions ($parentLabel)\n");
    
    
   if ($htmlSyntaxTree->containsTextPattern("Select Region"))
   {
      
      # if this page contains a form to select whether to proceed or not...
      $htmlForm = $htmlSyntaxTree->getHTMLForm();
           
      #$htmlSyntaxTree->printText();     
      if ($htmlForm)
      {       
         $actualAction = $htmlForm->getAction();
         $actionURL = new URI::URL($htmlForm->getAction(), $parameters{'url'})->abs()->as_string();
          
         # get all of the checkboxes and set them
         $checkboxListRef = $htmlForm->getCheckboxes();
            
         $sessionProgressTable->prepareRegionStateMachine($threadID, $currentRegion);     

         #print "restartLastRegion:$restartLastRegion($lastRegion) startFirstRegion:$startFirstRegion continueNextRegion:$continueNextRegion (cr=$currentRegion)\n";

         # loop through all the regions defined in this page - the flags are used to determine 
         # which one to set for the transaction
         $regionAdded = 0;         
         $useNextRegion = 0;
         $useThisRegion = 0;
         foreach (@$checkboxListRef)
         {   
            
            $useThisRegion = $sessionProgressTable->isRegionAcceptable($_->getValue(), $currentRegion);

            
            #print "   ", $_->getValue(), ":useThisRegion:$useThisRegion useNextRegion:$useNextRegion\n";
            
            # if this flag has been set in the logic above, a transaction is used for this region
            if ($useThisRegion)
            {      
               # $_ is a reference to an HTMLFormCheckbox
               # set this checkbox input to true
               $htmlForm->setInputValue($_->getName(), $_->getValue());            
               
               # set global variable for tracking that this instance has been run before
               $currentRegion = $_->getValue();
               
               my $newHTTPTransaction = HTTPTransaction::new($htmlForm, $url, $parentLabel.".".$_->getValue());
               # add this new transaction to the list to return for processing
               $transactionList[$noOfTransactions] = $newHTTPTransaction;
               $noOfTransactions++;

               $htmlForm->clearInputValue($_->getName());
               
               # record which region was last processed in this thread
               # and reset to the first suburb in the region
               $sessionProgressTable->reportRegionOrSuburbChange($threadID, $currentRegion, 'Nil');

               $regionAdded = 1;
               last;   # break out of the checkbox loop
            }
         } # end foreach

         if (!$regionAdded)
         {
            # no more regions to process - finished            
            $sessionProgressTable->reportRegionOrSuburbChange($threadID, 'Nil', 'Nil');
         }
         else
         {
            # add the home directory as the second transaction to start a new session for the next region
            ##### NEED TO RESET COOKIES HERE?
            my $newHTTPTransaction = HTTPTransaction::new('http://www.domain.com.au/Public/advancedsearch.aspx?mode=rent', undef, 'base');
            
            # add this new transaction to the list to return for processing
            $transactionList[$noOfTransactions] = $newHTTPTransaction;
            $noOfTransactions++;
         }
         
         $printLogger->print("   parseChooseRegions: returning $noOfTransactions GET transactions (next region and home)...\n");
            
      }	  
      else 
      {
         $printLogger->print("   parseChooseRegions: regions form not found\n");
         $crawlerWarning->reportWarning($sourceName, $instanceID, $url, $crawlerWarning->{'CRAWLER_EXPECTED_FORM_NOT_FOUND'}, "parseChooseRegions: regions form not found");
      }
   }
   else
   {
      # for some dodgy reason the action for the form above actually comes back to the same page, put returns
      # a STATUS 302 object has been moved message, pointing to an alternative page.  Seems like a hack
      # to overcome a problem with their server.  I don't know why they don't just post to a different address, but anyway,
      # this code detects the object not found message and follows the alternative URL
      if ($htmlSyntaxTree->containsTextPattern("Object moved"))
      {
         $printLogger->print("   parseChooseRegions: following object moved redirection...\n");
         $anchor = $htmlSyntaxTree->getNextAnchorContainingPattern("here");
         if ($anchor)
         {
            $printLogger->print("   following anchor 'here'\n");
            $httpTransaction = HTTPTransaction::new($anchor, $url, $parentLabel);
       
            $transactionList[$noOfTransactions] = $httpTransaction;
            $noOfTransactions++;
         }
         else
         {
            $crawlerWarning->reportWarning($sourceName, $instanceID, $url, $crawlerWarning->{'CRAWLER_EXPECTED_PATTERN_NOT_FOUND'}, "parseChooseRegions: 'object moved' pattern not found"); 
         }
         
         #$htmlSyntaxTree->printText();
      }
   }
   
   if ($noOfTransactions > 0)
   {
      return @transactionList;
   }
   else
   {      
      $printLogger->print("   parseChooseRegions: returning empty list\n");
      return @emptyList;
   }   
}

# -------------------------------------------------------------------------------------------------
# parseDomainChooseState
# parses the htmlsyntaxtree to extract the link to each of the specified state
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
sub parseDomainChooseState

{	
   my $documentReader = shift;
   my $htmlSyntaxTree = shift;
   my $httpClient = shift;         
   my $instanceID = shift;
   my $transactionNo = shift;
   my $threadID = shift;
   my $parentLabel = shift;
   my $dryRun = shift;
   my @anchors;
   my $printLogger = $documentReader->getGlobalParameter('printLogger');
   my $state = $documentReader->getGlobalParameter('state');
   my @transactionList;
   my $url = $httpClient->getURL();
   
   my $sourceName =  $documentReader->getGlobalParameter('source');
   my $crawlerWarning = CrawlerWarning::new($documentReader->getSQLClient());

   # delete cookies to start a fresh session 
   $documentReader->deleteCookies();
   
   
   # --- now extract the property information for this page ---
   $printLogger->print("inParseChooseState ($parentLabel):\n");
   if ($htmlSyntaxTree->containsTextPattern("Advanced Search"))
   { 
      $htmlSyntaxTree->setSearchStartConstraintByText("Browse by State");
      $htmlSyntaxTree->setSearchEndConstraintByText("Searching for Real Estate");                                    
      $anchor = $htmlSyntaxTree->getNextAnchorContainingPattern($state);
      
      if ($anchor)
      {
         $printLogger->print("   following anchor '$state'\n");
      }
      else
      {
         $printLogger->print("   anchor '$state' not found!\n");
      }
   }	  
   else 
   {      
      $crawlerWarning->reportWarning($sourceName, $instanceID, $url, $crawlerWarning->{'CRAWLER_EXPECTED_PATTERN_NOT_FOUND'}, "parseChooseState: pattern not found");
   }
   
   # return a list with just the anchor in it
   if ($anchor)
   {
      $httpTransaction = HTTPTransaction::new($anchor, $url, $parentLabel.".".$state);   # use the state in the label
       
      return ($httpTransaction);
   }
   else
   {
      return @emptyList;
   }
}


# -------------------------------------------------------------------------------------------------
# parseDomainDisplayResponse
# parser that just displays the content of a response 
#
# Purpose:
#  testing
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
sub parseDomainDisplayResponse

{	
   my $documentReader = shift;
   my $htmlSyntaxTree = shift;
   my $httpClient = shift;         
   my $instanceID = shift;   
   my $transactionNo = shift;
   my $threadID = shift;
   my $parentLabel = shift;
   my $dryRun = shift;
   my @anchors;
   my $printLogger = $documentReader->getGlobalParameter('printLogger');
   my $url = $httpClient->getURL();

   # --- now extract the property information for this page ---
   $printLogger->print("in ParseDisplayResponse ($parentLabel):\n");
   $htmlSyntaxTree->printText();
   
   # return a list with just the anchor in it  
   return @emptyList;
   
}

# -------------------------------------------------------------------------------------------------

