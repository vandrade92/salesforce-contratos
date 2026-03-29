trigger ClausulaTrigger on Clausula__c (after insert, after update, after delete, after undelete) {
    Set<Id> contratoIds = new Set<Id>();

    if (Trigger.isInsert || Trigger.isUndelete) {
        for (Clausula__c clause : Trigger.new) {
            contratoIds.add(clause.Contrato__c);
        }
    }

    if (Trigger.isDelete) {
        for (Clausula__c clause : Trigger.old) {
            contratoIds.add(clause.Contrato__c);
        }
    }

    if (Trigger.isUpdate) {
        for (Clausula__c clause : Trigger.new) {
            Clausula__c oldClause = Trigger.oldMap.get(clause.Id);
            if (oldClause == null) {
                contratoIds.add(clause.Contrato__c);
                continue;
            }

            if (clause.Contrato__c != oldClause.Contrato__c ||
                clause.Ordem__c != oldClause.Ordem__c ||
                clause.Ativa__c != oldClause.Ativa__c) {
                contratoIds.add(clause.Contrato__c);
                contratoIds.add(oldClause.Contrato__c);
            }
        }
    }

    contratoIds.remove(null);
    ClausulaOrderService.renumber(contratoIds);
}