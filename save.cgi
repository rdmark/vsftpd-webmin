#!/usr/bin/perl

require "vsftpd-lib.pl";

use libvsftpdconfig::HtmlUIController;
use libvsftpdconfig::HtmlUICreator;

my $redirect = HtmlUIController::handle_save(HtmlUICreator::get_permission());

redirect($redirect);
