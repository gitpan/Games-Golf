# 50taccess.t
#
# Games::Golf methods: new() and accessors.
#
# $Id: 50gaccess.t,v 1.1 2002/05/21 00:05:11 book Exp $

use strict;
use Test;

use Games::Golf;

#use t::Sweeties;    # import the %TESTSUITE hash

my $golf;
my @holes;

#----------------------------------------#
#        Check the constructor           #
#----------------------------------------#

# Not enough parameters for the constructor
eval { $golf = Games::Golf->new(); };
ok( $@, qr/^fatal: Not enough parameters/ );

$golf = Games::Golf->new('t/tpr02.glf');

ok( ref $golf, "Games::Golf" );

#----------------------------------------#
#        Check the accessors             #
#----------------------------------------#

# single hole

$golf = Games::Golf->new('t/tpr02.glf');

ok( $golf->file, "t/tpr02.glf" );

@holes = $golf->hole_names;
ok( @holes, 1 );
ok( $holes[0], "anagrams" );

ok( $golf->get_pgas, qr/^http:/ );
$golf->set_pgas('test');
ok( $golf->get_pgas, 'test' );

ok( $golf->get_version, qr/Revision/ );
$golf->set_version('foobar');
ok( $golf->get_version, 'foobar' );

# multi hole

$golf = Games::Golf->new('t/tpr03.glf');

@holes = sort $golf->hole_names;
ok( @holes, 2 );
ok( $holes[0], "cantor" );
ok( $holes[1], "kola" );

BEGIN { plan tests => 12 }

