# n8n-pennylane-auto-invoicing

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![n8n](https://img.shields.io/badge/n8n-1.40%2B-orange)
![Contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen)

Automate customer invoice creation, payment tracking, and overdue reminders using [n8n](https://n8n.io) and the [Pennylane API v2](https://pennylane.readme.io/).

Pennylane is the leading accounting and financial OS for SMEs in France. This workflow bridges the gap between your business tools and your accounting, without manual data entry.

---

## What it does

This project contains **3 n8n workflows** that work together as a billing automation pipeline:

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| **[PENNYLANE] Auto Invoice from Webhook** | Webhook (any CRM or app) | Receives deal/order data, creates or matches a customer in Pennylane, generates a customer invoice with line items and VAT, optionally sends it by email, and notifies your team |
| **[PENNYLANE] Track Payments** | Scheduled (every 15 min) | Polls Pennylane for invoice status changes, classifies invoices as paid, overdue, or upcoming, sends Slack notifications when changes are detected |
| **[PENNYLANE] Overdue Reminder** | Scheduled (daily at 9 AM) | Identifies unpaid invoices past their deadline by 7+ days, sends a detailed Slack reminder with invoice links |

---

## WF1: Create Invoice — Detailed flow

```
WH Receive Invoice Data
  → Code Validate Payload
  → PL Search Customer
  → IF Customer Exists
    → (yes) Set Customer ID
    → (no)  PL Create Customer → Set Customer ID
  → Code Build Invoice Payload
  → PL Create Invoice
  → IF Send Email
    → (yes) Wait PDF Generation → PL Send Invoice Email
  → Code Build Notification
    → SL Send Notification
    → IF Has Notification Email
      → (yes) GM Send Notification
  → Set Output Response
```

## WF2: Track Payments — Detailed flow

```
Schedule Trigger (every 15 min)
  → PL Fetch Invoices
  → Code Filter Status Changes
  → IF Has Updates
    → (yes) Code Build Payment Notification → SL Send Notification
    → (no)  Set Done
```

## WF3: Overdue Reminder — Detailed flow

```
Schedule Trigger (daily at 9 AM)
  → PL Fetch Invoices
  → Code Filter Overdue
  → IF Has Overdue
    → (yes) Code Build Reminder → SL Send Notification
    → (no)  Set Done
```

Each section of every workflow is documented with a colored Sticky Note explaining its purpose, the API endpoints used, and the expected data format.

---

## Node naming conventions

All nodes follow a strict naming convention for readability and maintainability. Each node name starts with a **prefix** identifying the service, followed by a verb and object in English.

| Prefix | Service | Examples |
|--------|---------|----------|
| `WH` | Webhook | WH Receive Invoice Data |
| `PL` | Pennylane | PL Search Customer, PL Create Customer, PL Create Invoice, PL Send Invoice Email, PL Fetch Invoices |
| `SL` | Slack | SL Send Notification |
| `GM` | Gmail | GM Send Notification |
| `IF` | Condition | IF Customer Exists, IF Send Email, IF Has Notification Email, IF Has Updates, IF Has Overdue |
| `Set` | Set node | Set Customer ID, Set Output Response, Set Done |
| `Code` | Code (JavaScript) | Code Validate Payload, Code Build Invoice Payload, Code Build Notification, Code Filter Status Changes, Code Filter Overdue, Code Build Payment Notification, Code Build Reminder |

Code nodes reference other nodes using `$('Node Name')`. All node names are listed in the main Sticky Note of each workflow for quick reference when renaming.

---

## Requirements

- **n8n** (self-hosted or cloud), version 1.40+
- **Pennylane account** with API access (Essentiel plan or higher)
- **Pennylane API token** (Company API token, Bearer auth)
- (Optional) Slack workspace for notifications
- (Optional) Gmail OAuth credentials for email notifications

---

## Quick start

### 1. Get your Pennylane API token

1. Log in to your Pennylane account
2. Go to **Settings > Connectivity > Developers**
3. Create a new API token with the following scopes: `customer_invoices:all`, `customers:all`, `products:readonly`, `ledger_accounts:readonly`
4. Copy and save the token securely

> **Tip:** Use the sandbox environment for testing. Go to your profile (top-right) > Test environment > Create my sandbox. See [`docs/setup-pennylane-sandbox.md`](./docs/setup-pennylane-sandbox.md) for a step-by-step guide.

### 2. Import the workflows

1. Download the workflow JSON files from the [`workflows/`](./workflows/) folder
2. In n8n, go to the menu (three dots) > **Import from File**
3. Import each workflow:
   - `01-create-invoice.json`
   - `02-track-payments.json`
   - `03-overdue-reminder.json`
4. Set up your Pennylane credentials in n8n: create a **Header Auth** credential with name `Authorization` and value `Bearer <YOUR_TOKEN>`

### 3. Configure

After importing, you need to set up credentials for each service used in the workflow:

| Credential | Type | Required |
|------------|------|----------|
| Pennylane API | Header Auth (`Authorization: Bearer <token>`) | Yes |
| Slack | OAuth2 | Optional |
| Gmail | OAuth2 | Optional (WF1 only) |

Configure your Error Workflow in each workflow's settings for production error handling.

### 4. Test

Send a test payload to the webhook URL:

```bash
curl -X POST https://your-n8n-instance.com/webhook/pennylane-invoice \
  -H "Content-Type: application/json" \
  -d '{
    "customer_name": "Acme Corp",
    "customer_email": "billing@acme.com",
    "customer_address": "123 Business St",
    "customer_postal_code": "75001",
    "customer_city": "Paris",
    "customer_country": "FR",
    "items": [
      {
        "label": "AI Automation Consulting - April 2026",
        "quantity": 1,
        "unit_price": 2500,
        "vat_rate": "FR_200"
      }
    ],
    "due_date": "2026-05-07",
    "currency": "EUR",
    "payment_conditions": "30_days",
    "reference": "PROJ-2026-001",
    "send_email": false,
    "notification_email": "your-email@example.com"
  }'
```

---

## Webhook payload reference

### Required fields

| Field | Type | Description |
|-------|------|-------------|
| `customer_name` | string | Customer company name |
| `customer_email` | string | Billing email address |
| `items` | array | Line items (at least one) |
| `items[].label` | string | Description of the product or service |
| `items[].quantity` | number | Quantity (must be > 0) |
| `items[].unit_price` | number | Unit price excl. tax in EUR (must be > 0) |

### Optional fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `items[].vat_rate` | string | `FR_200` | Pennylane VAT rate code |
| `customer_address` | string | `""` | Street address |
| `customer_postal_code` | string | `"00000"` | Postal code (required by Pennylane for customer creation) |
| `customer_city` | string | `"Non renseigné"` | City (required by Pennylane for customer creation) |
| `customer_country` | string | `"FR"` | ISO alpha-2 country code |
| `due_date` | string (YYYY-MM-DD) | +30 days | Invoice due date |
| `currency` | string | `"EUR"` | ISO currency code |
| `payment_conditions` | string | `"30_days"` | Payment terms |
| `reference` | string | — | External reference (e.g., deal ID). Must be unique per invoice |
| `send_email` | boolean | `false` | Send the invoice to the customer via Pennylane email |
| `notification_email` | string | — | Email address to receive an internal HTML notification |

---

## Pennylane API v2 — what we learned building this

This workflow was built and tested against the Pennylane Company API v2 in a sandbox environment. Here are the key things to know:

**Endpoints used:**

| Action | Method | Endpoint |
|--------|--------|----------|
| Search customers | GET | `/customers` |
| Create customer | POST | `/company_customers` (not `/customers`) |
| Create invoice | POST | `/customer_invoices` |
| List invoices | GET | `/customer_invoices` |
| Send invoice by email | POST | `/customer_invoices/{id}/send_by_email` |

**Filtering customers by email:** The filter field is `emails` (plural), and the only allowed operator is `in` (not `eq`). Example: `[{"field":"emails","operator":"in","value":"test@example.com"}]`

**Filtering invoices by status:** The Pennylane API does not support filtering by `status` or `paid` fields. All filtering must be done client-side after fetching invoices. The `draft` field supports filtering but only with string values `"true"` or `"false"` passed through URL encoding.

**Creating a customer:** The `billing_address` object requires `address`, `postal_code`, `city`, and `country_alpha2` (not `country`). All four fields are mandatory.

**Invoice amounts:** The `raw_currency_unit_price` field must be a string (e.g., `"1500.00"`), not a number.

**Invoice numbering:** You must configure sequential invoice numbering in Pennylane settings before creating finalized invoices (`draft: false`). Without it, the API returns a 422 error.

**Sending invoices by email:** The PDF takes a few minutes to generate after invoice creation. The API returns a 409 if you call `/send_by_email` too quickly. The workflow includes a 30-second Wait node to handle this.

**Rate limits:** 4 requests/second for most endpoints, 2/second for customer invoice endpoints.

**External references:** The `external_reference` field must be unique across all invoices. Reusing one returns a 422 error. Finalized invoices with an external reference cannot be deleted via API.

**2026 API migration:** Pennylane is rolling out breaking changes in 2026 (cursor-based pagination, new scopes, deadline July 1st 2026). This workflow is built for the new API behavior. See the [migration guide](https://pennylane.readme.io/docs/2026-api-changes-guide).

---

## CRM integration examples

The webhook accepts a generic JSON payload, so you can connect any CRM or app. Here are common setups:

### Pipedrive

Add a webhook trigger in Pipedrive when a deal moves to "Won". Map the fields:

```json
{
  "customer_name": "{{organization.name}}",
  "customer_email": "{{person.email}}",
  "customer_postal_code": "{{organization.postal_code}}",
  "customer_city": "{{organization.city}}",
  "items": [
    {
      "label": "{{deal.title}}",
      "quantity": 1,
      "unit_price": {{deal.value}}
    }
  ],
  "reference": "pipedrive-{{deal.id}}"
}
```

### Sellsy

Use Sellsy's webhook on "opportunity won" and map to the same payload structure.

### Axonaut

Use Axonaut's Zapier/Make integration or direct API to trigger a webhook call on deal close.

### Manual (curl/Postman)

Use the test command from the Quick Start section above. See the [`examples/`](./examples/) folder for sample payloads.

---

## Repo structure

```
n8n-pennylane-auto-invoicing/
├── README.md
├── LICENSE
├── workflows/
│   ├── 01-create-invoice.json
│   ├── 02-track-payments.json
│   └── 03-overdue-reminder.json
├── examples/
│   ├── payload-simple.json
│   ├── payload-multi-items.json
│   ├── payload-with-address.json
│   └── payload-pipedrive-webhook.json
└── docs/
    ├── setup-pennylane-sandbox.md
    ├── pennylane-vat-rates.md
    └── troubleshooting.md
```

---

## Roadmap

- [x] WF1: Invoice creation from webhook
- [x] WF2: Payment status tracking
- [x] WF3: Overdue reminders
- [ ] Support for credit notes
- [ ] Multi-currency invoicing (CHF, USD)
- [ ] Stripe payment matching (`transaction_reference`)
- [ ] GoCardless payment matching

---

## Contributing

Contributions are welcome. If you use a different CRM or have a specific Pennylane use case, feel free to open an issue or submit a PR with your payload mapping.

---

## License

MIT License. See [LICENSE](./LICENSE).

---

## About

Built by [Gauthier Huguenin](https://hgnn.io), freelance AI automation consultant specializing in n8n, AI agents, and business process automation for SMEs.

- Website: [hgnn.io](https://hgnn.io)
- LinkedIn: [Gauthier Huguenin](https://www.linkedin.com/in/gauthier-huguenin/)