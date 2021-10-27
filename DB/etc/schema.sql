CREATE EXTENSION IF NOT EXISTS citext;

CREATE TABLE person (
    id                          serial          PRIMARY KEY,
    username                    citext          not null unique,
    email                       citext          not null unique,
    tagline                     text            ,
    about                       text            ,
    is_enabled                  boolean         not null default true,
    created_at                  timestamptz     not null default current_timestamp
);

-- Settings for a given user.
create TABLE person_settings (
    id                          serial          PRIMARY KEY,
    person_id                   int             not null references person(id),
    name                        text            not null,
    value                       json            not null default '{}',
    created_at                  timestamptz     not null default current_timestamp,

    -- Allow ->find_or_new_related()
    CONSTRAINT unq_person_id_name UNIQUE(person_id, name)
);

-- A password can be associated with a user account.
CREATE TABLE auth_password (
    person_id                   int             not null unique references person(id),
    password                    text            not null,
    salt                        text            not null,
    updated_at                  timestamptz     not null default current_timestamp,
    created_at                  timestamptz     not null default current_timestamp
);

-- Reset passwords by creating a token for the user.  Tokens can only be used
-- once and should be marked is_redeemed true after use.
CREATE TABLE password_token (
    id                          serial          PRIMARY KEY,
    person_id                   int             not null references person(id),
    token                       text            not null,
    is_redeemed                 boolean         not null default false,
    created_at                  timestamptz     not null default current_timestamp
);

-- Root table for the blog listing.
CREATE TABLE blog (
    id                          serial          PRIMARY KEY,
    url                         text            not null unique,
    img_url                     text            ,
    rss_url                     text            ,
    title                       text            ,
    tagline                     text            ,
    about                       text            ,
    last_updated                timestamptz     ,
    is_published                boolean         not null default true,
    is_adult                    boolean         not null default false,
    created_at                  timestamptz     not null default current_timestamp
);

-- RSS Reader will create these for the blogs.
CREATE TABLE blog_entry (
    id                          serial          PRIMARY KEY,
    blog_id                     int             not null references blog(id),
    title                       text            not null,
    url                         text            not null,
    publish_date                timestamptz     not null,
    description                 text            ,
    created_at                  timestamptz     not null default current_timestamp
);

-- Tags that are approved.
CREATE TABLE tag (
    id                          serial          PRIMARY KEY,
    name                        text            not null unique,
    is_adult                    boolean         not null default false,
    created_at                  timestamptz     not null default current_timestamp
);

-- Map between tags <-> blogs so we can get a listing of tags for a blog, or a listing
-- of blogs for a tag.
CREATE TABLE blog_tag_map (
    id                          serial          PRIMARY KEY,
    blog_id                     int             not null references blog(id),
    tag_id                      int             not null references tag(id),
    created_at                  timestamptz     not null default current_timestamp
);

-- When a user adds a tag, it's added to the pending table, and can be voted on,
-- approved, or deleted.
CREATE TABLE pending_tag (
    id                          serial          PRIMARY KEY,
    name                        text            not null unique,
    is_adult                    boolean         not null default false,
    created_at                  timestamptz     not null default current_timestamp
);

-- Normal users can vote on tags, vote will be 1 or -1
CREATE TABLE tag_vote (
    id                          serial          PRIMARY KEY,
    tag_id                      int             not null references pending_tag(id),
    person_id                   int             not null references person(id),
    vote                        int             not null default '1',
    created_at                  timestamptz     not null default current_timestamp
);

-- Allow people to follow blogs, and make a people <-> blog association.
CREATE TABLE person_follow_blog_map (
    id                          serial          PRIMARY KEY,
    person_id                   int             not null references person(id),
    blog_id                     int             not null references blog(id),
    created_at                  timestamptz     not null default current_timestamp
);

-- Allow people to follow other people, and make a people <-> followed association.
CREATE TABLE person_follow_person_map (
    id                          serial          PRIMARY KEY,
    person_id                   int             not null references person(id),
    follow_id                   int             not null references person(id),
    created_at                  timestamptz     not null default current_timestamp
);

-- Message thread for blogs.
CREATE TABLE message (
    id                          serial          PRIMARY KEY,
    author_id                   int             not null references person(id),
    blog_id                     int             references blog(id),               -- Find all root comments for blog
    parent_id                   int             references message(id),            -- Find children for recursive messages
    vote                        int             not null default '1',              -- Does the user recommend the blog?
    content                     text            ,
    created_at                  timestamptz     not null default current_timestamp
);

