package BlogDB::Web::Controller::Create;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub post_new ($c) {

}

sub get_new_blog ($c) {
    $c->set_template( 'new/index' );
}

sub post_new_blog ($c) {
    $c->set_template( 'new/index' );
}

sub post_push_blog ($c) {

}

1;
