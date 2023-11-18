package HtmlUIController;

use WebminCore;
use libvsftpdconfig::HtmlUICreator;
use libvsftpdconfig::config::ConfigType;
use libvsftpdconfig::ConfigManager;
use libvsftpdconfig::LineConfigManager;
use libvsftpdconfig::Util;

init_config();

sub handle_persist {
	my $permission = shift;
	
	my @instances = @_;	
	# if no instances are give, we select the instances that fall into this permission
	if (!@instances) {
		foreach my $instance (ConfigManager::instance()->config_instances()) {
			if ($instance->type()->restricted($permission) == $permission) {
				push @instances, $instance;
			}
		} 
	}
		
	foreach my $element (@instances) {
		my $name = HtmlUICreator::create_form_name($element->type()->name());
		
		if (!$element->type()->restricted($permission)) {
			next;
		}
						
		my $value;
		if (!exists($in{$name})) {
			# When checkbox is not checked no value is sent
			if ($element->type()->value_type() == ConfigType::BOOLEAN) {
				$value = 0;
			}
		}
		else {
			$value = $in{$name};
		}
						
		if (!$element->set_value($value)) {
			return ("error_save_value", $element, $value);
		}
	}
	
	if (!ConfigManager::instance()->persist($permission)) {
		return "error_save_write";
	}
}

sub handle_save {	
	my $permission = shift;
	
	if (exists $in{'rollback'}) {
		ConfigManager::instance()->rollback();
		return "manual.cgi?permission=$permission";		
	}	
	elsif (exists $in{'undo'}) {
		return "manual.cgi?permission=$permission";
	}
	elsif (exists $in{'restore'}) {
		ConfigManager::instance()->rollback();		
		ConfigManager::instance()->rollback("_perm");
		return "manual.cgi?permission=$permission";
	}
	
	my ($error, $element, $value) = handle_persist($permission, @_);
	
	if ($error) {
		my $error_url = "manual.cgi?error=error_save&permission=$permission&reason=$error";
		
		if ($error eq "error_save_value") {
			$error_url .= "&element=" . $element->type()->name() . "&value=" . $value;
		}
		
		return $error_url;
	}
	
	return "manual.cgi?save=1&permission=$permission";
}

sub handle_line_config_save {
	my $file = $in{'file'};
	my $lines = $file eq 'userdb' ? 2 : 1;
	my $files = shift;
	
	my $manager = LineConfigManager::instance($file);
	
	if (exists $in{'remove'}) {
		for my $line (split '\0', $in{'remove_line'}) {
			$manager->remove_lines($line, $lines);
		}		
	}
	elsif (exists $in{'add'}) {
		my @values;
		for(my $i = 0; $i < $lines; $i++) {
			push @values, $in{'add_' . $i};
		}
		
		$manager->add_lines(@values);		
	}
	elsif (exists $in{'regenerate'}) {
		my $error;
		my $userdb = ConfigManager::instance()->config_instance('userdb')->value();
		if (!exists $config{'cmd_dbload'} || !has_command($config{'cmd_dbload'})) {
			 $error = 'additional_error_regenerate_cmd';
		}
		elsif (!$userdb) {
			$error = 'additional_error_regenerate_disabled';
		}
		else {
			userdb_regenerate($userdb);
		}
		
		
		if ($error) {			
			return "additional_config.cgi?file=$file&error=$error";
		}		
	}
	elsif (exists $in{'save'}) {
		my @instances;

		foreach my $file_opts (@{$files}) {
			my @file_optsa = @{$file_opts};
			warn (@file_optsa);

			if ($file_optsa[0] eq $file) {
				foreach my $opt (@{$file_optsa[2]}) {
					push @instances, ConfigManager::instance()->config_instance($opt);
				}				
			}
		}
		
		# handle_save(7, @instances);
		my ($error, $element, $value) = handle_persist(Util::get_permission(), @instances);
		
		if ($error) {
			my $error_url = "additional_config.cgi?file=$file&error=error_save&reason=$error";
		
			if ($error eq "error_save_value") {
				$error_url .= "element=" . $element->type()->name() . "&value=" . $value;
			}
			
			return $error_url;
		}
		
		return "additional_config.cgi?file=$file";
	}
	
	$manager->persist();
	
	return "additional_config.cgi?file=$file";
}

sub handle_select_save() {
	do "libvsftpdconfig/profiles.pl";
	if (exists $in{'profile'}) {
		my %overrides;
		
		foreach my $o (@{$ConfigManager::profiles}) {
			my @option = @{$o};
			
			if ($option[0] eq $in{'profile'}) {
				foreach my $feat (@{$option[2]}) {
					$overrides{$feat} = $in{'value_' . $feat};
				}
			}
		}
		
		my ($name, $value) = ConfigManager::instance()->load_profile($in{'profile'}, %overrides);
		
		# invalid value in one of the overrides 
		if ($name) {
			my $error_url = "select_config.cgi?error=error_save&profile=$in{'profile'}&reason=error_save_value";
			$error_url .= "&element=" . $name . "&value=" . $value;			
			
			return $error_url;
		}
		
		ConfigManager::instance()->persist();
	}
	
	return "select_config.cgi?selected=1";
}

1;
