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
    public static void createUserData(Map<String, Object> userData) {
        String firstName = (String) userData.get(USER_FIRSTNAME);
        String lastName = (String) userData.get(USER_LASTNAME);
        String email = (String) userData.get(USER_EMAIL);
        String alias = (String) userData.get(USER_ALIAS);

        List<User> users = [SELECT Id FROM User WHERE Email = :email OR LastName = :lastName];
        if (users != null || users.size() > 0) return;
        createUserREST(new List<String>{firstName, lastName, email, alias});
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
        System.debug(JSON.serialize(userMap));
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
}