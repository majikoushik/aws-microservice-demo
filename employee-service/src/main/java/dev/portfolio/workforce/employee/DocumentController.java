package dev.portfolio.workforce.employee;

import org.springframework.core.io.Resource;
import org.springframework.http.*;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import java.io.IOException;
import java.util.*;

@RestController @RequestMapping("/api/employees/{employeeId}/documents")
public class DocumentController {
    private final EmployeeService employees;
    private final DocumentRepository documents;
    private final FileStore files;
    public DocumentController(EmployeeService employees,DocumentRepository documents,FileStore files) {
        this.employees=employees;this.documents=documents;this.files=files;
    }
    public record DocumentView(Long id,String filename,String contentType,long sizeBytes) {
        static DocumentView from(DocumentMetadata d) { return new DocumentView(d.id,d.originalFilename,d.contentType,d.sizeBytes); }
    }
    public record Download(String url,int validMinutes) {}

    @GetMapping public List<DocumentView> list(@PathVariable Long employeeId) {
        employees.getAuthorizedEntity(employeeId);
        return documents.findByEmployeeIdOrderByIdDesc(employeeId).stream().map(DocumentView::from).toList();
    }
    @PostMapping(consumes=MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    public DocumentView upload(@PathVariable Long employeeId,@RequestParam("file") MultipartFile file) throws IOException {
        employees.getAuthorizedEntity(employeeId);
        Set<String> allowed=Set.of("application/pdf","image/jpeg","image/png");
        String contentType=file.getContentType();
        if (file.isEmpty() || file.getSize()>5*1024*1024 || !allowed.contains(contentType))
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,"Upload nonempty PDF/JPEG/PNG up to 5 MB");
        // Randomized keys avoid untrusted filenames being interpreted as filesystem paths.
        String key="employees/"+employeeId+"/"+UUID.randomUUID();
        files.save(key,file.getInputStream(),file.getSize(),contentType);
        String original=Optional.ofNullable(file.getOriginalFilename()).orElse("upload").replaceAll("[\r\n\t]","_");
        return DocumentView.from(documents.save(new DocumentMetadata(employeeId,original,key,contentType,file.getSize())));
    }
    /** AWS: return short-lived presigned URL. Local: stream through authorization-protected endpoint. */
    @GetMapping("/{docId}/download")
    public Object download(@PathVariable Long employeeId,@PathVariable Long docId) {
        DocumentMetadata d=authorized(employeeId,docId);
        java.net.URI signed = files.signedDownload(d.storageKey);
        if (signed != null) return new Download(signed.toString(),5);
        return new Download("/api/employees/"+employeeId+"/documents/"+docId+"/content",0);
    }
    @GetMapping("/{docId}/content")
    public ResponseEntity<Resource> localContent(@PathVariable Long employeeId,@PathVariable Long docId) {
        DocumentMetadata d=authorized(employeeId,docId);
        if (files.signedDownload(d.storageKey)!=null)
            throw new ResponseStatusException(HttpStatus.NOT_FOUND,"Use the signed download URL");
        return ResponseEntity.ok().contentType(MediaType.parseMediaType(d.contentType))
            .header(HttpHeaders.CONTENT_DISPOSITION,"attachment; filename=download")
            .body(files.localResource(d.storageKey));
    }
    private DocumentMetadata authorized(Long employeeId,Long docId) {
        employees.getAuthorizedEntity(employeeId);
        DocumentMetadata d=documents.findById(docId).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,"Document missing"));
        if (!d.employeeId.equals(employeeId)) throw new ResponseStatusException(HttpStatus.NOT_FOUND,"Document missing");
        return d;
    }
}
