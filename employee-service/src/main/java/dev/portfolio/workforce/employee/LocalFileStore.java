package dev.portfolio.workforce.employee;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Component;
import java.io.*;
import java.nio.file.*;

@Component @Profile("local")
public class LocalFileStore implements FileStore {
    private final Path root;
    public LocalFileStore(@Value("${app.storage.local-dir:local-uploads}") String folder) throws IOException {
        root=Paths.get(folder).toAbsolutePath().normalize();Files.createDirectories(root);
    }
    @Override public void save(String key, InputStream data,long size,String type) throws IOException {
        Path target=resolved(key);
        Files.copy(data,target,StandardCopyOption.REPLACE_EXISTING);
    }
    @Override public Resource localResource(String key) {
        try { return new UrlResource(resolved(key).toUri()); }
        catch(IOException e) { throw new UncheckedIOException(e); }
    }
    /** Defends against ../ traversal even if the key was corrupted. */
    private Path resolved(String key) throws IOException {
        Path target=root.resolve(key).normalize();
        if (!target.startsWith(root)) throw new IOException("Invalid document key");
        return target;
    }
}
