
#
#This method sends an error report to the Team's gmail account from the account etset.error.report1 .
#
def send_email(subject, body)
  Pony.mail(:to => 'etsetpm@gmail.com', :via => :smtp, :via_options => {
  :address => 'smtp.gmail.com',
  :port => '587',
  :enable_starttls_auto => true,
  :user_name => 'etset.error.report1',
  :password => 'cknqwrpwtejeyefu',
  :authentication => :plain, # :plain, :login, :cram_md5, no auth by default
  :domain => 'HELO', # don't know exactly what should be here
  },
  :subject => subject, :body => body)
end
