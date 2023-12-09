#!/usr/bin/perl

do "additional_config_options.pl";
require "vsftpd-lib.pl";

use libvsftpdconfig::HtmlUIController;

&ReadParse();

my $redirect = HtmlUIController::handle_line_config_save($files);
redirect($redirect);
