class IvlNotices::EligibilityNoticeBuilder < IvlNotices::NoticeBuilder

  def initialize(hbx_enrollment_id, template_name=nil)
    template_obj = {}
    template_obj[:template] = template_name || "notices/ivl/9c_eligibility_confirmation_notification.html.erb"
    super(PdfTemplates::EligibilityNotice,template_obj)
    @hbx_enrollment_id = hbx_enrollment_id
    build
  end

  def build

    @hbx_enrollment = HbxEnrollment.find(@hbx_enrollment_id)
    @consumer = @hbx_enrollment.subscriber.person
    super
    @family = @consumer.primary_family
    hbx_enrollments = @family.try(:latest_household).try(:hbx_enrollments).active rescue []  
    append_enrollments(hbx_enrollments)
  end
end