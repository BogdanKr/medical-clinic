/**
 * Created by Bogdan_Krasun on 20.12.2022.
 */

public with sharing class ChainingAsynchronousCallouts {

    // Unique label for the initial callout request
    public String requestLabel1;
    // Unique label for the chained callout request
    public String requestLabel2;
    // Result of initial callout
    public static String result1 { get; set; }
    // Result of chained callout
    public static HttpResponse result2 { get; set; }
    // Endpoint of long-running service
    public static String LONG_RUNNING_SERVICE_URL1 ;
    public static String LONG_RUNNING_SERVICE_URL2 ;
    public static String DOC_EMAIL ;

    public Object invokeInitialRequest() {
        // Create continuation with a timeout
        Continuation con = new Continuation(60);
        // Set callback method
        con.continuationMethod = 'processInitialResponse';

        // Create first callout request
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(LONG_RUNNING_SERVICE_URL1);
        req.setHeader('content-type', 'application/x-www-form-urlencoded');
        GoogleAuthSetting__mdt docAuthData = GoogleAuthService.getDocAuthMetadata(DOC_EMAIL);
        String messageBody = 'client_id=' + docAuthData.Client_Id__c +
                '&client_secret=' + docAuthData.Client_Secret__c +
                '&refresh_token=' + docAuthData.RefreshToken__c +
                '&grant_type=refresh_token';
        req.setHeader('Content-length', String.valueOf(messageBody.length()));
        req.setBody(messageBody);
//        req.setTimeout(60 * 1000);
        System.debug('messageBody:' + messageBody);

        // Add initial callout request to continuation
        this.requestLabel1 = con.addHttpRequest(req);

        // Return the continuation
        return con;
    }

    // Callback method for initial request
    public Object processInitialResponse() {
        // Get the response by using the unique label
        HttpResponse response = Continuation.getResponse(this.requestLabel1);
        // Set the result variable that is displayed on the Visualforce page
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody()) ;
        String accessToken = String.valueOf(responseMap.get('access_token'));
        result1 = accessToken;

        Continuation chainedContinuation = null;
        // Chain continuation if some condition is met
        if (response.getStatusCode() == 200) {
            // Create a second continuation
            chainedContinuation = new Continuation(60);
            // Set callback method
            chainedContinuation.continuationMethod = 'processChainedResponse';

            // Create callout request
            HttpRequest req = new HttpRequest();
            req.setMethod('GET');
            req.setEndpoint(LONG_RUNNING_SERVICE_URL2);
            Http http = new Http();
            req.setHeader('content-type', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + result1);

            // Add callout request to continuation
            this.requestLabel2 = chainedContinuation.addHttpRequest(req);
        }

        // Start another continuation
        return chainedContinuation;
    }

    // Callback method for chained request
    public Object processChainedResponse() {
        // Get the response for the chained request
        HttpResponse response = Continuation.getResponse(this.requestLabel2);
        // Set the result variable that is displayed on the Visualforce page
        result2 = response;

        // Return null to re-render the original Visualforce page
        return null;
    }
}