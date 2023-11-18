package LineConfigManager;

use WebminCore;
use vars qw/%config/;
use libvsftpdconfig::ConfigManager;

our %instances;

init_config();

sub instance($) {
	my $which = shift;

	if (!exists $instances{$which}) {
		$instances{$which} = LineConfigManager::new(
			ConfigManager::instance()->config_instance($which)->value() .
					($which eq 'userdb' ? '.txt' : ''), $which,
				$which eq 'userdb' ? 2 : 1);
	}

	return $instances{$which};
}

sub new($) {
	my $self = {};
	bless $self;

	$self->{CONFIG_FILE} = shift;
	$self->{NAME} = shift;

	my $subscript = shift;
	if (!$subscript) {
		$subscript = 1;
	}
	$self->{SUBSCRIPT} = $subscript;

	if (!$self->read_config()) {
		return;
	}

	return $self;
}

sub read_config($) {
	my $self = shift;

	$self->{LINES} = read_file_lines($self->{CONFIG_FILE});
	return 1;
}

sub persist() {
	my $self = shift;

	my $mask = umask();
	umask(0077);

	lock_file($self->{CONFIG_FILE});
	flush_file_lines($self->{CONFIG_FILE});
	unlock_file($self->{CONFIG_FILE});
	umask($mask);

	webmin_log("persist", "lineconfig", $self->{NAME}, undef);

	return 1;
}

sub add_lines {
	my $self = shift;

	push @{$self->{LINES}}, @_;
}

sub replace_lines {
	my $self = shift;
	my $replace_start = shift;

	my $index = $self->find_line($replace_start);
	if (defined $index) {
		splice(@{$self->{LINES}}, $index, length @_, @_);
	}

	return 1;
}

sub remove_lines {
	my $self = shift;
	my $remove_from = shift;
	my $length = shift;
	my $subscript = shift;

	my $index = $self->find_line($remove_from);
	if (defined $index) {
		splice(@{$self->{LINES}}, $index, $length);
	}
}

sub lines() {
	my $self = shift;

	return $self->{LINES};
}

sub find_line($) {
	my $self = shift;
	my $needle = shift;

	my @lines = @{$self->{LINES}};
	for(my $i = 0; $i < @lines; $i += $self->{SUBSCRIPT}) {
		warn("searching: $lines[$i]");
		if ($lines[$i] eq $needle) {
			return $i;
		}
	}

	warn("Unknown line given: ", $needle, "\n");
	return;
}

1;
