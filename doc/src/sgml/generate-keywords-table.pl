#!/usr/bin/perl
#
# Generate the keywords table file
# Copyright (c) 2019, PostgreSQL Global Development Group

use strict;
use warnings;

my @sql_versions = reverse sort ('1992', '2011', '2016');

my $srcdir = $ARGV[0];

my %keywords;

# read SQL keywords

foreach my $ver (@sql_versions)
{
	foreach my $res ('reserved', 'nonreserved')
	{
		foreach my $file (glob "$srcdir/keywords/sql${ver}*-${res}.txt")
		{
			open my $fh, '<', $file or die;

			while (<$fh>)
			{
				chomp;
				$keywords{$_}{$ver}{$res} = 1;
			}

			close $fh;
		}
	}
}

# read PostgreSQL keywords

open my $fh, '<', "$srcdir/../../../src/include/parser/kwlist.h" or die;

while (<$fh>)
{
	if (/^PG_KEYWORD\("(\w+)", \w+, (\w+)_KEYWORD\)/)
	{
		$keywords{ uc $1 }{'pg'}{ lc $2 } = 1;
	}
}

close $fh;

# print output

print "<!-- autogenerated, do not edit -->\n";

print <<END;
<table id="keywords-table">
<!--
 <title><acronym>SQL</acronym> Key Words</title>
-->
 <title><acronym>SQL</acronym>キーワード</title>

 <tgroup cols="5">
  <thead>
   <row>
<!--
    <entry>Key Word</entry>
-->
    <entry>キーワード</entry>
    <entry><productname>PostgreSQL</productname></entry>
END

foreach my $ver (@sql_versions)
{
	my $s = ($ver eq '1992' ? 'SQL-92' : "SQL:$ver");
	print "    <entry>$s</entry>\n";
}

print <<END;
   </row>
  </thead>

  <tbody>
END

foreach my $word (sort keys %keywords)
{
	print "   <row>\n";
	print "    <entry><token>$word</token></entry>\n";

	print "    <entry>";
	if ($keywords{$word}{pg}{'unreserved'})
	{
#		print "non-reserved";
		print "未予約";
	}
	elsif ($keywords{$word}{pg}{'col_name'})
	{
#		print "non-reserved (cannot be function or type)";
		print "未予約(関数または型として使用不可)";
	}
	elsif ($keywords{$word}{pg}{'type_func_name'})
	{
#		print "reserved (can be function or type)";
		print "予約(関数または型として使用可)";
	}
	elsif ($keywords{$word}{pg}{'reserved'})
	{
#		print "reserved";
		print "予約";
	}
	print "</entry>\n";

	foreach my $ver (@sql_versions)
	{
		print "    <entry>";
		if ($keywords{$word}{$ver}{'reserved'})
		{
#			print "reserved";
			print "予約";
		}
		elsif ($keywords{$word}{$ver}{'nonreserved'})
		{
#			print "non-reserved";
			print "未予約";
		}
		print "</entry>\n";
	}
	print "   </row>\n";
}

print <<END;
  </tbody>
 </tgroup>
</table>
END
