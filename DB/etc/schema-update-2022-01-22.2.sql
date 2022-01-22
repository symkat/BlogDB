
-- Allow the follow statuses to be public or private.
ALTER TABLE person_follow_blog_map
    ADD COLUMN is_public boolean not null default false;

ALTER TABLE person_follow_person_map
    ADD COLUMN is_public boolean not null default false;