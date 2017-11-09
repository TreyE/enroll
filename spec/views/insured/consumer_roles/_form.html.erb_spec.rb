require "rails_helper"

RSpec.describe "insured/consumer_roles/_form.html.erb" do
  let(:person) { Person.new }
  let(:current_user) {FactoryBot.create(:user)}

  #before do
    #Translation.create(key: "en.required_field", value: "\"required field\"")
  #end

  before :each do
    helper = Object.new.extend ActionView::Helpers::FormHelper
    helper.extend ActionView::Context
    helper.extend ActionDispatch::Routing::PolymorphicRoutes
    helper.extend ActionView::Helpers::FormOptionsHelper
    person.build_consumer_role if person.consumer_role.blank?
    person.consumer_role.build_nested_models_for_person
    mock_form = ActionView::Helpers::FormBuilder.new(:person, person, helper, {})
    stub_template "shared/_consumer_fields.html.erb" => ''
    sign_in current_user
    allow(view).to receive(:policy_helper).and_return(double("FamilyPolicy", updateable?: true))
    assign(:consumer_role, person.consumer_role)
    assign(:person, person)
    render partial: "insured/consumer_roles/form", locals: {f: mock_form}
  end

  context "render insured consumer role form" do
    let(:person) { Person.new }
    let(:current_user) {FactoryBot.create(:user)}
    before :each do
      helper = Object.new.extend ActionView::Helpers::FormHelper
      helper.extend ActionDispatch::Routing::PolymorphicRoutes
      helper.extend ActionView::Helpers::FormOptionsHelper
      person.build_consumer_role if person.consumer_role.blank?
      person.consumer_role.build_nested_models_for_person
      mock_form = ActionView::Helpers::FormBuilder.new(:person, person, helper, {})
      stub_template "shared/_consumer_fields.html.erb" => ''
      sign_in current_user
      allow(view).to receive(:policy_helper).and_return(double("FamilyPolicy", updateable?: true))
      assign(:consumer_role, person.consumer_role)
      assign(:person, person)
      render partial: "insured/consumer_roles/form", locals: {f: mock_form}
    end

    it "should have title" do
      expect(rendered).to match /Personal Information/
    end

    it "should display hint for asterisks" do
      expect(rendered).to have_selector('p.memo', text: '* = required field')
    end

    it "should display only one no_dc_address" do
      expect(rendered).to have_selector('input#no_dc_address', count: 1)
    end

    it "should display the is_applying_coverage field option" do
      expect(rendered).to match /Is this person applying for coverage?/
    end

    it "should display the affirmative message" do
      expect(rendered).to match /Even if you don’t want health coverage for yourself, providing your SSN can be helpful since it can speed up the application process. We use SSNs to check income and other information to see who’s eligible for help with health coverage costs./
    end
  end


  context "user has an associated e_case_id" do
    let(:person) { FactoryBot.create(:person) }
    let!(:person2) { FactoryBot.create(:person, :with_consumer_role) }
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person2) }
    let(:current_user) {FactoryBot.create(:user, :hbx_staff, person: person)}
    before :each do
      @person = person2
      sign_in current_user
      helper = Object.new.extend ActionView::Helpers::FormHelper
      helper.extend ActionDispatch::Routing::PolymorphicRoutes
      helper.extend ActionView::Helpers::FormOptionsHelper
      @person.build_consumer_role if @person.consumer_role.blank?
      @person.consumer_role.build_nested_models_for_person
      mock_form = ActionView::Helpers::FormBuilder.new(:person, @person, helper, {})
      stub_template "shared/_consumer_fields.html.erb" => ''
      allow(view).to receive(:policy_helper).and_return(double("FamilyPolicy", updateable?: true))
      assign(:consumer_role, @person.consumer_role)
      assign(:person, @person)
      render partial: "insured/consumer_roles/form", locals: {f: mock_form}
    end

    it "should display the label text Application Type" do
      expect(rendered).to match /Application Type :/
    end

    it "should display only 'curam' if user is accociated with e_case_id" do
      expect(rendered).to have_select("person[family][application_type]")
      expect(rendered).to match /Curam/
      expect(rendered).to have_select("person[family][application_type]", :options => ["Curam"])
      expect(rendered).not_to have_select("person[family][application_type]", :options => ["In Person"])
      expect(rendered).not_to have_select("person[family][application_type]", :options => ["Phone"])
    end
  end

  context "user doesn't has an associated e_case_id" do
    let(:person) { FactoryGirl.create(:person) }
    let!(:person2) { FactoryGirl.create(:person, :with_consumer_role) }
    let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person2) }
    let(:current_user) {FactoryGirl.create(:user, :hbx_staff, person: person)}
    before :each do
      @person = person2
      sign_in current_user
      helper = Object.new.extend ActionView::Helpers::FormHelper
      helper.extend ActionDispatch::Routing::PolymorphicRoutes
      helper.extend ActionView::Helpers::FormOptionsHelper
      @person.build_consumer_role if @person.consumer_role.blank?
      @person.consumer_role.build_nested_models_for_person
      mock_form = ActionView::Helpers::FormBuilder.new(:person, @person, helper, {})
      stub_template "shared/_consumer_fields.html.erb" => ''
      allow(view).to receive(:policy_helper).and_return(double("ConsumerRole", can_view_application_types?: true), double("FamilyPolicy", updateable?: true))

      assign(:consumer_role, @person.consumer_role)
      assign(:person, @person)
      allow(person2.primary_family).to receive(:e_case_id).and_return nil
      render partial: "insured/consumer_roles/form", locals: {f: mock_form}
    end

    it "should display all application types options when e_case_id not present" do
      expect(rendered).to have_select("application_type_id")
      #expect(rendered).to have_select("application_type_id", :options => ["choose  *" , "Curam", "In Person","Phone", "Mobile", "Paper"])
      expect(rendered).to have_select("application_type_id", :options => ["choose *", "Phone", "In Person", "Paper", "Curam", "Mobile"])

    end
  end
end
