class DOIUpdateJob < ActiveJob::Base
  queue_as :default

  def perform(generic_file_id)
    file = GenericFile.find(generic_file_id)
    Hydranorth::DOIService.update(file) unless file
  end
end
