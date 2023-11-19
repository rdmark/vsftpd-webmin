#!/usr/bin/perl

# vsftpd Webmin module, $Date: 2009-04-30
# Copyright (C) 2009 MagicWave Systems
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

use strict;
use vars qw(%text $tabs %config);
use libvsftpdconfig::ConfigManager;
use libvsftpdconfig::Util;

require "vsftpd-lib.pl";


my $permission = Util::get_permission();

ui_print_header($text{'index_version'} . " " . version(), $text{'index_title'}, "", "intro", 1, 1);

if (!has_command($config{'vsftpd_path'})) {
	error_setup($text{'index_config_invalid'});
	error($text{'index_config_invalid_msg'});
	print ui_print_footer("/", $text{"index_title"});
	exit;
}

my @links = ('manual.cgi?permission=1', 'additional_config.cgi', 'view_logs.cgi?file=vsftpd_log_file'); 
my @names = ($text{'index_link_manual'}, $text{'index_link_additional'}, $text{'index_link_view_logs'});
my @images = ('images/index_manual.png', 'images/misc.gif.png', 'images/log.png');

if ($permission == 7) {
	push @links, 'select_config.cgi', 'edit_config.cgi';
	push @names, $text{'index_link_select'}, $text{'index_link_edit_config'};
	push @images, 'images/kernel.gif.png', 'images/manual.gif.png';
}

print icons_table(\@links, \@names, \@images);

print ui_hr();

my $status;
my $running;
my $standalone = ConfigManager::instance()->config_instance('listen')->value() || 
		ConfigManager::instance()->config_instance('listen_ipv6')->value();
if ($standalone) {
	$running = get_vsftpd_pid();
	$status = $running ? $text{'index_status_running'} : $text{'index_status_stopped'};
}
else {
	$status = $text{'index_status_notlisten'};
}

print text('index_status_msg', "<tt>$status</tt>");

print ui_buttons_start();

if ($standalone) {	
	if ($running) {	
		print ui_buttons_row("cmd_restart.cgi", 
			$text{'index_cmd_restart'}, $text{'index_cmd_restart_msg'});
		print ui_buttons_row("cmd_stop.cgi", 
			$text{'index_cmd_stop'}, $text{'index_cmd_stop_msg'});
	}
	else {
		print ui_buttons_row("cmd_start.cgi", $text{'index_cmd_start'}, $text{'index_cmd_start_msg'});
	}
}

print ui_buttons_row("cmd_kill.cgi", $text{'index_cmd_kill'}, $text{'index_cmd_kill_msg'});

print ui_buttons_end();



print ui_print_footer("/", $text{"index_title"});
