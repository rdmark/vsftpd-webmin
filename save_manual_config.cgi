#!/usr/bin/perl

require "../ui-lib.pl";
require "../web-lib.pl";

use vars qw(%in);
use libvsftpdconfig::HtmlUIController;
use libvsftpdconfig::Util;

if (Util::get_permission() == 7) {
	init_config();
	ReadParseMime();

	error_setup($text{'edit_error'});

	$in{'data'} =~ s/\r//g;

	# Write to it
	open_lock_tempfile(OUT, ">$config{'vsftpd_config_file'}");
	print_tempfile(OUT, $in{'data'});
	close_tempfile(OUT);

	webmin_log("manual", undef, undef);
}

redirect("");
