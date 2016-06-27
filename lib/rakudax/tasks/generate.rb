module Rakudax
  class Tasks
    def self.generate
      FileUtils.rm_rf Rakudax::Base.im_path
      FileUtils.mkdir_p Rakudax::Base.im_path

      puts "[start generate]=============#{Time.now}"
      puts "output: #{Rakudax::Base.im_path}"

      Rakudax::Settings.models.each do |model|
        gen_code = "
  class #{model.name} < ActiveRecord::Base
    after_initialize :readonly!
    begin
      include GeneralAttributes
    rescue
    end
    def self.after_name
      '#{(model.after_name || model.name).underscore}'
    end
        #{"attr_accessor :id" if !model.id.nil? && model.auto_numbering}
        "
        (model.associations || []).each do |asc| 
          next unless asc.method
          next unless asc.scope
          gen_code += "#{asc.method} :#{asc.scope}#{", #{asc.options}" unless asc.options.nil?}
          "
        end

        (model.aliases || {}).each do |k, v|
          next unless k
          next unless v
          gen_code += "alias_attribute :#{v}, :#{k}
          "
        end

        (model.modules || []).each do |mdl| 
          gen_code += "include #{mdl}
          "
        end

        gen_code += "
    def convert
      {"
        (model.attributes || []).each_with_index do |k, i| 
          if i == 0
            gen_code += "\n        '#{k}' => self.#{k}"
          else
            gen_code += ",\n        '#{k}' => self.#{k}"
          end
        end

        gen_code += "
      }.reject{|key, value| (value.nil? || value == '')}
    end
  end
        "
        puts gen_code if Rakudax::Base.debug
        eval gen_code
        const_get(model.name).establish_connection Rakudax::Base.dbconfig[model.db]
        const_get(model.name).table_name = model.table unless model.table.nil?
        const_get(model.name).primary_key = model.id.to_sym unless model.id.nil?
        const_get(model.name).inheritance_column = nil if model.inheritance
      end

      finally = []

      Rakudax::Settings.models.each do |model|
        print "Generating #{model.name} ".ljust(40, ".")
        puts "total count: #{const_get(model.name).count}"
        Rakudax::Base.models[const_get(model.name).after_name] ||= []
        queue = Queue.new
        ary_threads = []
        if Rakudax::Settings.limit > 0
          const_get(model.name).limit(Rakudax::Settings.limit).each_with_index do |value, idx|
            queue.push [idx, value]
          end
        else
          const_get(model.name).all.each_with_index do |value, idx|
            queue.push [idx, value]
          end
        end

        Rakudax::Base.threads.to_i.times do
          ary_threads << Thread.start do
            while !queue.empty?
              idx, object = queue.pop(true)
              object.id = idx + (model.auto_numbering_begin || 1).to_i if model.auto_numbering
              value = object.convert
              valid = true
              encoding = Rakudax::Base.dbconfig[model.db]["encoding"] || "utf8"
              unless encoding == "utf8"
                require "nkf"
                opt = case encoding
                      when "ujis"; '-E -w'
                      when "sjis"; '-S -w'
                      when "jis"; '-J -w'
                      else; '-E -w'
                      end
                value.each do |k, v|
                  if v.nil? || v.blank? || k == "creater" || k == "updater" || (model.keep_encodes || []).include?(k)
                    next
                  elsif v.is_a?(String)
                    value[k] = NKF.nkf opt, v
                  else
                    STDERR.puts "Fatal Error: #{k} is not a String" if Rakudax::Base.debug
                  end
                end
              end
              (model.required || []).each do | col |
                valid = false if value[col].nil?
              end
              if valid
                Rakudax::Base.models[const_get(model.name).after_name].push value
              else
                STDERR.puts "Faital Error: #{value} validation error"
              end
            end

            Rakudax::Base.models[const_get(model.name).after_name].keep_if{|item| item.length != 0}

            model_name = const_get(model.name).after_name
            if model.data_output_finally == true
              finally.push model_name
              next
            end
            case Rakudax::Base.output_type
            when "yaml"
              File.open(Rakudax::Base.im_path.join(model_name), 'w') do | file |
                file << YAML.dump(Rakudax::Base.models[model_name])
              end
            when "json"
              require 'json'
              File.open(Rakudax::Base.im_path.join(model_name), 'w') do | file |
                file << Rakudax::Base.models[model_name].to_json
              end
            else
              STDERR.puts "Faital Error: output type [#{Rakudax::Base.output_type}] not supported."
            end
            Rakudax::Base.models[model_name] = nil unless model.keep_mem_data == true
          end
        end
        ary_threads.each { |th| th.join }
      end

      finally.each do |model_name|
        case Rakudax::Base.output_type
        when "yaml"
          File.open(Rakudax::Base.im_path.join(model_name), 'w') do | file |
            file << YAML.dump(Rakudax::Base.models[model_name])
          end
        when "json"
          require 'json'
          File.open(Rakudax::Base.im_path.join(model_name), 'w') do | file |
            file << Rakudax::Base.models[model_name].to_json
          end
        else
          STDERR.puts "Faital Error: output type [#{Rakudax::Base.output_type}] not supported."
        end
      end

      puts "[finish generate]=============#{Time.now}"
    end
  end
end

