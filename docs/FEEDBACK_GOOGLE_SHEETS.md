# Google Sheets Feedback Sink

`preflight_v2` can forward optional operator feedback and bug reports to a Google Sheets sheet through a Google Apps Script web app.

## Helm values

Set these values on the preflight release:

```yaml
app:
  feedback:
    webhookUrl: "https://script.google.com/macros/s/REPLACE_WITH_DEPLOYED_WEBAPP_ID/exec"
    webhookSharedSecret: "replace-with-random-secret"
    webhookBearerToken: ""
    webhookTimeoutMs: 8000
```

Notes:
- `webhookUrl` is the deployed Apps Script web app URL.
- `webhookSharedSecret` is recommended for Apps Script because the receiver can validate it directly from the JSON body.
- `webhookBearerToken` is optional and usually not needed for Apps Script.

## Payload shape

The preflight server sends JSON like this:

```json
{
  "source": "glassbox-preflight",
  "namespace": "default",
  "appFullname": "molecular-audit-core-1",
  "sharedSecret": "replace-with-random-secret",
  "record": {
    "id": "uuid",
    "kind": "feedback",
    "createdAt": "2026-03-17T11:21:43.417Z",
    "title": "Short subject",
    "message": "Operator note body",
    "email": "user@example.com",
    "context": {
      "runId": "...",
      "projectId": "...",
      "activeTab": "preflight"
    },
    "client": {
      "origin": "...",
      "referer": "...",
      "userAgent": "..."
    }
  }
}
```

## Apps Script receiver

Create a Google Sheet with a tab named `Feedback`, then attach this Apps Script and deploy it as a Web App.

```javascript
function doPost(e) {
  const payload = JSON.parse(e.postData.contents || "{}");
  const expectedSecret = PropertiesService.getScriptProperties().getProperty("GBX_SHARED_SECRET");
  if (expectedSecret && payload.sharedSecret !== expectedSecret) {
    return jsonResponse({ ok: false, error: "unauthorized" }, 401);
  }

  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName("Feedback");
  if (!sheet) {
    throw new Error("Missing Feedback sheet");
  }

  const record = payload.record || {};
  const context = record.context || {};
  const client = record.client || {};

  sheet.appendRow([
    new Date(),
    payload.source || "",
    payload.namespace || "",
    payload.appFullname || "",
    record.id || "",
    record.kind || "",
    record.createdAt || "",
    record.title || "",
    record.email || "",
    record.message || "",
    context.runId || "",
    context.projectId || "",
    context.activeTab || "",
    context.preflightView || "",
    context.reportsView || "",
    context.namespace || "",
    context.overallStatus || "",
    context.filesValidated || "",
    client.origin || "",
    client.referer || "",
    client.userAgent || "",
  ]);

  return jsonResponse({ ok: true });
}

function jsonResponse(body, status) {
  return ContentService
    .createTextOutput(JSON.stringify(body))
    .setMimeType(ContentService.MimeType.JSON);
}
```

## Recommended sheet columns

Use these headers in row 1:

`received_at, source, namespace, app_fullname, id, kind, created_at, title, email, message, run_id, project_id, active_tab, preflight_view, reports_view, context_namespace, overall_status, files_validated, origin, referer, user_agent`

A ready-to-import header-only CSV template is included beside this doc:

- `preflight_v2/docs/docs/feedback_sheet_template.csv`

## Deploy

1. Set script property `GBX_SHARED_SECRET` to the same value as `app.feedback.webhookSharedSecret`.
2. Deploy the script as a Web App.
3. Put the Web App URL into `app.feedback.webhookUrl`.
4. Upgrade the preflight Helm release.

If the webhook is configured and forwarding fails, preflight still stores the note locally but returns an explicit delivery error instead of claiming it was sent.
