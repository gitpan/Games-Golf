#-*-perl-*-
#
# Test suite for Games::Golf::Entry
#

# Modules we rely on.
use Test;
use Games::Golf::Entry;

# create a Games::Golf::Entry object
my $entry = new Games::Golf::Entry(
    author => "foo",
    email  => 'foo@bar.com',
    nick   => "fubar",
    date   => "2002.02.01.12.34.59",
    hole   => "gs.pl",
    code   => qq(#!/usr/bin/perl -p0\ns/\n//g;warn y///c."\n"),
);

# check it was created
ok( ref $entry, "Games::Golf::Entry" );

# check the accessors don't exist yet
# (use subs prevents from using can)
# ok( ref $entry->can('nick'), '' );

# use an accessor and autoload the method
ok( $entry->nick, 'fubar' );

# check the method exists now
ok( ref $entry->can('nick'), 'CODE' );

# set the value to something else
$entry->nick( 'foobar' );
ok( $entry->nick, 'foobar' );

# try a non-existing accessor
eval { $entry->scoore; };
ok( $@, qr/Undefined method Games::Golf::Entry::scoore/ );

# compute score
ok( $entry->score, 25 );

BEGIN { plan tests => 6 };

