def open_invoices_today
  # NOTE this example uses a simple invoice search to process all open invoices,
  #      whose due is the current day. This search can easily be modified to reference
  #      a customized saved search, or 

  open_invoice_search = NetSuite::Records::Invoice.search(
  	basic: [
      {
        field: 'type',
        operator: 'anyOf',
        value: %w(_invoice)
      },
      {
        field: 'status',
        operator: 'anyOf',
        value: %w(_invoiceOpen)
      },
      {
        field: 'dueDate',
        operator: 'on',
        value: DateTime.now
      }
    ],

    preferences: {
      body_fields_only: true
    }
  )

  if !open_invoice_search
    fail "error running invoice search"
  end

  open_invoices = []

  open_invoice_search.results_in_batches do |batch|
    batch.each do |ns_invoice|
      open_invoices << ns_invoice
    end
  end

  open_invoices
end
