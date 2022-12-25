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

//    public static void getCalendarList() {
//        String docEmail = 'James.Black.doc@gmail.com';
//        HttpResponse response = sendRequest(docEmail, ENDPOINT_CALENDAR_LIST, GET_METHOD, null);
//        System.debug('response =>' + response);
//        System.debug('response body ==>' + response.getBody());
//        getPrimaryCalendar(response);
//    }

    @AuraEnabled(Cacheable=true)
    public static List<EventWrapper> getPrimaryCalendarEventsByDoctor(String doctorId) {
        String docEmail = [SELECT Email FROM Contact WHERE Id = :doctorId].Email;
        if (docEmail == '') {
            return new List<EventWrapper>();
        }
        System.debug('Doc Id == >' + doctorId);
        HttpResponse response = sendRequest(docEmail, ENDPOINT, GET_METHOD, null);
        System.debug('response =>' + response);
        System.debug('response body = ' + response.getBody());
        if (response.getStatusCode() == 200) {
            String resultBody = response.getBody().substringAfter('"items": ');
            resultBody = resultBody.substringBeforeLast('}');
            List<EventWrapper> result = (List<EventWrapper>) JSON.deserialize(replaceReservedIdentifiers(resultBody, true),
                    List<EventWrapper>.class);
            System.debug('result = ' + result);
            convertTime(result);
            for (EventWrapper event : result) {
                System.debug('ID= ' + event.id + 'Summary - ' + event.summary + ', Start time - ' + event.start +
                        ', End time - ' + event.end_c + ', Attendees - ' + event.attendees);
            }
            return result;
        }
        throw new CalloutException('Events where not received');
    }

    private static void convertTime(List<EventWrapper> events) {
        for (EventWrapper event : events) {
            if (event.start != null) {
                event.start.dateTime_c = event.start.dateTime_c?.addHours(-5);
            }
            if (event.end_c != null) {
                event.end_c.dateTime_c = event.end_c.dateTime_c?.addHours(-5);
            }
        }
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

    @AuraEnabled
    public static void deleteEventById(String removeObj) {
        Map<String, Object> eventMap = (Map<String, Object>) JSON.deserializeUntyped(removeObj);
        String eventId = eventMap.get('id')?.toString();
        String doctorId = eventMap.get('doctorId')?.toString();
        System.debug('EventId = ' + eventId + ' DoctorId = ' + doctorId);
        System.debug('Event MAP = ' + eventMap);
        if (eventId != null && doctorId != null) {
            String docEmail = [SELECT Email FROM Contact WHERE Id = :doctorId].Email;
            HttpResponse response = sendRequest(docEmail, ENDPOINT + '/' + eventId, DELETE_METHOD, null);
            System.debug('response =>' + response);
            if (response.getStatusCode() == 204) {
                System.debug('Event Deleted');
            } else {
                throw new CalloutException(response.getBody());
            }
        } else {
            throw new IllegalArgumentException('Event id is not passed');
        }
    }

    @AuraEnabled
    public static String upsertEvent(String obj) {
        EventWrapper event = convertToEvent(obj);
        String docEmail = [SELECT Id, Email FROM Contact WHERE Id = :event.doctorId].Email;
        String jsonEvent = JSON.serialize(event);
        jsonEvent = replaceReservedIdentifiers(jsonEvent, false);
        System.debug('Serialized object = ' + jsonEvent);
        HttpResponse response = sendRequest(docEmail, ENDPOINT + '/' + event.id, event.id == '' ? POST_METHOD : PUT_METHOD, jsonEvent);

        System.debug('Create response == ' + response);
        System.debug('Create response body == ' + response.getBody());
        if (response.getStatusCode() == 200) {
            EventWrapper result = (EventWrapper) JSON.deserialize(replaceReservedIdentifiers(response.getBody(), true), EventWrapper.class);
            event.id = result.id;
            AppointmentService.upsertAppointmentFromEventWrapper(event);
            return result.id;
        } else {
            throw new CalloutException(response.getBody());
        }
    }

    private static EventWrapper convertToEvent(String event) {
        Map<String, Object> eventMap = (Map<String, Object>) JSON.deserializeUntyped(event);
        EventWrapper newEvent = new EventWrapper();
        newEvent.id = eventMap.get('id')?.toString();
        newEvent.summary = eventMap.get('title')?.toString();
        newEvent.description = eventMap.get('description')?.toString();
        newEvent.doctorId = eventMap.get('doctorId')?.toString();
        newEvent.isSalesforceProcess = (Boolean) eventMap.get('isSalesforceProcess');
        String clientEmail = eventMap.get('clientEmail')?.toString();
        List<Contact> clients = [SELECT Id, Name FROM Contact WHERE Email = :clientEmail AND RecordType.DeveloperName = 'Client_Record_Type'];
        if (clients.isEmpty()) {
            throw new IllegalArgumentException('Client is not selected');
        }
        Contact client = clients.get(0);
        newEvent.attendees = new List<GoogleCalendarService.AttendeeWrapper>{
                new AttendeeWrapper(clientEmail, client.Name, false, 'needsAction')
        };
        System.debug('Start time from ui -' + eventMap.get('start'));
        String startDate = eventMap.get('start')?.toString().replace('T', ' ').replace('.000Z', '');
        String endDate = eventMap.get('end')?.toString().replace('T', ' ').replace('.000Z', '');
        newEvent.start = new DateTimeWrapper(startDate != null ? Datetime.valueOfGmt(startDate) : null, 'America/New_York');
        newEvent.start.dateTime_c = newEvent.start.dateTime_c.addHours(5);
        System.debug('Start after convert -' + newEvent.start);
        newEvent.end_c = new DateTimeWrapper(endDate != null ? Datetime.valueOfGmt(endDate) : null, 'America/New_York');
        newEvent.end_c.dateTime_c = newEvent.end_c.dateTime_c.addHours(5);
        newEvent.clientId = client.Id;
        return newEvent;
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
        GoogleAuthSetting__mdt tokenMetadata = getUserMetadata(docEmail);
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setMethod(requestMethod);
        request.setEndpoint(endpoint);
        request.setHeader('content-type', 'application/json');
        request.setHeader('Authorization', 'Bearer ' + ACCESS_TOKEN);
        System.debug('Send request docEmail -> ' + docEmail);
        System.debug('Request method - ' + requestMethod);
        if (requestMethod.equals(POST_METHOD) || requestMethod.equals(PUT_METHOD)) {
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

    private static GoogleAuthSetting__mdt getUserMetadata(String docEmail) {
        IS_TOKEN_REFRESHED = false;
        List<GoogleAuthSetting__mdt> tokenMetadata = [
                SELECT Doctor_email__c, RefreshToken__c, DeveloperName, Label, Expiration_Time__c, AccessToken__c
                FROM GoogleAuthSetting__mdt
                WHERE Doctor_email__c = :docEmail
        ];
        if (tokenMetadata.isEmpty()) {
            throw new IllegalArgumentException('Doctors Calendar does not connected');
        }
        System.debug('token time = ' + tokenMetadata.get(0).Expiration_Time__c);
        System.debug('system  time = ' + System.now());
        ACCESS_TOKEN = tokenMetadata.get(0).AccessToken__c;
        if (tokenMetadata.get(0).Expiration_Time__c < System.now()) {
            System.debug('Token has been expired');
            ACCESS_TOKEN = GoogleAuthService.refreshAccessToken(tokenMetadata.get(0).RefreshToken__c);
            IS_TOKEN_REFRESHED = true;
            System.debug('Refreshed token ==>' + ACCESS_TOKEN);
        }
        return tokenMetadata.get(0);
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
        public String doctorId { get; set; }
        public Id clientId { get; set; }
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
        @AuraEnabled
        public Boolean isSalesforceProcess { get; set; }
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