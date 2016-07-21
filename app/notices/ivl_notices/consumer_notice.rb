class IvlNotices::ConsumerNotice < IvlNotice

  def initialize(consumer_role, args = {})
    super(args)

    @template = args[:template]
    @delivery_method = args[:delivery_method].split(',')
    @recipient = consumer_role.person
    @secure_message_recipient = consumer_role.person
    @notice = PdfTemplates::ConditionalEligibilityNotice.new
    @market_kind = 'individual'

    # @to = @recipient.home_email.address
    # @email_notice = args[:email_notice] || true
    # @paper_notice = args[:paper_notice] || true
  end

  def build
    @family = @recipient.primary_family    
    @notice.primary_fullname = @recipient.full_name.titleize
    # @notice.primary_identifier = @recipient.hbx_id
    if @recipient.mailing_address
      append_address(@recipient.mailing_address)
    else
      # @notice.primary_address = nil
      raise 'mailing address not present' 
    end

    append_unverified_family_members
  end

  def append_unverified_family_members
    enrollments = @family.enrollments.individual_market.where(:aasm_state.in => ["enrolled_contingent", "unverifeid"]).or({:terminated_on => nil }, {:terminated_on.gt => TimeKeeper.date_of_record})

    # .verification_needed
    # select{|e| e.currently_active? || e.future_active?}
    # Comment this for reminders

    enrollments.each {|e| e.update_attributes(special_verification_period: TimeKeeper.date_of_record + 95.days)}
  
    family_members = enrollments.inject([]) do |family_members, enrollment|
      family_members += enrollment.hbx_enrollment_members.map(&:family_member)
    end.uniq

    people = family_members.map(&:person).uniq

    # Logic to skip people pending SSA validation
    # if people.any?{|p| (p.consumer_role.lawful_presence_determination.vlp_authority == 'dhs' && !p.ssn.blank?) }
    #   raise 'needs ssa validation!'
    # end

    people.reject!{|p| p.consumer_role.aasm_state != 'verification_outstanding'}
    people.reject!{|person| !ssn_outstanding?(person) && !lawful_presence_outstanding?(person) }

    if people.empty?
      raise 'no family member found with outstanding verification'
    end

    outstanding_people = []
    people.each do |person|
      verification_types = person.consumer_role.outstanding_verification_types
      if verification_types.detect{|type| !person.consumer_role.has_docs_for_type?(type) }
        outstanding_people << person
      end
    end
    outstanding_people.uniq!
    
    if outstanding_people.empty?
      raise 'no family member found without uploaded documents'
    end

    if enrollments.map(&:special_verification_period).uniq.size > 1
      raise 'found multiple enrollments with different due dates'
    end

    append_unverified_individuals(outstanding_people)
    @notice.enrollments << enrollments.first

    @notice.due_date = enrollments.first.special_verification_period.strftime("%m/%d/%Y")
  end

  def verification_type_outstanding?(person, verification_type)
    verification_pending = false
    if person.verification_types.include?(verification_type)
      if person.consumer_role.is_type_outstanding?(verification_type)
        verification_pending = true
      end
    end
    verification_pending
  end

  def ssn_outstanding?(person)
    person.consumer_role.ssn_validation == 'outstanding'
  end

  def lawful_presence_outstanding?(person)
    person.consumer_role.lawful_presence_determination.aasm_state == 'verification_outstanding'
  end

  def append_unverified_individuals(people)
    people.each do |person|
      if ssn_outstanding?(person)
        @notice.ssa_unverified << PdfTemplates::Individual.new({ full_name: person.full_name.titleize })
      end

      if lawful_presence_outstanding?(person)
        @notice.dhs_unverified << PdfTemplates::Individual.new({ full_name: person.full_name.titleize })
      end
    end
  end

  def append_address(primary_address)
    @notice.primary_address = PdfTemplates::NoticeAddress.new({
      street_1: capitalize_quadrant(primary_address.address_1.to_s.titleize),
      street_2: capitalize_quadrant(primary_address.address_2.to_s.titleize),
      city: primary_address.city.titleize,
      state: primary_address.state,
      zip: primary_address.zip
      })
  end

  def capitalize_quadrant(address_line)
    address_line.split(/\s/).map do |x| 
      x.strip.match(/^NW$|^NE$|^SE$|^SW$/i).present? ? x.strip.upcase : x.strip
    end.join(' ')
  end

  def to_csv
    [
      @recipient.hbx_id,
      @recipient.first_name,
      @recipient.last_name,
      @notice.primary_address.present? ? @notice.primary_address.attributes.values.reject{|x| x.blank?}.compact.join(',') : "",
      @notice.due_date,
      (@notice.enrollments.first.submitted_at || @notice.enrollments.first.created_at),
      @notice.enrollments.first.effective_on,
      @notice.ssa_unverified.map{|individual| individual.full_name }.join(','),
      @notice.dhs_unverified.map{|individual| individual.full_name }.join(','),
      @secure_message_recipient.consumer_role.contact_method,
      @secure_message_recipient.home_email.try(:address) || @secure_message_recipient.user.try(:email)
    ]
  end
end 