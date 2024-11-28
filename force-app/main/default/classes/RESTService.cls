public with sharing class RESTService {
    public static final String NAMED_CREDENTIAL = 'Salesforce_Server';
    private static final String CONTEXT_USERNAME = 'developer@cloobees.com';
    public static final String TOKEN_ENDPOINT_CREDENTIAL = '/services/oauth2/token';
    public static final String CREATE_USER_ENDPOINT = '/services/data/v58.0/sobjects/User';
    public static final String GET_USER_ENDPOINT_SOQL = '/services/data/v58.0/query/?q=';
    
    public static HttpRequest createRequest(String method, String endpoint, String body, String contentType) {
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
    public static void refreshAccessToken() {
        Http http = new Http();
        Salesforce_Server__c server = [SELECT Client_Id__c, Client_Secret__c FROM Salesforce_Server__c WHERE Name = 'Salesforce_Server_CAPP' LIMIT 1];
        String endpoint = 'callout:' + NAMED_CREDENTIAL + TOKEN_ENDPOINT_CREDENTIAL;
        String contentType = 'application/x-www-form-urlencoded';
        String body = 
        'grant_type=password' +
        '&client_id=' + server.Client_Id__c +
        '&client_secret=' + server.Client_Secret__c +
        '&username=' + CONTEXT_USERNAME +
        '&password=restAPI1029@';

        HttpRequest req = createRequest('POST', endpoint, body, contentType);
        sendRequest(req);
    }

    public static HttpResponse sendRequest(HttpRequest request) {
        Http http = new Http();
        HttpResponse resp;
        try {
            resp = http.send(request);
        }catch(Exception ex) {
            System.debug(ex.getMessage());
        }
        return resp;
    }
}