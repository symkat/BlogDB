
-- Settings for a given blog.
create TABLE blog_settings (
    id                          serial          PRIMARY KEY,
    blog_id                     int             not null references blog(id),
    name                        text            not null,
    value                       json            not null default '{}',
    created_at                  timestamptz     not null default current_timestamp,

    -- Allow ->find_or_new_related()
    CONSTRAINT unq_blog_id_name UNIQUE(blog_id, name)
);


-- Settings for a given pending_blog.
create TABLE pending_blog_settings (
    id                          serial          PRIMARY KEY,
    pending_blog_id             int             not null references pending_blog(id),
    name                        text            not null,
    value                       json            not null default '{}',
    created_at                  timestamptz     not null default current_timestamp,

    -- Allow ->find_or_new_related()
    CONSTRAINT unq_pending_blog_id_name UNIQUE(pending_blog_id, name)
);