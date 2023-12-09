#!/usr/bin/perl

require "vsftpd-lib.pl";

use libvsftpdconfig::HtmlUIController;
use libvsftpdconfig::HtmlUICreator;

&ReadParse();

my $redirect = HtmlUIController::handle_save(HtmlUICreator::get_permission());

redirect($redirect);
