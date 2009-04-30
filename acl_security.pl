do "../web-lib.pl";
do "../ui-lib.pl";

init_config();

sub acl_security_form
{
	print $text{'acl_permission'};
	
	print text('acl_permission');
	print ui_select('permission', $_[0]->{'permission'}, 
		[
			['7', $text{'acl_permission_all'}], 
			['3', $text{'acl_permission_advanced'}], 
			['1', $text{'acl_permission_basic'}]
		]);
}

sub acl_security_save
{
	$_[0]->{'permission'} = $in{'permission'};
}

