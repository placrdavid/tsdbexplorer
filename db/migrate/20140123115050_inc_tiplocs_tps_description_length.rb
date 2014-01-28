class IncTiplocsTpsDescriptionLength < ActiveRecord::Migration
   def up
 	  change_column :tiplocs, :tps_description, :string, :limit => 50
   end

   def down
 	  change_column :tiplocs, :tps_description, :string, :limit => 26
   end
end
