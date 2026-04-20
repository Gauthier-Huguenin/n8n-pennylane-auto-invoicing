# Pennylane VAT Rates Reference

When creating invoices via the API, you need to specify VAT rates using Pennylane's internal codes. These codes are company-specific but follow a standard pattern for French companies.

## Common French VAT rates

| Code | Rate | Description | Use case |
|------|------|-------------|----------|
| `FR_200` | 20% | Standard rate | Most services and goods |
| `FR_100` | 10% | Intermediate rate | Restaurants, transport, home renovation |
| `FR_055` | 5.5% | Reduced rate | Food, books, energy |
| `FR_021` | 2.1% | Super-reduced rate | Medicines, press |
| `exempt` | 0% | Exempt | Intra-EU B2B (reverse charge), exports |

## How to find your exact VAT rate codes

VAT rate codes can vary by company configuration. To list yours:

```bash
curl https://app.pennylane.com/api/external/v2/ledger_accounts \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Look for accounts with VAT-related labels (44571, 44566, etc.) to confirm the available rates in your Pennylane setup.

## Swiss clients (CHF invoicing)

If you invoice Swiss clients, VAT handling depends on your setup:

- **Exempt (export):** Use `exempt` VAT rate
- **Swiss VAT registered:** Consult your accountant for the correct rate codes

## Intra-EU B2B (reverse charge)

For B2B clients in the EU (outside France), use:
- VAT rate: `exempt`
- Add a mention on the invoice: "Reverse charge - Article 283-2 du CGI"

## Important

Always confirm VAT rate codes with your accountant. Incorrect VAT rates will cause accounting discrepancies in Pennylane.
