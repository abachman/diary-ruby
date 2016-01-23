MIGRATIONS = {}

INITIALIZE = %[
CREATE TABLE IF NOT EXISTS `versions` (
  `version` TEXT NOT NULL,
  `migrated_at` TEXT DEFAULT NULL
);
]

## MIGRATION FORMAT:
# MIGRATIONS[number] = array of sql statements

# 001 - create initial tables
MIGRATIONS['001'] = [%[
  CREATE TABLE IF NOT EXISTS `entries` (
    `date_key` TEXT NOT NULL PRIMARY KEY,
    `day`  TEXT NOT NULL,
    `time` TEXT NOT NULL,
    `title` TEXT,
    `link` TEXT,
    `body` TEXT,
    `created_at` TEXT NOT NULL,
    `updated_at` TEXT DEFAULT NULL
  );
], %[
  CREATE INDEX IF NOT EXISTS `index_entries_on_key` on `entries` (`date_key`);
], %[
  CREATE TABLE IF NOT EXISTS `tags` (
    `name` TEXT DEFAULT NULL
  );
], %[
  CREATE TABLE IF NOT EXISTS `taggings` (
    `tag_id` INTEGER NOT NULL,
    `entry_id` TEXT NOT NULL
  );
], %[
  CREATE INDEX IF NOT EXISTS `index_taggings_on_tag_id` on `taggings` (`tag_id`);
], %[
  CREATE INDEX IF NOT EXISTS `index_taggings_on_entry_id` on `taggings` (`entry_id`);
]]

MIGRATION_VERSIONS = MIGRATIONS.keys.sort

module Diary
  class Migrator
    attr_reader :db

    def initialize(db)
      @db = db.database
    end

    def migrate!
      exists = false
      db.execute( "SELECT name FROM sqlite_master WHERE type='table' AND name='versions';" ) do |row|
        if row
          exists = true
        end
      end

      if !exists
        db.execute(INITIALIZE)
      end

      MIGRATION_VERSIONS.each do |version|
        exists = false
        on_date = nil
        db.execute( "select rowid, migrated_at from versions WHERE version = '#{version}'" ) do |row|
          if row
            exists = true
            on_date = row[1]
          end
        end

        if !exists
          Diary.debug("UPDATING DATABASE TO VERSION #{ version }")
          if MIGRATIONS[version].is_a?(Array)
            MIGRATIONS[version].each do |statement|
              db.execute(statement)
            end
          else
            db.execute(MIGRATIONS[version])
          end
          db.execute("INSERT INTO versions VALUES ('#{version}', strftime('%Y-%m-%dT%H:%M:%S+0000'));")
        else
          Diary.debug("AT #{ version } SINCE #{ on_date }")
        end
      end
    end
  end
end
