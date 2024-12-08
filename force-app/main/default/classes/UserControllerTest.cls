@IsTest
public with sharing class UserControllerTest {
    
    @testSetup
    static void setupTestData() {

        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Chatter External User' LIMIT 1];
        
        Salesforce_Server__c server = new Salesforce_Server__c(
            Name = 'Salesforce_Server_CAPP',
            Client_Id__c = 'testClientId',
            Client_Secret__c = 'testClientSecret'
        );
        insert server;

        insert new User(
            Username = 'oauthresttest@gmail.com',
            LastName = 'TestUser',
            Email = 'testuser@test.com',
            Alias = 'test',
            LanguageLocaleKey = 'en_US',
            TimeZoneSidKey = 'GMT',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US',
            ProfileId = testProfile.Id
        );
    }

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('query')) {
                res.setStatusCode(200);
                res.setBody('{"totalSize": 1, "records": [{"Id": "005xx000001SvHjAAK", "Username": "username"}]}');
            } else if (req.getEndpoint().contains('token')) {
                res.setStatusCode(200);
                res.setBody('{"access_token": "mockAccessToken"}');
            } else if (req.getEndpoint().contains('User')) {
                res.setStatusCode(200);
                res.setBody('{"id": "005xx000001SvHjAAK"}');
            } else {
                res.setStatusCode(400);
                res.setBody('{"error": "Invalid Request"}');
            }
            return res;
        }
    }

    @isTest
    static void testCreateUserData() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Map<String, Object> userData = new Map<String, Object>{
            'username' => 'newuser@test.com',
            'email' => 'newuser@test.com',
            'alias' => 'newuser'
        };

        Test.startTest();
        Boolean result = UserController.createUserData(userData);
        Test.stopTest();

        System.assertEquals(true, result, 'User creation should return true');
    }

    @isTest
    static void testCreateUserREST() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        List<String> data = new List<String>{'newuser@test.com', 'newuser@test.com', 'alias'};
        
        Test.startTest();
        UserController.createUserREST(data);
        Test.stopTest();
    
        String expectedEndpoint = 'callout:' + RESTService.NAMED_CREDENTIAL + RESTService.CREATE_USER_ENDPOINT;
        Map<String, Object> expectedBody = new Map<String, Object>{
            'Username' => 'newuser@test.com',
            'LastName' => 'newuser@test.com',
            'Email' => 'newuser@test.com',
            'Alias' => 'alias',
            'LanguageLocaleKey' => 'en_US',
            'TimeZoneSidKey' => 'GMT',
            'EmailEncodingKey' => 'UTF-8',
            'LocaleSidKey' => 'en_US'
        };
    
        Profile chatterProfile = [SELECT Id FROM Profile WHERE Name = 'Chatter External User' LIMIT 1];
        expectedBody.put('ProfileId', chatterProfile.Id);
    
        HttpRequest req = RESTService.createRequest(
            'POST',
            expectedEndpoint,
            JSON.serialize(expectedBody),
            'application/json'
        );
        HttpResponse response = RESTService.sendRequest(req);
    
        System.assertEquals(200, response.getStatusCode(), 'The HTTP status code should be 200 for a successful callout.');
        System.assert(response.getBody().contains('"id"'), 'Response body should contain user creation success with an ID.');
    }

    @isTest
    static void testSetUserPassword() {
        String username = 'oauthresttest@gmail.com';
        String password = 'newPassword123';

        Test.startTest();
        Boolean result = UserController.setUserPassword(username, password);
        Test.stopTest();

        System.assertEquals(true, result, 'Password should be set successfully');
    }

    @isTest
    static void testCheckUsername() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        String username = 'testuser@test.com';

        Test.startTest();
        String response = UserController.checkUsername(username);
        Test.stopTest();

        System.assert(response.contains('"totalSize": 1'), 'Response should indicate a record is found');
    }

    @isTest
    static void testCheckPassword() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        String username = 'oauthresttest@gmail.com';
        String password = 'testPassword123';

        Test.startTest();
        String response = UserController.checkPassword(username, password);
        Test.stopTest();

        System.assert(response.contains('"access_token": "mockAccessToken"'), 'Response should contain access token');
    }

    @isTest
    static void testGetLastUsers() {
        Test.startTest();
        List<User> users = UserController.getLastUsers();
        Test.stopTest();

        System.assertNotEquals(0, users.size(), 'There should be at least one user');
        System.assertEquals('oauthresttest@gmail.com', users[0].Username, 'The user data should match the inserted user');
    }
}