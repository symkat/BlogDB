package BlogDB::DB::ResultSet::Blog;
use warnings;
use strict;
use base 'DBIx::Class::ResultSet';

sub recent_entries {
    my ( $self, $opt ) = @_;

    $opt->{rows_per_page} //= 10;
    $opt->{page_number}   //= 1;
    $opt->{filter_adult}  //= 1;

    my @results;

    if ( $opt->{has_tag} ) {
        my $tag = $self->result_source->schema->resultset('Tag')->search({ name => $opt->{has_tag} })->first;
        
        if ( $tag ) {
            push @results, map { $_->blog } $tag->search_related('blog_tag_maps', {
                ( $opt->{filter_adult} ? ( 'is_adult' => 0 ) : () ),
            }, {
                order_by => { -desc => 'last_updated'},
                rows     => $opt->{rows_per_page},
                offset   => ( $opt->{page_number} - 1 )  * $opt->{rows_per_page},
            })->all;

            my $has_next_page = $tag->search_related('blog_tag_maps', {
                ( $opt->{filter_adult} ? ( 'is_adult' => 0 ) : () ),
            }, {
                order_by => { -desc => 'last_updated'},
                rows     => $opt->{rows_per_page},
                offset   => $opt->{page_number}  * $opt->{rows_per_page},
            })->count;

            return {
                results => \@results,
                has_next_page => $has_next_page >= 1 ? 1 : 0,
            };
        }
    } else {
        push @results, $self->search({
            ( $opt->{filter_adult} ? ( 'is_adult' => 0 ) : () ),
        }, {
            order_by => { -desc => 'last_updated'},
            rows     => $opt->{rows_per_page},
            offset   => ( $opt->{page_number} - 1 ) * $opt->{rows_per_page},
        })->all;

        my $has_next_page = $self->search({
            ( $opt->{filter_adult} ? ( 'is_adult' => 0 ) : () ),
        }, {
            order_by => { -desc => 'last_updated'},
            rows     => $opt->{rows_per_page},
            offset   => $opt->{page_number}  * $opt->{rows_per_page},
        })->count;

        return {
            results => \@results,
            has_next_page => $has_next_page >= 1 ? 1 : 0,
        };
    }


}


1;