#!/usr/bin/perl

require "../ui-lib.pl";
require "../web-lib.pl";
require "vsftpd-lib.pl";

use strict;
use libvsftpdconfig::ConfigManager;

my @vsftpd_config = ConfigManager::instance()->config_instances();

print ui_print_header();

my @headers = ["Name", "Value", "Default"];
print ui_columns_start(@headers); 

foreach my $element (@vsftpd_config) {	
	print ui_columns_row([$element->type()->name(), $element->value(), $element->is_default() ? "yes" : "no"]);
}

print ui_table_end();
print ui_print_footer();
