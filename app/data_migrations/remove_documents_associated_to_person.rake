#RAILS_ENV=production bundle exec rake migrations:remove_documents_associated_to_person hbx_id=1987877 doc_id=13423545757778 titleize=SHOP SEP Denial Notice_Peper 19964520.pdf
require File.join(Rails.root, "app", "data_migrations", "remove_documents_associated_to_person")

namespace :migrations do 
  desc "remove documents associated to person"
  RemoveDocumentsAssociatedToPerson.define_task :add_family_member_to_coverage_household => :environment
end
