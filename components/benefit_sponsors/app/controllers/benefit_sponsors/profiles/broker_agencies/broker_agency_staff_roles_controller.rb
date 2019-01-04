module BenefitSponsors
  module Profiles
    module BrokerAgencies
      class BrokerAgencyStaffRolesController < ::BenefitSponsors::ApplicationController

        def new
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_new
          respond_to do |format|
            format.html { render 'new', layout: false}
          end
        end

        def create
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_create(staff_params)
          begin
            @status , @result = @staff.save
            unless @status
              flash[:error] = (' Broker Staff Role was not added because '  + @result)
            else
              flash[:notice] = "Broker Staff Role added sucessfully"
            end
          rescue Exception => e
            flash[:error] = e.message
          end
          redirect_to new_profiles_registration_path(profile_type: "broker_agency")
        end

        def search_broker_agency
          @filter_criteria = params.permit(:q)
          results = BenefitSponsors::Organizations::Organization.broker_agencies_with_matching_agency_or_broker(@filter_criteria, params[:broker_registration_page])
          if results.first.is_a?(Person)
            @filtered_broker_roles  = results.map(&:broker_role)
            @broker_agency_profiles = results.map{|broker| broker.broker_role.broker_agency_profile}.uniq
          else
            @broker_agency_profiles = results.map(&:broker_agency_profile).uniq
          end
        end

        private

        def staff_params
          params[:staff].present? ? params[:staff] :  params[:staff] = {}
          params[:staff].merge!(profile_type: params[:profile_type])
          params[:staff].permit!
        end
      end
    end
  end
end



