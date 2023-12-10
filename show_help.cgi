#!/usr/bin/perl

do "vsftpd-lib.pl";

use libvsftpdconfig::DocReader;

&ReadParse();

my $subject = $in{'subject'};
popup_header($text{'help_popup_header'});
print ui_subheading($text{'config_' . $subject});

print "<div>Configuration name: <tt>$subject</tt></div><br/>";

if ($text{'help_' . $subject}) {
	print $text{'help_' . $subject};
}
else {
	print "<pre>";	
	print DocReader::instance()->get_subject($subject);
	print "</pre>";	
}

popup_footer();
