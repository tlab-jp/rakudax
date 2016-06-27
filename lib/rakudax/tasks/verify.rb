module Rakudax
  class Tasks
    def self.verify
      require 'csv'

      FileUtils.rm_rf Rakudax::Base.verify_path
      FileUtils.mkdir_p Rakudax::Base.verify_path
      FileUtils.mkdir_p Rakudax::Base.verify_path.join("before")
      FileUtils.mkdir_p Rakudax::Base.verify_path.join("after")

      puts "[start verify(file create)]=============#{Time.now}"
      puts "output: #{Rakudax::Base.verify_path}"

      Rakudax::Settings.models.each do |model|
        {after: model.after, before: model.before}.each do |key, value|
          key = key.to_s
          model_name = model.name + (key == "after" ? "After" : "Before")
          gen_code = "
      class #{model_name} < ActiveRecord::Base
        after_initialize :readonly!
          "

          (value.associations || []).each do |asc|
            next unless asc.method
            next unless asc.scope
            gen_code += "#{asc.method} :#{asc.scope}#{", #{asc.options}" unless asc.options.nil?}
            "
          end

          (value.modules || []).each do |mdl| 
            gen_code += "include #{mdl}
            "
          end

          gen_code += "
      def output_verify
        ["
          flg=true
          (model.attributes || {}).each do |k, v| 
            method_name = (key == "after" ? v : k)
            if flg == true
              flg = false
            else
              gen_code += ","
            end
            gen_code += "\n          self.#{method_name}"
          end

          gen_code += "
        ].map{|ittr| ittr.blank? ? nil : ittr}
      end
    end
          "
          puts gen_code if Rakudax::Base.debug
          eval gen_code
          const_get(model_name).establish_connection Rakudax::Base.dbconfig[value.db]
          table_name = value.table.nil? ? model.name.tableize : value.table
          const_get(model_name).table_name = table_name
          const_get(model_name).primary_key = value.id.to_sym unless value.id.nil?
          const_get(model_name).inheritance_column = nil if value.inheritance
        end
      end

      Rakudax::Settings.models.each do |model|
        print "Reading #{model.name} ..."
        CSV.open(Rakudax::Base.verify_path.join("after").join(model.name), 'w') do | file |
          scope = const_get("#{model.name}After").all
          unless model.after.scope.nil?
            (model.after.scope.joins || []).each do |join|
              scope = scope.joins(join.to_sym)
            end
            (model.after.scope.wheres || []).each do |where|
              scope = scope.where(where)
            end
            (model.after.scope.orders || []).each do |order|
              scope = scope.order(order)
            end
          end
          scope.each do |klass|
            file << klass.output_verify
          end
        end
        CSV.open(Rakudax::Base.verify_path.join("before").join(model.name), 'w') do | file |
          scope = const_get("#{model.name}Before").all
          unless model.before.scope.nil?
            (model.before.scope.joins || []).each do |join|
              scope = scope.joins(join.to_sym)
            end
            (model.before.scope.wheres || []).each do |where|
              scope = scope.where(where)
            end
            (model.before.scope.orders || []).each do |order|
              scope = scope.order(order)
            end
          end
          scope.each do |klass|
            file << klass.output_verify
          end
        end
        puts "finish"
      end

      puts "[finish verify(file create)]=============#{Time.now}"
    end
  end
end
