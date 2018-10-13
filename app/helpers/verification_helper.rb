module VerificationHelper
  include DocumentsVerificationStatus

  def doc_status_label(doc)
    case doc.status
      when "not submitted"
        "warning"
      when "downloaded"
        "default"
      when "verified"
        "success"
      else
        "danger"
    end
  end

  def verification_type_class(status)
    case status
      when "verified"
        "success"
      when "review"
        "warning"
      when "outstanding"
        "danger"
      when "curam"
        "default"
      when "attested"
        "default"
      when "valid"
        "success"
      when "pending"
        "info"
      when "expired"
        "default"
      when "unverified"
        "default"
    end
  end

  def unverified?(person)
    person.consumer_role.aasm_state != "fully_verified"
  end

  def enrollment_group_unverified?(person)
    person.primary_family.contingent_enrolled_active_family_members.flat_map(&:person).flat_map(&:consumer_role).flat_map(&:verification_types).select{|type| type.is_type_outstanding?}.any?
  end

  def verification_needed?(person)
    person.primary_family.active_household.hbx_enrollments.verification_needed.any? if person.try(:primary_family).try(:active_household).try(:hbx_enrollments)
  end

  def has_enrolled_policy?(family_member)
    return true if family_member.blank?
    family_member.family.enrolled_policy(family_member).present?
  end

  def is_not_verified?(family_member, v_type)
    return true if family_member.blank?
    !(["na", "verified", "attested", "expired"].include?(v_type.validation_status))
  end

  def can_show_due_date?(person)
    person.primary_family.contingent_enrolled_active_family_members.flat_map(&:person).flat_map(&:consumer_role).flat_map(&:verification_types).select{|type| VerificationType::DUE_DATE_STATES.include?(type.validation_status)}.any?
  end

  def documents_uploaded
    @person.primary_family.active_family_members.all? { |member| docs_uploaded_for_all_types(member) }
  end

  def member_has_uploaded_docs(member)
    true if member.person.consumer_role.try(:vlp_documents).any? { |doc| doc.identifier }
  end

  def member_has_uploaded_paper_applications(member)
    true if member.person.resident_role.try(:paper_applications).any? { |doc| doc.identifier }
  end

  def docs_uploaded_for_all_types(member)
    member.person.verification_types.all? do |type|
      member.person.consumer_role.vlp_documents.any?{ |doc| doc.identifier && doc.verification_type == type }
    end
  end

  def documents_count(family)
    family.family_members.map(&:person).flat_map(&:consumer_role).flat_map(&:vlp_documents).select{|doc| doc.identifier}.count
  end

  def get_person_v_type_status(people)
    v_type_status_list = []
    people.each do |person|
      person.verification_types.each do |v_type|
        v_type_status_list << verification_type_status(v_type, person)
      end
    end
    v_type_status_list
  end

  def show_send_button_for_consumer?
    current_user.has_consumer_role? && hbx_enrollment_incomplete && documents_uploaded
  end

  def hbx_enrollment_incomplete
    if @person.primary_family.active_household.hbx_enrollments.verification_needed.any?
      @person.primary_family.active_household.hbx_enrollments.verification_needed.first.review_status == "incomplete"
    end
  end

  #use this method to send docs to review for family member level
  def all_docs_rejected(person)
    person.try(:consumer_role).try(:vlp_documents).select{|doc| doc.identifier}.all?{|doc| doc.status == "rejected"}
  end

  def no_enrollments
    @person.primary_family.active_household.hbx_enrollments.empty?
  end

  def enrollment_incomplete
    if @person.primary_family.active_household.hbx_enrollments.verification_needed.any?
      @person.primary_family.active_household.hbx_enrollments.verification_needed.first.review_status == "incomplete"
    end
  end

  def all_family_members_verified
    @family_members.all?{|member| member.person.consumer_role.aasm_state == "fully_verified"}
  end

  def show_doc_status(status)
    ["verified", "rejected"].include?(status)
  end

  def show_v_type(status, admin = nil)
    if status == "curam"
      admin ? "External Source".center(12) : "verified".capitalize.center(12).gsub(' ', '&nbsp;').html_safe
    elsif status
      status = "verified" if status == "valid"
      status.capitalize.center(12).gsub(' ', '&nbsp;').html_safe
    end
  end

  # returns vlp_documents array for verification type
  def documents_list(person, v_type)
    person.consumer_role.vlp_documents.select{|doc| doc.identifier && doc.verification_type == v_type } if person.consumer_role
  end

  def admin_actions(v_type, f_member)
    options_for_select(build_admin_actions_list(v_type, f_member))
  end

  def mod_attr(attr, val)
      attr.to_s + " => " + val.to_s
  end

  def build_admin_actions_list(v_type, f_member)
    if f_member.consumer_role.aasm_state == 'unverified'
      ::VlpDocument::ADMIN_VERIFICATION_ACTIONS.reject{ |el| el == 'Call HUB' }
    elsif verification_type_status(v_type, f_member) == 'outstanding'
      ::VlpDocument::ADMIN_VERIFICATION_ACTIONS.reject{|el| el == "Reject" }
    else
      ::VlpDocument::ADMIN_VERIFICATION_ACTIONS
    end
  end

  def build_reject_reason_list(v_type)
    case v_type
      when "Citizenship"
        ::VlpDocument::CITIZEN_IMMIGR_TYPE_ADD_REASONS + ::VlpDocument::ALL_TYPES_REJECT_REASONS
      when "Immigration status"
        ::VlpDocument::CITIZEN_IMMIGR_TYPE_ADD_REASONS + ::VlpDocument::ALL_TYPES_REJECT_REASONS
      when "Income" #will be implemented later
        ::VlpDocument::INCOME_TYPE_ADD_REASONS + ::VlpDocument::ALL_TYPES_REJECT_REASONS
      else
        ::VlpDocument::ALL_TYPES_REJECT_REASONS
    end
  end

  def type_unverified?(v_type, person)
    !["verified", "valid", "attested"].include?(verification_type_status(v_type, person))
  end

  def request_response_details(person, record, v_type)
    if record.event_request_record_id
      v_type == "DC Residency" ? show_residency_request(person, record) : show_ssa_dhs_request(person, record)
    elsif record.event_response_record_id
      v_type == "DC Residency" ? show_residency_response(person, record) : show_ssa_dhs_response(person, record)
    end
  end

  def show_residency_request(person, record)
    raw_request = person.consumer_role.local_residency_requests.select{
        |request| request.id == BSON::ObjectId.from_string(record.event_request_record_id)
    }
    raw_request.any? ? Nokogiri::XML(raw_request.first.body) : "no request record"
  end

  def show_ssa_dhs_request(person, record)
    requests = person.consumer_role.lawful_presence_determination.ssa_requests + person.consumer_role.lawful_presence_determination.vlp_requests
    raw_request = requests.select{|request| request.id == BSON::ObjectId.from_string(record.event_request_record_id)} if requests.any?
    raw_request.any? ? Nokogiri::XML(raw_request.first.body) : "no request record"
  end

  def show_residency_response(person, record)
    raw_response = person.consumer_role.local_residency_responses.select{
        |response| response.id == BSON::ObjectId.from_string(record.event_response_record_id)
    }
    raw_response.any? ? Nokogiri::XML(raw_response.first.body) : "no response record"
  end

  def show_ssa_dhs_response(person, record)
    responses = person.consumer_role.lawful_presence_determination.ssa_responses + person.consumer_role.lawful_presence_determination.vlp_responses
    raw_request = responses.select{|response| response.id == BSON::ObjectId.from_string(record.event_response_record_id)} if responses.any?
    raw_request.any? ? Nokogiri::XML(raw_request.first.body) : "no response record"
  end

  def has_active_consumer_or_resident_members?(family_members)
    family_members.present? && (family_members.map(&:person).any?(&:is_consumer_role_active?) || family_members.map(&:person).any?(&:is_resident_role_active?))
  end

  def has_active_resident_members?(family_members)
    family_members.present? && family_members.map(&:person).any?(&:is_resident_role_active?)
  end

  def has_active_consumer_dependent?(person,dependent)
    !person.has_active_employee_role? && (dependent.try(:family_member).try(:person).nil? || dependent.try(:family_member).try(:person).is_consumer_role_active?)
  end

  def has_active_resident_dependent?(person,dependent)
    (dependent.try(:family_member).try(:person).nil? || dependent.try(:family_member).try(:person).is_resident_role_active?)
  end
end
