class GenericFile < ActiveFedora::Base
  include Sufia::GenericFile
  include Hydranorth::AccessControls::InstitutionalVisibility
  include Hydranorth::GenericFile::Metadata
  include Hydranorth::Thesis::Metadata
  include Hydranorth::GenericFile::Export
  include Hydranorth::GenericFile::Fedora3Foxml
  include Hydranorth::GenericFile::DOI
  include Hydranorth::GenericFile::DOIStates
  include Hydranorth::GenericFile::Era1Stats

  after_save :handle_doi_states

  # override the default indexer from Sufia
  def self.indexer
    Hydranorth::GenericFileIndexingService
  end

  # work around for ActiveFedora logic
  # that mapped activetriples to collection names
  # on persisted collection relationships
  alias_method :original_has_collection, :hasCollection

  def hasCollection
    return original_has_collection.map do |member_activetriple|
      if member_activetriple.is_a? String
        member_activetriple
      else
        ActiveFedora::Base.from_uri(member_activetriple.id, nil).title
      end
    end
  end

  def hasCollectionId=(arr)
    # when clearing hasCollectionId, we must also ensure
    # hasCollection stays in sync
    if arr.empty?
      self.hasCollection = []
    end
    super(arr)
  end

  def thesis?
    self.resource_type.include? Sufia.config.special_types['thesis']
  end

  def ser?
    self.resource_type.include? Sufia.config.special_types['ser']
  end

  def cstr?
    self.resource_type.include? Sufia.config.special_types['cstr']
  end

  def doi_fields_present?
    self && self.title.present? && self.creator.present? && self.resource_type.present? && Sufia.config.admin_resource_types[self.resource_type.first].present?
  end

  private

  def handle_doi_states
    if doi.blank?
      return if private? || excluded? || !doi_fields_present?
      if !unminted?
        created!
        DOICreateJob.perform_later(id)
      end
    else
      if doi_fields_changed? || visibility_changed? # TODO: not enough, could be changing from public to authenticated states or vice versa...
        if !unsynced?
          aasm_state = 'unsynced' # altered or readded
          save!
          DOIUpdateJob.perform_later(id)
        end
      end
    end
  end


  def doi_fields_changed?
    doi_fields = [:title, :creator, :year_created, :resource_type]
    doi_fields.any? {|k| previous_changes.key?(k) }
  end

end
