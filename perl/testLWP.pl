#!/usr/bin/perl
# 20Aug2006

use LWP::Simple;
$content = get("http://www.reiwa.com.au/js/active-suburbs-ressale.js");

print $content;
