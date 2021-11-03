package BlogDB::Web::Controller::Blog;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub get_blog ($c) {
    $c->set_template( 'blog/index' );

}

sub post_follow ($c) {
    $c->set_template( 'blog/index' );

}

sub post_unfollow ($c) {
    $c->set_template( 'blog/index' );

}

sub get_settings ($c) {
    $c->set_template( 'blog/settings' );

}

sub post_settings ($c) {
    $c->set_template( 'blog/settings' );

}

sub post_publish ($c) {
    $c->set_template( 'blog/settings' );

}

sub post_unpublish ($c) {
    $c->set_template( 'blog/settings' );

}

# Handle New Blogs

sub get_new_blogs ($c) {

}

sub post_new_blog ($c) {

}

sub get_edit_new_blog ($c) {

}

sub post_edit_new_blog ($c) {

}

1;
