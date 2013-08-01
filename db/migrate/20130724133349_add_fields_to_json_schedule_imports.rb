class AddFieldsToJsonScheduleImports < ActiveRecord::Migration
	def change
		add_column :train_jsonschedule_imports, :basic_schedules_size, :integer 
		add_column :train_jsonschedule_imports, :locations_size, :integer 
		add_column :train_jsonschedule_imports, :filesize, :integer 
		add_column :train_jsonschedule_imports, :duration, :time 
	end
end
