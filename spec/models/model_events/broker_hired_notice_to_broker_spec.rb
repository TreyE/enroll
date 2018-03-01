require 'rails_helper'

describe 'ModelEvents::BrokerHiredNoticeToBroker', dbclean: :around_each  do
  let(:model_event)  { "broker_hired_notice_to_broker" }
  let(:notice_event) { "broker_hired_notice_to_broker" }
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
  let!(:broker_agency_profile) { create :broker_agency_profile }
  let!(:broker_agency_account) { create :broker_agency_account,is_active: true, broker_agency_profile: broker_agency_profile }
  let!(:broker) { create :broker, broker_agency_profile: broker_agency_profile  }
  let!(:person){ create :person }
  let!(:model_instance) { create(:employer_profile,legal_name:"ffff",broker_agency_accounts:[broker_agency_account])}
  let(:person){ create :person}
 
  describe "NoticeTrigger" do
    context "when ER successfully hires a broker" do
      subject { Observers::Observer.new }
      it "should trigger notice event" do
        expect(subject).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.person.broker_hired_notice_to_broker"
          expect(payload[:event_object_kind]).to eq 'EmployerProfile'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.trigger_notice(recipient: person, event_object: model_instance, notice_event: "broker_hired_notice_to_broker")
      end
    end
  end

   describe "NoticeBuilder" do

    let(:data_elements) {
      [
          "broker_profile.notice_date",
          "broker_profile.employer_name",
          "broker_profile.first_name",
          "broker_profile.last_name",
          "broker_profile.assignment_date",
          "broker_profile.borker_agency_name",
          "broker_profile.employer_poc_firstname",
          "broker_profile.employer_poc_lastname"
      ]
    }

    let(:recipient) { "Notifier::MergeDataModels::BrokerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "event_object_kind" => "EmployerProfile",
        "event_object_id" => model_instance.id
    } }
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }

    before do
      allow(subject).to receive(:resource).and_return(person)
      allow(subject).to receive(:payload).and_return(payload)
      allow(person).to receive_message_chain('broker_role.broker_agency_profile').and_return(broker_agency_profile)
      allow(Person).to receive(:staff_for_employer).with(model_instance).and_return([person])
    end

    it "should return merge model" do
      expect(merge_model).to be_a(recipient.constantize)
    end

    it "should return notice date" do
      expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end

    it "should return employer name" do
      expect(merge_model.employer_name).to eq model_instance.legal_name
    end

    it "should return broker first and last name " do
      expect(merge_model.first_name).to eq person.first_name
      expect(merge_model.last_name).to eq person.last_name
    end

    it "should return broker assignment date" do
      expect(merge_model.assignment_date).to eq broker_agency_account.start_on
    end

    it "should return employer poc name" do
      expect(merge_model.employer_poc_firstname).to eq model_instance.staff_roles.first.first_name
      expect(merge_model.employer_poc_lastname).to eq model_instance.staff_roles.first.last_name
    end

    it "should return broker agency name " do
      expect(merge_model.borker_agency_name).to eq person.broker_role.broker_agency_profile.legal_name
    end


  end
end