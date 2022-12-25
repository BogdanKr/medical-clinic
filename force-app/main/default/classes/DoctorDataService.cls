/**
 * Created by Bogdan_Krasun on 21.12.2022.
 */

public with sharing class DoctorDataService {

    @AuraEnabled(Cacheable=true)
    public static List<Specialization__c> getSpecializations() {
        return [SELECT Name, Id, Appointment_price__c, Image_Url__c FROM Specialization__c WITH SECURITY_ENFORCED ORDER BY Name];
    }

    @AuraEnabled(Cacheable=true)
    public static List<Contact> getDoctors(String specializationId) {
        String query = 'SELECT Id, Name, Image_Url__c FROM Contact WHERE RecordType.DeveloperName = \'Doctor_Record_Type\'';
        if (String.isNotBlank(specializationId)) {
            query += ' AND Specialization__c =:specializationId';
        }
        query += ' WITH SECURITY_ENFORCED ';
        System.debug('query contact - ' + query);
        return Database.query(query);
    }

}