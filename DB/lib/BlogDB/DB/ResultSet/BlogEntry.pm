package BlogDB::DB::ResultSet::BlogEntry;
use warnings;
use strict;
use base 'DBIx::Class::ResultSet';

sub recent_entries {
    my ( $self, $opt ) = @_;

    $opt->{rows_per_page} //= 10;
    $opt->{page_number}   //= 1;
    $opt->{filter_adult}  //= 1;


    return $self->search({
        ( $opt->{filter_adult} ? ( 'blog.is_adult' => 0 ) : () ),
    }, {
        order_by => { -desc => 'publish_date'},
        rows     => $opt->{rows_per_page},
        offset   => ( $opt->{page_number} - 1 )  * $opt->{rows_per_page},
        prefetch => 'blog',
    })->all;

}


1;