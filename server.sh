export SECRET_KEY_BASE=$(rake secret)
RAILS_ENV=production rails s