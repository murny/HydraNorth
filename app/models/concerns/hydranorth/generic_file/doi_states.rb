module Hydranorth
  module GenericFile
    module DOIStates
      extend ActiveSupport::Concern

      included do


        include AASM

        aasm do
          state :unpublished, :initial => true
          state :unminted
          state :excluded
          state :available
          state :unsynced

          event :created do
            transitions from: :unpublished, to: :unminted
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
            transitions from: :available, to: :unsynced
          end

          event :synced do
            transitions from: :unsynced, to: :available
          end

          event :removed do
            transitions from: :unsynced, to: :unpublished
          end

          event :readded do
            transitions from: :unpublished,  to: :unsynced
          end
        end

      end
    end
  end
end
