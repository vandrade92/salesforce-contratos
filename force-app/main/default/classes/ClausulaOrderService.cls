public without sharing class ClausulaOrderService {
    @TestVisible
    private static Boolean isRunning = false;

    public static void renumber(Set<Id> contratoIds) {
        Set<Id> safeIds = new Set<Id>();
        if (contratoIds != null) {
            for (Id contratoId : contratoIds) {
                if (contratoId != null) {
                    safeIds.add(contratoId);
                }
            }
        }

        if (safeIds.isEmpty() || isRunning) {
            return;
        }

        isRunning = true;
        try {
            List<Clausula__c> activeClauses = [
                SELECT Id, Contrato__c, Ordem__c
                FROM Clausula__c
                WHERE Contrato__c IN :safeIds AND Ativa__c = true
                ORDER BY Contrato__c ASC, Ordem__c ASC, CreatedDate ASC
            ];

            Map<Id, Integer> nextByContratoId = new Map<Id, Integer>();
            List<Clausula__c> updates = new List<Clausula__c>();

            for (Clausula__c clause : activeClauses) {
                Integer nextOrder = nextByContratoId.containsKey(clause.Contrato__c)
                    ? nextByContratoId.get(clause.Contrato__c) + 1
                    : 1;

                nextByContratoId.put(clause.Contrato__c, nextOrder);

                Integer currentOrder = clause.Ordem__c == null ? null : Integer.valueOf(clause.Ordem__c);
                if (currentOrder != nextOrder) {
                    updates.add(new Clausula__c(
                        Id = clause.Id,
                        Ordem__c = nextOrder
                    ));
                }
            }

            if (!updates.isEmpty()) {
                update updates;
            }
        } finally {
            isRunning = false;
        }
    }
}