# Troubleshooting

Common issues and how to fix them.

## Authentication errors

### `401 Unauthorized`

- Check that your token is valid and not expired
- Make sure the Authorization header format is exactly: `Bearer <token>` (with space)
- Verify you're using the right environment (sandbox vs production)

### `403 Forbidden`

- Your token is missing required scopes. Regenerate it with all required scopes (see README)
- Your Pennylane plan may not include API access (Essentiel plan minimum)

## Invoice creation errors

### `422 Unprocessable Entity`

Common causes:
- **Missing customer:** The `customer_id` doesn't exist. Check WF1's customer search/create logic
- **Invalid VAT rate:** The VAT rate code doesn't match your Pennylane configuration. See `docs/pennylane-vat-rates.md`
- **Missing invoice numbering:** Configure sequential numbering in Pennylane settings
- **Missing company info:** Fill in your company address and bank details in Pennylane

### `429 Too Many Requests`

You're hitting the rate limit (4 req/s general, 2 req/s for invoices). The workflows include Wait nodes to handle this, but if you're running multiple instances or testing rapidly, you may hit limits. Wait a few seconds and retry.

## Payment tracking issues

### WF2 not detecting paid invoices

- Check the cron schedule (default: every 15 minutes)
- Verify that the `last_checked` timestamp is being updated correctly
- Make sure the token has `customer_invoices:all` scope

### Overdue invoices not triggering reminders

- Check `OVERDUE_THRESHOLD_DAYS` configuration
- Verify that the invoice `due_date` is set correctly
- Check that the invoice status is still `unpaid` in Pennylane

## Notification issues

### Slack notifications not sending

- Verify your Slack credentials in n8n
- Check that the Slack channel exists and the bot has permissions
- Test the Slack node independently with a simple message

### Email notifications not sending

- Check SMTP credentials (host, port, auth)
- Verify the recipient email address
- Check n8n execution logs for SMTP errors

## General debugging

1. **Check n8n execution logs:** Each workflow execution shows input/output for every node
2. **Test with Postman:** Call the Pennylane API directly to isolate whether the issue is in n8n or the API
3. **Use the sandbox:** Always test changes in sandbox before production
4. **Check Pennylane status:** Visit [status.pennylane.com](https://status.pennylane.com) for service availability

## Getting help

- Open an issue on this repository
- Check [Pennylane API documentation](https://pennylane.readme.io/)
- Join the [n8n community forum](https://community.n8n.io/)
