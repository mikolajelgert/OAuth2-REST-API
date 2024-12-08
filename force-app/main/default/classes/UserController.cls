/**
 * Klasa UserController zarządza operacjami na użytkownikach.
 * Obejmuje metody do tworzenia użytkowników, ustawiania hasła, 
 * sprawdzania danych uwierzytelniających oraz pobierania listy użytkowników.
 */
public without sharing class UserController {

    /**
     * Nazwa profilu dla użytkowników Chatter External.
     */
    private static final String CHATTER_USER_NAME = 'Chatter External User';
    private static final String USER_USERNAME = 'username';
    private static final String USER_EMAIL = 'email';
    private static final String USER_ALIAS = 'alias';
    private static final String USER_PASSWORD = 'password';

    /**
     * Pobiera Id profilu na podstawie nazwy.
     * 
     * @param name Nazwa profilu do wyszukania.
     * @return Id profilu, jeśli istnieje.
     */
    private static String getProfileId(String name) {
        return [SELECT Id FROM Profile WHERE Name = :name LIMIT 1].Id;
    }

    /**
     * Tworzy użytkownika na podstawie danych w mapie.
     * 
     * @param userData Mapa zawierająca dane użytkownika (nazwa, email, alias).
     * @return true, jeśli proces zakończy się sukcesem.
     */
    @AuraEnabled(cacheable=false)
    public static Boolean createUserData(Map<String, Object> userData) {
        String userName = (String) userData.get(USER_USERNAME);
        String email = (String) userData.get(USER_EMAIL);
        String alias = (String) userData.get(USER_ALIAS);

        createUserREST(new List<String>{userName, email, alias});
        return true;
    }

    /**
     * Wywołuje usługę REST w celu stworzenia użytkownika.
     * Metoda działa jako asynchroniczna (@future).
     * 
     * @param data Lista zawierająca dane użytkownika (nazwa, email, alias).
     */
    @future(callout=true)
    public static void createUserREST(List<String> data) {
        Map<String, Object> userMap = new Map<String, Object>{
            'Username' => data[0],
            'LastName' => data[0],
            'Email' => data[1],
            'Alias' => data[2],
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
        System.debug(response.getBody());
    }

    /**
     * Ustawia hasło dla użytkownika.
     * 
     * @param username Nazwa użytkownika (username) w Salesforce.
     * @param password Nowe hasło dla użytkownika.
     * @return true, jeśli hasło zostało ustawione pomyślnie.
     */
    @AuraEnabled
    public static Boolean setUserPassword(String username, String password) {
        User user = [SELECT Id FROM User WHERE Username = :username LIMIT 1];
        if (user != null) {
            try {
                System.setPassword(user.Id, password);
                return true;
            } catch(Exception ex) {
                System.debug(ex.getMessage());
            }
        }
        return false;
    }

    /**
     * Sprawdza, czy użytkownik o podanym nazwie użytkownika istnieje.
     * 
     * @param username Nazwa użytkownika (username) do sprawdzenia.
     * @return JSON z wynikami zapytania SOQL lub pusty string w przypadku błędu.
     */
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

    /**
     * Sprawdza poprawność podanego hasła użytkownika, 
     * wykonując żądanie do token endpoint w celu uwierzytelnienia.
     * 
     * @param username Nazwa użytkownika.
     * @param password Hasło użytkownika.
     * @return Odpowiedź z token endpoint w formacie JSON.
     */
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

    /**
     * Pobiera listę ostatnich użytkowników w Salesforce.
     * 
     * @return Lista obiektów User posortowanych według daty utworzenia (malejąco).
     */
    @AuraEnabled(cacheable=true)
    public static List<User> getLastUsers() {
        return [SELECT CreatedDate, Id, Username, Email, Profile.Name FROM User ORDER BY CreatedDate DESC];
    }
}