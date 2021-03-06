# frozen_string_literal: true

# rails runner script/ivl_tax_cover_letter_notice.rb, Example: rails runner script/ivl_tax_cover_letter_notice.rb -e production
begin
  person = Person.all_consumer_roles.first
  consumer_role = person.consumer_role
  event_name = 'ivl_tax_cover_letter_notice'
  event_kind = ApplicationEventKind.where(event_name: event_name).first
  notice_trigger = event_kind.notice_triggers.first

  # IVL_TAX(new) AQHP and UQHP pdf temaplates(true for AQHP and false for UQHP).
  [true, false].each do |true_or_false|
    builder = notice_trigger.notice_builder.camelize.constantize.new(consumer_role, { template: notice_trigger.notice_template,
                                                                                      subject: event_kind.title,
                                                                                      event_name: event_name,
                                                                                      options: { is_an_aqhp_hbx_enrollment: true_or_false},
                                                                                      mpi_indicator: notice_trigger.mpi_indicator}.merge(notice_trigger.notice_trigger_element_group.notice_peferences))
    builder.deliver
    aqhp_or_uqhp = true_or_false ? 'AQHP' : 'UQHP'
    puts "IVL_TAX #{aqhp_or_uqhp} pdf template(new) generated for person with hbx_id: #{person.hbx_id}, full_name: #{person.full_name}"
  end
rescue StandardError => e
  puts "Error message: #{e.message}, backtrace: #{e.backtrace}"
end
