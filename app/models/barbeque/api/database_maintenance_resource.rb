class Barbeque::Api::DatabaseMaintenanceResource
  include Garage::Representer

  property :message

  delegate :message, to: :@exception

  def initialize(exception)
    @exception = exception
  end
end
