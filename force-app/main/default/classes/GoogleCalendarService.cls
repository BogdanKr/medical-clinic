/**
 * Created by Bogdan_Krasun on 20.12.2022.
 */

public with sharing class GoogleCalendarService {
    static final String ENDPOINT = 'https://www.googleapis.com/calendar/v3/calendars/primary/events';
    static final String ENDPOINT_CALENDAR_LIST = 'https://www.googleapis.com/calendar/v3/users/me/calendarList/';
    static final String GET_METHOD = 'GET';
    static final String POST_METHOD = 'POST';
    static final String PUT_METHOD = 'PUT';
    static final String DELETE_METHOD = 'DELETE';
    static String ACCESS_TOKEN;
    static Boolean IS_TOKEN_REFRESHED;

    public static void getCalendarList() {
        String docEmail = 'James.Black.doc@gmail.com';
        HttpResponse response = sendRequest(docEmail, ENDPOINT_CALENDAR_LIST, GET_METHOD, null);
        System.debug('response =>' + response);
        System.debug('response body ==>' + response.getBody());
        getPrimaryCalendar(response);
    }

    @AuraEnabled(Cacheable=true)
    public static List<EventWrapper> getPrimaryCalendarEventsByDoctor(String doctorId) {
//        String docEmail = [SELECT Email FROM Contact WHERE Id = :doctorId].Email;
        String docEmail = 'James.Black.doc@gmail.com';
        HttpResponse response = sendRequest(docEmail, ENDPOINT, GET_METHOD, null);
        System.debug('response =>' + response);
        System.debug('response body = ' + response.getBody());
        if (response.getStatusCode() == 200) {
            String resultBody = response.getBody().substringAfter('"items": ');
            resultBody = resultBody.substringBeforeLast('}');
            List<EventWrapper> result = (List<EventWrapper>) JSON.deserialize(replaceReservedIdentifiers(resultBody, true),
                    List<EventWrapper>.class);
            System.debug('result = ' + result);
            for (EventWrapper event : result) {
                System.debug('ID= ' + event.id + 'Summary - ' + event.summary + ', Start time - ' + event.start +
                        ', End time - ' + event.end_c + ', Attendees - ' + event.attendees);
            }
            return result;
//            return new List<EventWrapper>{result.get(0)};
        }
        throw new CalloutException('Events where not received');
    }

    public static void getEventById(String eventId) {
        String docEmail = 'James.Black.doc@gmail.com';
        HttpResponse response = sendRequest(docEmail, ENDPOINT + '/' + eventId, GET_METHOD, null);
        System.debug('response =>' + response);
        if (response.getStatusCode() == 200) {
            EventWrapper result = (EventWrapper) JSON.deserialize(replaceReservedIdentifiers(response.getBody(), true),
                    EventWrapper.class);
            System.debug('Event=> ' + result);
            for (AttendeeWrapper attendee : result.attendees) {
                System.debug('Name - ' + attendee.displayName + ', Email - ' + attendee.email +
                        ', Self - ' + attendee.self + ', responseStatus - ' + attendee.responseStatus);
            }
        }
    }

    public static void deleteEventById(String eventId) {
        String docEmail = 'James.Black.doc@gmail.com';
        HttpResponse response = sendRequest(docEmail, ENDPOINT + '/' + eventId, DELETE_METHOD, null);
        System.debug('response =>' + response);
        if (response.getStatusCode() == 204) {
            System.debug('Event Deleted');
        }
    }

    public static void createEvent() {
        String docEmail = 'James.Black.doc@gmail.com';
        EventWrapper event = new EventWrapper();
        event.summary = 'New event REST api';
        event.description = 'testing custom API service';
        event.start = new DateTimeWrapper(System.now(), 'America/New_York');
        event.end_c = new DateTimeWrapper(System.now().addMinutes(10), 'America/New_York');
        event.attendees = new List<GoogleCalendarService.AttendeeWrapper>{
                new AttendeeWrapper('test@test.com', 'new client', true, 'accepted')
        };
        String json = JSON.serialize(event);
        json = replaceReservedIdentifiers(json, false);
        System.debug('Serialized object = ' + json);

        HttpResponse response = sendRequest(docEmail, ENDPOINT, POST_METHOD, json);

        System.debug('Create response == ' + response);
        System.debug('Create response body == ' + response.getBody());
    }

    public static void updateEventById() {
        String docEmail = 'James.Black.doc@gmail.com';
        String eventId = 'kans0dp2kts5h75v2cbn1amsr8';
        EventWrapper event = new EventWrapper();
        event.summary = 'New event REST api UPDATED';
        event.description = 'testing custom API service';
        event.start = new DateTimeWrapper(System.now(), 'America/New_York');
        event.end_c = new DateTimeWrapper(System.now().addMinutes(10), 'America/New_York');
//        event.attendees = new List<GoogleCalendarService.AttendeeWrapper>{
//                new AttendeeWrapper('test@test.com', 'new client', true, 'accepted')
//        };
        String json = JSON.serialize(event);
        json = replaceReservedIdentifiers(json, false);
        System.debug('Serialized object = ' + json);

        HttpResponse response = sendRequest(docEmail, ENDPOINT + '/' + eventId, PUT_METHOD, json);

        System.debug('Create response == ' + response);
        System.debug('Create response body == ' + response.getBody());
    }

    private static HttpResponse sendRequest(String docEmail, String endpoint, String requestMethod, String body) {
        GoogleAuthSetting__mdt tokenMetadata = getUsedMetadata(docEmail);
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setMethod(requestMethod);
        request.setEndpoint(endpoint);
        request.setHeader('content-type', 'application/json');
//        request.setHeader('Accept', 'application/json');
        request.setHeader('Authorization', 'Bearer ' + ACCESS_TOKEN);
        if (requestMethod.equals(POST_METHOD) || requestMethod.equals(PUT_METHOD)) {
            System.debug('Request method - ' + requestMethod);
            request.setBody(body);
        }
        HttpResponse response = http.send(request);
        if (response.getStatusCode() == 401) {
            System.debug('Bad request: ' + response.getBody());
            throw new CalloutException('Invalid Credentials');
        }
        if (IS_TOKEN_REFRESHED) {
            //Update token in custom metadata
            MetadataService.updateCustomMetadata(tokenMetadata, ACCESS_TOKEN);
        }
        return response;
    }

    private static GoogleAuthSetting__mdt getUsedMetadata(String docEmail) {
        IS_TOKEN_REFRESHED = false;
        GoogleAuthSetting__mdt tokenMetadata = [
                SELECT Doctor_email__c, RefreshToken__c, DeveloperName, Label, Client_Id__c, Client_Secret__c,
                        Expiration_Time__c, AccessToken__c
                FROM GoogleAuthSetting__mdt
                WHERE Doctor_email__c = :docEmail
        ];
        System.debug('token time = ' + tokenMetadata.Expiration_Time__c);
        System.debug('system  time = ' + System.now());
        ACCESS_TOKEN = tokenMetadata.AccessToken__c;
        if (tokenMetadata.Expiration_Time__c < System.now()) {
            System.debug('Token has been expired');
            ACCESS_TOKEN = GoogleAuthService.refreshAccessToken(docEmail);
            IS_TOKEN_REFRESHED = true;
        }
        return tokenMetadata;
    }

    private static CalendarWrapper getPrimaryCalendar(HttpResponse response) {
        if (response.getStatusCode() == 200) {
            CalendarListWrapper result = (CalendarListWrapper) JSON.deserialize(response.getBody(), CalendarListWrapper.class);
            System.debug('result = ' + result);
            List <CalendarWrapper> calList = result.items;
            for (CalendarWrapper cal : calList) {
                if (cal.primary == true) {
                    System.debug('Summary = ' + cal.summary + ' Id = ' + cal.id);
                    return cal;
                }
            }
        }
        return new CalendarWrapper();
    }

    private static String replaceReservedIdentifiers(String jsonInput, Boolean isDeserialization) {
        return isDeserialization ? jsonInput.replace('dateTime', 'dateTime_c').replace('"end"', '"end_c"') : jsonInput.replace('dateTime_c', 'dateTime').replace('"end_c"', '"end"');
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

    public class CalendarWithEventsWrapper {
        public String kind;
        public String etag;
        public String summary;
        public Datetime updated;
        public String timeZone;
        public String accessRole;
        public List<EventWrapper> items;
    }

    public class EventWrapper {
        @AuraEnabled
        public String kind { get; }
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String htmlLink { get; }
        @AuraEnabled
        public Datetime created { get; }
        @AuraEnabled
        public Datetime updated { get; }
        @AuraEnabled
        public String summary { get; set; }
        @AuraEnabled
        public String description { get; set; }
        @AuraEnabled
        public String location { get; set; }
        @AuraEnabled
        public DateTimeWrapper start { get; set; }
        @AuraEnabled
        public DateTimeWrapper end_c { get; set; }
        @AuraEnabled
        public String iCalUID { get; }
        @AuraEnabled
        public List<AttendeeWrapper> attendees { get; set; }
    }

    public class DateTimeWrapper {
        @AuraEnabled
        public Datetime dateTime_c { get; set; }
        @AuraEnabled
        public String timeZone { get; set; }
        DateTimeWrapper(Datetime dateTime_c, String timeZone) {
            this.dateTime_c = dateTime_c;
            this.timeZone = timeZone;
        }
    }

    public class AttendeeWrapper {
        @AuraEnabled
        public String email { get; set; }
        @AuraEnabled
        public String displayName { get; set; }
        @AuraEnabled
        public Boolean self { get; set; }
        @AuraEnabled
        public String responseStatus { get; set; }

        AttendeeWrapper(String email, String displayName, Boolean self, String responseStatus) {
            this.email = email;
            this.displayName = displayName;
            this.self = self;
            this.responseStatus = responseStatus;
        }
    }


}