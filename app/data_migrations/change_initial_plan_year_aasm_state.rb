require File.join(Rails.root, "lib/mongoid_migration_task")
class ChangeInitialPlanYearAasmState< MongoidMigrationTask

  def migrate
    begin
      organization = Organization.where(fein: ENV['fein']).first
      if organization.present?
        return unless ENV['plan_year_start_on'].present?
        plan_year_start_on = Date.strptime(ENV['plan_year_start_on'].to_s, "%m/%d/%Y")
        plan_year = organization.employer_profile.plan_years.where(:start_on => plan_year_start_on).first

        if plan_year.present?
          if plan_year.canceled?  # for plan year in canceled state
            plan_year.workflow_state_transitions << WorkflowStateTransition.new(
                from_state: plan_year.aasm_state,
                to_state: 'draft'
            )
            plan_year.update_attributes!(aasm_state:'draft')
          end
          plan_year.withdraw_pending! if plan_year.renewing_publish_pending?  # for plan year in publish_pending state
          plan_year.force_publish! if plan_year.may_force_publish?
          puts "Plan year aasm state changed to #{plan_year.aasm_state}" unless Rails.env.test?
        end
      else
        puts "No organization was found by the given fein" unless Rails.env.test?
      end
    rescue Exception => e
      puts e.message
    end
  end
end
