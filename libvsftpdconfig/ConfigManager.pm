package ConfigManager;

use strict;
use vars qw/%config/;
use libvsftpdconfig::config::ConfigInstance;
use libvsftpdconfig::config::ConfigType;
use libvsftpdconfig::Util;

our $profiles = [
	['stand_alone', 
		{
			'listen'=>1,
			'max_clients'=>200,
			'max_per_ip'=>4,
			'anonymous_enable'=>1,
			'local_enable'=>0,
			'write_enable'=>0,
			'anon_upload_enable'=>0,
			'anon_mkdir_write_enable'=>0,
			'anon_other_write_enable'=>0,
			'anon_world_readable_only'=>1,
			'connect_from_port_20'=>1,
			'hide_ids'=>1,
			'pasv_min_port'=>50000,
			'pasv_max_port'=>60000,
			'xferlog_enable'=>1,
			'ls_recurse_enable'=>0,
			'ascii_download_enable'=>0,
			'async_abor_enable'=>1,
			'one_process_model'=>1,
			'idle_session_timeout'=>120,
			'data_connection_timeout'=>300,
			'accept_timeout'=>60,
			'connect_timeout'=>60,
			'anon_max_rate'=>50000,
			'ftp_username'=>'ftp'		
		},
	 ['ftp_username']
	],
	['virtual_users',
		{
			'anonymous_enable'=>0,
			'local_enable'=>1,
			'write_enable'=>0,
			'anon_upload_enable'=>0,
			'anon_mkdir_write_enable'=>0,
			'anon_other_write_enable'=>0,
			'chroot_local_user'=>1,
			'guest_enable'=>1,
			'guest_username'=>'virtual',
			'listen'=>1,
			'pasv_min_port'=>30000,
			'pasv_max_port'=>30999,
			'userdb'=>'/etc/vsftpd.users.db'		
		},
	 ['guest_username']
	]
];

# create configuration defaults
our %vsftpd_config_types;
our $instance;

sub add_config_type_full {
	my ($name, $value_type, $value_default, $virtual, $restricted) = @_;

	$vsftpd_config_types{$name} =
	  ConfigType::new($name, $value_type, $value_default, $virtual, $restricted);
}

sub add_config_type {
	my ($name, $value_type, $value_default, $restricted) = @_;

	add_config_type_full($name, $value_type, $value_default, undef, $restricted);
}

sub instance() {
	return instance_file($main::config{"vsftpd_config_file"});
}

sub instance_file($) {
	my $file = shift;
	
	if (!$instance) {
		$instance = ConfigManager::new($file);
	}
	
	return $instance;
}

sub new($) {
	my $self = {};
	bless $self;

	$self->{CONFIG_FILENAME} = shift;
	$self->read_config();

	return $self;
}

sub read_config_userdb() {
	my $self = shift;
	
	my $pam_file = main::read_file_contents($self->get_pam_file());
	if ($pam_file =~ m/pam_userdb.so.+db=(\S+)/) {
		return $1;
	}
	
	return "";
}

# Reads the configurations file
# returns a hash with key/value pairs
sub read_config() {
	my $self = shift;

	my $filename = $self->{CONFIG_FILENAME};
	my %file_contents;
	my %instances;

	main::read_file( $filename, \%file_contents );

	my @virtuals;
	foreach my $key ( sort keys %vsftpd_config_types ) { 
		my $type  = $vsftpd_config_types{$key};
		
		# Postpone virtual options as they can depend on values in vsftpd.conf
		if ($type->virtual()) {
			push @virtuals, $type;
		}
		
		my $value = $file_contents{$key};		
		$instances{$key} = ConfigInstance::new( $type, $value );
	}
	$self->{CONFIG_INSTANCES} = \%instances;
	
	foreach my $virtual (@virtuals) {
		my $value;
		if ($virtual->name() eq 'userdb') { # XXX: refactor with strategy pattern
			$value = $self->read_config_userdb();			
		}
		
		$instances{$virtual->name()}->set_value($value);		 
	}	
}

sub config_instances() {
	my $self = shift;

	return values %{ $self->{CONFIG_INSTANCES} };
}

sub config_instance($) {
	my ( $self, $name ) = @_;

	if ( !exists( $self->{CONFIG_INSTANCES}{$name} ) ) {
		die("Unknown config name given: $name");
	}

	return $self->{CONFIG_INSTANCES}{$name};
}

sub get_pam_file() {
	my $self = shift;
	
	return $main::config{'pam_service_dir'} . "/" . $self->config_instance('pam_service_name')->value();	
}

