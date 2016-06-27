require 'spec_helper'

describe Rakudax do
  it 'has a version number' do
    expect(Rakudax::VERSION).not_to be nil
  end

  #self.root
  it 'Base.root is working directory' do
    expect(Rakudax::Base.root).to eq(Pathname.pwd)
  end

  #self.exit_with_message(code, usage=false, msg=nil)
  it 'Base.exit_with_message is work fine' do
    [-1, 0, 1, 2].each do |code|
      [false, true].each do |usage|
        [nil, "message"].each do |msg|
          begin
            expect(STDOUT).to receive(:puts).with(Rakudax::Base::USAGE) if usage == true
            expect(STDOUT).to receive(:puts).with(msg) unless msg.nil?
            Rakudax::Base.exit_with_message code, usage, msg
          rescue SystemExit => ex
            expect(ex.status).to eq code

          else
            expect(true).to eq false
          end
        end
      end
    end
  end

  #reader functions
  #self.logging, self.debug, self.output_type, self.threads
  #self.dbconfig, self.env, self.models
  context "reader function" do
    before(:all) do
      [:@@logging, :@@debug, :@@output_type, :@@threads, :@@dbconfig, :@@env, :@@models].each do |class_variable|
        if Rakudax::Base.class_variable_defined? class_variable
          Rakudax::Base.remove_class_variable class_variable
        end
      end
    end
    [
      ["logging", false],
      ["debug", false],
      ["output_type", "json"],
      ["threads", 1],
      ["dbconfig", {}],
      ["env", "production"],
      ["models", {}]
    ].each do |test_func, default_value|
      it "Base.#{test_func}'s default value is correct." do
        expect(Rakudax::Base.send(test_func)).to eq default_value
      end
    end
  end

  #writter and reader functions
  #self.im_path=, self.mods_path=, self.verify_path=
  #self.settings_path=
  context "accessor function" do
    before(:all) do
      [:@@im_path, :@@mods_path, :@@verify_path, :@@settings_path].each do |class_variable|
        if Rakudax::Base.class_variable_defined? class_variable
          Rakudax::Base.remove_class_variable class_variable
        end
      end
    end
   [
     ["im_path", nil, Pathname.pwd.join("dist").join("intermediate_files")],
     ["im_path", "./", Pathname.pwd],
     ["im_path", Pathname.pwd, Pathname.pwd],
     ["mods_path", nil, nil],
     ["mods_path", "./", Pathname.pwd],
     ["mods_path", Pathname.pwd, Pathname.pwd],
     ["verify_path", nil, Pathname.pwd.join("dist").join("verify")],
     ["verify_path", "./", Pathname.pwd],
     ["verify_path", Pathname.pwd, Pathname.pwd],
     ["settings_path", nil, nil],
     ["settings_path", "./", Pathname.pwd],
     ["settings_path", Pathname.pwd, Pathname.pwd],
   ].each do |read_func, received_value, read_value|
     test_func = "#{read_func}="
     it "Base.#{test_func}'s set value is correct." do
       Rakudax::Base.send test_func, received_value unless received_value.nil?
       expect(Rakudax::Base.send(read_func)).to eq read_value
     end
   end
  end

  #self.parse_options
  context "Base.parse_options" do
    before(:each) do
      $stdout = File.open(File::NULL, "w")
    end
    after(:each) do
      $stdout = STDOUT
    end
    it "exit patterns" do
      [
        [
          2, # exit code
          [
            [], # argv is empty
            ["generate", "--unknown"]
      ]
      ],
        [
          1, # exit code
          [
            ["unknown"], #unknown control
            ["generate", "--database", "./notfoundconfigfile.tmp"],
            ["generate", "--threads", "0"]
      ]
      ],
        [
          0, # exit code
          [
            ["--help"],
            ["-h"],
            ["generate", "--help"],
            ["generate", "-h"]
      ]
      ]
      ].each do |code, argvs|
        argvs.each do |argv|
          begin
            Rakudax::Base.parse_options argv
          rescue SystemExit => ex
            expect(ex.status).to eq code
          else
            expect(true).to eq false
          end
        end
      end
    end

    it "work fine patterns" do
      argv_base = ["generate", "--database", "spec/files/config/database.yml"]
      [
        {
          argv: argv_base.dup.push("--debug"),
          method: "debug",
          value: true
        },
        {
          argv: argv_base,
          method: "dbconfig",
          klass: Hash
        },
        {
          argv: argv_base.dup.push("--setting", "spec/files/config/generate.yml"),
          method: "settings_path",
          value: Pathname.pwd.join("spec/files/config/generate.yml")
        },
        {
          argv: argv_base.dup.push("--modules", "spec/files/mods_generate"),
          method: "mods_path",
          value: Pathname.pwd.join("spec/files/mods_generate")
        },
        {
          argv: argv_base.dup.push("--intermediate", "spec/tmp/dist/im"),
          method: "im_path",
          value: Pathname.pwd.join("spec/tmp/dist/im")
        },
        {
          argv: argv_base.dup.push("--verify", "spec/tmp/dist/vf"),
          method: "verify_path",
          value: Pathname.pwd.join("spec/tmp/dist/vf")
        },
        {
          argv: argv_base.dup.push("--env", "rakuda"),
          method: "env",
          value: "rakuda"
        },
        {
          argv: argv_base.dup.push("--threads", "2"),
          method: "threads",
          value: 2
        },
        {
          argv: argv_base.dup.push("--logging"),
          method: "logging",
          value: true
        },
        {
          argv: argv_base.dup.push("--yaml"),
          method: "output_type",
          value: "yaml"
        }
      ].each do |test|
        Rakudax::Base.parse_options test[:argv]
        if test.keys.include?(:value)
          expect(Rakudax::Base.send(test[:method])).to eq test[:value]
        end

        if test.keys.include?(:klass)
          expect(Rakudax::Base.send(test[:method]).class).to eq test[:klass]
        end
      end
    end
  end
end
