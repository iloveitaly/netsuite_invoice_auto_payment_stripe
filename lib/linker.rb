module CustomerLinker
  extend self

  def customer_from_invoice(ns_invoice)
    ns_customer = NetSuite::Utilities.get_record(
      NetSuite::Records::Customer,
      ns_invoice.entity.internal_id
    )

    retrieve_stripe_customer_from_invoice(ns_customer) ||
      create_stripe_customer_for_invoice(ns_customer)
  end

  def create_stripe_customer_for_invoice(ns_customer)
    stripe_customer = Stripe::Customer.create(
      description: ns_customer.company_name,
      email: ns_customer.email,

      metadata: {
        netsuite_customer_id: ns_customer.internal_id
      }
    )

    # NOTE if externalId is already used by another integration, you can use a custom
    #      field to link the NetSuite Customer to Stripe

    ns_customer.external_id = stripe_customer.id

    if !ns_customer.update
      fail "error linking netsuite customer to stripe"
    end

    stripe_customer
  end

  def retrieve_stripe_customer_from_invoice(ns_customer)
    begin
      Stripe::Customer.retrieve(ns_customer.external_id)
    rescue Stripe::InvalidRequestError => e
      return
    end
  end
end
