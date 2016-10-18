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
    }

    # pass the generic file to DOI, return the DOI
    def self.create(generic_file)
      return unless generic_file && generic_file.title.any? && generic_file.creator.any? && generic_file.resource_type.any?
      doi = Ezid::Identifier.mint(Ezid::Client.config.default_shoulder,
        { datacite_creator:  generic_file.creator.join('; '),
          datacite_publisher: PUBLISHER, # generic file does have a publisher field...?
          datacite_publicationyear: generic_file.year_created.present? ? generic_file.year_created : '(:unav)',
          datacite_resourcetype: DATACITE_METADATA_SCHEME[generic_file.resource_type.first],
          datacite_title:  generic_file.title.first,
          target: Rails.application.routes.url_helpers.generic_file_url(id: generic_file.id)
        }
      )
      #updates to generic file?
      # doi
      # doi created?
      # doi_url?
      #return unless doi.present?
      #generic_file.doi = doi.id
      #generic_file.save

      # just return doi id instead of object?
      return doi
    end

    def self.update(doi_id, new_metadata)
      Ezid::Identifier.modify(doi_id, new_metadata)
    end


    # MUST BE PUBLIC FIRST, or will fail (Cannot make a reserved identifier unavailable)
    # Might have to find the DOI first so we can validate this....
    # if this is the case there is a unavailable!(reason = nil) instance method
    # That should be used instead, which requires a save call after
    def self.unavailable(doi_id, status_message=nil)
      Ezid::Identifier.modify(doi_id, { status: status_message.nil? ? Ezid::Status::UNAVAILABLE : Ezid::Status::UNAVAILABLE + " | #{status_message}" })
    end

    # methods that maybe needed?
    # status must be reserved in order to delete
    # def self.delete(generic_file)
    #   want to archive using modify/setting status instead of actually delete?
    #   old ark code does just sets status to unavailable???
    #
    #   just need doi passed in not the generic_file object?
    #
    #   find doi
    #   call delete on doi object
    #   no api from gem API for just deleting off of doi??
    # end

    # def self.doi_server_reachable?
    #   Ezid::Client.new.server_status.up? rescue false
    # end

    # def self.find(doi_id)
    #   Ezid::Identifier.find(doi_id)
    # end

  end
end
