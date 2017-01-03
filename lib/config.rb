require 'netsuite'
require 'stripe'

require_relative './charger'
require_relative './emailer'
require_relative './invoices'
require_relative './linker'

Stripe.api_key = ENV['STRIPE_KEY']

NetSuite.configure do
  reset!

  # NOTE that API versions > 2015_1 require a more complicated authentication setup
  api_version '2015_1'
  read_timeout 60 * 3
  silent ENV['NETSUITE_SILENT'].nil? || ENV['NETSUITE_SILENT'] == 'true'

  email ENV['NETSUITE_EMAIL']
  password ENV['NETSUITE_PASSWORD']
  account ENV['NETSUITE_ACCOUNT']

  wsdl_domain 'webservices.na1.netsuite.com'

  soap_header({
    'platformMsgs:preferences' => {
      'platformMsgs:ignoreReadOnlyFields' => true,
    }
  })
end
