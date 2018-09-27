module Barbeque
  module Maintenance
    def self.database_maintenance_mode?
      ENV['BARBEQUE_DATABASE_MAINTENANCE'] == '1' && ENV['AWS_REGION'].present? && ENV['AWS_ACCOUNT_ID'].present?
    end
  end
end
