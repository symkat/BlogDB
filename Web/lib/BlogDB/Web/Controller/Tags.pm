package BlogDB::Web::Controller::Tags;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub get_tags ($c) {
    $c->set_template( 'tags/index' );

    push @{$c->stash->{tags}},         $c->db->resultset('Tag')->all;
    push @{$c->stash->{pending_tags}}, $c->db->resultset('PendingTag')->all;

}

sub post_suggest_tag ($c) {
    $c->set_template( 'tags/index' );

    push @{$c->stash->{tags}},         $c->db->resultset('Tag')->all;
    push @{$c->stash->{pending_tags}}, $c->db->resultset('PendingTag')->all;

    my $tag_name = $c->stash->{form_tag}   = $c->param('tag');
    my $is_adult = $c->stash->{form_adult} = $c->param('is_adult');

    push @{$c->stash->{errors}}, "Tag names must start with a letter, and may only contain letters and numbers."
        unless $tag_name =~ m/^[a-zA-Z][a-zA-Z0-9]+$/;

    return 0 if $c->stash->{errors};

    my $tag_exists         = $c->db->resultset('Tag'       )->search({ name => $tag_name })->first;
    my $pending_tag_exists = $c->db->resultset('PendingTag')->search({ name => $tag_name })->first;

    push @{$c->stash->{errors}}, "There is already a tag with that name."
        if $tag_exists;

    push @{$c->stash->{errors}}, "There is already a pending tag with that name."
        if $pending_tag_exists;

    return 0 if $c->stash->{errors};

    $c->db->resultset('PendingTag')->create({
        name => $tag_name,
    });

    $c->stash->{success}   = 1;
    $c->stash->{tag_name} = $tag_name;
}

sub post_vote_tag ($c) {
    $c->set_template( 'tags/index' );

    push @{$c->stash->{tags}},         $c->db->resultset('Tag')->all;
    push @{$c->stash->{pending_tags}}, $c->db->resultset('PendingTag')->all;

    my $tag_name = $c->stash->{form_tag} = $c->param('tag');

    my $tag = $c->db->resultset('PendingTag')->search({ name => $tag_name })->first;

    push @{$c->stash->{errors}}, "No such tag?"
        unless $tag;

    return 0 if $c->stash->{errors};

    # Find out if the user already voted -- in which case we are toggling the vote.
    my $vote = $c->db->resultset('TagVote')->search( {
        tag_id    => $tag->id,
        person_id => $c->stash->{person}->id,
    });

    if ( $vote ) {
        $vote->vote( ! $vote->vote );
        $vote->update;
    } else {
        $c->stash->{person}->create_related( 'tag_votes', {
            tag_id => $tag->id,
        });
    }

    $c->stash->{success} = 1;
}

sub post_delete_tag ($c) {
    $c->set_template( 'tags/index' );

    push @{$c->stash->{tags}},         $c->db->resultset('Tag')->all;
    push @{$c->stash->{pending_tags}}, $c->db->resultset('PendingTag')->all;

    my $tag_name = $c->stash->{form_tag} = $c->param('tag');
}

sub post_approve_tag ($c) {
    $c->set_template( 'tags/index' );

    push @{$c->stash->{tags}},         $c->db->resultset('Tag')->all;
    push @{$c->stash->{pending_tags}}, $c->db->resultset('PendingTag')->all;

    my $tag_name = $c->stash->{form_tag} = $c->param('tag');

    my $tag = $c->db->resultset('PendingTag')->search({ name => $tag_name })->first;

    push @{$c->stash->{errors}}, "No such tag?"
        unless $tag;

    return 0 if $c->stash->{errors};

    $c->db->resultset('Tag')->create({
        name     => $tag->name,
        is_adult => $tag->is_adult,
    });

    $c->stash->{success} = 1;
}

1;

