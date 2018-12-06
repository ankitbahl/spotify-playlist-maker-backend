rvm use ruby-2.5.3
bundle
rake db:migrate
export SECRET_KEY_BASE=$(rake secret)
RAILS_ENV=production rails s