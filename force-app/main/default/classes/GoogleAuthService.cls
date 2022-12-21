/**
 * Created by Bogdan_Krasun on 20.12.2022.
 */

public with sharing class GoogleAuthService {
    //ClientId
//    private static final String CLIENT_ID = '1009978681859-atp194qhmd4qvifm08hdvujr74j2i4a2.apps.googleusercontent.com';
//    private static final String SECRET_ID = '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';

    private static final String REDIRECT_CLINIC = 'https://appointment-dev-ed.develop.lightning.force.com/lightning/n/Medical_Clinic';
    private static final String REDIRECT_URL = 'https://appointment-dev-ed--c.develop.vf.force.com/apex/GoogleAuth';
    private static final String AUTH_URL = 'https://accounts.google.com/o/oauth2/v2/auth';
    private static final String SCOPE_EVENTS = 'https://www.googleapis.com/auth/calendar.events https://www.googleapis.com/auth/calendar.readonly';
    public static final String TOKEN_URL = 'https://accounts.google.com/o/oauth2/token';

    public static String CODE;

    public PageReference callAuth() {
        String docEmail = 'James.Black.doc@gmail.com';
        GoogleAuthSetting__mdt docAuthData = getDocAuthMetadata(docEmail);
        if (ApexPages.currentPage().getParameters().get('code') != null) {
            System.debug('code ===> ' + ApexPages.currentPage().getParameters().get('code'));
            CODE = ApexPages.currentPage().getParameters().get('code');
//            return new PageReference('https://appointment-dev-ed.develop.lightning.force.com/lightning/n/Medical_Clinic');
            System.debug('AuthCode ==> ' + CODE);
            getAccessToken(CODE, docAuthData.Client_Id__c, docAuthData.Client_Secret__c);
            return null;
        } else {
            return new PageReference(GoogleAuthService.createAuthURL(docAuthData.Client_Id__c));
        }
    }

    private static String createAuthURL(String clientId) {
        String key = EncodingUtil.urlEncode(clientId, 'UTF-8');
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

    private static Boolean getAccessToken(String code, String clientId, String clientSecret) {
        //Getting access token from google
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(TOKEN_URL);
        req.setHeader('content-type', 'application/x-www-form-urlencoded');
        String messageBody = 'code=' + code + '&client_id=' + clientId +
                '&client_secret=' + clientSecret +
                '&redirect_uri=' + REDIRECT_URL +
                '&grant_type=authorization_code';
        req.setHeader('Content-length', String.valueOf(messageBody.length()));
        req.setBody(messageBody);

        Http http = new Http();
        String responseText;
        HttpResponse response = http.send(req);
        responseText = response.getBody();
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseText) ;
        String accessToken = String.valueOf(responseMap.get('access_token'));
        String refreshToken = String.valueOf(responseMap.get('refresh_token'));

//        Create token in custom metadata
        MetadataService.createCustomMetadata('James.Black.doc@gmail.com', 'James Black', accessToken, refreshToken);
        return true;
    }


    public static String refreshAccessToken(String docEmail) {

        //Getting access token from google
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(TOKEN_URL);
        req.setHeader('content-type', 'application/x-www-form-urlencoded');
        GoogleAuthSetting__mdt docAuthData = getDocAuthMetadata(docEmail);
        String messageBody = 'client_id=' + docAuthData.Client_Id__c +
                '&client_secret=' + docAuthData.Client_Secret__c +
                '&refresh_token=' + docAuthData.RefreshToken__c +
                '&grant_type=refresh_token';
        req.setHeader('Content-length', String.valueOf(messageBody.length()));
        req.setBody(messageBody);

        Http http = new Http();
        String responseText;
        HttpResponse response = http.send(req);
        responseText = response.getBody();
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseText) ;
        String token = String.valueOf(responseMap.get('access_token'));
        return token;
    }


    private static GoogleAuthSetting__mdt getDocAuthMetadata(String email) {
        return [
                SELECT Doctor_email__c, RefreshToken__c, DeveloperName, Label, Client_Id__c,
                        Client_Secret__c, Expiration_Time__c, AccessToken__c
                FROM GoogleAuthSetting__mdt
                WHERE Doctor_email__c = :email
        ];
    }
}