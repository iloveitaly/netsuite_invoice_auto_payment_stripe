module Emailer
  extend self

  def send_payment_credentials_notice(stripe_customer, ns_invoice)
    collection_link = payment_web_link(stripe_customer, ns_invoice)

    send_email(
      to: stripe_customer.email,
      subject: "Update your payment credentials",
      body: <<EOL
Hello #{stripe_customer.description},

There is not a valid payment method on file to pay an invoice that is due.

Please update your payment method:

#{collection_link}

Contact us at support@suitesync.io or (415) 523-0948 with any questions.

Thanks

SuiteSync Collection Team
EOL
    )
  end

  def send_collection_notice(stripe_customer, ns_invoice)
    collection_link = payment_web_link(stripe_customer, ns_invoice)

    send_email(
      to: stripe_customer.email,
      subject: "Payment Failure for SuiteSync Invoice #{ns_invoice.tran_id}",
      body: <<EOL
Hello #{stripe_customer.description},

We tried to charge the payment method on file, but the charge failed.

You can pay off your invoice that is due using the following link:

#{collection_link}

When you pay this invoice, your payment method will automatically be updated.

Contact us at support@suitesync.io or (415) 523-0948 with any questions.

Thanks

SuiteSync Collection Team
EOL
    )
  end

  def send_email(to:, subject:, body:)
    response = RestClient.post(ENV['MAILGUN_ENDPOINT'],
      :from => 'support@suitesync.io',
      :to => 'mike@suitesync.io' || to,
      :subject => subject,
      :text => body
    )

    if response.code != 200
      fail "error sending email"
    end
  end

  def payment_web_link(stripe_customer, ns_invoice)
    # NOTE SuiteSync provides a hosted payment form for NetSuite Invoices
    #      You can use this payment form, or link directly to your own web portal for payment
    #
    #      A simplified open source version of the web payment form is available here:
    #      https://github.com/iloveitaly/netsuite_invoice_payment_with_stripe
    #
    #      Learn more about the hosted payment form here:
    #      https://dashboard.suitesync.io/docs/b2b-payments

    stripe_account = Stripe::Account.retrieve

    "https://dashboard.suitesync.io/payments/#{stripe_account.id}/#{ns_invoice.internal_id}"
  end
end
