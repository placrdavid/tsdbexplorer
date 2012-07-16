
class TrackedTrain < ActiveRecord::Base

  has_many :station_updates, :primary_key => :train_id, :foreign_key => :train_id, :dependent => :delete_all

end
