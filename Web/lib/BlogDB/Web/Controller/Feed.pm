package BlogDB::Web::Controller::Feed;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Data::UUID;
use URI;

sub get_feed ( $c ) {
    $c->set_template( 'feed/index' );

    my $page_number = $c->stash->{page}{number} = $c->param('page') || 1;
    $c->stash->{page}{has_prev} = 1 if $page_number >= 2;
    $c->stash->{page}{prev} = $page_number - 1;
    $c->stash->{page}{next} = $page_number + 1;

    my $recent_entries = $c->db->resultset('BlogEntry')->recent_entries({
        filter_adult       => ! $c->stash->{can_view_adult},
        rows_per_page      => 25,

        ( $page_number
            ? ( page_number => $page_number )
            : ()
        ),

        # Feed for this user.
        limit_to_person_id => $c->stash->{person}->id,
        
        # If we have a tag, only show entries that match it.
        ( $c->param('tag')
            ? ( has_tag => $c->param('tag') )
            : ( )
        ),

    });

    push @{$c->stash->{entries}}, @{$recent_entries->{results}};
    $c->stash->{page}{has_next} = $recent_entries->{has_next_page};
    
    push @{$c->stash->{tags_a}},  grep  { $_->id % 2 == 1 } $c->db->resultset('Tag')->search({
        ( ! $c->stash->{can_view_adult} ? ( is_adult => 0 ) : () ),
    })->all;

    push @{$c->stash->{tags_b}},  grep  { $_->id % 2 == 0 } $c->db->resultset('Tag')->search({
        ( ! $c->stash->{can_view_adult} ? ( is_adult => 0 ) : () ),
    })->all;
}


1;