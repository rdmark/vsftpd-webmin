#!/usr/bin/perl

do "additional_config_options.pl";
require "libvsftpdconfig/vsftpd-lib.pl";

use libvsftpdconfig::HtmlUIController;

my $redirect = HtmlUIController::handle_line_config_save($files);
redirect($redirect);
