BEGIN {
	$DEBUG = 1;
	if ($DEBUG) {
	  use warnings;
	  use CGI::Carp qw(carpout); 
      open(ERROR_LOG, ">>/tmp/webmin_vsftpd_error_log") 
                      or die("Can't setup error log: $!\n");
      carpout(\*ERROR_LOG);
	}
}

do "../ui-lib.pl";
do "../web-lib.pl";

init_config();

sub parse_webmin_log {
	my ($user, $script, $action, $type, $object, $p) = @_;
	
	warn("$action is action");
	
	if ($action eq "persist") {
		if ($type eq "lineconfig") {
			return text('webmin_log_persist', $text{'config_' . $object});
		}
		else {
			return text('webmin_log_persist', $text{'webmin_log_mainconfig'});
		}
	}
	elsif ($action eq "regenerate") {
		return text('webmin_log_regenerate');
	}
	elsif ($action eq "load") {
		return text('webmin_log_loadprofile', $text{'select_profile_' . $object});
	}
	elsif ($action eq "rollback") {
		return text('webmin_log_rollback', $text{'webmin_log_rollback_' . $object});
	}
	elsif ($action eq "manual") {
		return text('webmin_log_manual');
	}
	elsif ($action eq "cmd") {
		return text('webmin_log_cmd_' . $type);
	}
	else {
		return undef;
	}
}
