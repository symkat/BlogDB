use utf8;
package BlogDB::DB::Result::Tag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BlogDB::DB::Result::Tag

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

=head1 TABLE: C<tag>

=cut

__PACKAGE__->table("tag");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'tag_id_seq'

=head2 name

  data_type: 'text'
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
    sequence          => "tag_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
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

=head2 C<tag_name_key>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("tag_name_key", ["name"]);

=head1 RELATIONS

=head2 blog_tag_maps

Type: has_many

Related object: L<BlogDB::DB::Result::BlogTagMap>

=cut

__PACKAGE__->has_many(
  "blog_tag_maps",
  "BlogDB::DB::Result::BlogTagMap",
  { "foreign.tag_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-10-06 18:19:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3O/hbaaWPo4XH2M1y3Ogkw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
