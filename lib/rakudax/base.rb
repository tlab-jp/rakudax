module Rakudax
  class Base
    require 'pathname'
    USAGE=<<-EOS
===========================================================================
<>: required
[]: optional

## new rakuda project creation
Usage: rakudax new [name]

 name: project name

## rakuda project execution
Usage: rakudax <control> [Options]

 control: generate, submit, migrate, verify

 Options:
 
 --setting <path>        *path to control setting file (default: config/<control>.yml)
 --database <path>       *path to database setting file (default: config/database.yml)
 --modules <path>        path to modules directory
 --env <enviroment>      control-setting enviroment (default: development)
 --intermediate <path>   path to intermediate files (default: dist/intermediate_files)
 --verify <path>         path to verify files (default: dist/verify)
 --threads <num>         threads num in generate (deafult: 1)
 --yaml                  change output type to yaml (default: json)
 --debug                 print debugging information to console
 --logging               enable ActiveRecord's logging. (output: active_record.log)

 *only support yaml setting file
===========================================================================
    EOS

    def self.exit_with_message(code, usage=false, msg=nil)
      puts msg unless msg.nil?
      puts USAGE if usage
      exit code
    end

    def self.root
      @@root ||= Pathname.pwd
    end

    def self.logging
      @@debug ||= false
    end

    def self.debug
      @@debug ||= false
    end

    def self.output_type
      @@output_type ||= 'json'
    end

    def self.threads
      @@threads ||= 1
    end

    def self.im_path
      @@im_path ||= self.root.join("dist").join("intermediate_files")
    end

    def self.im_path=(str)
      @@im_path = Pathname.new str
      @@im_path = self.root.join(str) unless @@im_path.absolute?
    end

    def self.mods_path
      @@mods_path ||= nil
    end

    def self.mods_path=(str)
      @@mods_path = Pathname.new str
      @@mods_path = self.root.join(str) unless @@mods_path.absolute?
    end

    def self.verify_path
      @@verify_path ||= self.root.join("dist").join("verify")
    end

    def self.verify_path=(str)
      @@verify_path = Pathname.new str
      @@verify_path = self.root.join(str) unless @@verify_path.absolute?
    end

    def self.dbconfig
      @@dbconfig ||= {}
    end

    def self.load_dbconfig(str)
      path = Pathname.new str
      path = self.root.join(str) unless path.absolute?
      @@dbconfig = YAML.load(
        File.read(
          Pathname.new(path)
        )
      )
      @@dbconfig.each do |k, v|
        next unless v["adapter"] == "sqlite3"
        p = Pathname.new v["database"]
        @@dbconfig[k]["database"] = self.root.join(v["database"]).to_s unless p.absolute?
      end
      @@dbconfig
    rescue
      @@dbconfig = nil
    end

    def self.env
      @@env ||= "production"
    end

    def self.models
      @@models ||= {}
    end

    def self.control
      @@control
    end

    def self.settings_path
      @@settings_path ||= nil
    end

    def self.settings_path=(str)
      @@settings_path = Pathname.new str
      @@settings_path = self.root.join(str) unless @@settings_path.absolute?
    end

    def self.parse_options(argv)
      if argv.empty?
        self.exit_with_message 2, true
      end

      @@control = argv.shift


      if self.control == "--help" || self.control == "-h"
        self.exit_with_message 0, true
      end

      c_c_path = "config/#{self.control}.yml"
      d_c_path = "config/database.yml"

      while arg = argv.shift
        case arg
        when /\A--setting\z/
          c_c_path = argv.shift
        when /\A--database\z/
          d_c_path = argv.shift
        when /\A--modules\z/
          self.mods_path = argv.shift
        when /\A--intermediate\z/
          self.im_path = argv.shift
        when /\A--verify\z/
          self.verify_path = argv.shift
        when /\A--env\z/
          @@env = argv.shift
        when /\A--threads\z/
          th = argv.shift.to_i
          if th <= 0
            self.exit_with_message 1, false, "thread must be greater than 0."
          end
          @@threads = th
        when /\A--logging\z/
          @@logging = true
        when /\A--yaml\z/
          @@output_type = "yaml"
        when /\A--debug\z/
          @@debug = true
        when /\A--help\z/, /\A-h\z/
          self.exit_with_message 0, true
        else
          puts "unknown option #{arg}"
          self.exit_with_message 2, true
        end
      end

      # validate control and config
      case self.control
      when "generate", "migrate", "verify", "submit"
        self.settings_path = c_c_path
        require "rakudax/tasks/#{self.control}"
      else
        self.exit_with_message 1, true, "Control must chose from (generate migrate verify submit)"
      end

      # validate dbconfig
      if self.load_dbconfig(d_c_path).nil?
        self.exit_with_message 1, false, "Database config is broken or not found."
      end
    end

    def self.execute
      unless self.mods_path.nil?
        Dir.glob(Rakudax::Base.mods_path.join("*.rb")).each do |file|
          load file
        end
      end

      load "rakudax/settings.rb"
      puts "models: #{Rakudax::Settings.models}"
      if Rakudax::Settings.models.nil?
        self.exit_with_message 1, false, "models not defined."
      end

      if self.logging
        ActiveRecord::Base.logger = Logger.new Rakudax::Base.root.join("active_record.log")
        ActiveRecord::Base.logger.level = 0
      end

      Rakudax::Tasks.send self.control
    end
  end
end
