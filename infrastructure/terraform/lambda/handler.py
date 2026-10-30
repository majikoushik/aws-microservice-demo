"""AWS Lambda SQS consumer (Python standard runtime + boto3 included in Lambda).

Why Python instead of another Spring Boot server? It is a teaching example of a
serverless worker that runs only when an event arrives, so we avoid paying for an
always-on notification container. The business-facing services remain Java.

Production note: conditional PutItem before an external effect (e.g. sending an
email) achieves deduplication for this log-only demo, NOT exactly-once delivery.
For real notifications use a durable delivery state/outbox around the side effect.
"""
import json
import logging
import os
import time

log = logging.getLogger(__name__)
log.setLevel(logging.INFO)


def handle_record(record, table):
    payload = json.loads(record["body"])
    event_id = payload["eventId"]
    if not isinstance(event_id, str) or len(event_id) > 64:
        raise ValueError("Bad event ID")
    try:
        # Conditional put is atomic: a repeated SQS delivery cannot be processed twice.
        table.put_item(
            Item={"eventId": event_id, "expiresAt": int(time.time()) + 7 * 24 * 3600},
            ConditionExpression="attribute_not_exists(eventId)",
        )
    except Exception as error:
        # No hard dependency on botocore in local fake-table tests.
        if (error.__class__.__name__ == "ConditionalCheckFailedException" or
                getattr(error, "response", {}).get("Error", {}).get("Code") == "ConditionalCheckFailedException"):
            log.info("Skipping previously processed event: %s", event_id)
            return
        raise
    # Keep payload free of personally identifiable data in these logs.
    log.info("Processed %s, leaveId=%s", payload.get("eventType"), payload.get("leaveId"))


def lambda_handler(event, context):
    # Import only inside AWS entrypoint: students can run unit tests without boto3.
    import boto3
    table = boto3.resource("dynamodb").Table(os.environ["DEDUP_TABLE"])
    failures = []
    for record in event.get("Records", []):
        try:
            handle_record(record, table)
        except Exception:
            log.exception("Failed to process SQS message %s", record["messageId"])
            failures.append({"itemIdentifier": record["messageId"]})
    # Partial batch failure: successful records should NOT be retried.
    return {"batchItemFailures": failures}
