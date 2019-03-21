require 'rails_helper'

describe 'ModelEvents::InitialEmployerApplicationDenied', dbclean: :around_each do

  let(:notice_event)    { "initial_employer_application_denied" }
  let(:model_event)  { "application_denied" }
  let(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month}
  let!(:employer)       { FactoryGirl.create(:employer_profile) }
  let!(:model_instance) { FactoryGirl.create(:plan_year, employer_profile: employer, start_on: start_on, aasm_state: 'enrolling') }
  let!(:benefit_group)  { FactoryGirl.create(:benefit_group, plan_year: model_instance) }

  describe "ModelEvent" do
    context "when initial employer application is denied" do
      it "should trigger model event" do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:plan_year_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :application_denied, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.close_open_enrollment!
      end
    end
  end

  describe "NoticeTrigger" do
    context "when initial application denied" do
      subject { Observers::NoticeObserver.new }

       let(:model_event) { ModelEvents::ModelEvent.new(:application_denied, model_instance, {}) }

       it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.initial_employer_application_denied"
          expect(payload[:employer_id]).to eq employer.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.plan_year_update(model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employer_profile.notice_date",
        "employer_profile.employer_name",
        "employer_profile.plan_year.current_py_start_date",
        "employer_profile.plan_year.current_py_oe_start_date",
        "employer_profile.broker.primary_fullname",
        "employer_profile.broker.organization",
        "employer_profile.broker.phone",
        "employer_profile.broker.email",
        "employer_profile.broker_present?",
        "employer_profile.plan_year.enrollment_errors"
      ]
    }
    let(:merge_model) { subject.construct_notice_object }
    let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "event_object_kind" => "PlanYear",
        "event_object_id" => model_instance.id
    } }

    context "when notice event received" do

      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      before do
        allow(subject).to receive(:resource).and_return(employer)
        allow(subject).to receive(:payload).and_return(payload)
      end

      it "should return merge model" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return the date of the notice" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it "should return employer name" do
        expect(merge_model.employer_name).to eq employer.legal_name
      end

      it "should return plan year start date" do
        expect(merge_model.plan_year.current_py_start_date).to eq model_instance.start_on.strftime('%m/%d/%Y')
      end

      it "should build return plan year open enrollment start date" do
        expect(merge_model.plan_year.current_py_oe_start_date).to eq model_instance.open_enrollment_start_on.strftime('%m/%d/%Y')
      end

      it "should return false when there is no broker linked to employer" do
        expect(merge_model.broker_present?).to be_falsey
      end
      
      it "should return enrollment errors" do
        enrollment_errors = []
        model_instance.enrollment_errors.each do |k, v|
          case k.to_s
          when "eligible_to_enroll_count"
            enrollment_errors << "at least one employee must be eligible to enroll"
          when "non_business_owner_enrollment_count"
            enrollment_errors << "at least #{Settings.aca.shop_market.non_owner_participation_count_minimum} non-owner employee must enroll"
          when "enrollment_ratio"
            unless model_instance.effective_date.yday == 1
              enrollment_errors << "number of eligible participants enrolling (#{model_instance.total_enrolled_count}) is less than minimum required #{model_instance.minimum_enrolled_count}"
            end
          end
        end
        expect(merge_model.plan_year.enrollment_errors).to eq enrollment_errors.join(' AND/OR ')
      end
    end
  end
end