class ApplicationMailer < ActionMailer::Base
  default from: ENV["WRESTLINGDEV_EMAIL"]
  layout 'mailer'
end
