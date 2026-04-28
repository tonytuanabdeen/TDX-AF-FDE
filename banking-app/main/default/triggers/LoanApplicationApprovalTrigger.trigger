trigger LoanApplicationApprovalTrigger on Loan_Application__c (after update) {
    Set<Id> rejectedIds = new Set<Id>();
    for (Loan_Application__c rec : Trigger.new) {
        Loan_Application__c old = Trigger.oldMap.get(rec.Id);
        if (rec.Status__c == 'Rejected' && old.Status__c != 'Rejected') {
            rejectedIds.add(rec.Id);
        }
    }
    if (rejectedIds.isEmpty()) return;

    Map<Id, String> comments = new Map<Id, String>();
    for (ProcessInstanceStep step : [
        SELECT ProcessInstance.TargetObjectId, Comments
        FROM ProcessInstanceStep
        WHERE ProcessInstance.TargetObjectId IN :rejectedIds
          AND StepStatus = 'Rejected'
        ORDER BY CreatedDate DESC
    ]) {
        Id targetId = step.ProcessInstance.TargetObjectId;
        if (!comments.containsKey(targetId) && step.Comments != null) {
            comments.put(targetId, step.Comments);
        }
    }

    List<Loan_Application__c> toUpdate = new List<Loan_Application__c>();
    for (Id rid : rejectedIds) {
        toUpdate.add(new Loan_Application__c(
            Id = rid,
            Reject_Reason__c = comments.containsKey(rid) ? comments.get(rid) : 'Rejected by approver'
        ));
    }
    update toUpdate;
}
