package ConfigType;
use strict;

use constant {
	DIGIT => 0,
	BOOLEAN => 1,
	STRING => 2,
	DISCRETE => 3,
	UNKNOWN => 4,
	USERNAME => 5
};

sub new {
	my $self = {};
	bless $self;

	$self->{NAME} = shift;
	$self->{VALUE_TYPE} = shift;	
	$self->{VALUE_DEFAULT} = shift;
	$self->{VIRTUAL} = shift; # Virtual options are not stored in the vsftpd.conf file but somewhere else
	$self->{RESTRICTED} = shift;
	if (@_) {
		$self->{VALUES_ALLOWED} = shift;		
	}	
	
	return $self;
}

sub name() {
	my $self = shift;
	
	return $self->{NAME};
}

sub value_default() {
	my $self = shift;
	
	return $self->{VALUE_DEFAULT};
}

sub value_type() {
	my $self = shift;
	
	return $self->{VALUE_TYPE};
}

sub virtual() {
	my $self = shift;
	
	return $self->{VIRTUAL};
}

sub restricted {
	my $self = shift;
	my $arg = shift;
	
	if ($arg) {
		return $self->{RESTRICTED} & $arg;
	}
	
	return $self->{RESTRICTED};
}

sub value_allowed($) {
	my ($self, $value) = @_;
	
	if ($self->{VALUE_TYPE} == DIGIT) {
		return $value =~ m/^\d+$/;
	}
	elsif ($self->{VALUE_TYPE} == STRING) {
		warn("checking string");
		return 1;
	}
	elsif ($self->{VALUE_TYPE} == BOOLEAN) {
		return $value == 1 || $value == 0;
	}
	elsif ($self->{VALUE_TYPE} == DISCRETE) {		
		return grep(@$self->VALUES_ALLOWED, $value) != 0;
	}
	elsif ($self->{VALUE_TYPE} == UNKNOWN) { 
		return 1;
	}
	elsif ($self->{VALUE_TYPE} == USERNAME) {
		return getpwnam($value) != undef;
	}
}

sub convert_value_text($) {
	my ($self, $value) = @_;
	
	if ($self->{VALUE_TYPE} == BOOLEAN) {
		return $value == 0 ? "NO" : "YES";
	}
	else {
		return $value;
	}
}

sub convert_text_value($) {
	my ($self, $value) = @_;
		
	if ($self->{VALUE_TYPE} == BOOLEAN) {		
		return (lc $value eq "yes" ? 1 : 0);
	}
	else {
		return $value;
	}
	
}

1;