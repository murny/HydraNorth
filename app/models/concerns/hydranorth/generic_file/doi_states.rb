module Hydranorth
  module GenericFile
    module DOIStates
      extend ActiveSupport::Concern

      included do
        after_save :handle_doi_states
        # TODO before_destroy callback to cleanup doi?

        include AASM

        aasm do
          state :unpublished, :initial => true
          state :unminted
          state :excluded
          state :available
          state :unsynced

          event :created do
            transitions from: :unpublished, to: :unminted, after: :queue_create_job
          end

          event :exclude do
            transitions from: :unpublished, to: :excluded
          end

          event :include do
            transitions from: :excluded, to: :unpublished
          end

          event :minted do
            transitions from: :unminted, to: :available
          end

          event :altered do
            transitions from: :available, to: :unsynced, after: :queue_update_job
          end

          event :synced do
            transitions from: :unsynced, to: :available
          end

          event :removed do
            transitions from: :unsynced, to: :unpublished
          end

          event :readded do
            transitions from: :unpublished,  to: :unsynced, after: :queue_update_job
          end
        end

        def doi_fields_present?
          self && self.title.present? && self.creator.present? && self.resource_type.present? && Sufia.config.admin_resource_types[self.resource_type.first].present?
        end

        private

          def handle_doi_states
            # TODO handle unminted/unsynced states?
            if doi.blank?
              if !private? && unpublished? && doi_fields_present?
                created!(id)
              end
            else
              # logger.debug "changed attributes hash: #{previous_changes.inspect}"
              # logger.debug "doi_fields_changed value?: #{doi_fields_changed?}"
              # logger.debug "visibility_changed value?: #{visibility_changed?}"
              if doi_fields_changed? || visibility_changed? # TODO: not enough, could be changing from public to authenticated states or vice versa...
                  altered!(id) if available?
                  readded!(id) if unpublished?
              end
            end
          end


          def doi_fields_changed?
            doi_fields = [:title, :creator, :year_created, :resource_type]
            doi_fields.any? {|k| previous_changes.key?(k) }
          end

          def queue_create_job(generic_file_id)
            DOIServiceJob.perform_later(generic_file_id, 'create')
          end

          def queue_update_job(generic_file_id)
            DOIServiceJob.perform_later(generic_file_id, 'update')
          end

      end
    end
  end
end
