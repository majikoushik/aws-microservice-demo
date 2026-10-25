package dev.portfolio.workforce.leave;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.SendMessageRequest;

/** Allows local learning with no AWS credentials, yet uses real SQS in AWS. */
interface EventTransport { void publish(String json); }
@Component @Profile("local")
class LocalEventTransport implements EventTransport {
    private static final Logger log=LoggerFactory.getLogger(LocalEventTransport.class);
    @Override public void publish(String json) { log.info("LOCAL notification event (simulated SQS): {}",json); }
}
@Component @Profile("aws")
class SqsEventTransport implements EventTransport {
    private final SqsClient client=SqsClient.create();
    private final String queueUrl;
    SqsEventTransport(@Value("${app.notifications.queue-url}") String queueUrl) {this.queueUrl=queueUrl;}
    @Override public void publish(String json) {
        client.sendMessage(SendMessageRequest.builder().queueUrl(queueUrl).messageBody(json).build());
    }
}
@Component
class OutboxPublisher {
    private static final Logger log=LoggerFactory.getLogger(OutboxPublisher.class);
    private final OutboxRepository events;
    private final EventTransport transport;
    OutboxPublisher(OutboxRepository events,EventTransport transport) {this.events=events;this.transport=transport;}
    // Simple teaching implementation: suitable for ONE leave task/instance.
    // For >1 instances use row claims / SELECT FOR UPDATE SKIP LOCKED or distributed coordination.
    @Scheduled(fixedDelayString="${app.outbox.poll-ms:5000}")
    @Transactional
    public void publishPending() {
        for (OutboxEvent e:events.findTop20ByPublishedAtIsNullOrderByCreatedAtAsc()) {
            try {
                transport.publish(e.payload);
                e.publishedAt=java.time.Instant.now();
                events.save(e);
            } catch (Exception ex) {
                log.warn("Event delivery failed; outbox will retry event {}: {}",e.id,ex.getMessage());
                // Crucially, we don't mark the event delivered on failure.
                break;
            }
        }
    }
}
