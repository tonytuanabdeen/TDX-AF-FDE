@isTest
private class CreateLoanApplicationTest {

    @TestSetup
    static void setupData() {
        Account acct = new Account(Name = 'Test Account');
        insert acct;

        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            AccountId = acct.Id
        );
        insert con;
    }

    @isTest
    static void testHappyPath() {
        Contact con = [SELECT Id FROM Contact WHERE LastName = 'Doe' LIMIT 1];

        CreateLoanApplication.Request req = new CreateLoanApplication.Request();
        req.contactId   = con.Id;
        req.workSituation       = 'Employed Full-Time';
        req.annualNetIncome     = 60000;
        req.houseCost           = 300000;
        req.loanAmount          = 240000;
        req.loanDurationMonths  = 360;

        Test.startTest();
        List<CreateLoanApplication.Response> results = CreateLoanApplication.execute(
            new List<CreateLoanApplication.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        CreateLoanApplication.Response res = results[0];
        System.assertNotEquals(null, res.loanApplicationId,   'Loan Application ID should be set');
        System.assertNotEquals(null, res.loanApplicationName, 'Loan Application Name should be set');
        System.assertEquals(null,   res.errorMessage,         'No error expected on happy path');

        Loan_Application__c app = [
            SELECT Status__c, Work_Situation__c, Annual_Net_Income__c, House_Cost__c,
                   Loan_Amount__c, Loan_Duration_Months__c, Contact__c
            FROM Loan_Application__c WHERE Id = :res.loanApplicationId
        ];
        System.assertEquals('New',              app.Status__c);
        System.assertEquals('Employed Full-Time', app.Work_Situation__c);
        System.assertEquals(60000,  app.Annual_Net_Income__c);
        System.assertEquals(300000, app.House_Cost__c);
        System.assertEquals(240000, app.Loan_Amount__c);
        System.assertEquals(360,    app.Loan_Duration_Months__c);
        System.assertEquals(con.Id, app.Contact__c);

        List<Loan_QA__c> qaRecords = [
            SELECT Question__c, Answer__c FROM Loan_QA__c
            WHERE Loan_Application__c = :res.loanApplicationId
            ORDER BY Question__c
        ];
        System.assertEquals(5, qaRecords.size(), 'Should create 5 Q&A records');

        Map<String, String> qaMap = new Map<String, String>();
        for (Loan_QA__c qa : qaRecords) {
            qaMap.put(qa.Question__c, qa.Answer__c);
        }
        System.assertEquals('Employed Full-Time', qaMap.get('Work Situation'));
        System.assertEquals('60000',              qaMap.get('Annual Net Income'));
        System.assertEquals('300000',             qaMap.get('House Cost'));
        System.assertEquals('240000',             qaMap.get('Loan Amount'));
        System.assertEquals('360',                qaMap.get('Loan Duration (Months)'));
    }

    @isTest
    static void testMissingContact() {
        Contact ghost = new Contact(LastName = 'Ghost');
        insert ghost;
        Id deletedId = ghost.Id;
        delete ghost;

        CreateLoanApplication.Request req = new CreateLoanApplication.Request();
        req.contactId          = deletedId;
        req.workSituation      = 'Employed Full-Time';
        req.annualNetIncome    = 50000;
        req.houseCost          = 200000;
        req.loanAmount         = 160000;
        req.loanDurationMonths = 240;

        Test.startTest();
        List<CreateLoanApplication.Response> results = CreateLoanApplication.execute(
            new List<CreateLoanApplication.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(null,   results[0].loanApplicationId,   'No application ID expected on error');
        System.assertNotEquals(null, results[0].errorMessage,        'Error message should be populated');
    }
}
