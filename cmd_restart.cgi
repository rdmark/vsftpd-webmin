#!/usr/bin/perl

require "libvsftpdconfig/vsftpd-lib.pl";

vsftpd_lib::restart();
redirect("");