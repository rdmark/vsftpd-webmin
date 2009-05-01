#!/usr/bin/perl

require "libvsftpdconfig/vsftpd-lib.pl";

use libvsftpdconfig::HtmlUICreator;
use libvsftpdconfig::ConfigManager;

ui_print_header(undef, $text{'select_title'}, "", "profile", 1, 1);

if (exists $in{'selected'}) {
	print '<div style="font-weight: bold">' . text('selected_ok') . "</div><br/><br/>";
}
elsif (exists $in{'error'}) {
	my $error = $in{'error'};
	
	error_setup($text{'select_error_save'});
	error(HtmlUICreator::render_error_save());
}
else {
	print text('select_description');
	
	print ui_form_start("save_select.cgi", "post");	
	
	foreach my $o (@{$ConfigManager::profiles}) {
		print "<div>";
		
		my @option = @{$o};
			
		print ui_oneradio('profile', $option[0], $text{'select_profile_' . $option[0]}, undef);
		foreach my $feat (@{$option[2]}) {		
			# Little trick to make sure we show the default value, change is not actually persisted
			# so it's safe
			my $instance = ConfigManager::instance()->config_instance($feat);
			$instance->value($option[1]{$feat} ? $option[1]{$feat} : $instance->type()->value_default()); 
			
			print "<div>" . $text{"select_profile_" . $option[0] . "_" . $feat} . ": " .
				HtmlUICreator::render_config_instance($feat, 7) . "</div>";
		}
		
		print "</div>";
	}
	
	print ui_form_end([['select', $text{'select_do'}]]);
}

ui_print_footer(undef, $text{'index_title'});
