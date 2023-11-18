package Util;

use WebminCore;

sub get_permission() {
	my %access = get_module_acl();
	
	my $permission = $access{'permission'};
	if (!$permission) {
		$permission = 7; # if no acl just allow everything
	}
	
	return $permission;
}

1;