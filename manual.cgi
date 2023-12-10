#!/usr/bin/perl

require "vsftpd-lib.pl";

use strict;

&ReadParse();

use vars qw/%text %in/;
use libvsftpdconfig::HtmlUICreator;
use libvsftpdconfig::ConfigManager;
use libvsftpdconfig::Util;

our $sections = [
	['logging',
	[
		{'title'=>'logs'},
		'dual_log_enable',
		'xferlog_enable',
		'xferlog_file',
		'vsftpd_log_file',
		'log_ftp_protocol',
		'no_log_lock',
		'xferlog_std_format',
		'syslog_enable'
	]], 
	['server_port_ip_nic',
	[
		{'title'=>'server'},
		'accept_timeout',
		'anon_max_rate',
		'connect_timeout',
		'data_connection_timeout',
		# 'delay_failed_login',
		# 'delay_successful_login',
		'ftp_data_port',
		'idle_session_timeout',
		'listen_port',
		'local_max_rate',
		'ftpd_banner',
		'connect_from_port_20',
		'listen',
		'listen_address',
		'listen_address6',
		'pasv_enable',
		'port_enable',
		# 'pasv_addr_resolve',
		'pasv_max_port',
		'pasv_min_port',
		'cmds_allowed',
		'deny_file',
		'hide_file',
		'pasv_address',
		'background',
		'listen_ipv6',
		'check_shell',
		'one_process_model',
		'pasv_promiscuous',
		'port_promiscuous',
		'session_support',
		'setproctitle_enable',
		'tcp_wrappers',
		'use_sendfile',
		'trans_chunk_size',
		'secure_chroot_dir',
		'local_root'
	]],
	['site_and_transfer_features',
	[
		{'title'=>'transfers'},
		'dirlist_enable',
		'download_enable',
		'anon_world_readable_only',
		'anon_mkdir_write_enable',
		'passwd_chroot_enable',
		'ascii_download_enable',
		'ascii_upload_enable',
		'chown_uploads',
		'dirmessage_enable',
		'force_dot_files',
		'hide_ids',
		'ls_recurse_enable',
		'write_enable',
		'anon_other_write_enable',
		'anon_upload_enable',
		'chmod_enable',
		'use_localtime',
		'file_open_mode',
		'local_umask',
		'user_config_dir',
		# 'lock_upload_files',
		# 'mdtm_write',
		'async_abor_enable',
		'ssl_enable',
		'ssl_sslv2',
		'ssl_sslv3',
		'ssl_tlsv1',
		'run_as_launching_user',
		'anon_umask',
		'banner_file',
		'dsa_cert_file',
		# 'dsa_private_key_file',
		'rsa_cert_file',
		# 'rsa_private_key_file',
		'message_file',
		'ssl_ciphers'
	]], 
	['users_logins',
	[
		{'title'=>'users'},
		'anonymous_enable',
		'chroot_list_enable',
		'chroot_local_user',
		'deny_email_enable',
		'guest_enable',
		'local_enable',
		'virtual_use_local_privs',
		'max_clients',
		# 'max_login_fails',
		'max_per_ip',
		'no_anon_password',
		'secure_email_list_enable',
		'text_userdb_names',
		'tilde_user_enable',
		'userlist_deny',
		'userlist_enable',
		'anon_root',
		'guest_username',
		'nopriv_user',
		'pam_service_name',
		'user_sub_token',
		'allow_anon_ssl',
		# 'force_anon_data_ssl',
		# 'force_anon_logins_ssl',
		'force_local_data_ssl',
		'force_local_logins_ssl',
		'banned_email_file',
		'chown_username',
		'chroot_list_file',
		'email_password_file',
		'ftp_username',
		'userlist_file'
	]]
];

my @perms = (['basic', 1], ['advanced', 2], ['manual', 4]); 

ui_print_header(undef, $text{'manual_title'}, "", "manual", 1, 1);

print text('manual_show_options');

if (exists $in{'error'}) {
	print '<div style="color: red; font-weight: bold;">';
		
	my $error = $in{'error'};
	
	if ($error eq "error_save") {
		error_setup($text{'manual_error_save'});
		error(HtmlUICreator::render_error_save());
	}
	else {
		print "An error occurred"; # this can't happen, but just in case
	}
	
	print '</div>'
}

my @perm_opts;

my $permission = HtmlUICreator::get_permission();
my $conf_permission = Util::get_permission();

print ui_form_start('manual.cgi', 'post');
foreach my $opt (@perms) {
	if ($opt->[1] & $conf_permission) {
		push @perm_opts, [$opt->[1], $text{'manual_show_option_' . $opt->[0]}];
	}
}
print ui_radio('permission', $permission , \@perm_opts);
print ui_form_end([ ['select', $text{'manual_select_option'}] ]);

print HtmlUICreator::render_sections($sections, "logging");

ui_print_footer(undef, $text{'return_text'});
