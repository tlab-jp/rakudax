module Rakudax
  class Tasks
    def self.migrate
      puts "[start migrate]=============#{Time.now}"
      Rakudax::Settings.models.each do |migration|
        classname = migration.name
        classname_before = "#{classname}Before"
        model = migration.before
        gen_code = "
    class #{classname_before} < ActiveRecord::Base
      after_initialize :readonly!
      begin
        include GeneralAttributes
      rescue
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
    end
          "
        end

        puts gen_code if Rakudax::Base.debug
        eval gen_code
        const_get(classname_before).establish_connection Rakudax::Base.dbconfig[model.db]
        const_get(classname_before).table_name = model.table unless model.table.nil?
        const_get(classname_before).primary_key = model.id.to_sym unless model.id.nil?
        const_get(classname_before).inheritance_column = nil if model.inheritance

        model = migration.after
        gen_code = "
  class #{classname} < ActiveRecord::Base
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
        const_get(classname).establish_connection Rakudax::Base.dbconfig[model.db]
        const_get(classname).table_name = model.table unless model.table.nil?
        const_get(classname).primary_key = model.id.to_sym unless model.id.nil?
      end

      Rakudax::Settings.models.each do |migration|
        classname = migration.name
        classname_before = "#{classname}Before"
        model = migration.after

        classcount = 0
        print "Checking #{classname} ... "
        begin
          classcount = const_get(classname).count
          puts "Success (before count: #{classcount})"
        rescue
          puts "Fail"
          STDERR.puts "Fatal Error: class #{classname} not found"
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

        scope = const_get(classname_before).all
        data_count = scope.count
        print "Migrate #{const_get(classname).to_s}#{"s" if data_count > 1}(#{data_count}) ..."
        scope.each do |data|
          obj = const_get(classname).new
          if migration.auto_matching
            const_get(classname).attribute_names.each do |key|
              puts key
              obj.send("#{key}=", data.send(key)) if data.attribute_names.include?(key)
            end
          end
          puts migration.attributes
          (migration.attributes || {}).each do |key1, key2|
            obj.send("#{key2}=", data.send(key1))
          end
          begin
            unless obj.save
              STDERR.puts "Fatal Error: New #{classname} cant create. #{obj.errors.full_messages}"
            end
          rescue => ex
            STDERR.puts "Fatal Error: New #{classname} cant create. #{hash} (#{ex.message})"
          end
        end

        totalcount = const_get(classname).count
        createcount = totalcount - classcount
        if createcount == data_count
          puts " OK (succeed: #{createcount}/failed: 0/ total: #{totalcount})"
        else
          puts " NG (succeed: #{createcount}/failed: #{data_count - createcount}/ total: #{totalcount})"
        end
        value = nil
      end

      puts "[finish migrate]=============#{Time.now}"
    end
  end
end
