/**
 *  Author: Kirk Leibert
 *  Date: Aug 18, 2023
 * 
 *  Contact: kleibert@gmail.com
 * 
 *  Arguments:
 *  A list containing a single argument (HealthcareProvider Id)
 **/

public with sharing class NPIRegistryUpdate {

/*
List<String> arg = new List<String>(); 
arg.add('0cmHs000000btmIIAQ');
List<Object> test = NPIRegistryUpdate.NPIRegistryLookupGet(arg);

*/
    private static String mapGetString(Map<String, Object> m, String p) {
        return String.valueOf(m.get(p));
    }

    private static List<Object> mapGetList(Map<String, Object> m, String p) {
        return (List<Object>) (m.get(p));
    }

    private static Map<String,Object> listGetMap(List<Object> l, Integer i) {
        return (Map<String,Object>) (l[i]);
    }

    private static Map<String,Object> mapGetMap(Map<String, Object> m, String p) {
        return (Map<String,Object>) (m.get(p));
    }

    @InvocableMethod(callout=true label='NPI Registry Info Update')
    public static List<Providers> NPIRegistryUpdate(List<String> ids) {
        
        List<Object> results;
        Map<String, Object> jsonMap, result, basic;   
        List<Providers> providerList;
        Providers provider;
        String firstName, lastName, credential;

        // Record ID is passed in
        String lookupid = ids.get(0);
        // get NPI from Healthcare Provider record
        list <HealthcareProvider> NPI_list = [SELECT AccountId, NPI__c FROM HealthcareProvider WHERE Id = :lookupid LIMIT 1];
        String AccountId = NPI_list[0].AccountId;
        String NPI = NPI_list[0].NPI__c;

        System.debug('NPI retrieved:');
        System.debug(NPI);
        System.debug('Account Id retrieved:');
        System.debug(AccountId);
        //
        String endpoint = 'https://npiregistry.cms.hhs.gov/api/?version=2.1&number=' + NPI;

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        
        if(response.getStatusCode() == 200) {
            System.debug('Successful call. Response code 200');
            System.debug(response);
            
            jsonMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

            results     = mapGetList(jsonMap, 'results');
            result      = listGetMap(results,0);
            basic       = mapGetMap(result,'basic');

            // Get name and credential from basic section

            firstName = mapGetString(basic,'first_name');
            lastName = mapGetString(basic,'last_name');
            credential = mapGetString(basic,'credential');

            // update NPI related record
            String providerNPIStatus = updateProviderNPI(mapGetMap(result, 'basic'),AccountId,NPI );

            // update Identifier records
            String providerIdentifiersStatus = updateIdentifiers(mapGetList(result, 'identifiers'),AccountId );

            // update taxonomy records
            String providerTaxonomiesStatus = updateTaxonomies(mapGetList(result, 'taxonomies'),AccountId );
    
            // Assemble  property set to return flow
            providerList = new List<Providers>();
            provider = new Providers();

            provider.lastName = lastName;
            provider.firstName = firstName;
            provider.credential = credential;

            providerList.add(provider);
        }
        return providerList;
    }

    private static String updateProviderNPI(Map<String,Object> data, String id, String NPI) {
        List<HealthcareProviderNPI> ProviderNPIlist = new List<HealthcareProviderNPI>();
        Map<String,Object> ServiceNPI;

        String Status = deleteProviderNPI(id);

        ServiceNPI = data;
        HealthcareProviderNPI record = new HealthcareProviderNPI();

        record.first_name__c = ServiceNPI.get('first_name').toString();
        record.last_name__c = ServiceNPI.get('last_name').toString();
        record.Credential__c = ServiceNPI.get('credential').toString();
        record.Sole_Proprieter__c = Boolean.valueOf(ServiceNPI.get('sole_proprietor'));
        record.Gender__c = ServiceNPI.get('gender').toString();
        record.Enumeration_Date__c = Date.valueOf(ServiceNPI.get('enumeration_date').toString());
        record.Last_Updated__c = Date.valueOf(ServiceNPI.get('last_updated').toString());
        record.AccountId = id;
        record.Npi = NPI;
        record.SourceSystemIdentifier = NPI;
        record.Name = ServiceNPI.get('first_name').toString() + ' ' + ServiceNPI.get('last_name').toString() + ' ' + ServiceNPI.get('credential').toString();
        record.IsActive = true;
        System.debug(record);
        ProviderNPIlist.add(record);
        
        upsert ProviderNPIlist;
        return 'true';
    }

    private static String updateTaxonomies(List<Object> data, String id) {
        List<HealthcareProviderTaxonomy> taxlist = new List<HealthcareProviderTaxonomy>();
        //Taxonomies record;
        Map<String,Object> ServiceTaxonomies;

        String Status = deleteProviderTaxonomies(id);

        for (Integer i=0; i < data.size();i++) {
            ServiceTaxonomies = listGetMap(data,i);
            HealthcareProviderTaxonomy record = new HealthcareProviderTaxonomy();
            record.Code__c = ServiceTaxonomies.get('code').toString();
            record.Description__c = ServiceTaxonomies.get('desc').toString();
            record.State__c = ServiceTaxonomies.get('state').toString();
            record.License__c = ServiceTaxonomies.get('license').toString();
            record.IsPrimaryTaxonomy = Boolean.valueOf(ServiceTaxonomies.get('primary'));
            record.AccountId = id;
            record.Name = ServiceTaxonomies.get('code').toString();
            System.debug(record);
            taxlist.add(record);
        }
        upsert taxlist;
        return 'true';
    }

    private static String updateIdentifiers(List<Object> data, String id) {

        Map<String,Object> serviceIdentifiers;

        //code to add identifier records to salesforcec
        List<Identifier> identifierList = new List<Identifier>();

        string Status = deleteIdentifier(id);

        for (Integer i=0; i < data.size();i++) {
            serviceIdentifiers = listGetMap(data,i);
            Identifier record = new Identifier();
            record.Code__c = serviceIdentifiers.get('code').toString();
            record.Description__c = serviceIdentifiers.get('desc').toString();
            record.Issuer__c = serviceIdentifiers.get('issuer').toString();
            record.Identifier__c = serviceIdentifiers.get('identifier').toString();
            record.State__c = serviceIdentifiers.get('state').toString();
            record.ParentRecordId = id;
            System.debug(record);
            identifierList.add(record);
        }
        upsert identifierList;
        return 'true';
    }

    public class Providers {
        @invocableVariable(label='First Name'  description='First Name')
        Public String firstName;
        @invocableVariable(label='Last Name'  description='Last Name')
        Public String lastName;
        @invocableVariable(label='Credential'  description='Credential')
        Public String credential;
    }

    private static String deleteProviderSpecialties(String id) {
        //HealthcareProviderSpecialty
        HealthcareProviderSpecialty[] deleteRecords = [Select AccountId from HealthcareProviderSpecialty
                                                    Where AccountId = :id];
        try {
            delete deleteRecords;
        } catch (DmlException e) {
            System.debug(e);
        }
        return 'true';
    }

    private static String deleteProviderTaxonomies(String id) {
        //HealthcareProviderTaxonomy
        HealthcareProviderTaxonomy[] deleteRecords = [Select AccountId from HealthcareProviderTaxonomy
                                                    Where AccountId = :id];
        try {
            delete deleteRecords;
        } catch (DmlException e) {
            System.debug(e);
        }
        return 'true';
    }

    private static String deleteProviderNPI(String id) {
        //HealthcareProviderNpi
        HealthcareProviderNpi[] deleteRecords = [Select AccountId from HealthcareProviderNpi
        Where AccountId = :id];
        try {
            delete deleteRecords;
        } catch (DmlException e) {
            System.debug(e);
        }
        return 'true'; 
    }

    private static String deleteIdentifier(String id) {
        //Identifier

        Identifier[] deleteRecords = [Select ParentRecordId from Identifier
        Where ParentRecordId = :id];
        try {
            delete deleteRecords;
        } catch (DmlException e) {
            System.debug(e);
        }
        return 'true'; 
    }

}