package BlogDB::Web::Controller::User;
use Mojo::Base 'Mojolicious::Controller', -signatures;

# Do user listing for logged in or not logged in user.
# User to show is :name
sub get_user ($c) {
    $c->set_template( 'user/index' );

}

# Do follow/unfollow for currently logged in user.
# User to follow is :name
sub post_follow ($c) {
    $c->set_template( 'user/index' );

}

sub post_unfollow ($c) {
    $c->set_template( 'user/index' );

}

# Set settings for currently logged in user.
sub get_settings ($c) {
    $c->set_template( 'user/settings' );

}

sub post_bio ($c) {
    $c->set_template( 'user/settings' );

}

sub post_about ($c) {
    $c->set_template( 'user/settings' );

}

sub post_password ($c) {
    $c->set_template( 'user/settings' );

}

sub post_email ($c) {
    $c->set_template( 'user/settings' );

}

1;
