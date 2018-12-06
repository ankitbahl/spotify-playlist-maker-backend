rvm use ruby-2.5.3
bundle
rake db:migrate RAILS_ENV=production
export SECRET_KEY_BASE=$(rake secret)
RAILS_ENV=production rails s