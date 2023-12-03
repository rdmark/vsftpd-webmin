#!/usr/bin/perl
# Ripped from the sshd webmin module

use libvsftpdconfig::Util;

require "vsftpd-lib.pl";

use strict;
use vars qw(%text %in $data %config);

ui_print_header(undef, $text{'edit_title'}, "", "edit", 1, 1);

if (Util::get_permission() != 7) {
	redirect("");
}

# Work out and show the files
print ui_form_start('save_manual_config.cgi', 'form-data');
my $data = read_file_contents($config{'vsftpd_config_file'});

print ui_textarea("data", $data, 20, 80),"\n";
print ui_form_end([ [ "save", $text{'save'} ] ]);

ui_print_footer(undef, $text{'return_text'});
