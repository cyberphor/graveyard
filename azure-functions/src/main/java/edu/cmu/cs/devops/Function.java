package edu.cmu.cs.devops;

import com.microsoft.azure.functions.ExecutionContext;
import com.microsoft.azure.functions.HttpMethod;
import com.microsoft.azure.functions.HttpRequestMessage;
import com.microsoft.azure.functions.HttpResponseMessage;
import com.microsoft.azure.functions.HttpStatus;
import com.microsoft.azure.functions.annotation.AuthorizationLevel;
import com.microsoft.azure.functions.annotation.FunctionName;
import com.microsoft.azure.functions.annotation.HttpTrigger;

import java.util.Optional;

// libraries needed for the sortWords method in the Function class
import org.apache.commons.codec.binary.Base64;
import java.util.Arrays;
import java.util.Comparator;

/**
 * Azure Functions with HTTP Trigger.
 */
public class Function {
    /**
     * This method sorts words given in base64. 
     */
    private String sortWords(String base64request) {
        Comparator sorter = new Comparator<String>() {
            @Override
            public int compare(String string1, String string2) {
                return string2.compareToIgnoreCase(string1);
            }
        };
        String request = new String(Base64.decodeBase64(base64request));
        String[] words = request.toString().split(" ");
        Arrays.sort(words, sorter);
        String response = String.join(" ", Arrays.asList(words));
        String base64response = new String(Base64.encodeBase64(response.getBytes()));
        return base64response;
    }

    /**
     * This function listens at endpoint "/api/HttpExample". Two ways to invoke it using "curl" command in bash:
     * 1. curl -d "HTTP Body" {your host}/api/HttpExample
     * 2. curl "{your host}/api/HttpExample?name=HTTP%20Query"
     */
    @FunctionName("HttpExample")
    public HttpResponseMessage run(
            @HttpTrigger(
                name = "req",
                methods = {HttpMethod.GET, HttpMethod.POST},
                authLevel = AuthorizationLevel.ANONYMOUS)
                HttpRequestMessage<Optional<String>> request,
            final ExecutionContext context) {
        context.getLogger().info("Java HTTP trigger processed a request.");

        // Parse query parameter
        final String query = request.getQueryParameters().get("name");
        final String name = request.getBody().orElse(query);

        if (name == null) {
            return request.createResponseBuilder(HttpStatus.BAD_REQUEST).body("Please pass a name on the query string or in the request body").build();
        } else {
            String response = sortWords(name);
            return request.createResponseBuilder(HttpStatus.OK).body(response).build();
        }
    }
}
