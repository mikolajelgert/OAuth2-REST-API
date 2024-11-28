public without sharing class UserController {
    private static final String CHATTER_USER_NAME = 'Chatter External User';
    private static final String USER_FIRSTNAME = 'firstname';
    private static final String USER_LASTNAME = 'lastname';
    private static final String USER_EMAIL = 'email';
    private static final String USER_ALIAS = 'alias';
    private static final String USER_PASSWORD = 'password';

    private static String getProfileId(String name) {
        return [SELECT Id FROM Profile WHERE Name = :name LIMIT 1].Id;
    }

    @AuraEnabled(cacheable=false)
    public static Boolean createUserData(Map<String, Object> userData) {
        String firstName = (String) userData.get(USER_FIRSTNAME);
        String lastName = (String) userData.get(USER_LASTNAME);
        String email = (String) userData.get(USER_EMAIL);
        String alias = (String) userData.get(USER_ALIAS);

        //for testing purposes
        // List<User> users = [SELECT Id FROM User WHERE Email = :email OR LastName = :lastName];
        // if (users.size() > 0) {
        //     return false;
        // }
        createUserREST(new List<String>{firstName, lastName, email, alias});
        return true;
    }

    @future(callout=true)
    public static void createUserREST(List<String> data) {
        Map<String, Object> userMap = new Map<String, Object>{
            'Username' => data[0] + '.' + data[1] + '@restapi.com',
            'LastName' => data[1],
            'Email' => data[2],
            'Alias' => data[3],
            'LanguageLocaleKey' => 'en_US',
            'TimeZoneSidKey' => 'GMT',
            'EmailEncodingKey' => 'UTF-8',
            'LocaleSidKey' => 'en_US',
            'ProfileId' => getProfileId(CHATTER_USER_NAME)
        };
        String endpoint = 'callout:' + RESTService.NAMED_CREDENTIAL + RESTService.CREATE_USER_ENDPOINT;

        HttpRequest request = RESTService.createRequest(
            'POST', 
            endpoint,
            JSON.serialize(userMap),
            'application/json'
        );

        RESTService.refreshAccessToken();
        HttpResponse response = RESTService.sendRequest(request);
    }

    @AuraEnabled
    public static Boolean setUserPassword(String email, String password) {
        User user = [SELECT Id FROM User WHERE Email = :email LIMIT 1];
        if (user != null) {
            try {
                System.setPassword(user.Id, password);
                return true;
            }catch(Exception ex) {
                System.debug(ex.getMessage());
            }
        }
        return false;
    }

    @AuraEnabled(cacheable=false)
    public static String checkUsername(String username) {
        String query = 'SELECT Id FROM User WHERE Username = \'' + username + '\'';
        String encodedQuery = EncodingUtil.urlEncode(query, 'UTF-8');
        String endpoint = 'callout:' + RESTService.NAMED_CREDENTIAL + RESTService.GET_USER_ENDPOINT_SOQL + encodedQuery;

        HttpRequest request = RESTService.createRequest(
            'GET', 
            endpoint,
            null,
            'application/json'
        );

        RESTService.refreshAccessToken();
        HttpResponse response = RESTService.sendRequest(request);
        if (response.getStatusCode() == 200) {
            return response.getBody();
        }
        return '';
    }

    @AuraEnabled
    public static String checkPassword(String username, String password) {
        Http http = new Http();
        Salesforce_Server__c server = [SELECT Client_Id__c, Client_Secret__c FROM Salesforce_Server__c WHERE Name = 'Salesforce_Server_CAPP' LIMIT 1];
        String endpoint = 'callout:' + RESTService.NAMED_CREDENTIAL + RESTService.TOKEN_ENDPOINT_CREDENTIAL;
        String contentType = 'application/x-www-form-urlencoded';
        String body = 
        'grant_type=password' +
        '&client_id=' + server.Client_Id__c +
        '&client_secret=' + server.Client_Secret__c +
        '&username=' + username +
        '&password=' + password;

        RESTService.refreshAccessToken();
        HttpRequest req = RESTService.createRequest('POST', endpoint, body, contentType);
        HttpResponse resp = RESTService.sendRequest(req);
        return resp.getBody();
    }
}