#!/usr/bin/perl
# 30 Jan 06 - derived from multiple sources
#  Contains parsers for the JustListed website to obtain advertised sales information
#
#  all parses must accept two parameters:
#   $documentReader
#   $htmlSyntaxTree
#
# The parsers can't access any other global variables, but can use functions in the WebsiteParser_Common module
#
# History:
#    This version uses the new Ellamaine Crawler Architecture that splits the crawler from the parser and includes
#  a crawler warning system
# 5 Feb 06 - Modified to use the AdvertisementCache instead of AdvertisedPropertyProfiles
#
#
package Crawler_JustListed;

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
# extractJustListedPropertyAdvertisement
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
sub extractJustListedPropertyAdvertisement

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

   $printLogger->print("in extractJustListedPropertyAdvertisement ($parentLabel)\n");

   # IMPORTANT: extract the cacheID from the parent label   
   @splitLabel = split /\./, $parentLabel;
   $cacheID = $splitLabel[$#splitLabel];  # extract the cacheID from the parent label
   
   if ($htmlSyntaxTree->containsTextPattern("Back to Search Results"))
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
# parseJustListedSearchResults
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
sub parseJustListedSearchResults

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
   my $cacheID;   
   my $originatingHTMLId = undef;
   my $crawlerWarning = CrawlerWarning::new($documentReader->getSQLClient());
   
   # --- now extract the property information for this page ---
   $printLogger->print("inParseSearchResults ($parentLabel):\n");
   
   #@splitLabel = split /\./, $parentLabel;
   #$suburbName = $splitLabel[$#splitLabel];  # extract the suburb name from the parent label
   #sessionProgressTable->reportRegionOrSuburbChange($threadID, undef, $suburbName);     
   
   #$htmlSyntaxTree->printText();
   
   if ($htmlSyntaxTree->containsTextPattern("Search Results"))
   {         
      # if no exact matches are found the search engine sometimes returns related matches - these aren't wanted
      # determine if these are RENT or SALE results
                        
      # the name of the form at the top of the page indicates if its sale or rental     
      $htmlForm = $htmlSyntaxTree->getHTMLForm("formres");
      if ($htmlForm)
      {
         $saleOrRentalFlag = 0;  # sale
      }
      else
      {
         if ($htmlSyntaxTree->containsTextPattern("For Rent Search Results"))
         {            
            # on this site rentals have no 'details' page - the search results contain all the details
            # this is really annoying (has to be catered for below)
      
            $saleOrRentalFlag = 1; # rental;
         }
         else         
         {
            $printLogger->print("WARNING: sale or rental pattern not found\n");
            $crawlerWarning->reportWarning($sourceName, $instanceID, $url, $crawlerWarning->{'CRAWLER_EXPECTED_PATTERN_NOT_FOUND'}, "parseSearchResults: sale or rental pattern not found");
         }
      }
                             
      $htmlSyntaxTree->resetSearchConstraints();   
      $htmlSyntaxTree->setSearchStartConstraintByTagAndClass("div", "property_title"); # start of a result              
      $htmlSyntaxTree->setSearchEndConstraintByTagAndClass("span", "base_credits");
         
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
         
         #   print "START: state=$state: Line:'$thisText' parsed=$parsedThisLine endOfList=$endOfList\n";
                 
         if ((!$parsedThisLine) && ($state == $SEEKING_FIRST_RESULT))
         {
            # if this text is the suburb name, we're in a new record
            if ($thisText =~ /$suburbName/i)
            {
               $state = $PARSING_RESULT_TITLE;               
            }
            $parsedThisLine = 0;  # continue to get title
         }
         
         if ((!$parsedThisLine) && ($state == $PARSING_RESULT_TITLE))
         {
            # the entire first line is the title
            $titleString = $thisText;   # always set
            $state = $PARSING_SUB_LINE;
            $parsedThisLine = 1;
         }          
         
         if ((!$parsedThisLine) && ($state == $PARSING_SUB_LINE))
         {
            # this line is optional - it may indicate that the property is under contract, sold etc
            # if included, it's appended to the title
            # it may also indicate price (this is the case for rentals)
            if ($thisText =~ /\$/gi)
            {
               $titleString .= " ".$thisText;
               $parsedThisLine = 1;
               # REMAIN IN THIS STATE to see what the next line is
            }
            else
            {
               # need to check for certain patterns in the sub line             
               if (($thisText =~ /under/gi) || ($thisText =~ /sold/gi) || ($thisText =~ /deposit/gi) || ($thisText =~ /lease/gi))
               {
                  $titleString .= " ".$thisText;
                  # change state to get source ID
                  $state = $PARSING_SOURCE_ID;
                  $parsedThisLine = 0;  # fall through
               }
               else
               {
                  # nothing obtained - change to next state
                  $state = $PARSING_SOURCE_ID;
                  $parsedThisLine = 0;  # fall through
               }
            }
            
         }          
         
         if ((!$parsedThisLine) && ($state == $PARSING_SOURCE_ID))
         {
            if ($saleOrRentalFlag == 0)
            {
               # this is a sale  - the property ID is in a 'more details' link
               $anchor = $htmlSyntaxTree->getNextAnchorContainingPatternFromLastFound("More Details");
               $temp=$anchor;
               $temp =~ s/prop=(.\d*)&/$sourceID = sprintf("$1")/ei;
            }
            else
            {
               # this is a rental - the property ID is in an email link
               $anchor = $htmlSyntaxTree->getNextAnchorContainingPatternFromLastFound("Email this agent");
               $temp=$anchor;
               $temp =~ s/prop=(.\d*)&/$sourceID = sprintf("$1")/ei;
            }
                              
            #print "$suburbName: '$title' \$$priceLower id=$sourceID\n";
         
            if (($sourceID) && ($anchor))
            {
               #$printLogger->print("   parseSearchResults: encountered anchor id ", $sourceID, " title='$titleString'...\n");
               
               # check if the cache already contains a profile matching this source ID and title           
               $cacheID = $advertisementCache->updateAdvertisementCache($saleOrRentalFlag, $sourceName, $sourceID, $titleString);
               if ($cacheID == 0)
               {
                  $printLogger->print("   parseSearchResults: record already in advertisement cache.\n");
                  $recordsSkipped++;
               }
               else
               {
                  if ($saleOrRentalFlag == 1)
                  {
                     if ($originatingHTMLId)
                     {
                        # this page has already been submitted to the repository      
                        $printLogger->print("   parseSearchDetails: adding another cache reference (rental) for OriginationHTML:$cacheID.\n");
                     
                        $advertisementCache->addReferenceToAdvertisementRepository($cacheID, $originatingHTMLId);
                        $statusTable->addToRecordsParsed($threadID, 1, 1, $url);
                     }
                     else
                     {
                        # rental page - this is THE DETAILS page as well as the results...
                        # this single page generates multiple properties, so save this page now
                        $printLogger->print("   parseSearchDetails: storing rental record in repository for CacheID:$cacheID.\n");
                     
                        $originatingHTMLId = $advertisementCache->storeInAdvertisementRepository($cacheID, $url, $htmlSyntaxTree);
                        $statusTable->addToRecordsParsed($threadID, 1, 1, $url);
                     }
                  }
                  else
                  {
                     # sale (or unknown) - follow the link to the details page
                     $printLogger->print("   parseSearchResults: adding anchor id ", $sourceID, " (cacheID:$cacheID)...\n");                               
                     # IMPORTANT: pass the CachedID through to the details page parser
                     my $httpTransaction = HTTPTransaction::new($anchor, $url, $parentLabel.".".$cacheID);                  
             
                     push @urlList, $httpTransaction;
                  }
               }
           
               #print "  END: state=$state: Line:'$thisText' ts:'$titleString' sid:'$sourceID' parsed=$parsedThisLine\n";
               $recordsEncountered++;  # count records seen
               # 23Jan05:save that this suburb has had some progress against it
               $sessionProgressTable->reportProgressAgainstSuburb($threadID, 1);
            }
            
            $state = $SEEKING_NEXT_RESULT;
            $parsedThisLine = 0;  ## fall through
         }
         
         if ((!$parsedThisLine) && ($state == $SEEKING_NEXT_RESULT))
         {
            # leap to the next result's division
            if (!$htmlSyntaxTree->setSearchStartConstraintByTagAndClassFromLastFound("div", "property_title"))
            {
               # there's no more
               $endOfList = 1;
            }
            $state = $SEEKING_FIRST_RESULT;
            $parsedThisLine = 1;
         }                 
      
        #print "END: state=$state: Line:'$thisText' parsed=$parsedThisLine endOfList=$endOfList\n";        
      }   
      
      $statusTable->addToRecordsEncountered($threadID, $recordsEncountered, $recordsSkipped, $url);   
         
      # now get the anchor for the NEXT button if it's defined 
      
      $htmlSyntaxTree->resetSearchConstraints();
      
      $anchor = $htmlSyntaxTree->getNextAnchorContainingPattern("next");
           
      # ignore the next button if it's only for related results
      if ($anchor)
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
      if ($htmlSyntaxTree->containsTextPattern("No properties found"))
      {
         $printLogger->print("   parseSearchResults: no results for suburb\n");
      }
      else
      {
         $printLogger->print("   parseSearchResults: pattern not found\n");         
         $crawlerWarning->reportWarning($sourceName, $instanceID, $url, $crawlerWarning->{'CRAWLER_EXPECTED_PATTERN_NOT_FOUND'}, "parseSearchResults: pattern not found");
      }
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

# global variable used for display purposes - indicates the current region being processed
my $currentRegion = 'Nil';

# -------------------------------------------------------------------------------------------------

# -------------------------------------------------------------------------------------------------
# parseJustListedChooseSuburbs
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
sub parseJustListedChooseSuburbs

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
   my $checkboxListRef;
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
   my $suburbName;
   my @suburbList;
   my $noOfSuburbs;
   my $okay;
   my $checkboxNo;
      
   $printLogger->print("in parseChooseSuburbs ($parentLabel)\n");
      
   @splitLabel = split /\./, $parentLabel;
   # set global variable for tracking that this instance has been run before
   $currentRegion = $splitLabel[$#splitLabel];    
   $sessionProgressTable->reportRegionOrSuburbChange($threadID, $currentRegion, 'Nil');

   # get the HTML Form instance
   $htmlForm = $htmlSyntaxTree->getHTMLForm("regsub");
    
   if ($htmlForm)
   {       
      if (($startLetter) || ($endLetter))
      {
         $printLogger->print("   parseChooseSuburbs: Filtering suburb names between $startLetter to $endLetter...\n");         
      }
      
      # in this implementation, suburbs are selected one at a time...                 
      $checkboxListRef = $htmlForm->getCheckboxes();
      #$htmlForm->setInputValue("entireregion", "no"); # select subset     

      # extract a list of suburb names from the page...
      # the names are in sequential order in a table
      $htmlSyntaxTree->resetSearchConstraints();
      $htmlSyntaxTree->setSearchStartConstraintByTagAndClass("table", "listing_text");
      $htmlSyntaxTree->setSearchEndConstraintByTagAndClass("span", "base_credits");
      $noOfSuburbs = 0;
      $okay = 1;
      while ($okay)
      {
         $suburbName = trimWhitespace($htmlSyntaxTree->getNextText());
        
         if ($suburbName)
         {        
            $suburbList[$noOfSuburbs] = $suburbName;
            $noOfSuburbs++;
         }
         else
         {
            $okay = 0;
         }
      }        
                           
      if (($noOfSuburbs > 0) && ($checkboxListRef))
      {
         # need to select a subset of suburbs
         $sessionProgressTable->prepareSuburbStateMachine($threadID);     
         
         $checkboxNo = 0;
         foreach (@$checkboxListRef)
         {            
            $acceptSuburb = 0;
            $useThisSuburb = 0;
            # BIG assumation here that checkbox list is same order as suburb name list
            $suburbName = $suburbList[$checkboxNo];
            
            if ($suburbName)
            {                               
               # check if the last suburb has been encountered - if it has, then start processing from this point
               $useThisSuburb = $sessionProgressTable->isSuburbAcceptable($suburbName);           
            }
            
            if ($useThisSuburb)
            {                                
               # determine if the suburbname is in the specific letter constraint
               $acceptSuburb = isSuburbNameInRange($suburbName, $startLetter, $endLetter);              
            }
                        
            if ($acceptSuburb)
            {
               # 23 Jan 05 - another check - see if the suburb has already been 'completed' in this thread
               # if it has been, then don't do it again (avoids special case where servers may return
               # the same suburb for multiple search variations)
               if (!$sessionProgressTable->hasSuburbBeenProcessed($threadID, $suburbName))
               { 
                  #print "accepted\n";                  
                  $htmlForm->clearInputValue('sbs');               # clear previously selected checkboxes
                  $htmlForm->setInputValue('sbs', $_->{'value'});  # the value of the checkbox
                  
                  my $newHTTPTransaction = HTTPTransaction::new($htmlForm, $url, $parentLabel.".".trimWhitespace($suburbName));                              
                  
                  # add this new transaction to the list to return for processing
                  $transactionList[$noOfTransactions] = $newHTTPTransaction;
                  $noOfTransactions++;
               }   
               else
               {
                  $printLogger->print("   parseChooseSuburbs:suburb ", $suburbName, " previously processed in this thread.  Skipping...\n");
               }
            }
            
            $checkboxNo++;  # next suburb name checkbox
         }
         
         $printLogger->print("   parseChooseSuburbs:Created a transaction for $noOfTransactions suburbs...\n");
      }
      else
      {
         $printLogger->print("   parseChooseSuburbs: list of suburb checkboxes not recognised\n");
         $crawlerWarning->reportWarning($sourceName, $instanceID, $url, $crawlerWarning->{'CRAWLER_EXPECTED_FORM_ELEMENT_NOT_FOUND'}, " parseChooseSuburbs: list of suburb checkboxes not recognised");
      }
   }	  
   else 
   {
      $printLogger->print("   parseChooseSuburbs:Search form not found.\n");
      $crawlerWarning->reportWarning($sourceName, $instanceID, $url, $crawlerWarning->{'CRAWLER_EXPECTED_FORM_NOT_FOUND'}, " parseChooseSuburbs:Search form not found");
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
# parseJustListedSalesHomePage
# parses the htmlsyntaxtree to extract the link to the Advertised Sale page
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
sub parseJustListedSalesHomePage

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

   my $printLogger = $documentReader->getGlobalParameter('printLogger');
   my @anchors;
   my $htmlForm;
   my $regionAdded = 0;
   my $useThisRegion;
   my $sessionProgressTable = $documentReader->getSessionProgressTable();   # 23Jan05
   my $sourceName =  $documentReader->getGlobalParameter('source');
   my $crawlerWarning = CrawlerWarning::new($documentReader->getSQLClient());
   
   # --- now extract the property information for this page ---
   $printLogger->print("inParseSalesHomePage ($parentLabel):\n");
         
   # get the HTML Form instance
   $htmlForm = $htmlSyntaxTree->getHTMLForm("formres");
    
   if ($htmlForm)
   {                 
      # javascript changes target and sets some default values
      $htmlForm->overrideAction("/sp/jlresschreg.asp");
      $htmlForm->setInputValue("pricefr", '0');   # default instead of blank
      $htmlForm->setInputValue("priceto", '0');   # default instead of blank
      
      # get the list of regions
      $optionsRef = $htmlForm->getSelectionOptions('region');
                
      $sessionProgressTable->prepareRegionStateMachine($threadID, $currentRegion);  
      
      if ($optionsRef)
      {                
         foreach (@$optionsRef)
         {                                       
            if ($_->{'value'} > 0)  # skip 'region' entry (not set)
            {
               
               # use the state machine to determine if this region should be processed
               $useThisRegion = $sessionProgressTable->isRegionAcceptable($_->{'text'}, $currentRegion);
               #print "   ", $_->getValue(), ":useThisRegion:$useThisRegion useNextRegion:$useNextRegion\n";
            
               # if this flag has been set in the logic above, a transaction is used for this region
               if ($useThisRegion)
               {                                            
                  $htmlForm->setInputValue("region", $_->{'value'});                                    
                  
                  # get the request to get next page for this region
                  
                  my $newHTTPTransaction = HTTPTransaction::new($htmlForm, $url, $parentLabel.".".trimWhitespace($_->{'text'}));
                  #print $htmlForm->getEscapedParameters(), "\n";
               
                  # add this new transaction to the list to return for processing
                  $transactionList[$noOfTransactions] = $newHTTPTransaction;
                  $noOfTransactions++;
               
                  # record which region was last processed in this thread
                  # and reset to the first suburb in the region
                  $sessionProgressTable->reportRegionOrSuburbChange($threadID, $currentRegion, 'Nil');
                  $regionAdded = 1;
               }
            }                     
         }
                 
         if (!$regionAdded)
         {
            # no more regions to process - finished
            $sessionProgressTable->reportRegionOrSuburbChange($threadID, 'Nil', 'Nil');              
         }
         
         $printLogger->print("   ParseSalesHomePage:Created a transaction for $noOfTransactions regions...\n");
      }  
      else
      {
         $crawlerWarning->reportWarning($sourceName, $instanceID, $url, $crawlerWarning->{'CRAWLER_EXPECTED_FORM_ELEMENT_NOT_FOUND'}, "ParseSalesHomePage: List of regions not found");  
      }               
   }	  
   else 
   {
      $printLogger->print("   ParseSalesHomePage:Search form not found.\n");
      $crawlerWarning->reportWarning($sourceName, $instanceID, $url, $crawlerWarning->{'CRAWLER_EXPECTED_FORM_NOT_FOUND'}, "ParseSalesHomePage: Search form not found");
   }
   
   if ($noOfTransactions > 0)
   {      
      return @transactionList;
   }
   else
   {      
      $printLogger->print("   ParseSalesHomePage:returning zero transactions.\n");
      return @emptyList;
   }   
}


# -------------------------------------------------------------------------------------------------
# parseJustListedRentalsHomePage
# parses the htmlsyntaxtree to extract the link to the Advertised Rentals page
# There is a different form for rentals on the same page as the sales form 
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
sub parseJustListedRentalsHomePage

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
      
   my $printLogger = $documentReader->getGlobalParameter('printLogger');
   
   my @anchors;
   my $htmlForm;
   my $regionAdded = 0;
   my $useThisRegion;
   my $sessionProgressTable = $documentReader->getSessionProgressTable();
   my $sourceName =  $documentReader->getGlobalParameter('source');
   my $crawlerWarning = CrawlerWarning::new($documentReader->getSQLClient());      
 
   # --- now extract the property information for this page ---
   $printLogger->print("inParseRentalsHomePage ($parentLabel):\n");
         
   # get the HTML Form instance
   $htmlForm = $htmlSyntaxTree->getHTMLForm("formrent");
    
   if ($htmlForm)
   {                 
      # javascript changes target and sets some default values
      $htmlForm->overrideAction("/sp/jlrentschreg.asp");      
      
      # get the list of regions
      $optionsRef = $htmlForm->getSelectionOptions('in_region');
                      
      $sessionProgressTable->prepareRegionStateMachine($threadID, $currentRegion);  
      
      if ($optionsRef)
      {                
         foreach (@$optionsRef)
         {                                       
            if ($_->{'value'} > 0) # skip 'region' entry (not set)
            {
               # use the state machine to determine if this region should be processed
               $useThisRegion = $sessionProgressTable->isRegionAcceptable($_->{'text'}, $currentRegion);
               #print "   ", $_->getValue(), ":useThisRegion:$useThisRegion useNextRegion:$useNextRegion\n";
            
               # if this flag has been set in the logic above, a transaction is used for this region
               if ($useThisRegion)
               {                                       
                  $htmlForm->setInputValue("in_region", $_->{'value'});
                  
                  # get the request to get next page for this region
                  
                  my $newHTTPTransaction = HTTPTransaction::new($htmlForm, $url, $parentLabel.".".trimWhitespace($_->{'text'}));
                  #print $htmlForm->getEscapedParameters(), "\n";
               
                  # add this new transaction to the list to return for processing
                  $transactionList[$noOfTransactions] = $newHTTPTransaction;
                  $noOfTransactions++;
                  
                   # record which region was last processed in this thread
                  # and reset to the first suburb in the region
                  $sessionProgressTable->reportRegionOrSuburbChange($threadID, $currentRegion, 'Nil');
                  $regionAdded = 1;
               }
            }                     
         }
         
         if (!$regionAdded)
         {
            # no more regions to process - finished
            $sessionProgressTable->reportRegionOrSuburbChange($threadID, 'Nil', 'Nil');              
         }
         
         $printLogger->print("   ParseRentalsHomePage:Created a transaction for $noOfTransactions regions...\n");
      } 
      else
      {
         $crawlerWarning->reportWarning($sourceName, $instanceID, $url, $crawlerWarning->{'CRAWLER_EXPECTED_FORM_ELEMENT_NOT_FOUND'}, "ParseRentalsHomePage: List of regions not found");  
      }              
   }	  
   else 
   {
      $printLogger->print("   ParseRentalsHomePage:Search form not found.\n");
      $crawlerWarning->reportWarning($sourceName, $instanceID, $url, $crawlerWarning->{'CRAWLER_EXPECTED_FORM_NOT_FOUND'}, "ParseRentalsHomePage: Search form not found");
   }
   
   if ($noOfTransactions > 0)
   {      
      return @transactionList;
   }
   else
   {      
      $printLogger->print("   ParseRentalsHomePage:returning zero transactions.\n");
      return @emptyList;
   }   
}


# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# parseJustListedDisplayResponse
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
sub parseJustListedDisplayResponse

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

