use utf8;
package BlogDB::DB;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_components("Schema::Config");

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-10-06 18:19:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NPmhmBYK6vnPZZUxqtXD6A

our $VERSION = 1;

sub install_defaults {
    my ( $self ) = @_;
}

1;
