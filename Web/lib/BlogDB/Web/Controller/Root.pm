package BlogDB::Web::Controller::Root;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub get_register ($c) {
    $c->set_template( 'register' );

}

sub post_register ($c) {
    $c->set_template( 'register' );

}

sub get_forgot ($c) {
    $c->set_template( 'forgot' );

}

sub post_forgot ($c) {
    $c->set_template( 'forgot' );

}

sub get_reset ($c) {
    $c->set_template( 'reset' );

}

sub post_reset ($c) {
    $c->set_template( 'reset' );

}

sub post_login ($c) {

}

sub post_logout ($c) {

}

1;
