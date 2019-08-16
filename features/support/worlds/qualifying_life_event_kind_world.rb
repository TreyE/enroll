module QualifyingLifeEventKindWorld

  def qualifying_life_event_kind(qle_kind_title = nil, market_kind = 'shop')
    qle_kind = QualifyingLifeEventKind.where(title: qle_kind_title)
    if qle_kind.present?
      return qle_kind.first
    end
    @qle_kind ||= FactoryBot.create(
      :qualifying_life_event_kind,
      title: qle_kind_title.present? ? qle_kind_title : 'Married',
      market_kind: market_kind
    )
  end

  def fill_qle_kind_form_and_submit(action_name, qle_kind_title)
    case action_name
    when 'new'
      form_name = "creation_form"
      button_text = 'Create QLE Kind'
    when 'edit'
      form_name = 'edit_form'
      button_text = 'Update QLE Kind'
    when 'deactivate'
      # TODO: Fill out buttons and text
      form_name = "deactivation_form"
      button_text = nil
    end
    if %w[creation_form edit_form].include?(form_name)
      fill_in("qle_kind_#{form_name}_title", with: qle_kind_title)
      fill_in("qle_kind_#{form_name}_tool_tip", with: "Tool Tip")
      # TODO: Selectric selects are considered not visible
      # However, they are set to `not_applicable` by default, which is valid.
      # remove selectric or find a work around to select them.
      # options = page.all('option')
      # Action kind
      # administrative_action_kind = options.detect { |option| option['ng-reflect-ng-value'] == 'administrative' }
      # administrative_action_kind.click
      # Reason
      # natural_disaster_option = options.detect { |option| option['ng-reflect-ng-value'] == 'exceptional_circumstances_natural_disaster' }
      # natural_disaster_option.click

      # TODO: Add these to the edit form too
      if form_name == 'creation_form'
        click_button('Create a New Question')
        # Question 1
        fill_in('qle_kind_question_0_title', with: "Did you just move to DC?")
        click_button('Add Response')
        fill_in('qle_kind_response_response_0_content', with: 'No')
        select('Declined', from: 'qle_kind_response_response_0_action_to_take')
        click_button('Create a New Question')
        sleep(2)
        buttons = page.all('button')
        add_response_buttons = []
        second_add_response = buttons.each { |button| add_response_buttons << button if button.text == 'Add Response' }
        add_response_buttons.second.click
        # TODO: These need to have the index properly added to them so they have different
        # IDS
        # fill_in('qle_kind_response_response_1_content', with: 'Yes')
        # select('Accepted', from: 'qle_kind_response_response_1_action_to_take')
      end
      # TODO: Consider modifying this step to allow visibility as false
      # Visible to Customer
      choose("qle_kind_#{form_name}_visible_to_customer", option: 'Yes')
      # Note: not using capybara 'choose' here because the 'option' param
      # is for value, but we're using ng-reflect-value
      inputs = page.all('input')
      # TODO: Consider modifying this step to allow different market kinds
      market_kind = 'individual'
      shop_radio = inputs.detect { |input| input["ng-reflect-value"] == market_kind }
      shop_radio.click
      # Self attested
      is_self_attested_radio = inputs.detect do |input|
        input[:id] == "qle_kind_#{form_name}_is_self_attested" && input["ng-reflect-value"] == 'Yes'
      end
      is_self_attested_radio.click
      fill_in("qle_kind_#{form_name}_pre_event_sep_eligibility", with: '10')
      fill_in("qle_kind_#{form_name}_post_event_sep_eligibility", with: '10')
      fill_in("qle_kind_#{form_name}_start_on", with: '10/10/2030')
      fill_in("qle_kind_#{form_name}_end_on", with: '10/20/2040')
      click_button(button_text)
    elsif form_name == 'deactivate'
      # TODO: Fill out deactivate form
      # TODO: Click deactivation button
      fill_in("qle_kind_#{form_name}_end_on", with: '10/10/2030')
    end
  end

  def qle_kind_wizard_selection(action_name)
    case action_name
    when 'Create a Custom QLE'
      choose('qle_wizard_new_qle_selected_radio')
      click_button('Submit')
    when 'Modify Existing QLE, Market Kind, and first QLE Kind'
      choose('qle_wizard_modify_qle_selected_radio')
      choose('qle_wizard_kind_selected_radio_category_shop')
      first_qle_kind = QualifyingLifeEventKind.first
      first_qle_kind_option_value = deactivation_form_exchanges_qle_path(first_qle_kind._id)
      options = page.all('option')
      first_qle_kind_option = options.detect { |option| option[:value] == first_qle_kind_option_value }
      first_qle_kind_option.click
      click_button('Submit')
    when 'Deactivate Active QLE, Market Kind, and first QLE Kind'
      choose('qle_wizard_deactivate_qle_selected_radio')
      click_button('Submit')
    end
  end
end

World(QualifyingLifeEventKindWorld)

Given(/^qualifying life event kind (.*?) present for (.*?) market$/) do |qle_kind_title, market_kind|
  qualifying_life_event_kind(qle_kind_title, market_kind)
end

And(/^all qualifying life event kinds (.*?) to customer$/) do |visible_to_customer|
  case visible_to_customer
  when 'are visible'
    QualifyingLifeEventKind.update_all(visible_to_customer: true)
  when 'are not visible'
    QualifyingLifeEventKind.update_all(visible_to_customer: false)
  end
end

And(/^.+ clicks the Manage QLE link$/) do
  click_link 'Manage QLEs'
end

Then(/^.+ should see the QLE Kind Wizard$/) do
  expect(page.current_path).to eq(manage_exchanges_qles_path)
  expect(page).to have_content("Manage Qualifying Life Events")
end

And(/^.+user visits the new Qualifying Life Event Kind page$/) do
  visit(manage_exchanges_qles_path)
end

And(/^.+ visits the (.*?) Qualifying Life Event Kind page for (.*?) QLE Kind$/) do |action_name, qle_kind_title|
  qle_kind = qualifying_life_event_kind(qle_kind_title)
  case action_name
  when 'deactivate'
    visit(deactivation_form_exchanges_qle_path(qle_kind))
  when 'edit'
    visit(edit_exchanges_qle_path(qle_kind))
  end
end

# TODO: Need to implement reusable step for edit and deactivate
And(/^.+ selects (.*?) and clicks submit$/) do |action_name|
  qle_kind_wizard_selection(action_name)
end

When(/^.+ fills out the (.*?) QLE Kind form for (.*?) event and clicks submit$/) do |action_name, qle_kind_title|
  fill_qle_kind_form_and_submit(action_name, qle_kind_title)
end

Given(/^.+ should see a message that QLE Kind (.*?) has been successfully (.*?) for (.*?)$/) do |qle_kind_title, action_verb|
  binding.pry
end