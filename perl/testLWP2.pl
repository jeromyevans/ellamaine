

use LWP::UserAgent; 
use HTTP::Request; 
use HTTP::Response; 

$userAgent = LWP::UserAgent->new();

$userAgent->agent("Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)"); 
$userAgent->use_alarm(0);  # disable use of alarm on timeouts
$userAgent->timeout(30);   # set 30 second timeout (instead of 3 mins)

#$url = "http://search.cpan.org/s/style.css";
$url = "http://www.reiwa.com.au/js/active-suburbs-ressale.js";
#$url = "http://search.cpan.org/~gaas/libwww-perl-5.805/lib/LWP/UserAgent.pm";

my $req = HTTP::Request->new(GET => $url); 
my $response = $userAgent->request($req);

if ($response->is_error()) {
     printf " %s\n", $response->status_line;
 } else {
   my $content = $response->content();
   $bytes = length $content;
   $count = ($content =~ tr/\n/\n/);
   printf "(%d lines, %d bytes)\n", $count, $bytes;
   print $content;
 }
