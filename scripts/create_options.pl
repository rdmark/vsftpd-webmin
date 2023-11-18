#!/usr/bin/perl

undef $/;
my $file = <STDIN>;

if ($ARGV[0] eq "boolean") {
	while ($file =~ m$<DT><B>([\w_]+)</B>\s+<DD>(.+?)<P>\s+Default: (NO|YES)$imsg) {
		my $value = ($3 eq "YES") ? 1 : 0;
		
		print "add_config_type(\"$1\", ConfigType::BOOLEAN, $value);\n";
	}
}
elsif ($ARGV[0] eq "digit") {
	while ($file =~ m$<DT><B>([\w_]+)</B>\s+<DD>(.+?)<P>\s+Default: (\d+)$imsg) {		
		print "add_config_type(\"$1\", ConfigType::DIGIT, $3);\n";
	}
}
elsif ($ARGV[0] eq "string") {
	while ($file =~ m$<DT><B>([\w_]+)</B>\s+<DD>(.+?)<P>\s+Default: ([.,\-\(\)/\w\d]+)$imsg) {
		my $name = $1;
		my $string = $3 =~ m/none/ eq "(none)" ? "" : $3; 
		print "add_config_type(\"$name\", ConfigType::STRING, \"$string\");\n";
	}
}
 
	
