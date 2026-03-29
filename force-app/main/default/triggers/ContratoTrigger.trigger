trigger ContratoTrigger on Contrato__c (before insert, before update, after insert, after update) {
    if (Trigger.isBefore) {
        ContratoTriggerHandler.handleBefore(Trigger.new, Trigger.oldMap, Trigger.isInsert);
    }

    if (Trigger.isAfter) {
        ContratoTriggerHandler.handleAfter(Trigger.new, Trigger.oldMap, Trigger.isInsert);
    }
}
