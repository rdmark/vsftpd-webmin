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

require "../ui-lib.pl";
require "../web-lib.pl";

init_config();
ReadParse();

%access = get_module_acl();

package vsftpd_lib;

@EXPORT = qw($tabs);

sub get_vsftpd_pid() {
	return main::check_pid_file($main::config{'vsftpd_pid_file'});
}

sub stop() {
	my $out = main::system_logged("$main::config{'vsftpd_cmd_stop'} 2>&1 </dev/null");
	main::webmin_log("cmd", "stop", undef, undef);
	return "<pre>$out</pre>" if ($?);
}

sub start() {
	my $out = main::system_logged("$main::config{'vsftpd_cmd_start'} 2>&1 </dev/null");
	main::webmin_log("cmd", "start", undef, undef);
	return "<pre>$out</pre>" if ($?);
}

sub restart() {
	my $out = main::system_logged("$main::config{'vsftpd_cmd_restart'} 2>&1 </dev/null");
	main::webmin_log("cmd", "restart", undef, undef);
	return "<pre>$out</pre>" if ($?);
}

sub kill() {
	# regex matches the path itself if it contains no / or the last element in a path 
	$main::config{'vsftpd_path'} =~ m!^((([^/])+)|(.*/([^/]+)))$!;	
	my $cmd = $2 . $5; # either one of these contains something
	
	if ($cmd) {
		main::system_logged('pkill', '^' . $cmd . '$');
		main::webmin_log("cmd", "kill", undef, undef);
	}
}

sub userdb_regenerate($) {
	my $userdb = shift;
	my $dbname = $userdb . ".db";	
		
	my $mask = umask();
	umask(0077);	
	main::system_logged($main::config{'cmd_dbload'}, "-T", "-t", "hash", "-f",
				$userdb . ".txt", $dbname);
	umask($mask);
	
	main::webmin_log("regenerate", "userdb", undef, undef);
}

sub version() {
	if (!main::has_command($main::config{'vsftpd_path'})) {
		return "x";
	}
			
	my $version = `$main::config{'vsftpd_path'} -v 0>&1`;
	$version =~ m/version (.+)/;
	
	return $1;
}

1;

package main;