# Needs some special handling as this is really a PAM feature and is separate from vsftpd
sub persist_userdb($) {
	my ($self, $value) = @_;
	
	if (!exists $main::config{'pam_service_dir'} || 
			!$self->config_instance('pam_service_name')->value()) {
		warn("Not persisting userdb option as pam.d file not specified");
		return;
	}
	
	if ($value->value()) {
		my $val = $value->value();
		$val =~ s/\.db//;
		$value->value($val);
	}
	
	
	my $pam_filename = $self->get_pam_file();
	my $contents = main::read_file_contents($pam_filename);
	
	# check if already configured for pam_userdb, we might need to backup or restore the file.
	# Note: this is not an exhaustive check, could as well be specified in an @include file
	my $configured = $contents =~ m/pam_userdb.so\s+db=/;		
	my $backup = "/etc/webmin/vsftpd/pam_d_backup_webmin";
	if ($value->value() && !$configured) {  # enable it
		main::copy_source_dest($pam_filename, $backup);
	}
	elsif (!$value->value() && $configured) { # disable it
		if (-w $backup) { # if we made a backup, otherwise we can't do much
			main::rename_logged($backup, $pam_filename);
		}
		
		return;
	}
	
	my $vsftpd_db_name = $value->value();
	$vsftpd_db_name =~ s/\.db//; 
		
	my $template = main::read_file_contents(main::module_root_directory('vsftpd') . "/vsftpd_pam_d_template");
	$template = main::substitute_template($template, {'USERDB'=>$vsftpd_db_name});
	
	main::lock_file($pam_filename);
	open (FILE, ">$pam_filename");
	print FILE $template;
	close FILE;
	main::unlock_file($pam_filename);
	
	main::webmin_log("persist", "main_config", "userdb", undef);
}

sub persist {
	my $self = shift;
	my $permission = shift;
	
	my %access = main::get_module_acl();
	
	if (!$permission) {
		$permission = Util::get_permission();
	}

	my %contents;
	foreach my $value ( values %{ $self->{CONFIG_INSTANCES} } ) {				
		if ($value->type()->virtual()) {
			if ($value->type->name() eq 'userdb') {
				$self->persist_userdb($value);
			}
		}
		elsif ($value->is_default()) {
			next;
		}
		else {
			$contents{$value->type()->name()} = $value->value_text();					
		}
	}
		
	if (!$self->can_rollback("_perm")) {
		main::rename_logged($self->{CONFIG_FILENAME}, $self->backup_name("_perm"));
	} 
	else {		
		main::rename_logged($self->{CONFIG_FILENAME}, $self->backup_name());
	}
	main::lock_file($self->{CONFIG_FILENAME});
	main::write_file($self->{CONFIG_FILENAME}, \%contents);
	main::unlock_file($self->{CONFIG_FILENAME});
	
	main::webmin_log("persist", "main_config", "main", undef);

	return 1;
}

sub backup_name {
	my $self = shift;
	my $optional = shift;
	
	return "/etc/webmin/vsftpd/vsftpd.conf.webmin_backup" . $optional;
}

sub can_rollback {
	my $self = shift;
	my $type = shift;
		
	return -e $self->backup_name($type);
}

sub rollback {
	my $self = shift;
	my $type = shift;
	
	warn("GONNAA ROLLBACKKKK" . $type);
	if ($self->can_rollback($type)) {
		warn("rollback: " . main::rename_logged($self->backup_name($type), $self->{CONFIG_FILENAME}));
		main::webmin_log("rollback", "main_config", $type ? $type : "oneversion", undef);
	}
	
	return 1;
}

sub load_profile($) {
	my ($self, $profile_name, %overrides) = @_;
	
	my $profile = (grep { @{$_}[0] eq $profile_name } @{$profiles})[0];
		
	my %instances;
	foreach my $type ( values %vsftpd_config_types ) {
		$instances{$type->name()} = ConfigInstance::new( $type, undef);
	}
	$self->{CONFIG_INSTANCES} = \%instances;
	
	my %options = %{@{$profile}[1]};
	foreach my $option (keys %options) {
		warn("$option: $overrides{$option}");
		
		my $value = $overrides{$option} ? $overrides{$option} : $options{$option};
		if (!$self->config_instance($option)->set_value($value)) {
			return ($option, $value);	
		}
	}
	
	main::webmin_log("load", "profile", $profile_name, undef);
	
	return;
}

