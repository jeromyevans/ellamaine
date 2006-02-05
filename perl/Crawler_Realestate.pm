#!/usr/bin/perl
# 11 Nov 04 - derived from multiple sources
#  Contains parsers for the RealEstate website to obtain advertised sales information
#
#  all parses must accept two parameters:
#   $documentReader
#   $htmlSyntaxTree
#
# The parsers can't access any other global variables, but can use functions in the WebsiteParser_Common module
#
# History:
#  5 December 2004 - adapted to use common AdvertisedPropertyProfiles instead of separate rentals and sales tables
# 22 January 2005  - added support for the StatusTable reporting of progress for the thread
# 23 January 2005  - added support for the SessionProgressTable reporting of progress of the thread
#                  - added check against SessionProgressTable to reject suburbs that appear 'completed' already
#  in the table.  Should prevent procesing of suburbs more than once if the server returns the same suburb under
#  multiple searches.  Note: completed indicates the propertylist has been parsed, not necessarily all the details.
#  25 April  2005   - modified parsing of search results to ignore 'related results' returned by the search engine
#  24 May 2005      - major change to support new AdvertisedPropertyProfiles table that combines rental and sale 
#  advertisements and perform less processing of the source data before entry
#  24 June 2005     - added support for RecordsSkipped field in status table - to track how many records
#  are deliberately skipped because they're likely to be in the db already.  
#  in theory: recordsEncountered = recordsSkipped+recordsParsed
#                   - bug fixed that was setting recordsEncountered in the wrong part of the state machine
#  giving too high a value
#  25 June 2005     - added support for the parser dryRun flag
#  26 June 2005     - modified extraction function so it always defines local variables - was possible that 
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
# 3 July 2005      - changed the function for a replace writeMethod slightly - when the changed profile is 
#  generated now, values that are UNDEF in the new profile are CLEARed in the profile.  Previously they
#  were retain as-is - which meant corrupt values are retains.  Reparing from the source html should completely
#  clear existing invalid values.  This almost warrant reprocessing of all source records (urgh...)
# 11 July 2005     - found another variation of realestate.com records - fixed the way it extracts the suburb name
#  that results in scarab defect #40 (suburb name = quick menu)
# 28 Aug 2005      - have to override the action in the search form because it was recently changed to
# a relative address of the value:  "cgi-bin/rsearch" instead of "/cgi-bin/rsearch".  
# The new value does not comping properly with the base path to generate the URL for the form's GET
# request.  Now override the value to "/cgi-bin/research".                   
# 5 Feb 2006       - Modified to use the new crawler architecture - the crawler has been separated from the parser 
#   and a crawler warning system has been included.
#                  - Renamed to Crawler*
#                  - Moved Parsing code out to Parser*
#                  - Modified to use the AdvertisementCache instead of AdvertisedPropertyProfiles
# ---CVS---
# Version: $Revision$
# Date: $Date$
# $Id$
#
package Crawler_Realestate;

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

@ISA = qw(Exporter);

# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# extractRealEstatePropertyAdvertisement
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
sub extractRealEstatePropertyAdvertisement

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

   $printLogger->print("in extractRealEstatePropertyAdvertisement ($parentLabel)\n");

   # IMPORTANT: extract the cacheID from the parent label   
   @splitLabel = split /\./, $parentLabel;
   $cacheID = $splitLabel[$#splitLabel];  # extract the cacheID from the parent label
   
   if ($htmlSyntaxTree->containsTextPattern("Property No"))
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
# parseRealEstateSearchResults
# parses the htmlsyntaxtree that contains the list of homes generated in response 
# to a query
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
sub parseRealEstateSearchResults

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

   my $SEEKING_FIRST_RESULT = 1;
   my $PARSING_RESULT_TITLE = 2;
   my $PARSING_SUB_LINE     = 3;
   my $PARSING_PRICE        = 4;
   my $PARSING_SOURCE_ID    = 5;
   my $SEEKING_NEXT_RESULT  = 6;
   
   my $printLogger = $documentReader->getGlobalParameter('printLogger');
   my $sourceName =  $documentReader->getGlobalParameter('source');
   my $length = 0;
   my @urlList;
   my @anchorList;
   my $firstRun = 1;
   my $statusTable = $documentReader->getStatusTable();
   my $recordsEncountered = 0;
   my $recordsSkipped = 0;
   my $sessionProgressTable = $documentReader->getSessionProgressTable();   # 23Jan05
   my $ignoreNextButton = 0;
   my $sqlClient = $documentReader->getSQLClient();
   my $tablesRef = $documentReader->getTableObjects();
   my $advertisementCache = $$tablesRef{'advertisementCache'};
   my $saleOrRentalFlag = -1;
   my $crawlerWarning = CrawlerWarning::new($documentReader->getSQLClient());
      
   # --- now extract the property information for this page ---
   $printLogger->print("inParseSearchResults ($parentLabel):\n");
   @splitLabel = split /\./, $parentLabel;
   $suburbName = $splitLabel[$#splitLabel];  # extract the suburb name from the parent label

   $sessionProgressTable->reportRegionOrSuburbChange($threadID, undef, $suburbName);    # 23Jan05 
   
   #$htmlSyntaxTree->printText();
   if ($htmlSyntaxTree->containsTextPattern("Displaying"))
   {         
      # if no exact matches are found the search engine sometimes returns related matches - these aren't wanted
      if (!$htmlSyntaxTree->containsTextPattern("No exact matches found"))
      {
         # determine if these are RENT or SALE results
         # 20 June 2005 - all pages now contain Homes for Sale in the title bar - setting a search constraint
         # to the first h1 tag
         $htmlSyntaxTree->resetSearchConstraints();
         $htmlSyntaxTree->setSearchStartConstraintByTag("h1");
         if ($htmlSyntaxTree->containsTextPattern("Homes for Sale"))
         {
            $saleOrRentalFlag = 0;
         }
         elsif ($htmlSyntaxTree->containsTextPattern("Homes for Rent"))
         {
            $saleOrRentalFlag = 1;
         }
         else
         {
            $printLogger->print("WARNING: sale or rental pattern not found\n");
            $crawlerWarning->reportWarning($sourceName, $instanceID, $url, $crawlerWarning->{'CRAWLER_EXPECTED_PATTERN_NOT_FOUND'}, "parseSearchResults: sale or rental pattern not found");
         }
         
         #20Jun2005 - page has been re-designed - try old and new patterns
         $htmlSyntaxTree->resetSearchConstraints();
         if (!$htmlSyntaxTree->setSearchStartConstraintByText("properties found"))
         {
            $htmlSyntaxTree->setSearchStartConstraintByText("Your search returned");
         }
         $htmlSyntaxTree->setSearchEndConstraintByText("Page:");
            
         $state = $SEEKING_FIRST_RESULT;
         $endOfList = 0;
         while (!$endOfList)
         {
            # state machine for processing the list of results
            $parsedThisLine = 0;
            $thisText = $htmlSyntaxTree->getNextText();
            if (!$thisText)
            {
               # not set - at the end of the list - exit the state machine
               $parsedThisLine = 1;
               $endOfList = 1;
            }
            #print "START: state=$state: Line:'$thisText' parsed=$parsedThisLine\n";
            
            if ((!$parsedThisLine) && ($state == $SEEKING_FIRST_RESULT))
            {
               # if this text is the suburb name, we're in a new record
               if ($thisText =~ /$suburbName/i)
               {
                  #$state = $PARSING_RESULT_TITLE;
                  $state = $PARSING_SUB_LINE;        #20Jun05 - no title following anymore
               }
               $parsedThisLine = 1;
            }
            
            if ((!$parsedThisLine) && ($state == $PARSING_RESULT_TITLE))
            {
               $title = $thisText;   # always set
               $state = $PARSING_SUB_LINE;
               $parsedThisLine = 1;
            }
            
            if ((!$parsedThisLine) && ($state == $PARSING_SUB_LINE))
            {
               # optionally set to the price, or AUCTION or UNDER OFFER or SOLD
               
               if ($thisText =~ /UNDER|SOLD/gi)
               {
                  $state = $PARSING_PRICE;
                  $parsedThisLine = 1;
               }
               else
               {
                  if ($thisText =~ /Auction/gi)
                  {
                     # price is not set for auctions
                     $priceLower = undef;
                     $state = $PARSING_SOURCE_ID;
                     $parsedThisLine = 1;
                  }
                  else
                  { 
                      $state = $PARSING_PRICE;
                      # don't set the parsed this line flag - keep processing
                  }
               }
            }
              
            if ((!$parsedThisLine) && ($state == $PARSING_PRICE))
            {
               # the titleString for RealEstate.com is the line with the price on it
               $titleString = $thisText;
                           
               $state = $PARSING_SOURCE_ID;
               $parsedThisLine = 1;
            }
            
            if ((!$parsedThisLine) && ($state == $PARSING_SOURCE_ID))
            {
               $anchor = $htmlSyntaxTree->getNextAnchor();
               $temp=$anchor;
               $temp =~ s/id=(.\d*)&f/$sourceID = sprintf("$1")/ei;
   
               #print "$suburbName: '$title' \$$priceLower id=$sourceID\n";
               
               if (($sourceID) && ($anchor))
               {
                  # check if the cache already contains a profile matching this source ID and title           
                  $cacheID = $advertisementCache->updateAdvertisementCache($saleOrRentalFlag, $sourceName, $sourceID, $titleString);
                  if ($cacheID == 0)
                  {
                     $printLogger->print("   parseSearchResults: record already in advertisement cache.\n");
                     $recordsSkipped++;
                  }                 
                  else
                  {
                     $printLogger->print("   parseSearchResults: adding anchor id ", $sourceID, " (cacheID:$cacheID)...\n");   
                     #$printLogger->print("   parseSearchList: url=", $sourceURL, "\n");          
                     my $httpTransaction = HTTPTransaction::new($anchor, $url, $parentLabel.".".$cacheID);                  
                
                     push @urlList, $httpTransaction;
                  }
              
                  #print "  END: state=$state: Line:'$thisText' ts:'$titleString' sid:'$sourceID' parsed=$parsedThisLine\n";
                  $recordsEncountered++;  # count records seen
                  # 23Jan05:save that this suburb has had some progress against it
                  $sessionProgressTable->reportProgressAgainstSuburb($threadID, 1);
               }
               
               $state = $SEEKING_NEXT_RESULT;
               $parsedThisLine = 1;
            }
            
            if ((!$parsedThisLine) && ($state == $SEEKING_NEXT_RESULT))
            {
               # searching for the start of the next result - possible outcomes are the
               # start of the next result is found or the start of an advertisement is found
               
               if ($thisText eq $suburbName)
               {
                  #$state = $PARSING_RESULT_TITLE;   # 20June05 - no title anymore
                  $state = $PARSING_SUB_LINE;
               }
               $parsedThisLine = 1;
            }
            
         }      
         $statusTable->addToRecordsEncountered($threadID, $recordsEncountered, $recordsSkipped, $url);
      }
      else
      {
         $printLogger->print("   parseSearchResults: no exact matches found\n");
         $ignoreNextButton = 1;
      }
         
      # now get the anchor for the NEXT button if it's defined 
      
      $htmlSyntaxTree->resetSearchConstraints();
      $htmlSyntaxTree->setSearchStartConstraintByText("properties found");
      $htmlSyntaxTree->setSearchEndConstraintByText("property details");
      
      $anchor = $htmlSyntaxTree->getNextAnchorContainingPattern("Next");
           
      # ignore the next button if it's only for related results
      if (($anchor) && (!$ignoreNextButton))
      {            
         $printLogger->print("   parseSearchResults: list includes a 'next' button anchor...\n");
         $httpTransaction = HTTPTransaction::new($anchor, $url, $parentLabel);                  
         #print "   anchor=$anchor\n";
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
      $printLogger->print("   parseSearchResults: following $length anchors...\n");
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
      
      $printLogger->print("   parseSearchResults: returning empty anchor list.\n");
      return @emptyList;
   }   
     
}


# -------------------------------------------------------------------------------------------------
# parseRealEstateSearchForm
# parses the htmlsyntaxtree to post form information
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
sub parseRealEstateSearchForm

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
   my $startLetter = $documentReader->getGlobalParameter('startrange');
   my $endLetter =  $documentReader->getGlobalParameter('endrange');
   my $printLogger = $documentReader->getGlobalParameter('printLogger');
   my $sessionProgressTable = $documentReader->getSessionProgressTable();   # 23Jan05
   my $sourceName =  $documentReader->getGlobalParameter('source');
   my $crawlerWarning = CrawlerWarning::new($documentReader->getSQLClient());
   
   my %subAreaHash;
      
   $printLogger->print("in parseSearchForm ($parentLabel)\n");
      
   # get the HTML Form instance
   $htmlForm = $htmlSyntaxTree->getHTMLForm("n");
    
   if ($htmlForm)
   {       
      if (($startLetter) || ($endLetter))
      {
         $printLogger->print("   parseSearchForm: Filtering suburb names between $startLetter to $endLetter...\n");
      }
      # for all of the suburbs defined in the form, create a transaction to get it
      $optionsRef = $htmlForm->getSelectionOptions('u');
      $htmlForm->clearInputValue('is');   # clear checkbox selecting surrounding suburbs
      $htmlForm->setInputValue('cat', '');   
      $htmlForm->setInputValue('o', 'def');   

      
      # parse through all those in the perth metropolitan area
      if ($optionsRef)
      {
         $sessionProgressTable->prepareSuburbStateMachine($threadID);     # 23Jan05
         
         foreach (@$optionsRef)
         {            
            $acceptSuburb = 0;

            # check if the last suburb has been encountered - if it has, then start processing from this point
            $useThisSuburb = $sessionProgressTable->isSuburbAcceptable($_->{'text'});  # 23Jan05
            
            if ($useThisSuburb)
            {
               if ($_->{'text'} =~ /\*\*\*/i)
               {
                   # ignore '*** show all suburbs ***' option
               }
               else
               {
                  $htmlForm->setInputValue('u', trimWhitespace($_->{'text'}));
   
                  # determine if the suburbname is in the specific letter constraint
                  $acceptSuburb = isSuburbNameInRange($_->{'text'}, $startLetter, $endLetter);  # 23Jan05
               }
            }
                        
            if ($acceptSuburb)
            {
               # 23 Jan 05 - another check - see if the suburb has already been 'completed' in this thread
               # if it has been, then don't do it again (avoids special case where servers may return
               # the same suburb for multiple search variations)
               if (!$sessionProgressTable->hasSuburbBeenProcessed($threadID, $_->{'text'}))
               { 
                  
                  #print "accepted\n";                            
                  #27 August 2005 - have to override the action because it was recently changed to
                  # a relative address of the form:  "cgi-bin/rsearch" instead of "/cgi-bin/rsearch"
                  # in the new form, the url for the GET is corrupted by the relative path when combined
                  # with the base url
                  $htmlForm->overrideAction("/cgi-bin/rsearch");
                  my $newHTTPTransaction = HTTPTransaction::new($htmlForm, $url, $parentLabel.".".trimWhitespace($_->{'text'}));
                  #print $htmlForm->getEscapedParameters(), "\n";
               
                  # add this new transaction to the list to return for processing
                  $transactionList[$noOfTransactions] = $newHTTPTransaction;
                  $noOfTransactions++;
               }   
               else
               {
                  $printLogger->print("   parseSearchForm:suburb ", $_->{'text'}, " previously processed in this thread.  Skipping...\n");
               }
            }
         }
         
         $printLogger->print("   ParseSearchForm:Created a transaction for $noOfTransactions suburbs...\n");
      }  # end of metropolitan areas
              
   }	  
   else 
   {
      $printLogger->print("   parseSearchForm:Search form not found.\n");
      $crawlerWarning->reportWarning($sourceName, $instanceID, $url, $crawlerWarning->{'CRAWLER_EXPECTED_FORM_NOT_FOUND'}, " parseSearchForm:Search form not found.");
   }
   
   if ($noOfTransactions > 0)
   {      
      return @transactionList;
   }
   else
   {      
      $printLogger->print("   parseSearchForm:returning zero transactions.\n");
      return @emptyList;
   }   
}

# -------------------------------------------------------------------------------------------------
# parseRealEstateDisplayResponse
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
sub parseRealEstateDisplayResponse

{	
   my $documentReader = shift;
   my $htmlSyntaxTree = shift;
   my $url = shift;         
   my $instanceID = shift;   
   my $transactionNo = shift;
   my $threadID = shift;
   my $parentLabel = shift;
   my $dryRun = shift;
   
   my @anchors;
   my $printLogger = $documentReader->getGlobalParameter('printLogger');
   
   # --- now extract the property information for this page ---
   $printLogger->print("in ParseDisplayResponse:\n");
   $htmlSyntaxTree->printText();
   
   # return a list with just the anchor in it  
   return @emptyList;   
}

# -------------------------------------------------------------------------------------------------

