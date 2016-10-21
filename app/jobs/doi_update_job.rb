class DOIUpdateJob < ActiveJob::Base
  queue_as :default

  def perform(generic_file_id)
    work = GenericFile.find(generic_file_id)
    # TODO
    # Create new_metadata hash off work object
    Hydranorth::DOIService.update(work.doi, new_metadata)
  end
end
