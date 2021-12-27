use utf8;
package BlogDB::DB::Result::PendingBlogSetting;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BlogDB::DB::Result::PendingBlogSetting

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

=head1 TABLE: C<pending_blog_settings>

=cut

__PACKAGE__->table("pending_blog_settings");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'pending_blog_settings_id_seq'

=head2 pending_blog_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 value

  data_type: 'json'
  default_value: '{}'
  is_nullable: 0
  serializer_class: 'JSON'

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
    sequence          => "pending_blog_settings_id_seq",
  },
  "pending_blog_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "value",
  {
    data_type        => "json",
    default_value    => "{}",
    is_nullable      => 0,
    serializer_class => "JSON",
  },
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

=head2 C<unq_pending_blog_id_name>

=over 4

=item * L</pending_blog_id>

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("unq_pending_blog_id_name", ["pending_blog_id", "name"]);

=head1 RELATIONS

=head2 pending_blog

Type: belongs_to

Related object: L<BlogDB::DB::Result::PendingBlog>

=cut

__PACKAGE__->belongs_to(
  "pending_blog",
  "BlogDB::DB::Result::PendingBlog",
  { id => "pending_blog_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-12-27 00:20:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ROU+KGD7SM9g8BiTA6lz4w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
