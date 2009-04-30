#!/usr/bin/perl

require "libvsftpdconfig/vsftpd-lib.pl";

use strict;
use libvsftpdconfig::HtmlUIController;

my $redirect = HtmlUIController::handle_select_save();
redirect($redirect);