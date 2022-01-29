use utf8;
package BlogDB::DB::Result::Blog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BlogDB::DB::Result::Blog

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

=head1 TABLE: C<blog>

=cut

__PACKAGE__->table("blog");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'blog_id_seq'

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
    sequence          => "blog_id_seq",
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

=head2 C<blog_url_key>

=over 4

=item * L</url>

=back

=cut

__PACKAGE__->add_unique_constraint("blog_url_key", ["url"]);

=head1 RELATIONS

=head2 blog_author_maps

Type: has_many

Related object: L<BlogDB::DB::Result::BlogAuthorMap>

=cut

__PACKAGE__->has_many(
  "blog_author_maps",
  "BlogDB::DB::Result::BlogAuthorMap",
  { "foreign.blog_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 blog_entries

Type: has_many

Related object: L<BlogDB::DB::Result::BlogEntry>

=cut

__PACKAGE__->has_many(
  "blog_entries",
  "BlogDB::DB::Result::BlogEntry",
  { "foreign.blog_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 blog_settings

Type: has_many

Related object: L<BlogDB::DB::Result::BlogSetting>

=cut

__PACKAGE__->has_many(
  "blog_settings",
  "BlogDB::DB::Result::BlogSetting",
  { "foreign.blog_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 blog_tag_maps

Type: has_many

Related object: L<BlogDB::DB::Result::BlogTagMap>

=cut

__PACKAGE__->has_many(
  "blog_tag_maps",
  "BlogDB::DB::Result::BlogTagMap",
  { "foreign.blog_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 messages

Type: has_many

Related object: L<BlogDB::DB::Result::Message>

=cut

__PACKAGE__->has_many(
  "messages",
  "BlogDB::DB::Result::Message",
  { "foreign.blog_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 person_follow_blog_maps

Type: has_many

Related object: L<BlogDB::DB::Result::PersonFollowBlogMap>

=cut

__PACKAGE__->has_many(
  "person_follow_blog_maps",
  "BlogDB::DB::Result::PersonFollowBlogMap",
  { "foreign.blog_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2022-01-22 15:10:12
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tDkGjf7QXBYuOW0iy0itEA


# You can replace this text with custom code or comments, and it will be preserved on regeneration

sub tags {
    my ( $self ) = @_;

    return [map {
      +{
        id       => $_->tag->id,
        name     => $_->tag->name,
        is_adult => $_->tag->is_adult,
      }
    } $self->search_related('blog_tag_maps', {})->all];
}

sub slug {
    my ( $self ) = @_;

    my $title = $self->title ? $self->title : $self->url;

    $title = lc($title);
    s/[^a-zA-Z0-9]/_/g, s/[_]+/_/g, s/^_//, s/_$// for $title;

    return sprintf( "%d-%s", $self->id, $title );
}

sub post_count {
  my ( $self ) = @_;

  my $blog_entry_count = $self->search_related( 'blog_entries', {} )->count;

  return $blog_entry_count;
}

sub posts {
  my ( $self ) = @_;

  return [ map {
    +{
      title         => $_->title,
      url           => $_->url,
      date          => $_->publish_date,
      published_ago => $_->published_ago,
    }
  } $self->search_related( 'blog_entries', {}, { order_by => { -desc => 'publish_date'} })->all ];
}

sub get_comments {
    my ( $self ) = @_;

    return [ $self->search_related('messages', { parent_id => undef, })->all ];
}

sub get_votes {
    my ( $self ) = @_;

    return {
        total => $self->search_related( 'messages', { parent_id => undef})->sum('vote'),
        pos   => $self->search_related( 'messages', { parent_id => undef, vote => 1})->count,
        neg   => $self->search_related( 'messages', { parent_id => undef, vote => -1})->count,
    };
}

# This is pretty janky.
sub formatted_about {
  my ( $self ) = @_;

  my $str;

  foreach my $paragraph ( split /\n/, $self->about ) {
    $str .= '<p class="fs-5 mb-4">' . $paragraph . "</p>\n";
  }

  return $str;
}

sub last_post {
  my ( $self ) = @_;

  return $self->search_related('blog_entries', { }, 
    { order_by => { -desc => 'publish_date' } } 
  )->first;
}

sub published_ago {
  my ( $self ) = @_;

  my $post = $self->last_post;

  return 'never before?' unless $post;

  return $post->published_ago;

}

# Settings.
sub setting {
    my ( $self, $setting, $value ) = @_;

    if ( defined $value ) {
        my $rs = $self->find_or_new_related( 'blog_settings', { name => $setting } );
        $rs->value( ref $value ? $value : { value => $value } );

        $rs->update if     $rs->in_storage;
        $rs->insert unless $rs->in_storage;

        return $value;
    } else {
        return undef unless $setting;
        my $result = $self->find_related('blog_settings', { 'name' => $setting });
        return undef unless $result;
        return $self->_get_setting_value($result);
    }
}

sub _get_setting_value {
    my ( $self, $setting ) = @_;

    if ( ref $setting->value eq 'HASH' and keys %{$setting->value} == 1 and exists $setting->value->{value} ) {
        return $setting->value->{value};
    }

    return $setting->value;
}

sub get_settings {
    my ( $self ) = @_;

    my $return = {};

    foreach my $setting ( $self->search_related( 'blog_settings', {} )->all ) {
        $return->{${\($setting->name)}} = $self->_get_setting_value($setting);
    }

    return $return;
}

1;
