public with sharing class GetContactInfo {

    public class Request {
        @InvocableVariable(label='Contact ID' description='Salesforce Contact ID of the authenticated user' required=true)
        public String contactId;
    }

    public class Response {
        @InvocableVariable(label='First Name' description='Contact first name')
        public String firstName;

        @InvocableVariable(label='Last Name' description='Contact last name')
        public String lastName;

        @InvocableVariable(label='Account ID' description='ID of the Account associated with the contact')
        public String accountId;
    }

    @InvocableMethod(label='Get Contact Info' description='Retrieves first name, last name, and account ID for a given Contact ID')
    public static List<Response> execute(List<Request> requests) {
        List<Response> results = new List<Response>();

        Set<Id> contactIds = new Set<Id>();
        for (Request req : requests) {
            if (String.isNotBlank(req.contactId)) {
                contactIds.add(Id.valueOf(req.contactId));
            }
        }

        Map<Id, Contact> contactMap = new Map<Id, Contact>(
            [SELECT Id, FirstName, LastName, AccountId FROM Contact WHERE Id IN :contactIds]
        );

        for (Request req : requests) {
            Response res = new Response();
            Id cId = String.isNotBlank(req.contactId) ? Id.valueOf(req.contactId) : null;
            if (cId != null && contactMap.containsKey(cId)) {
                Contact c = contactMap.get(cId);
                res.firstName = c.FirstName;
                res.lastName = c.LastName;
                res.accountId = String.valueOf(c.AccountId);
            } else {
                res.firstName = 'Unknown';
                res.lastName = 'User';
                res.accountId = null;
            }
            results.add(res);
        }
        return results;
    }
}
