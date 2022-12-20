/**
 * Created by Bogdan_Krasun on 20.12.2022.
 */

public with sharing class GoogleCalendarService {
    static final String ENDPOINT = 'https://www.googleapis.com/calendar/v3/calendars/primary/events';
    static final String ENDPOINT_CALENDAR_LIST = 'https://www.googleapis.com/calendar/v3/users/me/calendarList/';

    public static void getCalendar() {
        String docEmail = 'James.Black.doc@gmail.com';
        HttpResponse response = makeGetRequest(docEmail, ENDPOINT_CALENDAR_LIST);
        System.debug('response =>' + response);
        System.debug('response body ==>' + response.getBody());
        getPrimaryCalendar(response);
    }

    private static HttpResponse makeGetRequest(String docEmail, String endpoint){
        GoogleAuthSetting__mdt tokenMetadata = [
                SELECT Id, Doctor_email__c, AccessToken__c, Expiration_Time__c
                FROM GoogleAuthSetting__mdt
                WHERE Doctor_email__c = :docEmail
        ];
        System.debug('token time = ' +tokenMetadata.Expiration_Time__c );
        System.debug('system  time = ' +System.now() );
        if (tokenMetadata.Expiration_Time__c < System.now()) {
            throw new IllegalArgumentException('Token has been expired');
        }
        String access_token = tokenMetadata.AccessToken__c;
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint(endpoint);
        request.setHeader('content-type', 'application/json');
        request.setHeader('Authorization', 'Bearer ' + access_token);
        HttpResponse response = http.send(request);
        return response;
    }

    private static CalendarWrapper getPrimaryCalendar (HttpResponse response){
        if (response.getStatusCode() == 200) {
            CalendarListWrapper result = (CalendarListWrapper) JSON.deserialize(response.getBody(), CalendarListWrapper.class);
            System.debug('result = ' + result);
            List <CalendarWrapper> calList = result.items;
            for (CalendarWrapper cal: calList ){
                if (cal.primary == true){
                    System.debug('Summary = ' + cal.summary + ' Id = ' + cal.id);
                    return cal;
                }
            }
        }
        return new CalendarWrapper();
    }
    public static void createCalendarEvent() {
        String eventJson = '{ ' +
                '"summary":"", ' +
                '"description": "",' +
                '"location": "Miami",' +
                '"start": {"dateTime": startdate},' +
                '"end": {"dateTime": enddate}' +
                '}';
    }

    public class CalendarListWrapper {
        public List<CalendarWrapper> items;
    }
    public class CalendarWrapper {
        public String id;
        public String summary;
        public String timeZone;
        public Boolean primary;
    }
}