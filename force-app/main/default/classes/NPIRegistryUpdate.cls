public with sharing class NPIRegistryUpdate {

/*
List<String> arg = new List<String>(); 
arg.add('0cmHs000000btmIIAQ');
List<Object> test = NPIRegistryUpdate.NPIRegistryLookupGet(arg);

*/

@InvocableMethod(callout=true label='NPI Registry Info Update')
public static List<Providers> NPIRegistryUpdate(List<String> ids) {
    
    List<Object> results;
    Map<String, Object> jsonMap, result, basic;   
    List<Providers> providerList;
    Providers provider;
    String firstName, lastName, credential;

    //Map<String, Object> result;
    //Map<String, Object> basic; 

    // HealthcareProvider ID is passed in
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

        // update basic section

        firstName = mapGetString(basic,'first_name');
        lastName = mapGetString(basic,'last_name');
        credential = mapGetString(basic,'credential');

        // update addressess, to be implemented later
        String providerNPIStatus = updateProviderNPI(mapGetMap(result, 'basic'),AccountId,NPI );

        // update Identifiers
        String providerIdentifiersStatus = updateIdentifiers(mapGetList(result, 'identifiers'),AccountId );

        // update taxonomies
        String providerTaxonomiesStatus = updateTaxonomies(mapGetList(result, 'taxonomies'),AccountId );
  

        // Assemble return property set that could possibly be used in flow
        providerList = new List<Providers>();
        provider = new Providers();

        provider.lastName = lastName;
        provider.firstName = firstName;
        provider.credential = credential;

        //if this test fails. change back to the below:
        //provider.addresses = providerAddresses;
        //provider.taxonomies = providerTaxonomies;
        //provider.identifiers = providerIdentifiers;

        providerList.add(provider);
    }
    return providerList;
}

private static List<Addresses> updateAddresses( List<Object> data, String id) {
    List<Addresses> retlist = new List<Addresses>();
    Addresses record;
    Map<String,Object> addr;

    for (Integer i=0; i < data.size();i++) {
        addr = listGetMap(data,i);
        record = new Addresses();
        record.address_1 = addr.get('address_1').toString();
        record.city = addr.get('city').toString();
        record.state = addr.get('state').toString();
        record.address_type = addr.get('address_type').toString();
        record.postal_code = addr.get('postal_code').toString();
        record.telephone_number = addr.get('telephone_number').toString();

        System.debug(record);            
        retlist.add(record);
    }
    return retlist;
}

private static String updateProviderNPI(Map<String,Object> data, String id, String NPI) {
    List<HealthcareProviderNPI> ProviderNPIlist = new List<HealthcareProviderNPI>();
    //Taxonomies record;
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
/*
"code": "01",
"desc": "Other (non-Medicare)",
"issuer": "BCBS",
"identifier": "129HK",
"state": "NC",
*/
private static String updateIdentifiers(List<Object> data, String id) {
    //List<Identifiers> retlist = new List<Identifiers>();
    //Identifiers record;
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

/*
private static List<Identifiers> getIdentifiers(List<Object> data) {
    // execute loop
    return list
}
*/
public class Providers {
    @invocableVariable(label='First Name'  description='First Name')
    Public String firstName;
    @invocableVariable(label='Last Name'  description='Last Name')
    Public String lastName;
    @invocableVariable(label='Credential'  description='Credential')
    Public String credential;
    @invocableVariable(label='Addresses'  description='Addresses')
    Public List<Addresses> addresses;
    @invocableVariable(label='Taxonomies'  description='Taxonomies')
    Public List<Taxonomies> taxonomies;   
    @invocableVariable(label='Indentifiers'  description='Indentifiers')
    Public List<identifiers> identifiers;   
}

Public class Addresses {
    @invocableVariable(label='country_code'  description='country_code')
    Public String country_code;
    @invocableVariable(label='country_name'  description='country_name')
    Public String country_name;
    @invocableVariable(label='address_purpose'  description='address_purpose')
    Public String address_purpose;
    @invocableVariable(label='address_type'  description='address_type')
    Public String address_type;
    @invocableVariable(label='address_1'  description='address_1')
    Public String address_1;
    @invocableVariable(label='address_2'  description='address_2')
    Public String address_2;
    @invocableVariable(label='city'  description='city')
    Public String city;
    @invocableVariable(label='state'  description='state')
    Public String state;
    @invocableVariable(label='postal_code'  description='postal_code')
    Public String postal_code;
    @invocableVariable(label='telephone_number'  description='telephone_number')
    Public String telephone_number;
}

Public class Taxonomies {
    @invocableVariable(label='code'  description='code')
    Public String code;
    @invocableVariable(label='taxonomy_group'  description='taxonomy_group')
    Public String taxonomy_group;
    @invocableVariable(label='description'  description='description')
    Public String description;
    @invocableVariable(label='state'  description='state')
    Public String state;
    @invocableVariable(label='license'  description='license')
    Public String license;
    @invocableVariable(label='primary'  description='primary')
    Public String primary;
}

Public class Identifiers {
    @invocableVariable(label='code'  description='code')
    Public String code;
    @invocableVariable(label='description'  description='description')
    Public String description;
    @invocableVariable(label='issuer'  description='issuer')
    Public String issuer;
    @invocableVariable(label='identifier'  description='identifier')
    Public String identifier;
    @invocableVariable(label='state'  description='state')
    Public String state;
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
    System.debug('Delete HealthcareProviderNpi');
    System.debug('Delete HealthcareProviderNpi');
    System.debug('Delete HealthcareProviderNpi');
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

}