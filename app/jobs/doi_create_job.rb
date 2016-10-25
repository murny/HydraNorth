class DOICreateJob < ActiveJob::Base
  queue_as :default

  def perform(generic_file_id)
    file = GenericFile.find(generic_file_id)
    if file
      Hydranorth::DOIService.create(file)
    end
  end
end
