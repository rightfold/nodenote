module NN.Server.Setup
( setupDB
) where

import Database.PostgreSQL (Connection, execute, POSTGRESQL)
import NN.Prelude

setupDB :: ∀ eff. Connection -> Aff (postgreSQL :: POSTGRESQL | eff) Unit
setupDB conn = do
    execute conn """
        CREATE TABLE IF NOT EXISTS users (
            id              uuid        NOT NULL,
            name            text        NOT NULL,
            email_address   char(254)   NOT NULL,
            password_hash   bytea       NOT NULL,
            PRIMARY KEY (id)
        )
    """ unit

    execute conn """
        CREATE UNIQUE INDEX IF NOT EXISTS users__email_address
            ON users
            (lower(email_address))
    """ unit

    execute conn """
        CREATE TABLE IF NOT EXISTS files (
            id              uuid        NOT NULL,
            name            text        NOT NULL,
            author_id       uuid        NOT NULL,
            root_id         uuid        NOT NULL,
            PRIMARY KEY (id),
            FOREIGN KEY (author_id)
                REFERENCES users(id)
                ON DELETE CASCADE
        );
    """ unit

    execute conn """
        CREATE INDEX IF NOT EXISTS files__name
            ON files
            (name)
    """ unit

    execute conn """
        CREATE TABLE IF NOT EXISTS vertices (
            id          uuid        NOT NULL,
            note        text        NOT NULL,
            style       char(20)    NOT NULL,
            file_id     uuid        NOT NULL,
            PRIMARY KEY (id),
            FOREIGN KEY (file_id)
                REFERENCES files(id)
                ON DELETE CASCADE
        )
    """ unit

    execute conn """
        ALTER TABLE files
        DROP CONSTRAINT IF EXISTS files_root_id_fkey,
        ADD CONSTRAINT files_root_id_fkey
            FOREIGN KEY (root_id)
            REFERENCES vertices(id)
            ON DELETE CASCADE
    """ unit

    execute conn """
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
        )
    """ unit

    execute conn """
        CREATE INDEX IF NOT EXISTS edges__child_id
            ON edges
            (child_id)
    """ unit
