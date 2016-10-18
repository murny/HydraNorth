module Hydranorth
  module GenericFile
    module DOI_States
      include AASM

      aasm do
        state :new, :initial => true
        state :available
        state :unavailable
        state :unsynced

        event :created do
          transitions from: :new, to: :unsynced
        end

        event :changed do
          transitions from: :available, to: :unsynced
        end

        event :synced do
          transitions from: :unsynced, to: :available
        end

        event :deleted do
          transitions from: [:unsynced, :available], to: :unavailable
        end
      end
    end
  end
end
