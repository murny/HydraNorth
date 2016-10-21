class DOIRemoveJob < ActiveJob::Base
  queue_as :default

  def perform(doi_id, status_message)
    Hydranorth::DOIService.unavailable(doi_id, status_message)
  end
end
