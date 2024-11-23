public with sharing class UserController {
    private static final String COMMUNITY_USER_NAME = 'Customer Community User';

    private static String getProfileId(String name) {
        return [SELECT Id FROM Profile WHERE Name = :name LIMIT 1].Id;
    }

    public static void createRelationshipObjects() {
        Account account = new Account(Name = 'Test Account');
        insert account;

        Contact contact = new Contact(
        FirstName = 'Test',
        LastName = 'LastName',
        AccountId = account.Id
        );
        insert contact;
    }
    
    //@AuraEnabled(cacheable=false)
    @future(callout=true)
    public static void createUser() {
        RESTService.refreshAccessToken();
        createRelationshipObjects();

        Map<String, Object> userData = new Map<String, Object>{
            'Username' => 'tralala@lala.com',
            'LastName' => 'testLastName',
            'Alias' => 'demoapi',
            'Email' => 'test@example.com',
            'LanguageLocaleKey' => 'en_US',
            'ProfileId' => getProfileId(COMMUNITY_USER_NAME),
            'ContactId' => [SELECT Id FROM Contact WHERE FirstName = 'Test' LIMIT 1].Id
        };
        String endpoint = 'callout:' + RESTService.NAMED_CREDENTIAL + RESTService.CREATE_USER_ENDPOINT;

        HttpRequest request = RESTService.createRequest(
            'POST', 
            endpoint,
            JSON.serialize(userData),
            'application/json'
        );

        HttpResponse resp;
        try {
            Http http = new Http();
            resp = http.send(request);
            System.debug(resp.getBody());
        }catch(Exception ex) {
            System.debug(ex.getMessage());
        }
    }
}