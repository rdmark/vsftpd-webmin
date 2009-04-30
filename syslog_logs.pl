#!/usr/bin/perl

# Contains a function to supply the syslog module with extra logs

require "../web-lib.pl";

use vars qw(%text);
use libvsftpdconfig::ConfigManager;


# syslog_getlogs()
# Returns the vsftpd log
sub syslog_getlogs
{
	my %vconfig = get_module_info('vsftpd');
	
	my $instance = ConfigManager::instance_file($vconfig{'vsftpd_config_file'});
	
	my $active = !$instance->config_instance('syslog_enable')->value();
			
	return ( {'file' => $instance->config_instance('vsftpd_log_file')->value(),
			  'desc' => 'vsftpd logfile',
			  'active' => $active
			 },
			 {'file' => $instance->config_instance('xferlog_file')->value(),
			  'desc' => 'vsftpd xferlog',
			  'active' => $active				 	
			 } );
}