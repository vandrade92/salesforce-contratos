@IsTest
private class OpportunityRecordTypeServiceTest {
    @IsTest
    static void testAppliesMappedRecordTypeOnInsertAndUpdate() {
        Account acc = new Account(Name = 'Conta RT Teste');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Opp RT Teste',
            StageName = getAnyOpportunityStage(),
            CloseDate = Date.today().addDays(15),
            AccountId = acc.Id,
            Servico__c = getAnyMappedService('Monitoramento_Remoto')
        );
        insert opp;

        System.assertEquals('Monitoramento_Remoto', getRecordTypeDeveloperName(opp.Id));

        opp.Servico__c = getAnyMappedService('Elaboracao_de_Parecer');
        update opp;

        System.assertEquals('Elaboracao_de_Parecer', getRecordTypeDeveloperName(opp.Id));
    }

    @IsTest
    static void testUnmappedServiceKeepsCurrentRecordType() {
        Account acc = new Account(Name = 'Conta RT Unmapped');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Opp RT Unmapped',
            StageName = getAnyOpportunityStage(),
            CloseDate = Date.today().addDays(20),
            AccountId = acc.Id,
            Servico__c = getAnyMappedService('Monitoramento_Remoto')
        );
        insert opp;
        System.assertEquals('Monitoramento_Remoto', getRecordTypeDeveloperName(opp.Id));

        String unmappedService = getAnyUnmappedServiceValue();
        System.assertNotEquals(null, unmappedService, 'Nao foi encontrado servico nao mapeado para validar teste.');

        opp.Servico__c = unmappedService;
        update opp;

        System.assertEquals('Monitoramento_Remoto', getRecordTypeDeveloperName(opp.Id));
    }

    private static String getRecordTypeDeveloperName(Id opportunityId) {
        if (!Opportunity.SObjectType.getDescribe().fields.getMap().containsKey('RecordTypeId')) {
            return null;
        }

        Opportunity opp = [
            SELECT Id, RecordTypeId
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];

        Id recordTypeId = (Id) opp.get('RecordTypeId');
        System.assertNotEquals(null, recordTypeId, 'RecordTypeId nao foi definido na oportunidade.');

        RecordType rt = [
            SELECT DeveloperName
            FROM RecordType
            WHERE Id = :recordTypeId
            LIMIT 1
        ];
        return rt.DeveloperName;
    }

    private static String getAnyMappedService(String expectedRecordTypeDeveloperName) {
        for (Schema.PicklistEntry entry : Opportunity.Servico__c.getDescribe().getPicklistValues()) {
            if (!entry.isActive()) {
                continue;
            }

            String mappedRecordType = OpportunityRecordTypeService.resolveRecordTypeByService(entry.getValue());
            if (mappedRecordType == expectedRecordTypeDeveloperName) {
                return entry.getValue();
            }
        }

        System.assert(false, 'Servico mapeado nao encontrado para record type: ' + expectedRecordTypeDeveloperName);
        return null;
    }

    private static String getAnyUnmappedServiceValue() {
        for (Schema.PicklistEntry entry : Opportunity.Servico__c.getDescribe().getPicklistValues()) {
            if (!entry.isActive()) {
                continue;
            }

            if (OpportunityRecordTypeService.resolveRecordTypeByService(entry.getValue()) == null) {
                return entry.getValue();
            }
        }

        return null;
    }

    private static String getAnyOpportunityStage() {
        for (Schema.PicklistEntry entry : Opportunity.StageName.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                return entry.getValue();
            }
        }
        return 'Prospecting';
    }
}
