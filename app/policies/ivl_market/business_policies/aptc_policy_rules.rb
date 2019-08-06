# frozen_string_literal: true

module IvlMarket
  module BusinessPolicies
    class AptcPolicyRules
      include BenefitMarkets::BusinessRulesEngine

      attr_reader :errors, :satisfied

      APTC_INELIGIBLE_ENROLLMENT_STATES = HbxEnrollment::CANCELED_STATUSES + HbxEnrollment::TERMINATED_STATUSES

      rule  :edit_aptc,
            validate: ->(enrollment){ APTC_INELIGIBLE_ENROLLMENT_STATES.exclude? enrollment.aasm_state },
            success:  ->(enrollment) { "#{enrollment} validated successfully" },
            fail:     ->(enrollment) {"APTC can not be changed for cancelled or trminated enrollment. Current Enrollment is in #{enrollment.aasm_state} state"}

      rule  :edit_aptc_2,
            validate: ->(enrollment){ APTC_INELIGIBLE_ENROLLMENT_STATES.exclude? enrollment.aasm_state },
            success:  ->(enrollment) { "#{enrollment} validated successfully" },
            fail:     ->(enrollment) {"Another rule for #{enrollment.aasm_state} state"}

      business_policy :update_aptc_for_current_enrollment, rules: [:edit_aptc, :edit_aptc_2]

      def initialize
        @errors = []
        @satisfied = false
      end

      def execute(enrollment)
        applied_policy = business_policies[:update_aptc_for_current_enrollment]
        @satisfied = applied_policy.is_satisfied?(enrollment)
        @errors << applied_policy.fail_results
        {errors: errors, satisfied: satisfied}
      end
    end
  end
end