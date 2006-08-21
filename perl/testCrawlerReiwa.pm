#!/usr/bin/perl
# 20Aug2006

sub printHashOfLists
{
   my $hashName = shift;
   my $hashToPrintRef = shift;
     
   print "---[start \%$hashName]---<br/>\n";
   while(($key, $value) = each(%$hashToPrintRef)) 
   {
      # do something with $key and $value
      print "   $key=";
      printList("vals", $value);
   }
   print "---[end   \%$hashName]---<br/>\n";
}

sub printList
{
   my $listName = shift;
   my $listToPrintRef = shift;
   my $first = 1;
     
   print "---[$listName][";
   foreach (@$listToPrintRef) 
   {
      # determine if a comma needs to preceed this element
      if (!$first)
      {
         print ", ";
      }
      else
      {
         $first = 0;
      }
      
      # do something with $key and $value
      print "$_";
   }
   print "]---<br/>\n";
}

# -------------------------------------------------------------------------------------------------
# loadFile
# loads a text file that contains suburb information for the website
#
# Parameters:
#  string properties file name
#
# Returns:
#  reference to a list of the lines in the file
#
sub loadFile 
{ 
   my $filename = shift;  
   my @lines;
   my $lineNo = 0;
      
   if (-e $filename)
   {          
      open(FILE, "<$filename");
      
      @lines = <FILE>;
      
      close(FILE);
   }   
   
   $lineCount = @lines;
   #print "lineCount=$lineCount\n";
   
   return \@lines;
}

# -------------------------------------------------------------------------------------------------

sub parseSuburbList 
{
   my $linesRef = shift;
   my %regionNameHash;
   my %regionIdHash;
   my $lastRegionId = 0;
   
   # loop through all the lines
   foreach (@$linesRef) 
   {      
      if ($_ =~ /stcRegions\[\"main\"\]\[\"(\d+)\"\]/) 
      {
         $line = $_;
         $regionId = $1;
         # this line defines a new main region         
         $line  =~ /\[\"(\d+)\"\]/g;         
         $line =~ /\s\"(\D+)\"/g;   # non-digits (allow spaces & punct)
         $regionName = $1;
                  
         #print $line;
         #print "regionId=$regionId\n";
         #print "regionName=$regionName\n";
         
         my @newList1;
         my @newList2;
         $regionNameHash{$regionId} = \@newList1;
         $regionIdHash{$regionId} = \@newList2;
         
         $lastRegionId = $regionId;
      } 
      else
      {
         # if this is a suburb in the current region, add it to the hash
         if ($_ =~ /stcRegions\[\"$lastRegionId\,allsub\"\]\[\"(\d+)\"\]/)
         {
            $line = $_;
            $suburbId = $1;
            $line =~ /\s\"(\D+)\"/g;      # non-digits (allow spaces & punct)            
            $suburbName = $1;
            #print "$line\n";
            #print "lastRegionId = $lastRegionId\n";
            #print "suburbId = $suburbId\n";
            #print "suburbName = $suburbName\n";
            
            $nameList = $regionNameHash{$lastRegionId};            
            $idList = $regionIdHash{$lastRegionId};
            
            #printList("nameList($lastRegionId)", $nameList);
            # store the name and id in the hash
            $len = @$nameList; 
            $$nameList[$len] = $suburbName;
            $$idList[$len] = $suburbId;            
         }                        
      }      
   }
   #printHashOfLists("regionNameHash", \%regionNameHash);
   #printHashOfLists("regionIdHash", \%regionIdHash);
   
   return (\%regionNameHash, \%regionIdHash);
}

# -------------------------------------------------------------------------------------------------

my $regionNameHash;
my $regionIdHash;

$lines = loadFile("active-suburbs-ressale.js");

($regionNameHash, $regionIdHash) = parseSuburbList($lines);

@regionIds = keys %$regionNameHash;

foreach (@regionIds) 
{
   printList("$_", $$regionIdHash{$_});
}

