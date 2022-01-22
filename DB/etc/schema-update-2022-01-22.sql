
-- Allow blog authors, such that a blog listing may say "written by Alice, Mallory & Bob",
-- and each of their profiles may list the blog as something they write.
CREATE TABLE blog_author_map (
    id                          serial          PRIMARY KEY,
    blog_id                     int             not null references blog(id),
    person_id                   int             not null references person(id),
    created_at                  timestamptz     not null default current_timestamp
);
