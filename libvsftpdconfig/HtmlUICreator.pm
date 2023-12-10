package HtmlUICreator;

use strict;
use WebminCore;
use libvsftpdconfig::config::ConfigType;
use libvsftpdconfig::ConfigManager;
use libvsftpdconfig::LineConfigManager;
use libvsftpdconfig::Util;

use vars qw/%config %access %text/;

init_config();

# these options are mutually exclusive, this could use some refactoring in ConfigManager
my @mutuals = (['listen', 'listen_ipv6']);

sub render_config_instance {
	my $instance = ConfigManager::instance->config_instance(shift);
	my $permission = shift;

	my $type = $instance->type();
	my $form_name = create_form_name($type->name());
	my $value_type = $type->value_type();

	warn($type->name() . "=$value_type");

	if (!$type->restricted($permission)) {
		my $valtxt = $type->value_type() == ConfigType::BOOLEAN ?
			($instance->value ? $text{'enabled'} : $text{'disabled'}) : $instance->value();
		return "<tt>" . $valtxt . "</tt>"
	}
	elsif ($value_type == ConfigType::BOOLEAN) {
		foreach my $mutual (@mutuals) {
			my ($mutual1, $mutual2) = @{$mutual};

			if ($type->name() eq $mutual1 || $type->name() eq $mutual2) {
				my $the_other = create_form_name($type->name() eq $mutual1 ? $mutual2 : $mutual1);

				return '<input type=checkbox name="' . $form_name . '" value="1" id="' . $form_name . '" ' .
					"onClick=\"javascript:document.getElementById('$the_other').checked = " .
					"document.getElementById('$form_name').checked ? 0 : document.getElementById('$the_other').checked;\"" .
					($instance->value() == 1 ? " checked" : "") . '> ';
			}
		}

		return ui_checkbox($form_name, "1", "", $instance->value() == 1 ? 1 : undef);
	}
	elsif ($value_type == ConfigType::DIGIT) {
		return ui_textbox($form_name, $instance->value(), 10);
	}
	elsif ($value_type == ConfigType::STRING) {
		return ui_textbox($form_name, $instance->value(), 30);
	}
	elsif ($value_type == ConfigType::USERNAME) {
		return ui_textbox($form_name, $instance->value(), 10) .
			user_chooser_button($form_name, undef, "0");
	}
	else {
		die("Unsupported value type: " . $value_type);
	}
}

sub render_config_instance_row {
	my $permission = shift;
	my $readonly = shift;

	my $widgets = "";
	my $first_instance;

	foreach my $option (@_) {
		my $instance = ConfigManager::instance->config_instance($option);

		if (!$instance->type()->restricted($permission) && !$readonly) {
			return "";
		}

		if (!$first_instance) {
			$first_instance = $instance;
		}

		$widgets .= render_config_instance($option, $permission);
	}

	my $name = text("config_" . $first_instance->type()->name()) . " " .
		 ($access{'restricted'} && $first_instance->type()->restricted() ? $text{'restricted'} : "");

	$widgets .= render_js_popup_link($first_instance->type()->name());

	return ui_table_row($name, $widgets, 2, ['width=30%']);
}

sub render_tabs($$) {
	my $tab_ref = shift;
	my @tabs = @{$tab_ref};
	my $default = shift;

	my $permission = get_permission();

	warn("restrictions: " . $access{'restricted'});

	my $ret = render_js_popup_start();
	$ret .= ui_tabs_start([
		map { [ @{$_}[0], $text{'index_title_'.@{$_}[0]}, "index.cgi?tabname=" . @{$_}[0] ] } @tabs ],
		"tabname",
		$in{'tabname'} || $default,
		1);

	$ret .= ui_form_start('save.cgi', 'post');
	$ret .= ui_hidden('permission', $permission);

	foreach my $tab (@tabs) {
		my @tab = @{$tab};
		$ret .= render_tab($tab[1], $tab[0], $permission);
	}

	my @buttons;
	if (ConfigManager::instance()->can_rollback("_perm")) {
		push @buttons, ["restore", $text{'manual_restore'}];
	}
	if (ConfigManager::instance()->can_rollback()) {
		push @buttons, ["rollback", $text{'manual_rollback'}];
	}

	push @buttons, ["undo", $text{'manual_undo'}],
				   ["submit", $text{'manual_save'}];

	$ret .= ui_form_end(\@buttons);
	$ret .= ui_tabs_end();

	return $ret;
}

sub render_tab($$) {
	my $tab = shift;
	my $title = shift;
	my $permission = shift;

	my $ret = "";
	$ret .= ui_tabs_start_tab("tabname", $title);

	my $started;
	foreach my $item (@{$tab}) {
		if (ref($item) eq "HASH") {
			if ($started) {
				$ret .= ui_table_end();
			}

			my %item_hash = %{$item};
			$ret .= ui_table_start($text{'tab_sub_title_' . $item_hash{'title'}}, "width=100%", 2);
			$started = 1;
			next;
		}
		elsif (ref($item) eq "ARRAY") {
			my @item = @{$item};
			$ret .= render_config_instance_row($permission, 0, $item[0], $item[1]);
		}
		else {
			$ret .= render_config_instance_row($permission, 0, $item);
		}
	}
	$ret .= ui_table_end();
	$ret .= ui_tabs_end_tab("tabname", $title);

	return $ret;
}

