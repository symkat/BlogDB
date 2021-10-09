package BlogDB::Web::Controller::Tags;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub get_tags ($c) {
    $c->set_template( 'tags/index' );
}

sub post_suggest_tag ($c) {
    $c->set_template( 'tags/index' );
}

sub post_vote_tag ($c) {
    $c->set_template( 'tags/index' );
}

sub post_delete_tag ($c) {
    $c->set_template( 'tags/index' );
}

1;

