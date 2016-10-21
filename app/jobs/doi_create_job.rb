class DOICreateJob < ActiveJob::Base
  queue_as :default

  def perform(generic_file_id)
    work = GenericFile.find(generic_file_id)
    Hydranorth::DOIService.create(work)
  end
end
