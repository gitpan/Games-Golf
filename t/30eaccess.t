# 30eaccess.t
#
# Games::Golf::Entry methods: new() and accessors.
#
# $Id: 30eaccess.t,v 1.4 2002/05/12 14:07:37 jquelin Exp $

use strict;
use Test;
use Games::Golf::Entry;

my $entry;
my %temp;

# create a Games::Golf::Entry object
$entry = new Games::Golf::Entry(
    author => "foo",
    email  => 'foo@bar.com',
    date   => 1021212095,
    hole   => "gs.pl",
    code   => qq(#!/usr/bin/perl -p0\ns/\n//g;warn y///c."\n"),
);

# check it was created
ok( ref $entry, "Games::Golf::Entry" );

# check the accessors don't exist yet
# (use subs prevents from using can)
# ok( ref $entry->can('author'), '' );

# use an accessor and autoload the method
ok( $entry->author, 'foo' );

# check the method exists now
ok( ref $entry->can('author'), 'CODE' );

# set the value to something else
$entry->author( 'foobar' );
ok( $entry->author, 'foobar' );

# try a non-existing accessor
eval { $entry->scoore; };
ok( $@, qr/Undefined method Games::Golf::Entry::scoore/ );

BEGIN { plan tests => 5 }
