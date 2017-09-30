class HealthChecksController < ActionController::Base
  def show
    head :ok
  end
end
