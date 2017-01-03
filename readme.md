[![Slack Status](https://opensuite-slackin.herokuapp.com/badge.svg)](http://opensuite-slackin.herokuapp.com)  

# Auto-pay NetSuite Invoices with Stripe

This is an example application that should serve as a starting point for implementing
automatic payment for NetSuite invoices using Stripe. [SuiteSync](http://suitesync.io/) is used to facilitate payment application and reconciliation.

There is more robust version of this application that is hosted and managed as part of the SuiteSync product. This open source implementation is designed for organizations that would like to customize their collection process beyond what the hosted version allows.

Also checkout [this payment form](https://github.com/iloveitaly/netsuite_invoice_payment_with_stripe) if you are looking for a way for customers to pay NetSuite invoices using Stripe.

## Help?

[Join the OpenSuite chat room](http://opensuite-slackin.herokuapp.com/) or reach out to support@suitesync.io.

## Getting Started

```shell
cp .env-example .env
# edit .env with NetSuite, Stripe, and Mailgun credentials

bundle
bundle exec ruby pay.rb
```