sub render_line_config_file($$$) {
	my ($file, $warns, $adds) = @_;

	my @warnings = @{$warns};
	my @add_opts = @{$adds};

	my $ret = ui_hr();

	my $headings = $file eq 'userdb' ?
		[undef, $text{'additional_heading_1_' . $file}, text('additional_heading_2_' . $file)] :
		[undef, $text{'additional_heading_1_' . $file}];

	my $manager = LineConfigManager::instance($file);
	my @lines = @{$manager->lines()};
	my $cols = @{$headings} - 1;

	# Error box
	if (exists $in{'error'}) {
		error_setup($text{'additional_error'});
		error($text{$in{'error'}});
	}

	# Additional options
	$ret .= ui_form_start("save_additional.cgi", "post");
	$ret .= ui_hidden('file', $file);
	$ret .= ui_table_start($text{'additional_options'}, "width=90%");

	foreach my $opt (@add_opts) {
		$ret .= render_config_instance_row(Util::get_permission(), 1, $opt);
	}

	$ret .= ui_table_end();
	$ret .= ui_form_end([['save', $text{'manual_save'}]]);

	$ret .= ui_hr();

	# List box
	$ret .= ui_form_start("save_additional.cgi", "post");
	$ret .= ui_hidden('file', $file);

	push @{$headings}, undef;
	$ret .= ui_columns_start([@{$headings}], 90);

	# Add fields
	my @row_fields = (undef);
	my @row_submit_field = (undef);
	for (my $i = 0; $i < $cols; $i++) {
		push @row_fields, $i == 1 ?
			ui_password('add_' . $i, '', 30) : ui_textbox('add_' . $i, '', 60);
	}

	push @row_fields,  ui_submit($text{'additional_add'}, 'add');
	$ret .= ui_columns_row(\@row_fields, [undef, "align=\"left\"", "align=\"left\""]);

	# List box
	for(my $i = 0; $i < @lines; $i += $cols) {
		my @items = ($lines[$i], '');

		if ($cols == 2) {
			push @items, undef;
		}
		$ret .= ui_checked_columns_row(\@items, [], "remove_line", $lines[$i]);
	}
	$ret .= ui_columns_end();
	$ret .= ui_form_end([
		['remove', $text{'additional_remove_selected'}],
		$file eq 'userdb' ? ['regenerate', $text{'additional_regenerate'}] : undef]);

	foreach my $entry (@warnings) {
		my ($value, $property, $message) = @{$entry};

		if (ConfigManager::instance()->config_instance($property)->value() eq $value) {
			$ret .= render_warning_box($message);
			last;
		}
	}

	return $ret;
}

sub get_permission() {
	my $name = 'permission';
	my %access = get_module_acl();

	my $conf_permission = $access{$name};
	my $req_permission = $in{$name};

	if ($req_permission && (!$conf_permission || ($req_permission <= $conf_permission))) {
		return $req_permission;
	}

	return $conf_permission ? $conf_permission : 7;
}

sub create_form_name($) {
	return "value_" . shift;
}

sub render_warning_box($) {
	my $message = shift;

	# A good old dirty html table
	return '<table align="center" style="position: absolute; top: 0px; border: groove #C1665A 1px; background-color: #E0B6AF; width: 50%"><tr>' .
					  '<td><img src="images/warning.png"/></td>' .
					  '<td>' . $text{$message} . '</td></tr></table><p>';
}

sub render_js_popup_link($) {
	my $subject = shift;

	return '&nbsp;<img style="cursor: pointer;" src="images/info.png" onClick="javascript:popup_help(\'' . $subject . '\');"/>';
}

sub render_js_popup_start() {
	return '<script type="text/javascript">
		function popup_help(subject)
		{ window.open("show_help.cgi?subject=" + subject, "help_popup", "width=600,height=250"); }
		</script>';
}

# This renders an error message when an error is encountered during saving of values
sub render_error_save() {
	my $reason = $in{'reason'};

	if ($reason eq "error_save_value") {
		my $element = ConfigManager::instance()->config_instance($in{'element'});
		my $friendly_name = $text{"config_" . $element->type()->name()};

		# This could be extended to also include range errors for integers, discrete fields, etc.
		if ($element->type()->value_type() == ConfigType::USERNAME) {
			return text("error_save_value_username", $friendly_name, $in{'value'});
		}
		else {
			return text("error_save_value", $friendly_name, $in{'value'});
		}
	}

	return $text{$reason};
}

1;
