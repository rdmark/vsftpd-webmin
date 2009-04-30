#!/usr/bin/perl

require "libvsftpdconfig/vsftpd-lib.pl";

use libvsftpdconfig::HtmlUIController;
use libvsftpdconfig::HtmlUICreator;

my $redirect = HtmlUIController::handle_save(HtmlUICreator::get_permission());

redirect($redirect);