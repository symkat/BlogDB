use utf8;
package BlogDB::DB::Result::PendingBlog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BlogDB::DB::Result::PendingBlog

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::InflateColumn::Serializer>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "InflateColumn::Serializer");

=head1 TABLE: C<pending_blog>

=cut

__PACKAGE__->table("pending_blog");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'pending_blog_id_seq'

=head2 url

  data_type: 'text'
  is_nullable: 0

=head2 img_url

  data_type: 'text'
  is_nullable: 1

=head2 rss_url

  data_type: 'text'
  is_nullable: 1

=head2 title

  data_type: 'text'
  is_nullable: 1

=head2 tagline

  data_type: 'text'
  is_nullable: 1

=head2 about

  data_type: 'text'
  is_nullable: 1

=head2 last_updated

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 is_published

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 is_adult

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 submitter_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 edit_token

  data_type: 'text'
  is_nullable: 1

=head2 state

  data_type: 'text'
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "pending_blog_id_seq",
  },
  "url",
  { data_type => "text", is_nullable => 0 },
  "img_url",
  { data_type => "text", is_nullable => 1 },
  "rss_url",
  { data_type => "text", is_nullable => 1 },
  "title",
  { data_type => "text", is_nullable => 1 },
  "tagline",
  { data_type => "text", is_nullable => 1 },
  "about",
  { data_type => "text", is_nullable => 1 },
  "last_updated",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "is_published",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "is_adult",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "submitter_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "edit_token",
  { data_type => "text", is_nullable => 1 },
  "state",
  { data_type => "text", is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<pending_blog_url_key>

=over 4

=item * L</url>

=back

=cut

__PACKAGE__->add_unique_constraint("pending_blog_url_key", ["url"]);

=head1 RELATIONS

=head2 pending_blog_entries

Type: has_many

Related object: L<BlogDB::DB::Result::PendingBlogEntry>

=cut

__PACKAGE__->has_many(
  "pending_blog_entries",
  "BlogDB::DB::Result::PendingBlogEntry",
  { "foreign.blog_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pending_blog_tag_maps

Type: has_many

Related object: L<BlogDB::DB::Result::PendingBlogTagMap>

=cut

__PACKAGE__->has_many(
  "pending_blog_tag_maps",
  "BlogDB::DB::Result::PendingBlogTagMap",
  { "foreign.blog_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 submitter

Type: belongs_to

Related object: L<BlogDB::DB::Result::Person>

=cut

__PACKAGE__->belongs_to(
  "submitter",
  "BlogDB::DB::Result::Person",
  { id => "submitter_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-11-24 04:45:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:F4GsyDnhsW34Ywl+BCrVEw

sub tags {
    my ( $self ) = @_;

    return [map {
      +{
        id       => $_->tag->id,
        name     => $_->tag->name,
        is_adult => $_->tag->is_adult,
      }
    } $self->search_related('pending_blog_tag_maps', {})->all];
}

sub slug {
    my ( $self ) = @_;

    my $title = $self->title ? $self->title : $self->url;

    $title = lc($title);
    s/[^a-zA-Z0-9]/_/g, s/[_]+/_/g, s/^_//, s/_$// for $title;

    return sprintf( "%d-%s", $self->id, $title );
}

sub posts {
  my ( $self ) = @_;

  return [ map {
    +{
      title => $_->title,
      url   => $_->url,
      date  => $_->publish_date,
    }
  } $self->search_related( 'pending_blog_entries', { order_by => { -desc => 'publish_date'} })->all ];
}

sub published_ago {
  my ( $self ) = @_;

  my $post = $self->search_related('pending_blog_entries', { }, { order_by => { -desc => 'publish_date' } } )->first;

  return 'never before?' unless $post;

  return $post->published_ago;

}

1;
