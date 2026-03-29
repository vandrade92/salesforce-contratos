public with sharing class ContratoTriggerHandler {
    private static Boolean beforeExecuting = false;
    private static Boolean afterExecuting = false;

    public static void handleBefore(List<Contrato__c> newList, Map<Id, Contrato__c> oldMap, Boolean isInsert) {
        if (beforeExecuting || newList == null || newList.isEmpty()) {
            return;
        }

        beforeExecuting = true;
        try {
            Boolean enforceValidations = isInsert == true;
            ContratoTemplateService.defaultContractTypeAndTemplate(newList, enforceValidations);
        } finally {
            beforeExecuting = false;
        }
    }

    public static void handleAfter(List<Contrato__c> newList, Map<Id, Contrato__c> oldMap, Boolean isInsert) {
        if (afterExecuting || newList == null || newList.isEmpty()) {
            return;
        }

        Set<Id> idsToInitialize = new Set<Id>();

        for (Contrato__c contrato : newList) {
            if (contrato.Oportunidade__c == null || contrato.Inicializado__c == true) {
                continue;
            }

            if (isInsert) {
                idsToInitialize.add(contrato.Id);
                continue;
            }

            Contrato__c oldContrato = oldMap == null ? null : oldMap.get(contrato.Id);
            Boolean changedContext = oldContrato == null
                || contrato.Oportunidade__c != oldContrato.Oportunidade__c
                || contrato.Tipo_Contrato__c != oldContrato.Tipo_Contrato__c
                || contrato.Contrato_Padrao__c != oldContrato.Contrato_Padrao__c
                || contrato.Inicializado__c != oldContrato.Inicializado__c;

            if (changedContext) {
                idsToInitialize.add(contrato.Id);
            }
        }

        if (idsToInitialize.isEmpty()) {
            return;
        }

        afterExecuting = true;
        try {
            ContratoTemplateService.initializeContracts(idsToInitialize);
        } finally {
            afterExecuting = false;
        }
    }
}
