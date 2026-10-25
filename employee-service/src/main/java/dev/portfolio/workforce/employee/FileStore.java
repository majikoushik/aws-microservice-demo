package dev.portfolio.workforce.employee;
import org.springframework.core.io.Resource;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;

/** Filesystem and S3 share an interface; only the implementation changes per profile. */
public interface FileStore {
    void save(String key, InputStream data,long size,String contentType) throws IOException;
    /** S3 returns a temporary URL. Local responds through a protected controller instead. */
    default URI signedDownload(String key) { return null; }
    default Resource localResource(String key) { throw new UnsupportedOperationException("Not local storage"); }
}
