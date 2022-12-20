/**
 * Created by Bogdan_Krasun on 20.12.2022.
 */

public with sharing class GoogleAuthService {
//API Secret Key
    private static final String clientId = '1009978681859-atp194qhmd4qvifm08hdvujr74j2i4a2.apps.googleusercontent.com';//ClientId
    //API Secret
    private static final String secret = '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';
    //API Redirect. Use your Lightning Tab or Lightning community URL
    private static final String redirect_clinic = 'https://appointment-dev-ed.develop.lightning.force.com/lightning/n/Medical_Clinic';
    private static final String redirect_uri = 'https://appointment-dev-ed--c.develop.vf.force.com/apex/GoogleAuth';
    private static final String authUrl = 'https://accounts.google.com/o/oauth2/v2/auth';
    private static final String scope = 'https://www.googleapis.com/auth/calendar.events';
    private static final String tokenUrl = 'https://accounts.google.com/o/oauth2/token';

    public static String code { get; set; }

    public PageReference callAuth() {
        if (ApexPages.currentPage().getParameters().get('code') != null) {
            System.debug('code ===> ' + ApexPages.currentPage().getParameters().get('code'));
            code = ApexPages.currentPage().getParameters().get('code');
//            return new PageReference('https://appointment-dev-ed.develop.lightning.force.com/lightning/n/Medical_Clinic');
            getAccessToken(code);
            return null;
        } else {
            return new PageReference(GoogleAuthService.createAuthURL());
        }
    }

    private static String createAuthURL() {
        String key = EncodingUtil.urlEncode(clientId, 'UTF-8');
        String uri = EncodingUtil.urlEncode(redirect_uri, 'UTF-8');
        String authuri = '';
        authuri = authUrl + '?' +
                'client_id=' + key +
                '&response_type=code' +
                '&scope=' + scope +
                '&redirect_uri=' + uri +
                '&access_type=offline' +
                '&prompt=consent';
        return authuri;
    }

    public static Boolean getAccessToken(String code) {
        //Getting access token from google
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(tokenUrl);
        req.setHeader('content-type', 'application/x-www-form-urlencoded');

        String messageBody = 'code=' + code + '&client_id=' + clientId +
                '&client_secret=' + secret +
                '&redirect_uri=' + redirect_uri +
                '&grant_type=authorization_code';
        req.setHeader('Content-length', String.valueOf(messageBody.length()));
        req.setBody(messageBody);
        req.setTimeout(60 * 1000);
        System.debug('messageBody:' + messageBody);

        Http callout = new Http();
        String responseText;
        HttpResponse response = callout.send(req);
        responseText = response.getBody();
        System.debug('responseText:' + responseText);
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseText) ;
        String token = String.valueOf(responseMap.get('access_token'));
        System.debug('token:' + token);

        //Update token in custom metadata
//        MetadataService.UpdateCustomMetadata(token);
        return true;
    }

    static void getCalendar() {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('callout:_AUTH PROVIDER_/calendar/v3/calendars/primary/events');
        Http callout = new Http();
        HttpResponse response = callout.send(request);
    }


    public static Boolean generateRefreshToken() {
        //Getting access token from google
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(tokenUrl);
        req.setHeader('content-type', 'application/x-www-form-urlencoded');

        String refresh_token = '1//062uF8Zg_d6LhCgYIARAAGAYSNwF-L9IrYx6qMAXHfrV5JjtC0nSoKidSQg3HpD9T0kIpXKvJI8fm_LfzFtb7a_iFcwysWyPvVPY';
        String messageBody ='client_id=' + clientId +
                '&client_secret=' + secret +
                '&refresh_token=' + refresh_token +
                '&grant_type=refresh_token';
        req.setHeader('Content-length', String.valueOf(messageBody.length()));
        req.setBody(messageBody);
        req.setTimeout(60 * 1000);
        System.debug('messageBody:' + messageBody);

        Http callout = new Http();
        String responseText;
        HttpResponse response = callout.send(req);
        responseText = response.getBody();
        System.debug('responseText:' + responseText);
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseText) ;
        String token = String.valueOf(responseMap.get('access_token'));
        System.debug('token:' + token);

        //Update token in custom metadata
//        MetadataService.UpdateCustomMetadata(token);
        return true;
    }
}