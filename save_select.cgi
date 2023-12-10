#!/usr/bin/perl

require "vsftpd-lib.pl";

use strict;
use libvsftpdconfig::HtmlUIController;

&ReadParse();

my $redirect = HtmlUIController::handle_select_save();
redirect($redirect);
