# Setting up your Pennylane Sandbox

This guide walks you through creating a Pennylane sandbox environment for testing the workflows.

## Prerequisites

- A Pennylane account with **Essentiel** plan or higher
- Administrator or Owner role on the account

## Step 1: Create the sandbox

1. Log in to [app.pennylane.com](https://app.pennylane.com)
2. Click your profile icon (top-right corner)
3. Select **Test environment**
4. Click **Create my sandbox**

You now have a second environment named `Sandbox – your@email.com`.

## Step 2: Configure invoice settings

In the sandbox environment:

1. Go to **Settings > Invoice settings**
2. Fill in:
   - Company name and address
   - Bank account details (use test data)
   - Logo (optional but recommended)
3. Set up sequential invoice numbering (required by French law)

## Step 3: Generate an API token

1. Go to **Settings > Connectivity > Developers**
2. Click **Create a new token**
3. Select the following scopes:
   - `customer_invoices:all`
   - `customers:all`
   - `products:readonly`
   - `ledger_accounts:readonly`
4. Copy the generated token

## Step 4: Verify the token

```bash
curl https://app.pennylane.com/api/external/v2/me \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

Expected response:

```json
{
  "id": "12345",
  "email": "your@email.com",
  "role": "customer"
}
```

## Step 5: Configure n8n credentials

In n8n:

1. Go to **Settings > Credentials**
2. Create a new **HTTP Header Auth** credential:
   - Name: `Pennylane API`
   - Header Name: `Authorization`
   - Header Value: `Bearer YOUR_TOKEN_HERE`

## API base URL

- **Production:** `https://app.pennylane.com/api/external/v2`
- **Sandbox:** Same URL (the token determines the environment)

## Rate limits

- General endpoints: 4 requests/second
- Customer invoice endpoints: 2 requests/second

The workflows include built-in Wait nodes to respect these limits.

## Useful links

- [Pennylane API documentation](https://pennylane.readme.io/)
- [API scopes reference](https://pennylane.readme.io/docs/v2-scopes)
- [2026 API migration guide](https://pennylane.readme.io/docs/2026-api-changes-guide)
- [Pennylane support](https://help.pennylane.com/)