BEGIN {
	# Boolean options
	add_config_type( "allow_anon_ssl",           ConfigType::BOOLEAN, 0, 4 );
	add_config_type( "anon_mkdir_write_enable",  ConfigType::BOOLEAN, 0, 1 ); # make anon write options restricted
	add_config_type( "anon_other_write_enable",  ConfigType::BOOLEAN, 0, 2 );
	add_config_type( "anon_upload_enable",       ConfigType::BOOLEAN, 0, 2 );
	add_config_type( "anon_world_readable_only", ConfigType::BOOLEAN, 1, 1 );
	add_config_type( "anonymous_enable",         ConfigType::BOOLEAN, 1, 1 );
	add_config_type( "ascii_download_enable",    ConfigType::BOOLEAN, 0, 2 );
	add_config_type( "ascii_upload_enable",      ConfigType::BOOLEAN, 0, 4 );
	add_config_type( "async_abor_enable",        ConfigType::BOOLEAN, 0, 4 );
	add_config_type( "background",               ConfigType::BOOLEAN, 0, 4 );
	add_config_type( "check_shell",              ConfigType::BOOLEAN, 1, 4 );
	add_config_type( "chmod_enable",             ConfigType::BOOLEAN, 1, 2 );
	add_config_type( "chown_uploads",            ConfigType::BOOLEAN, 0, 2 );
	add_config_type( "chroot_list_enable",       ConfigType::BOOLEAN, 0, 1 );
	add_config_type( "chroot_local_user",        ConfigType::BOOLEAN, 0, 1 );
	add_config_type( "connect_from_port_20",     ConfigType::BOOLEAN, 0, 2 );
	add_config_type( "deny_email_enable",        ConfigType::BOOLEAN, 0, 1 );
	add_config_type( "dirlist_enable",           ConfigType::BOOLEAN, 1, 1 );
	add_config_type( "dirmessage_enable",        ConfigType::BOOLEAN, 0, 2 );
	add_config_type( "download_enable",          ConfigType::BOOLEAN, 1, 1 );
	add_config_type( "dual_log_enable",          ConfigType::BOOLEAN, 0, 1 );
	add_config_type( "force_dot_files",          ConfigType::BOOLEAN, 0, 2 );
	add_config_type( "force_local_data_ssl",     ConfigType::BOOLEAN, 1, 4 );
	add_config_type( "force_local_logins_ssl",   ConfigType::BOOLEAN, 1, 4 );
	add_config_type( "guest_enable",             ConfigType::BOOLEAN, 0, 1 );
	add_config_type( "hide_ids",                 ConfigType::BOOLEAN, 0, 4 );
	add_config_type( "listen",                   ConfigType::BOOLEAN, 0, 4 );
	add_config_type( "listen_ipv6",              ConfigType::BOOLEAN, 0, 4 );
	add_config_type( "local_enable",             ConfigType::BOOLEAN, 0, 1 );
	add_config_type( "log_ftp_protocol",         ConfigType::BOOLEAN, 0, 2 );
	add_config_type( "ls_recurse_enable",        ConfigType::BOOLEAN, 0, 2 );
	add_config_type( "no_anon_password",         ConfigType::BOOLEAN, 0, 2 );
	add_config_type( "no_log_lock",              ConfigType::BOOLEAN, 0, 1 );
	add_config_type( "one_process_model",        ConfigType::BOOLEAN, 0, 4 );
	add_config_type( "passwd_chroot_enable",     ConfigType::BOOLEAN, 0, 1 );
	add_config_type( "pasv_enable",              ConfigType::BOOLEAN, 1, 2 );
	add_config_type( "pasv_promiscuous",         ConfigType::BOOLEAN, 0, 4 );
	add_config_type( "port_enable",              ConfigType::BOOLEAN, 1, 2 );
	add_config_type( "port_promiscuous",         ConfigType::BOOLEAN, 0, 4 );
	add_config_type( "run_as_launching_user",    ConfigType::BOOLEAN, 0, 1 );
	add_config_type( "secure_email_list_enable", ConfigType::BOOLEAN, 0, 2 );
	add_config_type( "session_support",          ConfigType::BOOLEAN, 0, 4 );
	add_config_type( "setproctitle_enable",      ConfigType::BOOLEAN, 0, 4 );
	add_config_type( "ssl_enable",               ConfigType::BOOLEAN, 0, 4 );
	add_config_type( "ssl_sslv2",                ConfigType::BOOLEAN, 0, 4 );
	add_config_type( "ssl_sslv3",                ConfigType::BOOLEAN, 0, 4 );
	add_config_type( "ssl_tlsv1",                ConfigType::BOOLEAN, 1, 4 );
	add_config_type( "syslog_enable",            ConfigType::BOOLEAN, 0, 4 );
	add_config_type( "tcp_wrappers",             ConfigType::BOOLEAN, 0, 4 );
	add_config_type( "text_userdb_names",        ConfigType::BOOLEAN, 0, 2 );
	add_config_type( "tilde_user_enable",        ConfigType::BOOLEAN, 0, 2 );
	add_config_type( "use_localtime",            ConfigType::BOOLEAN, 0, 2 );
	add_config_type( "use_sendfile",             ConfigType::BOOLEAN, 1, 4 );
	add_config_type( "userlist_deny",            ConfigType::BOOLEAN, 1, 2 );
	add_config_type( "userlist_enable",          ConfigType::BOOLEAN, 0, 2 );
	add_config_type( "virtual_use_local_privs",  ConfigType::BOOLEAN, 0, 1 );
	add_config_type( "write_enable",             ConfigType::BOOLEAN, 0, 2 );
	add_config_type( "xferlog_enable",           ConfigType::BOOLEAN, 0, 1 );
	add_config_type( "xferlog_std_format",       ConfigType::BOOLEAN, 0 );

	# Digit options
	add_config_type( "accept_timeout",          ConfigType::DIGIT, 60, 1 );
	add_config_type( "anon_max_rate",           ConfigType::DIGIT, 0,  1 );
	add_config_type( "anon_umask",              ConfigType::DIGIT, 077, 4 );
	add_config_type( "connect_timeout",         ConfigType::DIGIT, 60, 1);
	add_config_type( "data_connection_timeout", ConfigType::DIGIT, 300, 1 );
	add_config_type( "file_open_mode",          ConfigType::DIGIT, 0666, 2 );
	add_config_type( "ftp_data_port",           ConfigType::DIGIT, 20, 1 );
	add_config_type( "idle_session_timeout",    ConfigType::DIGIT, 300, 1 );
	add_config_type( "listen_port",             ConfigType::DIGIT, 21, 1 );
	add_config_type( "local_max_rate",          ConfigType::DIGIT, 0, 1 );
	add_config_type( "local_umask",             ConfigType::DIGIT, 077, 2 );
	add_config_type( "max_clients",             ConfigType::DIGIT, 0, 1 );
	add_config_type( "max_per_ip",              ConfigType::DIGIT, 0, 1 );
	add_config_type( "pasv_max_port",           ConfigType::DIGIT, 0, 2 );
	add_config_type( "pasv_min_port",           ConfigType::DIGIT, 0, 2 );
	add_config_type( "trans_chunk_size",        ConfigType::DIGIT, 0, 4 );

	# String options
	add_config_type( "anon_root", 			ConfigType::STRING, "", 2 );
	add_config_type( "banned_email_file", 	ConfigType::STRING, "/etc/vsftpd.banned_emails", 4 );
	add_config_type( "banner_file",    		ConfigType::STRING, "", 4 );
	add_config_type( "chown_username", 		ConfigType::STRING, "root" );
	add_config_type( "chroot_list_file", 	ConfigType::STRING, "/etc/vsftpd.chroot_list", 1 );
	add_config_type( "cmds_allowed",  		ConfigType::STRING, "", 2 );
	add_config_type( "deny_file",     		ConfigType::STRING, "", 2 );
	add_config_type( "dsa_cert_file", 		ConfigType::STRING, "", 4 );
	add_config_type( "email_password_file", ConfigType::STRING, "/etc/vsftpd.email_passwords", 4 );	
	add_config_type( "ftpd_banner",      	ConfigType::STRING, "", 1 );	
	add_config_type( "hide_file",        	ConfigType::STRING, "", 2 );
	add_config_type( "listen_address",   	ConfigType::STRING, "", 2 );
	add_config_type( "listen_address6",  	ConfigType::STRING, "", 2 );
	add_config_type( "local_root",       	ConfigType::STRING, "", 4 );
	add_config_type( "message_file",     	ConfigType::STRING, ".message", 4 );
	add_config_type( "nopriv_user",      	ConfigType::STRING, "nobody", 2 );
	add_config_type( "pam_service_name", 	ConfigType::STRING, "vsftpd", 2 );
	add_config_type( "pasv_address",     	ConfigType::STRING, "", 2 );
	add_config_type( "rsa_cert_file", 		ConfigType::STRING, "/usr/share/ssl/certs/vsftpd.pem", 4 );
	add_config_type( "secure_chroot_dir", 	ConfigType::STRING, "/usr/share/empty", 4 );
	add_config_type( "ssl_ciphers",     	ConfigType::STRING, "DES-CBC3-SHA", 4 );
	add_config_type( "user_config_dir", 	ConfigType::STRING, "", 2 );
	add_config_type( "user_sub_token",  	ConfigType::STRING, "", 2 );
	add_config_type( "userlist_file", 		ConfigType::STRING,	"/etc/vsftpd.user_list", 4 );
	add_config_type( "vsftpd_log_file",		ConfigType::STRING,	"/var/log/vsftpd.log", 2 );
	add_config_type( "xferlog_file", 		ConfigType::STRING, "/var/log/xferlog", 2 );
	
	# Username options
	add_config_type( "guest_username",   	ConfigType::USERNAME, "ftp", 2 );
	add_config_type( "ftp_username",     	ConfigType::USERNAME, "ftp", 4 );

	# Virtual options
	add_config_type_full( "userdb", ConfigType::STRING, "", 1, 4 ); # This option is stored in pam.d	
}

1;
