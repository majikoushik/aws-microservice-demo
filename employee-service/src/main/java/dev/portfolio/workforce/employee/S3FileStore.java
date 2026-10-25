package dev.portfolio.workforce.employee;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.time.Duration;

@Component @Profile("aws")
public class S3FileStore implements FileStore {
    private final String bucket;
    private final S3Client s3=S3Client.create();
    private final S3Presigner presigner=S3Presigner.create();
    public S3FileStore(@Value("${app.storage.s3-bucket}") String bucket) { this.bucket=bucket; }
    @Override public void save(String key,InputStream input,long size,String type) throws IOException {
        // The bucket uses Block Public Access; application task role grants scoped PutObject.
        s3.putObject(PutObjectRequest.builder().bucket(bucket).key(key).contentType(type).build(),
            RequestBody.fromInputStream(input,size));
    }
    @Override public URI signedDownload(String key) {
        var req=GetObjectRequest.builder().bucket(bucket).key(key).build();
        return URI.create(presigner.presignGetObject(GetObjectPresignRequest.builder()
            .signatureDuration(Duration.ofMinutes(5)).getObjectRequest(req).build()).url().toString());
    }
}
