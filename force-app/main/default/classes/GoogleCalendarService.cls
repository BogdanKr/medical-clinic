/**
 * Created by Bogdan_Krasun on 20.12.2022.
 */

public with sharing class GoogleCalendarService {
    static final String ENDPOINT = 'https://www.googleapis.com/calendar/v3/calendars/primary/events';

    public static void getCalendar() {
        String accessToken = '';
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint(ENDPOINT);
        request.setHeader('content-type', 'application/json');
        request.setHeader('Authorization', 'Bearer ' + accessToken);

        HttpResponse response = http.send(request);
        System.debug(response);
    }
}