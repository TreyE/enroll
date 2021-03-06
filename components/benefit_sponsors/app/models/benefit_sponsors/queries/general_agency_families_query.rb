module BenefitSponsors
  module Queries
    class GeneralAgencyFamiliesQuery
      attr_reader :search_string
      attr_reader :custom_attributes

      def datatable_search(string)
        @search_string = string
        self
      end

      def initialize(general_agency_id)
        @general_agency_id = BSON::ObjectId.from_string(general_agency_id)
      end

      def skip(num)
        build_scope.skip(num)
      end

      def limit(num)
        build_scope.limit(num)
      end

      def klass
        Family
      end

      def size
        build_scope.count
      end

      def order_by(var)
        @order_by = var
        self
      end

      def build_scope
        criteria = {
          "family_members" => {
            :$elemMatch => {
              :is_primary_applicant => true,
              :person_id => {"$in" => employee_person_ids}
            }
          }
        }
        if @search_string
          person_id = Person.unscoped.where(Person.search_hash(@search_string)).limit(700).pluck(:_id)
          criteria = {
            "$and" => [
              { 'family_members.person_id' => {"$in" => person_id} },
              criteria
            ]
          }
        end
        if @order_by
          return Family.unscoped.where(criteria).order_by(@order_by)
        end
        Family.unscoped.where(criteria)
      end

      def census_employee_ids
        @census_member_ids ||= CensusMember.collection.aggregate([
          { "$match" => {aasm_state: {"$in"=> CensusEmployee::EMPLOYMENT_ACTIVE_STATES}, benefit_sponsors_employer_profile_id: {"$in" => employer_ids}}},
          { "$group" => {"_id" => "$_id"}}
        ]).map { |rec| rec["_id"] }
      end

      def employee_person_ids
        @employee_person_ids ||= Person.unscoped.where("employee_roles.census_employee_id" => {"$in" => census_employee_ids}).pluck(:_id)
      end

      def plan_design_organizations
        ::SponsoredBenefits::Organizations::PlanDesignOrganization.find_by_active_general_agency(@general_agency_id)
      end

      def employer_ids
        @employer_ids ||= plan_design_organizations.pluck(:sponsor_profile_id).compact
      end

    end
  end
end
