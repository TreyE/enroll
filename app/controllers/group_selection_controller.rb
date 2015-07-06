class GroupSelectionController < ApplicationController
  def new
    initialize_common_vars

    @change_plan = params[:change_plan].present? ? params[:change_plan] : ''
  end

  def create
    initialize_common_vars
    change_plan = params[:change_plan].present? ? params[:change_plan] : ''
    keep_existing_plan = params[:commit] == "Keep existing plan"

    family_member_ids = params.require(:family_member_ids).collect() do |index, family_member_id|
      BSON::ObjectId.from_string(family_member_id)
    end

    if keep_existing_plan or change_plan.present?
      hbx_enrollment = @family.latest_household.hbx_enrollments.active.last
      hbx_enrollment.rebuild_members_by_coverage_household(coverage_household: @coverage_household)
    else
      hbx_enrollment = HbxEnrollment.new_from(
        employee_role: @employee_role,
        coverage_household: @coverage_household,
        benefit_group: find_benefit_group(@employee_role))
    end

    hbx_enrollment.hbx_enrollment_members = hbx_enrollment.hbx_enrollment_members.select do |member|
      family_member_ids.include? member.applicant_id
    end
    hbx_enrollment.save!

    if keep_existing_plan 
      redirect_to purchase_consumer_profiles_path
    elsif change_plan.present?
      redirect_to insured_plan_shopping_path(:id => hbx_enrollment.id, change_plan: change_plan)
    else
      redirect_to insured_plan_shopping_path(:id => hbx_enrollment.id)
    end
  end

  private

  def initialize_common_vars
    person_id = params.require(:person_id)
    emp_role_id = params.require(:employee_role_id)
    @person = Person.find(person_id)
    @family = @person.primary_family
    @employee_role = @person.employee_roles.detect { |emp_role| emp_role.id.to_s == emp_role_id.to_s }
    @coverage_household = @family.active_household.immediate_family_coverage_household
  end

  def find_benefit_group(employee_role)
    employee_role.benefit_group
  end
end
