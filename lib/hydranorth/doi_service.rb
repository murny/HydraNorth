module Hydranorth
  # class for interacting with DOI API using EZID
  class DOIService
    PUBLISHER = 'University of Alberta Libraries'.freeze
    DATACITE_METADATA_SCHEME = {
      'Book' => 'Text/Book',
      'Book Chapter' => 'Text/Chapter',
      'Conference\/workshop Poster' => 'Image/Conference Poster',
      'Conference\/workshop Presentation' => 'Other/Presentation',
      'Dataset' => 'Dataset',
      'Image' => 'Image',
      'Journal Article (Draft-Submitted)' => 'Text/Submitted Journal Article',
      'Journal Article (Published)' => 'Text/Published Journal Article',
      'Learning Object' => 'Other/Learning Object',
      'Report' => 'Text/Report',
      'Research Material' => 'Other/Research Material',
      'Review' => 'Text/Review',
      'Computing Science Technical Report' => 'Text/Report',
      'Structual Engineering Report' => 'Text/Report',
      'Thesis' => 'Text/Thesis'
    }.freeze

    # pass the generic file to DOI, return the DOI
    def self.create(generic_file)
      return unless generic_file && generic_file.title.any? && generic_file.creator.any? && generic_file.resource_type.any?
      ezid_identifer = Ezid::Identifier.mint(Ezid::Client.config.default_shoulder,
                                             datacite_creator:  generic_file.creator.join('; '),
                                             datacite_publisher: PUBLISHER, # generic file does have a publisher field...?
                                             datacite_publicationyear: generic_file.year_created.present? ? generic_file.year_created : '(:unav)',
                                             datacite_resourcetype: DATACITE_METADATA_SCHEME[generic_file.resource_type.first],
                                             datacite_title:  generic_file.title.first,
                                             target: Rails.application.routes.url_helpers.generic_file_url(id: generic_file.id))
      return unless ezid_identifer.present?
      generic_file.doi = ezid_identifer.id
      generic_file.save!
      ezid_identifer
    end

    def self.update(doi_id, new_metadata)
      Ezid::Identifier.modify(doi_id, new_metadata)
    end

    # MUST BE PUBLIC FIRST, or will fail (Cannot make a reserved identifier unavailable)
    # Might have to find the DOI first so we can validate this....
    # if this is the case there is a unavailable!(reason = nil) instance method
    # That should be used instead, which requires a save call after
    def self.unavailable(doi_id, status_message = nil)
      Ezid::Identifier.modify(doi_id, status: status_message.nil? ? Ezid::Status::UNAVAILABLE : Ezid::Status::UNAVAILABLE + " | #{status_message}")
    end
  end
end
