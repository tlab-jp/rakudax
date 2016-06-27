require 'spec_helper'
require 'fileutils'
require 'digest/md5'

describe "Tasks" do
  before(:each) do
    FileUtils.rm_rf "spec/tmp/dist"
    FileUtils.cp 'spec/files/db/before.sqlite3.template', 'spec/files/db/before.sqlite3'
    FileUtils.cp 'spec/files/db/after.sqlite3.template', 'spec/files/db/after.sqlite3'
    [:@@logging, :@@debug, :@@output_type, :@@threads, :@@dbconfig, :@@env, :@@models, :@@im_path, :@@mods_path, :@@verify_path, :@@settings_path].each do |class_variable|
      if Rakudax::Base.class_variable_defined? class_variable
        Rakudax::Base.remove_class_variable class_variable
      end
    end
    [:"Test", :"TestAfter", :"TestBefore"].each do |classname|
      Rakudax::Tasks.send(:remove_const, classname) if Rakudax::Tasks.const_defined? classname
    end
    [:"TestAttributes", :"TestBeforeAttributes", :"TestAfterAttributes"].each do |classname|
      Object.send(:remove_const, classname) if Object.const_defined? classname
    end
    $stdout = File.open(File::NULL, "w")
  end
  after(:each) do
    $stdout = STDOUT
  end

  it "generate submit verify is work fine." do
    FileUtils.cp 'spec/files/config/generate.yml', 'spec/tmp/setting.yml'
    argv = [
      "generate",
      "--debug",
      "--database", "spec/files/config/database.yml",
      "--setting", "spec/tmp/setting.yml",
      "--intermediate", "spec/tmp/dist/im",
      "--verify", "spec/tmp/dist/vf",
      "--modules", "spec/files/mods_generate",
      "--env", "test"
    ]
    Rakudax::Base.parse_options argv
    Rakudax::Settings.reload! if Rakudax::const_defined? "Settings"
    Rakudax::Base.execute
    expect(File.exist?("spec/tmp/dist/im/test")).to eq true

    Rakudax::Tasks.send(:remove_const, :"Test") if Rakudax::Tasks.const_defined? :"Test"

    FileUtils.cp 'spec/files/config/submit.yml', 'spec/tmp/setting.yml'
    argv = [
      "submit",
      "--debug",
      "--database", "spec/files/config/database.yml",
      "--setting", "spec/tmp/setting.yml",
      "--intermediate", "spec/tmp/dist/im",
      "--verify", "spec/tmp/dist/vf",
      "--env", "test"
    ]
    Rakudax::Base.parse_options argv
    Rakudax::Settings.reload! if Rakudax::const_defined? :"Settings"
    Rakudax::Base.execute
    expect(Digest::MD5.file("spec/files/db/after.sqlite3").to_s).not_to eq "128ceb8a24f469d479b754aa584bddac"


    FileUtils.cp 'spec/files/config/verify.yml', 'spec/tmp/setting.yml'
    argv = [
      "verify",
      "--debug",
      "--database", "spec/files/config/database.yml",
      "--setting", "spec/tmp/setting.yml",
      "--intermediate", "spec/tmp/dist/im",
      "--verify", "spec/tmp/dist/vf",
      "--modules", "spec/files/mods_verify",
      "--env", "test"
    ]
    Rakudax::Base.parse_options argv
    Rakudax::Settings.reload! if Rakudax::const_defined? :"Settings"
    Rakudax::Base.execute

    after_text=<<-EOS
1,ほげ１００,テストカラム１００
2,ほげ１０１,テストカラム１０１
3,ほげ200,テストカラム200
4,ほげ201,テストカラム201
    EOS

    before_text=<<-EOS
