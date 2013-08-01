class RemoveDurationColFromjsonScheduleImportTab < ActiveRecord::Migration
	# the duration column (in time format) is no longer needed. Replaced by duration_secs col
	def up
		remove_column :train_jsonschedule_imports, :duration
	end
	
	def down
		add_column :train_jsonschedule_imports, :duration, :time 
	end
end
