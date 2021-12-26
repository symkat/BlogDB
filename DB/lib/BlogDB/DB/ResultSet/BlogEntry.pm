package BlogDB::DB::ResultSet::BlogEntry;
use warnings;
use strict;
use base 'DBIx::Class::ResultSet';

sub recent_entries {
    my ( $self, $opt ) = @_;

    $opt->{rows_per_page} //= 10;
    $opt->{page_number}   //= 1;
    $opt->{filter_adult}  //= 1;

    # If we are limited to tags, we're going to turn that
    # into a list a blog ids, and then limit our entries search
    # to those blogs.  If you have a better way, open a pull request.
    my @limit_ids;
    if ( $opt->{has_tag} ) {
        push @limit_ids, map { 
            $_->blog_id 
        } $self->result_source->schema->resultset('BlogTagMap')->search(
            { 'tag.name' => $opt->{has_tag} },
            { prefetch => 'tag' },
        )->all;
    }


    return $self->search({
        ( $opt->{filter_adult} ? ( 'blog.is_adult' => 0 ) : () ),
        ( @limit_ids ? ( blog_id => { -in => [ @limit_ids ] }) : () ),
    }, {
        order_by => { -desc => 'publish_date'},
        rows     => $opt->{rows_per_page},
        offset   => ( $opt->{page_number} - 1 )  * $opt->{rows_per_page},
        prefetch => 'blog',
    })->all;

}


1;