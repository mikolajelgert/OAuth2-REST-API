public with sharing class RESTService {
    private static final String NAMED_CREDENTIAL = 'Salesforce_Server';
    private static final String CONTEXT_USERNAME = 'developer@cloobees.com';
    
    private static HttpRequest createRequest(String method, String endpoint, String body, String contentType) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setHeader('Content-Type', contentType);
        if (body != null) {
            req.setBody(body);
        }
        return req;
    }

    //enable list type on schema settings for custom settings object type
    //insert record with consumer secrets of connected app 
    //all by manual step
    public static HttpResponse getAccessToken() {
        Http http = new Http();
        Salesforce_Server__c server = [SELECT Client_Id__c, Client_Secret__c FROM Salesforce_Server__c WHERE Name = 'Salesforce_Server_CAPP' LIMIT 1];
        String endpoint = 'callout:' + NAMED_CREDENTIAL + '/services/oauth2/token';
        String contentType = 'application/x-www-form-urlencoded';
        String body = 
        'grant_type=password' +
        '&client_id=' + server.Client_Id__c +
        '&client_secret=' + server.Client_Secret__c +
        '&username=' + CONTEXT_USERNAME +
        '&password=restAPI1029@';

        HttpRequest req = createRequest('POST', endpoint, body, contentType);
        HttpResponse resp = http.send(req);
        return resp;
    }
}