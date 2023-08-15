public class NPIAddress {
    @AuraEnabled
    @invocableVariable(label='country_code'  description='country_code')
    Public String country_code;
    @AuraEnabled
    @invocableVariable(label='country_name'  description='country_name')
    Public String country_name;
    @AuraEnabled
    @invocableVariable(label='address_purpose'  description='address_purpose')
    Public String address_purpose;
    @AuraEnabled
    @invocableVariable(label='address_type'  description='address_type')
    Public String address_type;
    @AuraEnabled
    @invocableVariable(label='address_1'  description='address_1')
    Public String address_1;
    @AuraEnabled
    @invocableVariable(label='address_2'  description='address_2')
    Public String address_2;
    @AuraEnabled
    @invocableVariable(label='city'  description='city')
    Public String city;
    @AuraEnabled
    @invocableVariable(label='state'  description='state')
    Public String state;
    @AuraEnabled
    @invocableVariable(label='postal_code'  description='postal_code')
    Public String postal_code;
    @AuraEnabled
    @invocableVariable(label='telephone_number'  description='telephone_number')
    Public String telephone_number;
}