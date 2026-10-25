import json
import unittest
from handler import handle_record

class FakeTable:
    def __init__(self): self.events = set()
    def put_item(self, Item, ConditionExpression):
        if Item["eventId"] in self.events:
            # Emulate botocore's exception class name without external packages.
            raise type("ConditionalCheckFailedException", (Exception,), {})()
        self.events.add(Item["eventId"])

class HandlerTests(unittest.TestCase):
    def test_duplicate_event_is_idempotent(self):
        table = FakeTable()
        record = {"body": json.dumps({"eventId": "evt-1", "eventType": "LeaveAPPROVED", "leaveId": 1})}
        handle_record(record, table)
        handle_record(record, table)
        self.assertEqual(len(table.events), 1)

if __name__ == "__main__": unittest.main()
