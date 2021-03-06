BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS sessions (
    id              bytea       NOT NULL,
    user_id         text        NOT NULL,
    description     text        NOT NULL,
    PRIMARY KEY (id)
);

CREATE INDEX IF NOT EXISTS sessions__user_id
    ON sessions
    (user_id);

CREATE TABLE IF NOT EXISTS files (
    id              uuid        NOT NULL,
    name            text        NOT NULL,
    author_id       text        NOT NULL,
    root_id         uuid        NOT NULL,
    PRIMARY KEY (id)
);

CREATE INDEX IF NOT EXISTS files__author_id
    ON files
    (author_id);

CREATE INDEX IF NOT EXISTS files__name
    ON files
    (name);

CREATE TABLE IF NOT EXISTS vertices (
    id          uuid        NOT NULL,
    note        text        NOT NULL,
    style       "char"      NOT NULL,
    file_id     uuid        NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (file_id)
        REFERENCES files(id)
        ON DELETE CASCADE
);

ALTER TABLE files
DROP CONSTRAINT IF EXISTS files_root_id_fkey,
ADD CONSTRAINT files_root_id_fkey
    FOREIGN KEY (root_id)
    REFERENCES vertices(id)
    ON DELETE CASCADE;

CREATE TABLE IF NOT EXISTS edges (
    parent_id   uuid        NOT NULL,
    child_id    uuid        NOT NULL,
    index       int         NOT NULL,
    PRIMARY KEY (parent_id, index),
    FOREIGN KEY (parent_id)
        REFERENCES vertices(id)
        ON DELETE CASCADE,
    FOREIGN KEY (child_id)
        REFERENCES vertices(id)
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS edges__child_id
    ON edges
    (child_id);

CREATE SEQUENCE IF NOT EXISTS edge_index;

COMMIT;
