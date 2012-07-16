
class StationUpdate < ActiveRecord::Base
  belongs_to :tracked_train, :primary_key => :train_id, :foreign_key => :train_id
  has_one :tiploc, :primary_key => :tiploc_code, :foreign_key => :tiploc_code

end
