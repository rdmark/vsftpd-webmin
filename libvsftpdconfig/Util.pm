package Util;

sub get_permission() {
	my %access = main::get_module_acl();
	
	my $permission = $access{'permission'};
	if (!$permission) {
		$permission = 7; # if no acl just allow everything
	}
	
	return $permission;
}

1;