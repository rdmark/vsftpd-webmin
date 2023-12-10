BEGIN {
	push(@INC, "..");
	$DEBUG = 0;
	if ($DEBUG) {
		use warnings;
		use CGI::Carp qw(carpout);
		open(ERROR_LOG, ">>/tmp/webmin_vsftpd_error_log")
			or die("Can't setup error log: $!\n");
		carpout(\*ERROR_LOG);
	}
};
use WebminCore;

init_config();

%access = get_module_acl();

@EXPORT = qw($tabs);

sub get_vsftpd_pid() {
	return find_byname($config{'vsftpd_path'});
}

sub stop() {
	my $out = system_logged("$config{'vsftpd_cmd_stop'} 2>&1 </dev/null");
	webmin_log("cmd", "stop", undef, undef);
	return "<pre>$out</pre>" if ($?);
}

sub start() {
	my $out = system_logged("$config{'vsftpd_cmd_start'} 2>&1 </dev/null");
	webmin_log("cmd", "start", undef, undef);
	return "<pre>$out</pre>" if ($?);
}

sub restart() {
	my $out = system_logged("$config{'vsftpd_cmd_restart'} 2>&1 </dev/null");
	webmin_log("cmd", "restart", undef, undef);
	return "<pre>$out</pre>" if ($?);
}

sub pkill() {
	# regex matches the path itself if it contains no / or the last element in a path
	$config{'vsftpd_path'} =~ m!^((([^/])+)|(.*/([^/]+)))$!;
	my $cmd = $2 . $5; # either one of these contains something

	if ($cmd) {
		system_logged('pkill', '^' . $cmd . '$');
		webmin_log("cmd", "kill", undef, undef);
	}
}

sub userdb_regenerate($) {
	my $userdb = shift;
	my $dbname = $userdb . ".db";

	my $mask = umask();
	umask(0077);
	system_logged($config{'cmd_dbload'}, "-T", "-t", "hash", "-f",
				$userdb . ".txt", $dbname);
	umask($mask);

	webmin_log("regenerate", "userdb", undef, undef);
}

sub version() {
	if (!has_command($config{'vsftpd_path'})) {
		return "x";
	}

	my $version = `$config{'vsftpd_path'} -v 0>&1`;
	$version =~ m/version (.+)/;

	return $1;
}

1;
