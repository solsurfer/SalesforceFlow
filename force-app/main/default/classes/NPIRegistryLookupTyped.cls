global with sharing class NPIRegistryLookupTyped {

/*Anon Execute Window - use command below:
HttpResponse testResponse = NPIRegistryLookup.NPIRegistryLookupGet(); */
@InvocableMethod(callout=true label='Get NPI Registry Info NPESS')
public static List<Results> NPIRegistryLookupTypedGet(List<String> ids) {
    List<Results> resultsList;
    String lookupid = ids.get(0);
    String endpoint = 'https://npiregistry.cms.hhs.gov/api/?version=2.1&number=' + lookupid;

    Http http = new Http();
    HttpRequest request = new HttpRequest();
    request.setEndpoint(endpoint);
    request.setMethod('GET');
    HttpResponse response = http.send(request);
    
    if(response.getStatusCode() ==200) {
        System.debug('Successful call. Response code 200');
        String responseJSON = response.getBody();

        System.debug(responseJSON);
        
        System.debug('JSON returned by service');
        Results curResult = new Results();
        NPIJSON2Apex currentResult = NPIJSON2Apex.parse(responseJSON);
        curResult.npiresult = currentResult;

        resultsList = new List<Results>();
        resultsList.add(curResult);    
    }
    return resultsList;

    }

    global class Results {
        @InvocableVariable (label='NPIJSON2Apex'  description='NPIJSON2Apex')
        global NPIJSON2Apex npiresult;
    }
}