public with sharing class OpportunityRecordTypeService {
    private static final String RT_MONITORAMENTO = 'Monitoramento_Remoto';
    private static final String RT_ASSISTENCIA = 'Assistencia_Tecnica_Judicial';
    private static final String RT_PARECER = 'Elaboracao_de_Parecer';
    private static final String RT_DIAGNOSTICO = 'Diagnostico_de_Contrato';

    public static void applyByService(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        if (newList == null || newList.isEmpty()) {
            return;
        }
        if (!Opportunity.SObjectType.getDescribe().fields.getMap().containsKey('RecordTypeId')) {
            return;
        }

        Set<String> neededRecordTypes = new Set<String>();
        Map<Opportunity, String> recordTypeByOpportunity = new Map<Opportunity, String>();

        for (Opportunity opp : newList) {
            if (opp == null || String.isBlank(opp.Servico__c)) {
                continue;
            }

            String recordTypeDeveloperName = resolveRecordTypeByService(opp.Servico__c);
            if (String.isBlank(recordTypeDeveloperName)) {
                continue;
            }

            neededRecordTypes.add(recordTypeDeveloperName);
            recordTypeByOpportunity.put(opp, recordTypeDeveloperName);
        }

        if (neededRecordTypes.isEmpty()) {
            return;
        }

        Map<String, Id> recordTypeIdByDeveloperName = new Map<String, Id>();
        for (RecordType rt : [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE SObjectType = 'Opportunity'
              AND IsActive = true
              AND DeveloperName IN :neededRecordTypes
        ]) {
            recordTypeIdByDeveloperName.put(rt.DeveloperName, rt.Id);
        }

        for (Opportunity opp : recordTypeByOpportunity.keySet()) {
            String developerName = recordTypeByOpportunity.get(opp);
            Id targetRecordTypeId = recordTypeIdByDeveloperName.get(developerName);
            if (targetRecordTypeId == null) {
                continue;
            }

            Id currentRecordTypeId = (Id) opp.get('RecordTypeId');
            if (currentRecordTypeId != targetRecordTypeId) {
                opp.put('RecordTypeId', targetRecordTypeId);
            }
        }
    }

    @TestVisible
    private static String resolveRecordTypeByService(String serviceName) {
        String normalized = normalizeText(serviceName);
        if (String.isBlank(normalized)) {
            return null;
        }

        if (normalized.contains('monitoramento') && normalized.contains('remoto')) {
            return RT_MONITORAMENTO;
        }
        if ((normalized.contains('assist') || normalized.contains('acao')) && normalized.contains('judicial')) {
            return RT_ASSISTENCIA;
        }
        if (normalized.contains('parecer')) {
            return RT_PARECER;
        }
        if (normalized.contains('diagn')) {
            return RT_DIAGNOSTICO;
        }

        return null;
    }

    private static String normalizeText(String input) {
        if (String.isBlank(input)) {
            return '';
        }

        String output = input.toLowerCase();
        output = output.replace('á', 'a').replace('à', 'a').replace('â', 'a').replace('ã', 'a').replace('ä', 'a');
        output = output.replace('é', 'e').replace('è', 'e').replace('ê', 'e').replace('ë', 'e');
        output = output.replace('í', 'i').replace('ì', 'i').replace('î', 'i').replace('ï', 'i');
        output = output.replace('ó', 'o').replace('ò', 'o').replace('ô', 'o').replace('õ', 'o').replace('ö', 'o');
        output = output.replace('ú', 'u').replace('ù', 'u').replace('û', 'u').replace('ü', 'u');
        output = output.replace('ç', 'c');
        output = output.replaceAll('[^a-z0-9+ ]', ' ');
        output = output.replaceAll('\\s+', ' ').trim();
        return output;
    }
}
