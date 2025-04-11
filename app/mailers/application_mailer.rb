class ApplicationMailer < ActionMailer::Base
  default from: ENV["WRESTLINGDEV_EMAIL"] || 'noreply@wrestlingdev.com'
  layout 'mailer'
end
