class CustomerCharger
  attr_reader :stripe_customer,
              :ns_invoice

  def initialize(ns_invoice: nil)
    @ns_invoice = ns_invoice
    @stripe_customer = CustomerLinker.customer_from_invoice(ns_invoice)
  end

  # NOTE it would be possible to pre-authorize the charge up to 7 days before the charge is due
  #      https://support.stripe.com/questions/does-stripe-support-authorize-and-capture

  # NOTE instead of managing payment yourself, SuiteSync can handle this part of the process for you.
  #      Link the invoice to the customer you would like to bill. TODO link

  def pay_invoice
    # NOTE it's best to add the `amount_due` to the invoice form
    #      this method of determine the amount due will report an incorrect amount for foreign currencies
    #      TODO link to netsuite bug ID
    #      https://dashboard.suitesync.io/docs/netsuite-configuration#adding-amount-remaining-to-the-netsuite-invoice-form

    amount_due_string = amount_due_for_invoice(ns_invoice)

    # NOTE you'll need to handle zero decimal currencies here if you collect in multiple currencies
    #      Example: https://gist.github.com/iloveitaly/968ba7dd8b2d2cde7807e86c6ac32ee6

    amount_due = BigDecimal.new(amount_due_string)
    amount_due_in_cents = amount_due * 100.0

    begin
      charge = Stripe::Charge.create(
        amount: amount_due_in_cents,

        # NOTE charges are hardcoded to USD, but the correct currency can be extracted from the Invoice
        currency: 'usd',

        customer: self.stripe_customer.id,
        source: self.payment_source,

        # this description will be added to the memo field of the NetSuite CustomerPayment
        description: "NetSuite Automatic Payment for #{ns_invoice.tran_id}",

        metadata: {
          # this metadata field instructs SuiteSync to create a CustomerPayment and apply it to the associated invoice
          # https://dashboard.suitesync.io/docs/charges#charge-for-a-invoice
          netsuite_invoice_id: self.ns_invoice.internal_id

          # more metadata fields can be added to pass custom data over to the CustomerPayment
        }
      )

      puts "Charge created #{charge.id} for invoice #{ns_invoice.tran_id} (#{ns_invoice.internal_id})"

      true
    rescue Stripe::CardError => e
      update_memo(ns_invoice, "Stripe Payment Error: #{e.message}")

      return false
    end
  end

  # NOTE expired cards are handled automatically by Stripe
  #      https://stripe.com/blog/smarter-saved-cards

  def has_available_payment_source?
    stripe_customer.sources.count > 0
  end

  def payment_source
    # depending on your business logic, you may want to choose a different default payment source
    # payment sources have metadata, so you can store an indication about which payment you'd like
    # to use in the payment metadata

    stripe_customer.default_source
  end

  def update_memo(ns_record, memo)
    if !ns_record.memo.nil? && ns_record.memo.include?(memo)
      log.warn 'skipping memo, already exists', ns_record: ns_record
      return
    end

    NetSuite::Utilities.append_memo(ns_record, memo)

    result = NetSuite::Utilities.backoff { ns_record.update(memo: ns_record.memo) }

    if !result
      fail "failed to update memo #{ns_record.class}##{ns_record.internal_id} #{ns_record.errors}"
    end

    ns_record
  end


  # http://stackoverflow.com/questions/16810211/netsuite-obtaining-invoice-balance
  def amount_due_for_invoice(ns_invoice)
    search = NetSuite::Records::Invoice.search(
      criteria: {
        basic: [
          {
            field: 'type',
            operator: 'anyOf',
            value: %w(_invoice)
          },
          {
            field: 'mainLine',
            value: true
          },
          {
            field: 'internalIdNumber',
            operator: 'equalTo',
            value: ns_invoice.internal_id
          }
        ]
      },

      columns: {
        'tranSales:basic' => {
          'platformCommon:internalId/' => {},
          'platformCommon:amountRemaining' => {}
        }
      }
    )

    if search.results.size > 1
      fail "invoice search on internalId should never return more than a single result"
    end

    search.results.first.attributes[:amount_remaining]
  end
end
