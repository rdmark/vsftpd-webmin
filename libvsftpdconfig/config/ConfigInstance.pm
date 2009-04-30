package ConfigInstance;
use strict;

use libvsftpdconfig::config::ConfigType;

sub new($$) {	
	my $self = {};
	bless $self;
	
	$self->{TYPE} = shift;
	my $val = shift;
	
	if ($val) {
		$self->set_value($self->{TYPE}->convert_text_value($val));
	}

	return $self;
}

sub is_default {
	my $self = shift;
	
	return ($self->{VALUE} eq undef ||
		$self->{VALUE} eq $self->{TYPE}->value_default());
}

# Needed as we need to distiguish between undefined or the empty string
sub set_value($) {
	my ($self, $val) = @_;
	
	if (!$self->{TYPE}->value_allowed($val)) {
		return 0;
	}
				
	$self->{VALUE} = $val;
		
	return 1;
}

sub value { 
	my ($self, $val) = @_;
	
	if (defined $val) {
		return $self->set_value($val);
	}
	
	return $self->is_default() ?  $self->{TYPE}->value_default() : $self->{VALUE};
}

sub value_text {
	my $self = shift;
	warn("Converting value: " . $self->{TYPE}->name());
	return $self->{TYPE}->convert_value_text($self->{VALUE});
}

sub type {
	my $self = shift;
	
	return $self->{TYPE};
}

1;