public with sharing class CreateLoanApplication {

    public class Request {
        @InvocableVariable(label='Contact ID' description='Salesforce Contact ID of the applicant' required=true)
        public String contactId;

        @InvocableVariable(label='Work Situation' description='Applicant work situation' required=true)
        public String workSituation;

        @InvocableVariable(label='Annual Net Income' description='Annual net income' required=true)
        public Decimal annualNetIncome;

        @InvocableVariable(label='House Cost' description='Total purchase price of the house' required=true)
        public Decimal houseCost;

        @InvocableVariable(label='Loan Amount' description='Amount the applicant wants to borrow' required=true)
        public Decimal loanAmount;

        @InvocableVariable(label='Loan Duration Months' description='Repayment duration in months' required=true)
        public Decimal loanDurationMonths;
    }

    public class Response {
        @InvocableVariable(label='Loan Application ID' description='Salesforce record ID of the created loan application')
        public String loanApplicationId;

        @InvocableVariable(label='Loan Application Name' description='Auto-number name of the loan application (e.g. LA-0001)')
        public String loanApplicationName;

        @InvocableVariable(label='Error Message' description='Error message if the application could not be created')
        public String errorMessage;
    }

    @InvocableMethod(label='Create Loan Application' description='Creates a Loan Application record and associated Q&A records in Salesforce')
    public static List<Response> execute(List<Request> requests) {
        List<Response> results = new List<Response>();

        for (Request req : requests) {
            Response res = new Response();
            try {
                Contact c = [SELECT Id, AccountId FROM Contact WHERE Id = :req.contactId LIMIT 1];

                Loan_Application__c app = new Loan_Application__c(
                    Applicant__c = c.AccountId,
                    Contact__c = req.contactId,
                    Status__c = 'New',
                    Work_Situation__c = req.workSituation,
                    Annual_Net_Income__c = req.annualNetIncome,
                    House_Cost__c = req.houseCost,
                    Loan_Amount__c = req.loanAmount,
                    Loan_Duration_Months__c = req.loanDurationMonths.intValue()
                );
                insert app;

                app = [SELECT Id, Name FROM Loan_Application__c WHERE Id = :app.Id LIMIT 1];

                List<Loan_QA__c> qaRecords = new List<Loan_QA__c>{
                    new Loan_QA__c(Loan_Application__c = app.Id, Question__c = 'Work Situation',         Answer__c = req.workSituation),
                    new Loan_QA__c(Loan_Application__c = app.Id, Question__c = 'Annual Net Income',      Answer__c = String.valueOf(req.annualNetIncome)),
                    new Loan_QA__c(Loan_Application__c = app.Id, Question__c = 'House Cost',             Answer__c = String.valueOf(req.houseCost)),
                    new Loan_QA__c(Loan_Application__c = app.Id, Question__c = 'Loan Amount',            Answer__c = String.valueOf(req.loanAmount)),
                    new Loan_QA__c(Loan_Application__c = app.Id, Question__c = 'Loan Duration (Months)', Answer__c = String.valueOf(req.loanDurationMonths.intValue()))
                };
                insert qaRecords;

                res.loanApplicationId = app.Id;
                res.loanApplicationName = app.Name;

            } catch (QueryException e) {
                res.errorMessage = 'Contact not found. Please verify your identity and try again.';
            } catch (DmlException e) {
                res.errorMessage = 'Unable to create loan application: ' + e.getDmlMessage(0);
            } catch (Exception e) {
                res.errorMessage = 'An unexpected error occurred: ' + e.getMessage();
            }
            results.add(res);
        }
        return results;
    }
}
