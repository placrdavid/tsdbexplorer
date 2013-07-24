class AddMultiColumnIndexToBasicSchedules < ActiveRecord::Migration
	def change
		# add index on multiple colums http://stackoverflow.com/questions/6169996/index-on-multiple-columns-in-ror
		add_index :basic_schedules, [:train_uid, :runs_from, :stp_indicator], :name => 'bsi_trainuid_stpindicator_runsfrom'
  end
end
