class Commit < ActiveRecord::Base
  attr_accessible :commited_at, :diff, :key, :log, :status
end
