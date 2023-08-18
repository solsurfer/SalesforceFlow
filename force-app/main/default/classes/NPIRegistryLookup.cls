public class NPIRegistryLookup {

/*Anon Execute Window - use command below:
HttpResponse testResponse = NPIRegistryLookup.NPIRegistryLookupGet(); */
    @InvocableMethod(callout=true label='NPI Registry Info Get')
    public static List<Providers> NPIRegistryLookupGet(List<String> ids) {

        List<Object> results;
        Map<String, Object> jsonMap;
        Map<String, Object> result;
        Map<String, Object> basic;    
        List<Providers> providerList;
        
        Providers provider;

        String firstName, lastName, credential, lastUpdateEpoch;

        try { 

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

            firstName = mapGetString(basic,'first_name');
            lastName = mapGetString(basic,'last_name');
            credential = mapGetString(basic,'credential');
            lastUpdateEpoch = mapGetString(result,'last_updated_epoch');
            //convert 
            DateTime epoch = DateTime.newInstance(Long.ValueOf(lastUpdateEpoch));
            Date epochdt = date.newinstance(epoch.year(), epoch.month(), epoch.day());

            list <Addresses> providerAddresses = getAddresses(mapGetList(result, 'addresses') );
            list <Taxonomies> providerTaxonomies = getTaxonomies(mapGetList(result, 'taxonomies') );
            //list<Taxonomies> providerIdentifiers = getIdentifiers(mapGetList(result, "Identifiers") );
 
            providerList = new List<Providers>();
            provider = new Providers();

            provider.lastName = lastName;
            provider.firstName = firstName;
            provider.credential = credential;
            provider.lastUpdateEpoch = lastUpdateEpoch;
            provider.lastUpdateDate = epochdt;

            //if this test fails. change back to the below:
            provider.addresses = providerAddresses;
            provider.taxonomies = providerTaxonomies;

            providerList.add(provider);
        }
        return providerList;
      }
      catch(Exception e) {
        System.debug('Error--'+e.getMessage());
        return null;
      }

    }

    private static List<Addresses> getAddresses( List<Object> data) {
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
    
    private static List<Taxonomies> getTaxonomies(List<Object> data) {
        List<Taxonomies> retlist = new List<Taxonomies>();
        Taxonomies record;
        Map<String,Object> addr;

        for (Integer i=0; i < data.size();i++) {
            addr = listGetMap(data,i);
            record = new Taxonomies();
            record.code = addr.get('code').toString();
            record.taxonomy_group = addr.get('taxonomy_group').toString();
            record.state = addr.get('state').toString();
            record.description = addr.get('desc').toString();
            record.license = addr.get('license').toString();
            record.primary = addr.get('primary').toString();

            System.debug(record);
            retlist.add(record);
        }
        return retlist;
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
        @invocableVariable(label='lastUpdateEpoch'  description='lastUpdateEpoch')
        Public String lastUpdateEpoch;
        @invocableVariable(label='lastUpdateDate'  description='lastUpdateDate')
        Public Date lastUpdateDate;
        @invocableVariable(label='Addresses'  description='Addresses')
        Public List<Addresses> addresses;
        @invocableVariable(label='Taxonomies'  description='Taxonomies')
        Public List<Taxonomies> taxonomies;   
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
/*
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
    
}