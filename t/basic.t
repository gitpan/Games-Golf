#-*-perl-*-
#

#-----------------------------------#
#          Initialization.          #
#-----------------------------------#

# Modules we rely on.
use Test;

BEGIN { plan tests => 1 };

# Vars.


#--------------------------------#
#          Basic tests.          #
#--------------------------------#

# Loading the module.
eval { require Games::Golf; };
ok($@, "");
