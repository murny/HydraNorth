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


  private
    # AFTER SAFE callback
    # change state of generic file and DOI
    def handle_doi_states
      # Has it been minited already?
      if doi.blank?
        # TODO need to handle if in unminted state...job already running for minitng...
        return if !doi_fields_filled? || exclude? # if doi info is missing or already exclude then no minting required
        # if excluded? # If boolean is set to exclude
        #  excluded
        # else
          created
        # end
      else
        # Handle case where if in unsynced state already...job already running for updating
        if doi_fields_changed? || doi_visibility_changed?
          altered
        end
      end
    end


    def doi_fields_changed?
      doi_fields = [:title, :creator, :year_created, :resource_type]
      doi_fields.any? {|k| previous_changes.key?(k) }
    end

    def doi_fields_filled?
      self && self.title.present? && self.creator.present? && self.resource_type.present?
    end

    def doi_visibility_changed?
      false
      # TODO
      #permissions_previously_changed? && private?
    end
end
