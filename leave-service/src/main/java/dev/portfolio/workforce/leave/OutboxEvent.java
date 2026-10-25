package dev.portfolio.workforce.leave;
import jakarta.persistence.*;
import java.time.Instant;
/** Transactional outbox: the business update and event record commit atomically. */
@Entity @Table(name="outbox_events")
public class OutboxEvent {
    @Id @Column(length=36) public String id;
    @Column(nullable=false) public String eventType;
    @Column(nullable=false,length=3000) public String payload;
    @Column(nullable=false) public Instant createdAt;
    public Instant publishedAt;
    protected OutboxEvent() {}
    public OutboxEvent(String id,String eventType,String payload) {
        this.id=id;this.eventType=eventType;this.payload=payload;this.createdAt=Instant.now();
    }
}
