module Rakudax
  class Skel
    require 'pathname'
    require 'fileutils'

    DATABASE_YAML=<<-EOS
#sample_before:
#  adapter: mysql2
#  encoding: utf8
#  reconnect: true
#  database: sample_mysql
#  pool: 1
#  username: sample
#  password: sample
#  host: localhost

#sample_after:
#  adapter: sqlite3
#  pool: 1
#  database: db/sample_sqlite.sqlite3
#  timeout: 5000
EOS

    GENERATE_YAML=<<-EOS
default: &default
  limit: 0
  models: []

production:
  <<: *default

development:
  <<: *default
    EOS

    MIGRATE_YAML=<<-EOS
default: &default
  force_reset: true # truncate all data
  batch_size: 1000  # the size of the batch
  models:
    - name: Sample         # require
      auto_matching: true
      before:
        db: sample_before  # require
      after:
        db: sample_after   # require

production:
  <<: *default

development:
  <<: *default
    EOS

    SUBMIT_YAML=<<-EOS
default: &default
  force_reset: true # truncate all data
  models: []

production:
  <<: *default

development:
  <<: *default
    EOS

    VERIFY_YAML=<<-EOS
default: &default
  limit: 0
  models: []

production:
  <<: *default

development:
  <<: *default
    EOS

    GENERAL_MODULE=<<-EOS
module GeneralAttributes
##This module is loaded automatically in `generate` or `migrate`
##sample: overwrite(or add) a creator attribute.
# def creator
#   "rakuda"
# end
end
    EOS

    def self.root
      @@root ||= @@name.nil? ? Pathname.pwd : Pathname.pwd.join(@@name)
    end

    def self.create(name=nil)
      @@name = name
      self.create_dir("config")
      self.create_file("config/database.yml", DATABASE_YAML)
      self.create_file("config/generate.yml", GENERATE_YAML)
      self.create_file("config/migrate.yml",  MIGRATE_YAML)
      self.create_file("config/submit.yml", SUBMIT_YAML)
      self.create_file("config/verify.yml", VERIFY_YAML)
      self.create_dir("modules")
      self.create_file("modules/general_attributes.rb", GENERAL_MODULE)
    end

    def self.create_file(path, body)
      path = self.root.join(path)
      File.write path, body
      puts "create     #{path}"
    rescue => ex
      puts "cant create new file #{path}"
      puts ex.message
    end

    def self.create_dir(path)
      path = self.root.join(path)
      FileUtils.mkdir_p path
      puts "create     #{path}"
    rescue => ex
      puts "cant create new folder #{path}"
      puts ex.message
    end
  end
end
