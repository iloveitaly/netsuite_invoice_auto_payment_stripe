require 'dotenv'
Dotenv.load

require 'pry'

require_relative './lib/config'

# NOTE you can customize the search criteria to include custom fields, saved search, etc
#      to ensure that only a specific subset of invoices are paid automatically

open_invoices_today.each do |ns_invoice|
  ns_invoice.update(due_date: (DateTime.now - 7).iso8601)
end