100,ほげ１００,テストカラム１００
101,ほげ１０１,テストカラム１０１
200,ほげ200,テストカラム200
201,ほげ201,テストカラム201
    EOS

    expect(File.read("spec/tmp/dist/vf/after/Test")).to eq after_text
    expect(File.read("spec/tmp/dist/vf/before/Test")).to eq before_text
  end

  it "migrate verify is work fine." do
    FileUtils.cp 'spec/files/config/migrate.yml', 'spec/tmp/setting.yml'
    argv = [
      "migrate",
      "--debug",
      "--database", "spec/files/config/database.yml",
      "--setting", "spec/tmp/setting.yml",
      "--modules", "spec/files/mods_migrate",
      "--env", "test"
    ]
    Rakudax::Base.parse_options argv
    Rakudax::Settings.reload!
    Rakudax::Base.execute
    expect(Digest::MD5.file("spec/files/db/after.sqlite3").to_s).not_to eq "128ceb8a24f469d479b754aa584bddac"

    [:"Test", :"TestAfter", :"TestBefore"].each do |classname|
      Rakudax::Tasks.send(:remove_const, classname) if Rakudax::Tasks.const_defined? classname
    end

    [:"TestAttributes", :"TestBeforeAttributes", :"TestAfterAttributes"].each do |classname|
      Object.send(:remove_const, classname) if Object.const_defined? classname
    end

    FileUtils.cp 'spec/files/config/verify.yml', 'spec/tmp/setting.yml'
    argv = [
      "verify",
      "--debug",
      "--database", "spec/files/config/database.yml",
      "--setting", "spec/tmp/setting.yml",
      "--intermediate", "spec/tmp/dist/im",
      "--verify", "spec/tmp/dist/vf",
      "--modules", "spec/files/mods_verify",
      "--env", "test"
    ]
    Rakudax::Base.parse_options argv
    Rakudax::Settings.reload!
    Rakudax::Base.execute

    after_text=<<-EOS
1,ほげ１００,テストカラム１００
2,ほげ１０１,テストカラム１０１
3,ほげ200,テストカラム200
4,ほげ201,テストカラム201
    EOS

    before_text=<<-EOS
100,ほげ１００,テストカラム１００
101,ほげ１０１,テストカラム１０１
200,ほげ200,テストカラム200
201,ほげ201,テストカラム201
    EOS

    expect(File.read("spec/tmp/dist/vf/after/Test")).to eq after_text
    expect(File.read("spec/tmp/dist/vf/before/Test")).to eq before_text
  end

  it "generate is exit 1 with error message." do
    FileUtils.cp 'spec/files/config/generate_error.yml', 'spec/tmp/setting.yml'
    argv = [
      "generate",
      "--debug",
      "--database", "spec/files/config/database.yml",
      "--setting", "spec/tmp/setting.yml",
      "--intermediate", "spec/tmp/dist/im",
      "--verify", "spec/tmp/dist/vf",
      "--modules", "spec/files/mods_generate",
      "--env", "test"
    ]
    Rakudax::Base.parse_options argv
    Rakudax::Settings.reload! if Rakudax::const_defined? "Settings"
    begin
      Rakudax::Base.execute
    rescue SystemExit => ex
                      puts ex.message
            puts ex.status
      expect(ex.status).to eq 1

    else
      expect(true).to eq false
    end
  end

  it "submit is exit 2 with error message." do
    FileUtils.cp 'spec/files/config/submit.yml', 'spec/tmp/setting.yml'
    argv = [
      "submit",
      "--debug",
      "--database", "spec/files/config/database.yml",
      "--setting", "spec/tmp/setting.yml",
      "--intermediate", "spec/tmp/dist/im",
      "--verify", "spec/tmp/dist/vf",
      "--env", "test"
    ]
    Rakudax::Base.parse_options argv
    Rakudax::Settings.reload! if Rakudax::const_defined? :"Settings"
    begin
      Rakudax::Base.execute
    rescue SystemExit => ex
                      puts ex.message
            puts ex.status
      expect(ex.status).to eq 2

    else
      expect(true).to eq false
    end
  end

end