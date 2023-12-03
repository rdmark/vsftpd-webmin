#!/usr/bin/perl

do "additional_config_options.pl";

use strict;
use vars qw(%text %in $files);
require "vsftpd-lib.pl";

use libvsftpdconfig::HtmlUICreator;

# [ [option, textname, [conflicting options], enable option, location option], ... ]

ui_print_header(undef, text('additional_title'), "", "additional", 1, 1);

print HtmlUICreator::render_js_popup_start();

print ui_form_start('additional_config.cgi', 'get');
print ui_select('file', $in{'file'}, [ map {[ @{$_}[0], $text{'config_' . @{$_}[0]} ] } @{$files} ]);
print ui_form_end([['change', text('additional_select_file')]]);

if (exists $in{'file'}) {
	my ($conflicts, $add_opts);
	foreach my $file (@{$files}) {
		if (@{$file}[0] eq $in{'file'}) {
			$conflicts = @{$file}[1];
			$add_opts = @{$file}[2];
		}
	}
	print HtmlUICreator::render_line_config_file($in{'file'}, $conflicts, $add_opts);
}

ui_print_footer(undef, $text{'return_text'});
