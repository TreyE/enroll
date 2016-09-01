require 'rails_helper'

describe Importers::ConversionEmployeePolicyUpdate do
  describe "given an existing employee and valid employer", dbclean: :after_each do
    context "and the employee's plan HIOS ID is changed" do
      context "and the employee's enrollment is not auto-renewed" do
        it "should change the employee enrollment plan HIOS ID"
      end

      context "and the employee's enrollment is auto-renewed" do
        context "and the employee has not changed renewal enrollment" do
          it "should change the employee enrollment plan HIOS ID"
          it "should change the employee auto-renewed enrollment to mapped plan HIOS ID"
        end

        context "and the employee has changed renewal enrollment" do
          it "adds an 'update inconsistancy: employee enrollment record changed' error"
          it "adds the error to the instance's error[:base] array"
        end
      end
    end
  end

  describe "employee with coverage already exists", dbclean: :after_each do

    let!(:employer_profile) { FactoryGirl.create(:employer_with_renewing_planyear, start_on: TimeKeeper.date_of_record.next_month.beginning_of_month, renewal_plan_year_state: 'renewing_enrolling') }

    let(:benefit_group) { employer_profile.active_plan_year.benefit_groups.first }
    let(:renewal_benefit_group) { employer_profile.renewing_plan_year.benefit_groups.first }

    let!(:census_employee) {
      FactoryGirl.create(:census_employee_with_active_and_renewal_assignment, employer_profile: employer_profile, benefit_group: benefit_group, renewal_benefit_group: renewal_benefit_group)
    }

    let(:spouse) { FactoryGirl.create(:person, last_name: "richards", first_name: "denise", ssn: '555532232') }
    let(:child)  { FactoryGirl.create(:person, last_name: "sheen", first_name: "sam", ssn: '555532230') }
    let!(:person) { FactoryGirl.create(:person_with_employee_role, first_name: census_employee.first_name, last_name: census_employee.last_name, ssn: census_employee.ssn, dob: census_employee.dob, census_employee_id: census_employee.id, employer_profile_id: employer_profile.id, hired_on: census_employee.hired_on, person_relationships: family_relationships) }
    let!(:family) { FactoryGirl.create(:family, :with_family_members, person: person, people: family_members) }

    let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, :with_enrollment_members, enrollment_members: family.family_members, benefit_group_id: benefit_group.id, benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id, effective_on: benefit_group.start_on, household: family.active_household, active_year: benefit_group.start_on.year)}
    let!(:renewing_hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, :with_enrollment_members, enrollment_members: family.family_members, benefit_group_id: renewal_benefit_group.id, benefit_group_assignment_id: census_employee.renewal_benefit_group_assignment.id, effective_on: renewal_benefit_group.start_on, household: family.active_household, active_year: renewal_benefit_group.start_on.year)}

    let(:record_attrs) do
      {
        :action=>"Update",
        :fein=> employer_profile.fein,
        :benefit_begin_date=> benefit_group.start_on,
        :hios_id=>hbx_enrollment.plan.hios_id,
        :subscriber_ssn=>person.ssn,
        :subscriber_dob=>person.dob.strftime("%m/%d/%Y"),
        :subscriber_gender=>person.gender,
        :subscriber_name_first=>person.first_name,
        :subscriber_name_last=>person.last_name,
        :subscriber_address_1=>"6700 Osborn Street",
        :subscriber_city=>"Falls Church",
        :subscriber_state=>"VA",
        :subscriber_zip=>"22046",
        :dep_1_ssn=>spouse.ssn,
        :dep_1_dob=>spouse.dob,
        :dep_1_gender=>spouse.gender,
        :dep_1_name_first=>spouse.first_name,
        :dep_1_name_last=>spouse.last_name,
        :dep_1_relationship=>"spouse",
        :default_policy_start => employer_profile.active_plan_year.start_on, 
        :plan_year => employer_profile.active_plan_year.start_on.year
      }
    end

    context "and dependent dropped from employee's enrollment" do
      let(:family_relationships) { [PersonRelationship.new(relative: spouse, kind: "spouse"), PersonRelationship.new(relative: child, kind: "child")] }
      let(:family_members) { [person, spouse, child] }

      before do
        census_employee.update_attributes(employee_role_id: person.employee_roles.first.id)
      end

      context 'when renewing enrollment is manually selected' do 

        it 'should drop the dependent from current enrollment' do
          expect(hbx_enrollment.hbx_enrollment_members.map(&:person)).to eq [person, spouse, child]
          expect(renewing_hbx_enrollment.hbx_enrollment_members.map(&:person)).to eq [person, spouse, child]

          ::Importers::ConversionEmployeePolicyAction.new(record_attrs).save

          hbx_enrollment.reload 
          renewing_hbx_enrollment.reload

          expect(hbx_enrollment.hbx_enrollment_members.map(&:person)).to eq [person, spouse]
          expect(renewing_hbx_enrollment.hbx_enrollment_members.map(&:person)).to eq [person, spouse, child]
        end
      end

      context 'when renewing enrollment is a passive renewal' do
        let!(:renewing_hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, :with_enrollment_members, enrollment_members: family.family_members, benefit_group_id: renewal_benefit_group.id, benefit_group_assignment_id: census_employee.renewal_benefit_group_assignment.id, effective_on: renewal_benefit_group.start_on, household: family.active_household, active_year: renewal_benefit_group.start_on.year, aasm_state: 'auto_renewing')}

        it 'should drop the dependent from both current and renewing enrollment' do
          expect(hbx_enrollment.hbx_enrollment_members.map(&:person)).to eq [person, spouse, child]
          expect(renewing_hbx_enrollment.hbx_enrollment_members.map(&:person)).to eq [person, spouse, child]

          ::Importers::ConversionEmployeePolicyAction.new(record_attrs).save

          hbx_enrollment.reload 
          renewing_hbx_enrollment.reload

          expect(hbx_enrollment.hbx_enrollment_members.map(&:person)).to eq [person, spouse]
          expect(renewing_hbx_enrollment.hbx_enrollment_members.map(&:person)).to eq [person, spouse]
        end
      end
    end


    context "and dependent added to employee's enrollment" do
      let(:family_relationships) { [PersonRelationship.new(relative: child, kind: "child")] }
      let(:family_members) { [person, child] }

      let(:dependent_attrs) do
        {
          :dep_2_ssn=>child.ssn,
          :dep_2_dob=>child.dob,
          :dep_2_gender=>child.gender,
          :dep_2_name_first=>child.first_name,
          :dep_2_name_last=>child.last_name,
          :dep_2_relationship=>"child"
        }
      end

      before do
        census_employee.update_attributes(employee_role_id: person.employee_roles.first.id)
      end

      context 'when renewing enrollment is manually selected' do 

        it 'should add the dependent to current enrollment' do
          expect(hbx_enrollment.hbx_enrollment_members.map(&:person)).to eq [person, child]
          expect(renewing_hbx_enrollment.hbx_enrollment_members.map(&:person)).to eq [person, child]

          ::Importers::ConversionEmployeePolicyAction.new(record_attrs.merge(dependent_attrs)).save

          family.reload
          hbx_enrollment.reload 
          renewing_hbx_enrollment.reload

          expect(hbx_enrollment.hbx_enrollment_members.map(&:person)).to eq [person, child, spouse]
          expect(renewing_hbx_enrollment.hbx_enrollment_members.map(&:person)).to eq [person, child]
        end
      end

      context 'when renewing enrollment is a passive renewal' do
        let!(:renewing_hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, :with_enrollment_members, enrollment_members: family.family_members, benefit_group_id: renewal_benefit_group.id, benefit_group_assignment_id: census_employee.renewal_benefit_group_assignment.id, effective_on: renewal_benefit_group.start_on, household: family.active_household, active_year: renewal_benefit_group.start_on.year, aasm_state: 'auto_renewing')}

        it 'should add dependent to both current and renewing enrollment' do
          expect(hbx_enrollment.hbx_enrollment_members.map(&:person)).to eq [person, child]
          expect(renewing_hbx_enrollment.hbx_enrollment_members.map(&:person)).to eq [person, child]

          ::Importers::ConversionEmployeePolicyAction.new(record_attrs.merge(dependent_attrs)).save

          family.reload
          hbx_enrollment.reload 
          renewing_hbx_enrollment.reload

          expect(hbx_enrollment.hbx_enrollment_members.map(&:person)).to eq [person, child, spouse]
          expect(renewing_hbx_enrollment.hbx_enrollment_members.map(&:person)).to eq [person, child, spouse]
        end
      end
    end

  end
end
