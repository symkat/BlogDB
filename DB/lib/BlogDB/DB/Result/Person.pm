use utf8;
package BlogDB::DB::Result::Person;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BlogDB::DB::Result::Person

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

=head1 TABLE: C<person>

=cut

__PACKAGE__->table("person");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'person_id_seq'

=head2 username

  data_type: 'citext'
  is_nullable: 0

=head2 email

  data_type: 'citext'
  is_nullable: 0

=head2 tagline

  data_type: 'text'
  is_nullable: 1

=head2 about

  data_type: 'text'
  is_nullable: 1

=head2 is_enabled

  data_type: 'boolean'
  default_value: true
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
    sequence          => "person_id_seq",
  },
  "username",
  { data_type => "citext", is_nullable => 0 },
  "email",
  { data_type => "citext", is_nullable => 0 },
  "tagline",
  { data_type => "text", is_nullable => 1 },
  "about",
  { data_type => "text", is_nullable => 1 },
  "is_enabled",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
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

=head2 C<person_email_key>

=over 4

=item * L</email>

=back

=cut

__PACKAGE__->add_unique_constraint("person_email_key", ["email"]);

=head2 C<person_username_key>

=over 4

=item * L</username>

=back

=cut

__PACKAGE__->add_unique_constraint("person_username_key", ["username"]);

=head1 RELATIONS

=head2 auth_password

Type: might_have

Related object: L<BlogDB::DB::Result::AuthPassword>

=cut

__PACKAGE__->might_have(
  "auth_password",
  "BlogDB::DB::Result::AuthPassword",
  { "foreign.person_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 messages

Type: has_many

Related object: L<BlogDB::DB::Result::Message>

=cut

__PACKAGE__->has_many(
  "messages",
  "BlogDB::DB::Result::Message",
  { "foreign.author_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 password_tokens

Type: has_many

Related object: L<BlogDB::DB::Result::PasswordToken>

=cut

__PACKAGE__->has_many(
  "password_tokens",
  "BlogDB::DB::Result::PasswordToken",
  { "foreign.person_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pending_blogs

Type: has_many

Related object: L<BlogDB::DB::Result::PendingBlog>

=cut

__PACKAGE__->has_many(
  "pending_blogs",
  "BlogDB::DB::Result::PendingBlog",
  { "foreign.submitter_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 person_follow_blog_maps

Type: has_many

Related object: L<BlogDB::DB::Result::PersonFollowBlogMap>

=cut

__PACKAGE__->has_many(
  "person_follow_blog_maps",
  "BlogDB::DB::Result::PersonFollowBlogMap",
  { "foreign.person_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 person_follow_person_map_people

Type: has_many

Related object: L<BlogDB::DB::Result::PersonFollowPersonMap>

=cut

__PACKAGE__->has_many(
  "person_follow_person_map_people",
  "BlogDB::DB::Result::PersonFollowPersonMap",
  { "foreign.person_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 person_follow_person_maps_follow

Type: has_many

Related object: L<BlogDB::DB::Result::PersonFollowPersonMap>

=cut

__PACKAGE__->has_many(
  "person_follow_person_maps_follow",
  "BlogDB::DB::Result::PersonFollowPersonMap",
  { "foreign.follow_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 person_settings

Type: has_many

Related object: L<BlogDB::DB::Result::PersonSetting>

=cut

__PACKAGE__->has_many(
  "person_settings",
  "BlogDB::DB::Result::PersonSetting",
  { "foreign.person_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 tag_votes

Type: has_many

Related object: L<BlogDB::DB::Result::TagVote>

=cut

__PACKAGE__->has_many(
  "tag_votes",
  "BlogDB::DB::Result::TagVote",
  { "foreign.person_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-11-04 01:11:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uamr/+RThTQZLjXkv6wcxQ

sub setting {
    my ( $self, $setting, $value ) = @_;

    if ( defined $value ) {
        my $rs = $self->find_or_new_related( 'person_settings', { name => $setting } );
        $rs->value( ref $value ? $value : { value => $value } );

        $rs->update if     $rs->in_storage;
        $rs->insert unless $rs->in_storage;

        return $value;
    } else {
        my $result = $self->find_related('person_settings', { name => $setting });
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

    foreach my $setting ( $self->search_related( 'person_settings', {} )->all ) {
        $return->{${\($setting->name)}} = $self->_get_setting_value($setting);
    }

    return $return;
}

sub is_following_blog {
    my ( $self, $blog_id ) = @_;

    return 0 unless $blog_id;

    my $count = $self->search_related('person_follow_blog_maps', {
        blog_id => $blog_id,
    })->count;

    return $count >= 1 ? 1 : 0;
}

sub get_followed_blogs {
    my ( $self ) = @_;

    return [ map {
        $_->blog
    } $self->search_related('person_follow_blog_maps')->all ];
}

1;
