/**
 * Created by Bogdan_Krasun on 25.12.2022.
 */

public with sharing class AppointmentService {

    @AuraEnabled(Cacheable=true)
    public static List<Contact> getClients() {
        return [SELECT Name, Id, Email FROM Contact WHERE RecordType.DeveloperName = 'Client_Record_Type' WITH SECURITY_ENFORCED ORDER BY Name];
    }

    public static void upsertAppointmentFromEventWrapper(GoogleCalendarService.EventWrapper wrapper) {
        System.debug('Google ID = ' + wrapper.id);
        Appointment__c appointment = new Appointment__c(
                Google_Event_Id__c = wrapper.id, Title__c = wrapper.summary, Description__c = wrapper.description,
                Doctor__c = wrapper.doctorId, Client__c = wrapper.clientId,
                Start_Time__c = wrapper.start.dateTime_c, End_Time__c = wrapper.end_c.dateTime_c,
                Is_Salesforce_Process__c = wrapper.isSalesforceProcess
        );
        upsert appointment Google_Event_Id__c;
    }

}