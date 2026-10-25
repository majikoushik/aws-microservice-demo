package dev.portfolio.workforce.employee;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** No Docker, no real AWS account: local H2 + MockMvc. */
@SpringBootTest @AutoConfigureMockMvc @ActiveProfiles("local")
class EmployeeApiTest {
    @Autowired MockMvc mvc;
    @Test void unauthenticatedRequestsAreDenied() throws Exception {
        mvc.perform(get("/api/employees/1")).andExpect(status().isUnauthorized());
    }
    @Test void employeeSeesOwnRecordButNotColleagues() throws Exception {
        mvc.perform(get("/api/employees/1").header("X-Demo-Role","EMPLOYEE")
            .header("X-Demo-Subject","employee-alice")).andExpect(status().isOk())
            .andExpect(jsonPath("$.name").value("Alice Sharma"));
        mvc.perform(get("/api/employees/2").header("X-Demo-Role","EMPLOYEE")
            .header("X-Demo-Subject","employee-alice")).andExpect(status().isForbidden());
    }
    @Test void onlyHrCanCreateEmployee() throws Exception {
        String data="{\"identitySubject\":\"new-user\",\"name\":\"Demo User\",\"email\":\"new-user@example.test\",\"department\":\"QA\"}";
        mvc.perform(post("/api/employees").contentType(MediaType.APPLICATION_JSON).content(data)
            .header("X-Demo-Role","MANAGER").header("X-Demo-Subject","manager-maria"))
            .andExpect(status().isForbidden());
        mvc.perform(post("/api/employees").contentType(MediaType.APPLICATION_JSON).content(data)
            .header("X-Demo-Role","HR").header("X-Demo-Subject","hr-helen"))
            .andExpect(status().isCreated());
    }
}
