require 'dotenv'
Dotenv.load

require 'pry'

require_relative './lib/config'

# NOTE you can customize the search criteria to include custom fields, saved search, etc
#      to ensure that only a specific subset of invoices are paid automatically

open_invoices = open_invoices_today

if open_invoices.empty?
  puts "no open invoices due today"
  exit
end

open_invoices.each do |ns_invoice|
  charger = CustomerCharger.new(ns_invoice: ns_invoice)

  # NOTE in this example, we simply email the customer for each failure case.
  #      Alternatively (or additionally) you could also update the NetSuite invoice
  #      with information about the error, send a message to your CX team, etc.

  if !charger.has_available_payment_source?
    puts "Customer #{charger.stripe_customer.id} has no payment methods. Sending notice."

    # NOTE in thie case, if there is no payment method available, a notice is sent out the day the invoice is due
    #      this flow can be modified to send a message to users 7 days before the payment is due

    Emailer.send_payment_credentials_notice(charger.stripe_customer, ns_invoice)
  else
    if charger.pay_invoice
      puts "NetSuite Invoice #{ns_invoice.tran_id} (#{ns_invoice.internal_id}) has successfully been paid"
    else
      puts "Failure to charge saved card on customer #{charger.stripe_customer.id}. Sending collection notice."

      Emailer.send_collection_notice(charger.stripe_customer, ns_invoice)
    end
  end
end
