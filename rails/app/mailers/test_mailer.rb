class TestMailer < ApplicationMailer
  default from: "no-reply@aujourduy.fr"

  def hello
    mail(
      to: "bonjour.duy@gmail.com",
      subject: "Hello from Postmark (Rails)",
      body: "Bonjour Duy,\n\nce mail vient de Postmark 🚀",
      content_type: "text/plain",
      message_stream: "outbound"
    )
  end
end
