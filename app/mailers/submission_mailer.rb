class SubmissionMailer < ApplicationMailer
  default from: "CHILLFILTR® <info@chillfiltr.com>"

  def confirmation(submission)
    @submission = submission
    mail(
      to: %("#{submission.contact_name}" <#{submission.email}>),
      bcc: "info@chillfiltr.com",
      subject: t("submissions.confirmation_subject")
    )
  end
end
