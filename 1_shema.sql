CREATE TABLE IF NOT EXISTS accounts
(
    id                  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email               TEXT        NOT NULL,
    password_hash       TEXT        NOT NULL,
    registered_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    name                TEXT        NOT NULL,
    required_channel_id INTEGER     NOT NULL,

    CONSTRAINT uq_accounts_email_unique UNIQUE (email)
);

-- Дополнительная таблица сверх задания с явной связью 1:1
CREATE TABLE IF NOT EXISTS account_settings
(
    account_id            INTEGER PRIMARY KEY REFERENCES accounts (id),
    theme                 text    NOT NULL DEFAULT 'system',
    notifications_enabled boolean NOT NULL DEFAULT true,
    preferred_language    text    NOT NULL DEFAULT 'ru',

    CONSTRAINT ck_account_settings_theme CHECK (theme IN ('light', 'dark', 'system'))
);

CREATE TABLE IF NOT EXISTS channels
(
    id                  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name                TEXT        NOT NULL,
    description         TEXT        NOT NULL,
    profile_picture_url TEXT        NOT NULL,
    owner_id            INTEGER     NOT NULL REFERENCES accounts (id),
    topic               TEXT        NOT NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),


    CONSTRAINT uq_channels_name_unique UNIQUE (name),
    CONSTRAINT uq_channels_one_channel_one_account UNIQUE (id, owner_id)
);

-- Добиться того, чтобы у аккаунта всегда был один канал - вещь довольно непростая.
-- Чтобы требовать наличия хотя бы одного канала я сделал required_channel_id.
-- Чтобы БД требовала существование канала с этим id нужно добавить внешний ключ.
-- Но сделать это по простому не получается, так как у нас циклическая зависимость:
-- Аккаунт требует внешний ключ на таблицу каналов, а канал требует внешний ключ на таблицу аккаунтов.
-- Поэтому сначала создается таблица аккаунтов, потом каналы, в которых есть внешний ключ на аккаунты.
-- А уже потом выполняется добавление внешнего ключа для required_channel_id на каналы, когда обе таблицы уже созданы.
-- Так мы получаем требование того, чтобы у аккаунта был хотя-бы один валидный канал.
-- Его существование гарантирует внешний ключ.
-- А DEFERRABLE INITIALLY DEFERRED делает так, чтобы эта проверка выполнялась при коммите транзакции.
-- Иначе бы мы не смогли вставить аккаунт, для которого еще нет каналов.
-- Мы сначала можем вставить аккаунт, потом канал, а потом при коммите произойдет проверка.

ALTER TABLE accounts
    ADD CONSTRAINT account_has_channel
        FOREIGN KEY (id, required_channel_id)
            REFERENCES channels (owner_id, id)
            DEFERRABLE INITIALLY DEFERRED;

CREATE TABLE IF NOT EXISTS subscriptions
(
    id            INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    channel_id    INTEGER     NOT NULL REFERENCES channels (id),
    subscriber_id INTEGER     NOT NULL REFERENCES channels (id),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_subscriptions_pair UNIQUE (channel_id, subscriber_id),
    CONSTRAINT ck_subscriptions_channel_id_not_equals_subscriber_id CHECK (channel_id <> subscriber_id)
);

CREATE TABLE IF NOT EXISTS videos
(
    id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    channel_id  INTEGER     NOT NULL REFERENCES channels (id),
    title       TEXT        NOT NULL,
    url         TEXT        NOT NULL,
    description TEXT        NOT NULL DEFAULT 'The video has no description.',
    views       BIGINT      NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_videos_views_not_negative CHECK (views >= 0)
);

CREATE TABLE IF NOT EXISTS comments
(
    id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    video_id   INTEGER     NOT NULL REFERENCES videos (id),
    author_id  INTEGER     NOT NULL REFERENCES channels (id),
    text       TEXT        NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS likes
(
    id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    video_id   INTEGER     NOT NULL REFERENCES videos (id),
    channel_id INTEGER     NOT NULL REFERENCES channels (id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_likes_pair UNIQUE (channel_id, video_id)
);

