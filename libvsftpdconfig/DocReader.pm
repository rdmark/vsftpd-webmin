# A simple class for getting the documentation directly from the man pages
package DocReader;

our $instance;

sub instance() {
	if (!$instance) {
		$instance = DocReader::new("vsftpd.conf", qr/KEYWORD\n\s+(.+?Default: .+?\n)/ms);
	}
	
	return $instance;
}

sub new {
	my $self = {};	
	bless $self;
	
	$self->{MANPAGE} = shift;
	$self->{PATTERN} = shift;
	
	$self->read_man();
	
	return $self;
}

sub read_man {
	my $self = shift;
	
	$self->{MANPAGE_TEXT} = `man $self->{MANPAGE}`;
}

sub get_subject($) {
	my ($self, $subject) = @_;
	
	my $regex = $self->{PATTERN};	
	$regex =~ s/KEYWORD/$subject/;
	
	warn("get_subject(): matching for: " . $regex);
	
	if ($self->{MANPAGE_TEXT} =~ $regex) {
		my $match = $1;
		$match =~ s/^\s+//mg;
		
		return $match;
	} 
	
	return "Could not find documentation for: " . $subject;
}

1;