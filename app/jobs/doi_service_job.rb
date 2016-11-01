class DOIServiceJob < ActiveJob::Base
  queue_as :default

  def perform(generic_file_id, type)
    file = GenericFile.find(generic_file_id)
    if file
      if type == 'create'
        Hydranorth::DOIService.create(file)
      else
        Hydranorth::DOIService.update(file)
      end
    end
  end
end
