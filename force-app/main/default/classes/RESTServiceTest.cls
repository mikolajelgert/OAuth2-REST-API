@IsTest
public with sharing class RESTServiceTest {

    @testSetup
    static void setupTestData() {
        Salesforce_Server__c server = new Salesforce_Server__c(
            Name = 'Salesforce_Server_CAPP',
            Client_Id__c = 'testClientId',
            Client_Secret__c = 'testClientSecret'
        );
        insert server;
    }

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('token')) {
                res.setStatusCode(200);
                res.setBody('{"access_token": "testAccessToken", "instance_url": "https://test.salesforce.com"}');
            } else if (req.getEndpoint().contains('query')) {
                res.setStatusCode(200);
                res.setBody('{"totalSize": 1, "records": [{"Id": "005xx000001SvHjAAK", "Username": "developer@cloobees.com"}]}');
            } else {
                res.setStatusCode(400);
                res.setBody('{"error": "Invalid request"}');
            }
            return res;
        }
    }

    @isTest
    static void testCreateRequest() {
        String method = 'POST';
        String endpoint = 'https://test.salesforce.com';
        String body = '{"key": "value"}';
        String contentType = 'application/json';

        HttpRequest req = RESTService.createRequest(method, endpoint, body, contentType);

        System.assertEquals(method, req.getMethod());
        System.assertEquals(endpoint, req.getEndpoint());
        System.assertEquals(body, req.getBody());
        System.assertEquals(contentType, req.getHeader('Content-Type'));
    }

    @isTest
    static void testRefreshAccessToken() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        RESTService.refreshAccessToken();
        Test.stopTest();

        Salesforce_Server__c server = [SELECT Client_Id__c, Client_Secret__c FROM Salesforce_Server__c WHERE Name = 'Salesforce_Server_CAPP' LIMIT 1];
        HttpRequest req = RESTService.createRequest(
            'POST',
            'callout:' + RESTService.NAMED_CREDENTIAL + RESTService.TOKEN_ENDPOINT_CREDENTIAL,
            'grant_type=password' +
            '&client_id=' + server.Client_Id__c +
            '&client_secret=' + server.Client_Secret__c +
            '&username=' + RESTService.CONTEXT_USERNAME +
            '&password=restAPI1029@',
            'application/x-www-form-urlencoded'
        );
        
        HttpResponse mockResponse = RESTService.sendRequest(req);
        System.assertNotEquals(null, mockResponse, 'Response from refreshAccessToken should not be null');
        System.assertEquals(200, mockResponse.getStatusCode(), 'Status code should be 200 for a successful callout');
        System.assert(mockResponse.getBody().contains('access_token'), 'Response body should contain access_token');
    }

    @isTest
    static void testSendRequest() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        HttpRequest req = RESTService.createRequest(
            'POST',
            'https://test.salesforce.com/services/oauth2/token',
            '{"grant_type": "password"}',
            'application/json'
        );

        Test.startTest();
        HttpResponse resp = RESTService.sendRequest(req);
        Test.stopTest();

        System.assertNotEquals(null, resp, 'Response should not be null');
        System.assertEquals(200, resp.getStatusCode(), 'Status code should be 200');
        System.assert(resp.getBody().contains('"access_token"'), 'Response body should contain access_token');
    }

}