/**
 * Created by Bogdan_Krasun on 25.12.2022.
 */

public with sharing class AppointmentService {

    @AuraEnabled(Cacheable=true)
    public static List<Contact> getClients() {
        return [SELECT Name, Id, Email FROM Contact WHERE RecordType.DeveloperName = 'Client_Record_Type' WITH SECURITY_ENFORCED ORDER BY Name];
    }

}