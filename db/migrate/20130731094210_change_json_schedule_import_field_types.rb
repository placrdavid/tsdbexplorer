class ChangeJsonScheduleImportFieldTypes < ActiveRecord::Migration
	def up
		change_table :train_jsonschedule_imports do |t|
			# filesize doesn't fit in a 4bit integer, migrate to make it bigger
			t.change :filesize, :integer, :limit => 8
		end  
			# record duration in secs
		add_column :train_jsonschedule_imports, :duration_secs, :integer 
		# populate using
		# update train_jsonschedule_imports set duration_secs = (extract(hour from duration)*60*60) + (extract(minute from duration)*60) + extract(second from duration);
	end
	
	# return to prev state
	def down
		change_table :train_jsonschedule_imports do |t|
			t.change :filesize, :integer
		end
		remove_column :train_jsonschedule_imports, :duration_secs
	end
end