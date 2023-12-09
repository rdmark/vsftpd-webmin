#!/usr/bin/perl

# bs: copied this for the biggest part from the syslog-ng module
# Show a log file, 

require 'vsftpd-lib.pl';

use libvsftpdconfig::ConfigManager;

&foreign_require("proc", "proc-lib.pl");

&ReadParse();

# Work out the file
my $file_selected = $in{'file'};

ui_print_header("<tt>".($file || $cmd)."</tt>", $text{'view_logs_title'}, "");

print ui_form_start('view_logs.cgi', 'post');

$lines = $in{'lines'} ? int($in{'lines'}) : 20;
$filter = $in{'filter'} ? quotemeta($in{'filter'}) : "";

my @files = (['vsftpd_log_file', 
				$text{'view_logs_vsftpd_log_file'}],
			 ['xferlog_file', 
			 	$text{'view_logs_xferlog_file'}]);
			 	
if (grep @files, { $_[0] eq $file_selected }) {
	$file = ConfigManager::instance()->config_instance($file_selected)->value();
}

print text('view_logs_file') . ui_select('file', $file_selected, \@files);

print ' ' . text('view_logs_lines') . ui_textbox(lines, $lines, 3);

print ' ' . text('view_logs_filter');
print ui_textbox("filter", $in{'filter'}, 25);

print ui_form_end([['submit', $text{'view_logs_submit'}]]);

$| = 1;
print "<pre>";
local $tailcmd = $config{'tail_cmd'} || "tail -n LINES";
$tailcmd =~ s/LINES/$lines/g;
if ($filter ne "") {
	# Are we supposed to filter anything? Then use grep.
	my @cats;
	if ($cmd) {
		push(@cats, $cmd);
		}
	elsif ($config{'compressed'}) {
		# All compressed versions
		foreach $l (&all_log_files($file)) {
			$c = &catter_command($l);
			push(@cats, $c) if ($c);
			}
		}
	else {
		# Just the one log
		@cats = ( "cat ".quotemeta($file) );
		}
	$cat = "(".join(" ; ", @cats).")";
	$got = &foreign_call("proc", "safe_process_exec",
		"$cat | grep -i $filter | $tailcmd",
		0, 0, STDOUT, undef, 1, 0, undef, 1);
	}
else {
	# Not filtering .. so cat the most recent non-empty file
	if ($cmd) {
		$catter = $cmd;
		}
	else {
		$catter = "cat ".quotemeta($file);
		if (!-s $file && $config{'compressed'}) {
			foreach $l (&all_log_files($file)) {
				next if (!-s $l);
				$c = &catter_command($l);
				if ($c) {
					$catter = $c;
					last;
					}
				}
			}
		}
	$got = &foreign_call("proc", "safe_process_exec",
		$catter." | $tailcmd", 
		0, 0, STDOUT, undef, 1, 0, undef, 1);
	}
print "<i>$text{'view_logs_empty'}</i>\n" if (!$got);
print "</pre>\n";

ui_print_footer(undef, $text{'return_text'});
