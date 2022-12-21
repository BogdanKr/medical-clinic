/**
 * Created by Bogdan_Krasun on 21.12.2022.
 */

public with sharing class DoctorDataService {

    @AuraEnabled(Cacheable=true)
    public static List<Specialization__c> getSpecializations() {
        return [SELECT Name, Id, Appointment_price__c, Specialization_Image_URL__c FROM Specialization__c WITH SECURITY_ENFORCED ORDER BY Name];
    }

    @AuraEnabled(Cacheable=true)
    public static List<Contact> getDoctors(String specializationId) {
        // Without an explicit boatTypeId, the full list is desired
        String query = 'SELECT '
                + 'Name, Description__c, Geolocation__Latitude__s, '
                + 'Geolocation__Longitude__s, Picture__c, Contact__r.Name, '
                + 'BoatType__c, BoatType__r.Name, Length__c, Price__c '
                + 'FROM Contact';
        if (String.isNotBlank(specializationId)) {
            query += ' WHERE BoatType__c = :boatTypeId';
        }
        query += ' WITH SECURITY_ENFORCED ';
        return Database.query(query);
    }

}