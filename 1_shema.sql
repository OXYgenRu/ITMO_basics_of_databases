CREATE TABLE IF NOT EXISTS accounts
(
    id                  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email               TEXT       NOT NULL,
    password_hash       TEXT       NOT NULL,
    registered_at       TIMESTAMPZ NOT NULL DEFAULT NOW(),
    name                TEXT       NOT NULL,
    required_channel_id integer    NOT NULL,

    CONSTRAINT uq_accounts_email_unique UNIQUE (email)
);

CREATE TABLE IF NOT EXISTS channels
(
    id                   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name                 TEXT       NOT NULL,
    description          TEXT       NOT NULL,
    profile_picture_link TEXT       NOT NULL,
    owner_id             INTEGER    NOT NULL REFERENCES accounts (id),
    created_at           TIMESTAMPZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_channels_name_unique UNIQUE (name),
    CONSTRAINT uq_channels_one_channel_one_account UNIQUE (id, owner_id)
);

ALTER TABLE accounts
    ADD CONSTRAINT account_has_channel
        FOREIGN KEY (id, required_channel_id)
            REFERENCES channels (owner_id, id)
            DEFERRABLE INITIALLY DEFERRED;

CREATE TABLE IF NOT EXISTS subscriptions
(
    id            INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    channel_id    INTEGER    NOT NULL REFERENCES channels (id),
    subscriber_id INTEGER    NOT NULL REFERENCES channels (id),
    created_at    TIMESTAMPZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_subscriptions_pair UNIQUE (channel_id, subscriber_id),
    CONSTRAINT ck_subscriptions_channel_id_not_equals_subscriber_id CHECK (channel_id <> subscriber_id)
);

CREATE TABLE IF NOT EXISTS videos
(
    id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    channel_id  INTEGER    NOT NULL REFERENCES channels (id),
    title       TEXT       NOT NULL,
    description TEXT       NOT NULL DEFAULT 'The video has no description.',
    views       BIGINT     NOT NULL DEFAULT 0,
    created_at  TIMESTAMPZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_videos_views_not_negative CHECK (views >= 0)
);

CREATE TABLE IF NOT EXISTS comments
(
    id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    video_id   INTEGER    NOT NULL REFERENCES videos (id),
    author_id  INTEGER    NOT NULL REFERENCES channels (id),
    text       TEXT       NOT NULL,
    created_at TIMESTAMPZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS likes
(
    id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    video_id   INTEGER    NOT NULL REFERENCES videos (id),
    channel_id INTEGER    NOT NULL REFERENCES channels (id),
    created_at TIMESTAMPZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_likes_pair UNIQUE (channel_id, video_id)
);

