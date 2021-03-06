require File.join(Rails.root, "app", "data_migrations", "revert_termination_for_employee")
# This rake task is to revert the termination status of census employee
# RAILS_ENV=production bundle exec rake migrations:revert_termination_for_employee census_employee_id=580e456cfaca142b4a00006d enrollment_hbx_id=653416,653415,653433
namespace :migrations do
  desc "revert termination on census employee"
  RevertTerminationForEmployee.define_task :revert_termination_for_employee => :environment
end 
