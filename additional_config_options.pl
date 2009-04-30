our $files = [
	['userdb',
		[
			['', 'userdb', 'additional_userdb_location']
		], 
		['userdb'],
	],
	 
	['userlist_file', 
		[
		 	[0, 'userlist_enable', 'additional_userlist_enable'], 
		 	[1, 'userlist_deny', 'additional_userlist_not_deny'],
		 	[0, 'userlist_deny', 'additional_userlist_deny'],
		], 
		['userlist_file', 'userlist_enable', 'userlist_deny']
	],
		  
	['banned_email_file',  
		[
			# note It's kind of useless to ban email addresses when email password
			# file is enabled, so warn about it
			[1, 'secure_email_list_enable', 'additional_conflict_secure_email_list_enable'],		
		  	[0, 'deny_email_enable', 'additional_deny_email_enable']
		 ],
		 ['banned_email_file', 'deny_email_enable'] 
	],
		 
	['chroot_list_file', 
		[
		],
		['chroot_list_file','chroot_list_enable', 'chroot_local_user']
	],
	 
	['email_password_file', 
		[			
		],
		['email_password_file','secure_email_list_enable']
	]
];