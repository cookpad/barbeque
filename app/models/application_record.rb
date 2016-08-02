require 'kaminari'
require 'kaminari/models/active_record_model_extension'

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  include Kaminari::ActiveRecordModelExtension
end
