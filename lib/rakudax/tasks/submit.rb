module Rakudax
  class Tasks
    def self.submit
      unless Dir.exists?(Rakudax::Base.im_path)
        puts "error: Intermediate directory not found."
        puts "Intermediate directory path: #{Rakudax::Base.im_path}"
        exit 2
      end

      puts "[submit start]=============#{Time.now}"
      puts "Data file path: #{Rakudax::Base.im_path}/<files>"

      Rakudax::Settings.models.each do |model|
        gen_code = "
  class #{model.name} < ActiveRecord::Base
        "

        (model.associations || []).each do |asc|
          next unless asc.method
          next unless asc.scope
          gen_code += "#{asc.method} :#{asc.scope}#{", #{asc.options}" unless asc.options.nil?}
          "
        end

        (model.attrs || []).each do |attr| 
          next unless attr.method
          next unless attr.scope
          gen_code += "#{attr.method} :#{attr.scope}#{", #{attr.options}" unless attr.options.nil?}
          "
        end

        (model.modules || []).each do |mdl|
          gen_code += "include #{mdl}
          "
        end

        gen_code += "
  end
        "

        puts gen_code if Rakudax::Base.debug
        eval gen_code
        const_get(model.name).establish_connection Rakudax::Base.dbconfig[model.db]
        const_get(model.name).table_name = model.table unless model.table.nil?
        const_get(model.name).primary_key = model.id.to_sym unless model.id.nil?
      end


      Rakudax::Settings.models.each do |model|
        classname = model.name
        data_path = Rakudax::Base.im_path.join(classname.underscore)
        unless File.exists?(data_path)
          puts "Loaded: #{data_path}"
          puts "Skip #{classname}, because data is not found."
          next
        end
        value = YAML.load(File.read(data_path))
        classcount = 0
        print "Checking #{classname} ... "
        begin
          classcount = const_get(classname).count
          puts "Success (before count: #{classcount})"
        rescue => ex
          puts "Fail"
          STDERR.puts "Fatal Error: class #{classname} not found"
          puts ex.message if Rakudax::Base.debug
          next
        end

        if Rakudax::Settings.force_reset
          print "Delete All #{classname}s ... "
          tablename = model.table || classname.tableize
          ActiveRecord::Base.establish_connection Rakudax::Base.dbconfig[model.db]
          case Rakudax::Base.dbconfig[model.db]["adapter"]
          when "sqlite3"
            ActiveRecord::Base.connection.execute("DELETE FROM #{tablename}")
            ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='#{tablename}';")
            ActiveRecord::Base.connection.execute("VACUUM")
          else
            ActiveRecord::Base.connection.execute("TRUNCATE #{tablename}")
          end
          if const_get(classname).count == 0
            classcount = 0
            puts "Success"
          else
            puts "Fail"
          end
        end

        print "Submit #{const_get(classname).to_s}#{"s" if value.count > 1} ..."
        value.each do | hash |
          $hash = hash
          begin
            const_get(classname).create hash
          rescue => ex
            STDERR.puts "Fatal Error: New #{classname} cant create. #{hash}"
            puts ex.message if Rakudax::Base.debug
          end
        end

        totalcount = const_get(classname).count
        createcount = totalcount - classcount
        if createcount == value.count
          puts " OK (succeed: #{createcount}/failed: 0/ total: #{totalcount})"
        else
          puts " NG (succeed: #{createcount}/failed: #{value.count - createcount}/ total: #{totalcount})"
        end
        value = nil
      end

      puts "[submit finish]=============#{Time.now}"
    end
  end
end
