module Hydranorth
  module GenericFile
    module DOIStates
      extend ActiveSupport::Concern

      included do


        include AASM

        aasm do
          state :new, :initial => true
          state :unminted
          state :exclude
          state :available
          state :unsynced
          state :unavailable

          event :created do
            transitions from: :new, to: :unminted

            #call minting job -- successful sets to available
          end

          event :excluded do
            transitions from: :new, to: :exclude
          end

          event :included do
            transitions from: :exclude, to: :unminted

            #call miniting job -- successful sets to available
          end

          event :minted do
            transitions from: :unminted, to: :available
          end

          event :altered do
            transitions from: :available, to: :unsynced
          end

          event :synced do
            transitions from: :unsynced, to: :available

            # call update job if update-- successful sets state to available
          end

          event :removed do
            transitions from: :unsynced, to: :unavailable

            # call remove job if setting unavailable-- successful sets state to unavailable
          end
        end

      end
    end
  end
end
