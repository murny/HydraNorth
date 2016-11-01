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

    def self.create(generic_file)
      if generic_file.doi_fields_present?
        ezid_identifer = Ezid::Identifier.mint(Ezid::Client.config.default_shoulder, doi_metadata(generic_file))
        if ezid_identifer.present?
          generic_file.doi = ezid_identifer.id
          generic_file.minted
          generic_file.save!
          ezid_identifer
        end
      end
    end

    def self.update(generic_file)
      ezid_identifer = Ezid::Identifier.modify(generic_file.doi, doi_metadata(generic_file))
      if ezid_identifer.present?
        if generic_file.private?
          generic_file.removed!
        else
          generic_file.synced!
        end
        ezid_identifer
      end
    end

    private
      # Parse GenericFile and return hash of relevant DOI information
      def self.doi_metadata(generic_file)
        return {
          datacite_creator:  generic_file.creator.join('; '),
          datacite_publisher: PUBLISHER,
          datacite_publicationyear: generic_file.year_created.present? ? generic_file.year_created : '(:unav)',
          datacite_resourcetype: DATACITE_METADATA_SCHEME[generic_file.resource_type.first],
          datacite_title:  generic_file.title.first,
          target: Rails.application.routes.url_helpers.generic_file_url(id: generic_file.id),
          # Can only set status if been minted previously, else its public
          status: generic_file.private? && generic_file.doi.present? ? "#{Ezid::Status::UNAVAILABLE} | not publicly released" : Ezid::Status::PUBLIC
        }
      end
  end
end
