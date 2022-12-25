/**
 * Created by Bogdan_Krasun on 20.12.2022.
 */

public with sharing class GoogleAuthService {

    private static final String REDIRECT_CLINIC = 'https://appointment-dev-ed.develop.lightning.force.com/lightning/n/Medical_Clinic';
    private static final String REDIRECT_URL = 'https://appointment-dev-ed--c.develop.vf.force.com/apex/GoogleAuth';
    private static final String AUTH_URL = 'https://accounts.google.com/o/oauth2/v2/auth';
    private static final String SCOPE_EVENTS = 'https://www.googleapis.com/auth/calendar.events https://www.googleapis.com/auth/calendar.readonly';
    public static final String TOKEN_URL = 'https://accounts.google.com/o/oauth2/token';
    private static final String GOOGLE_CALENDAR_MDT = 'GoogleCalendarCreds';

    public static String CODE;
    public static String CLIENT_ID;
    public static String CLIENT_SECRET;
    public static String CURRENT_DOC_EMAIL;
    public static String CURRENT_DOC_NAME;

    public GoogleAuthService() {
        GoogleCalendarAppCred__mdt appCred = [
                SELECT Client_Id__c, Client_Secret__c
                FROM GoogleCalendarAppCred__mdt
                WHERE DeveloperName = :GOOGLE_CALENDAR_MDT
        ];
        CLIENT_ID = appCred.Client_Id__c;
        CLIENT_SECRET = appCred.Client_Secret__c;
    }

    @AuraEnabled
    public static void setDocNameEmail(String docId){
        Contact doc = [SELECT Name, Email, Is_Goggle_Cal__c FROM Contact WHERE Id =: docId];
        CURRENT_DOC_EMAIL = doc.Email;
        CURRENT_DOC_NAME = doc.Name;
        doc.Is_Goggle_Cal__c = true;
        update doc;
        System.debug('Setting doc email - ' + CURRENT_DOC_EMAIL);
        System.debug('Setting doc name - ' + CURRENT_DOC_NAME);
    }

    public PageReference callAuth() {
        if (ApexPages.currentPage().getParameters().get('code') != null) {
            System.debug('code ===> ' + ApexPages.currentPage().getParameters().get('code'));
            CODE = ApexPages.currentPage().getParameters().get('code');
            System.debug('AuthCode ==> ' + CODE);
            createAccessToken();
            return new PageReference('https://appointment-dev-ed.develop.lightning.force.com/lightning/n/Medical_Clinic');
        } else {
            return new PageReference(GoogleAuthService.createAuthURL());
        }
    }

    private static String createAuthURL() {
        String key = EncodingUtil.urlEncode(CLIENT_ID, 'UTF-8');
        String uri = EncodingUtil.urlEncode(REDIRECT_URL, 'UTF-8');
        String authuri = '';
        authuri = AUTH_URL + '?' +
                'client_id=' + key +
                '&response_type=code' +
                '&scope=' + SCOPE_EVENTS +
                '&redirect_uri=' + uri +
                '&access_type=offline' +
                '&prompt=consent';
        return authuri;
    }

    private static Boolean createAccessToken() {
        Contact doc = [SELECT Id, Name, Email, Is_Goggle_Cal__c FROM Contact WHERE Is_Goggle_Cal__c = TRUE];
        CURRENT_DOC_EMAIL = doc.Email;
        CURRENT_DOC_NAME = doc.Name;
        System.debug('CLIENT_ID ===> ' + CLIENT_ID);
        System.debug('CLIENT_SECRET ===> ' + CLIENT_SECRET);
        System.debug('CURRENT_DOC_EMAIL ===> ' + CURRENT_DOC_EMAIL);
        System.debug('CURRENT_DOC_NAME ===> ' + CURRENT_DOC_NAME);
        //Getting access token from google
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(TOKEN_URL);
        req.setHeader('content-type', 'application/x-www-form-urlencoded');
        String messageBody = 'code=' + CODE + '&client_id=' + CLIENT_ID +
                '&client_secret=' + CLIENT_SECRET +
                '&redirect_uri=' + REDIRECT_URL +
                '&grant_type=authorization_code';
        req.setHeader('Content-length', String.valueOf(messageBody.length()));
        req.setBody(messageBody);

        Http http = new Http();
        String responseText;
        HttpResponse response = http.send(req);
        responseText = response.getBody();
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseText) ;
        System.debug('Response Map ==> ' + responseMap);

        String accessToken = String.valueOf(responseMap.get('access_token'));
        String refreshToken = String.valueOf(responseMap.get('refresh_token'));
        setIsGoogleCalFalse(doc.Id);

//        Create token in custom metadata
        MetadataService.createCustomMetadata(CURRENT_DOC_EMAIL, CURRENT_DOC_NAME, accessToken, refreshToken);
        return true;
    }

    @Future
    private static void setIsGoogleCalFalse(String id){
        Contact doc = [SELECT Is_Goggle_Cal__c FROM Contact WHERE Is_Goggle_Cal__c = TRUE];
        doc.Is_Goggle_Cal__c = false;
        update doc;
    }

    public static String refreshAccessToken(String refreshToken) {
        GoogleCalendarAppCred__mdt appCred = getAppCredentials();
        CLIENT_ID = appCred.Client_Id__c;
        CLIENT_SECRET = appCred.Client_Secret__c;
        //Getting access token from google
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(TOKEN_URL);
        req.setHeader('content-type', 'application/x-www-form-urlencoded');
        String messageBody = 'client_id=' + CLIENT_ID +
                '&client_secret=' + CLIENT_SECRET +
                '&refresh_token=' + refreshToken +
                '&grant_type=refresh_token';
        req.setHeader('Content-length', String.valueOf(messageBody.length()));
        req.setBody(messageBody);

        Http http = new Http();
        String responseText;
        HttpResponse response = http.send(req);
        responseText = response.getBody();
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseText) ;
        System.debug('CLIENT_ID -> ' + CLIENT_ID);
        System.debug('CLIENT_SECRET -> ' + CLIENT_SECRET);
        System.debug('RefreshToken responseMap ==> ' + responseMap);
        String token = String.valueOf(responseMap.get('access_token'));
        return token;
    }


    private static GoogleAuthSetting__mdt getDocAuthMetadata(String email) {
        return [
                SELECT Doctor_email__c, RefreshToken__c, DeveloperName, Label, Expiration_Time__c, AccessToken__c
                FROM GoogleAuthSetting__mdt
                WHERE Doctor_email__c = :email
        ];
    }

    private static GoogleCalendarAppCred__mdt getAppCredentials(){
        return [
                SELECT Client_Id__c, Client_Secret__c
                FROM GoogleCalendarAppCred__mdt
                WHERE DeveloperName = :GOOGLE_CALENDAR_MDT
        ];
    }
}