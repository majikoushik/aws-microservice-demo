package dev.portfolio.workforce.leave;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import java.time.LocalDate;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** Isolate the HTTP integration with employee service without mocking the leave database. */
@SpringBootTest @AutoConfigureMockMvc @ActiveProfiles("local")
class LeaveApiTest {
    @Autowired MockMvc mvc;
    @MockitoBean EmployeeDirectoryClient employeeClient;
    @Test void approvalCannotBeRepeatedAndBalanceIsUpdatedOnce() throws Exception {
        when(employeeClient.lookup(eq(1L))).thenReturn(new EmployeeDirectoryClient.EmployeeSnapshot(
            1L,"employee-alice","Alice","alice@example.test","Engineering","manager-maria"));
        LocalDate start=LocalDate.now().plusDays(5);
        String body="{\"employeeId\":1,\"startDate\":\""+start+"\",\"endDate\":\""+start.plusDays(2)+"\"}";
        String result=mvc.perform(post("/api/leaves").contentType(MediaType.APPLICATION_JSON).content(body)
            .header("X-Demo-Role","EMPLOYEE").header("X-Demo-Subject","employee-alice"))
            .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        Long leaveId=new com.fasterxml.jackson.databind.ObjectMapper().readTree(result).path("id").asLong();
        mvc.perform(post("/api/leaves/"+leaveId+"/approve").contentType(MediaType.APPLICATION_JSON).content("{}")
            .header("X-Demo-Role","MANAGER").header("X-Demo-Subject","manager-maria"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.status").value("APPROVED"));
        mvc.perform(post("/api/leaves/"+leaveId+"/approve").contentType(MediaType.APPLICATION_JSON).content("{}")
            .header("X-Demo-Role","MANAGER").header("X-Demo-Subject","manager-maria"))
            .andExpect(status().isConflict());
        mvc.perform(get("/api/leaves/employee/1/balance")
            .header("X-Demo-Role","EMPLOYEE").header("X-Demo-Subject","employee-alice"))
            .andExpect(jsonPath("$.remainingDays").value(17));
    }
}
