module BenefitSponsors
  module Organizations
    class BrokerAgencyProfile < BenefitSponsors::Organizations::Profile
      include SetCurrentUser
      include AASM

      field :entity_kind, type: String
      field :market_kind, type: String
      field :corporate_npn, type: String
      field :primary_broker_role_id, type: BSON::ObjectId
      field :default_general_agency_profile_id, type: BSON::ObjectId

      field :languages_spoken, type: Array, default: ["en"] # TODO
      field :working_hours, type: Boolean, default: false
      field :accept_new_clients, type: Boolean

      field :aasm_state, type: String

      # Web URL - Broker Specific ? - Migrate data
      field :home_page, type: String

      embeds_one  :inbox, as: :recipient, cascade_callbacks: true
      embeds_many :documents, as: :documentable
      accepts_nested_attributes_for :inbox

      has_many :broker_agency_contacts, class_name: "Person", inverse_of: :broker_agency_contact
      accepts_nested_attributes_for :broker_agency_contacts, reject_if: :all_blank, allow_destroy: true

      validates_presence_of :market_kind, :entity_kind #, :primary_broker_role_id

      validates :corporate_npn,
        numericality: {only_integer: true},
        length: { minimum: 1, maximum: 10 },
        uniqueness: true,
        allow_blank: true

      validates :market_kind,
        inclusion: { in: ::BenefitMarkets::BENEFIT_MARKET_KINDS, message: "%{value} is not a valid practice area" },
        allow_blank: false

      validates :entity_kind,
        inclusion: { in: Organization::ENTITY_KINDS[0..3], message: "%{value} is not a valid business entity kind" },
        allow_blank: false

      after_initialize :build_nested_models

      scope :active,      ->{ any_in(aasm_state: ["is_applicant", "is_approved"]) }
      scope :inactive,    ->{ any_in(aasm_state: ["is_rejected", "is_suspended", "is_closed"]) }


      def employer_clients
      end

      def family_clients
      end

      aasm do #no_direct_assignment: true do
        state :is_applicant, initial: true
        state :is_approved
        state :is_rejected
        state :is_suspended
        state :is_closed

        event :approve do
          transitions from: [:is_applicant, :is_suspended], to: :is_approved
        end

        event :reject do
          transitions from: :is_applicant, to: :is_rejected
        end

        event :suspend do
          transitions from: [:is_applicant, :is_approved], to: :is_suspended
        end

        event :close do
          transitions from: [:is_approved, :is_suspended], to: :is_closed
        end
      end
      class << self

        private

        def initialize_profile
          return unless is_benefit_sponsorship_eligible.blank?

          write_attribute(:is_benefit_sponsorship_eligible, false)
          @is_benefit_sponsorship_eligible = false
          self
        end
      end
    end
  end
end
