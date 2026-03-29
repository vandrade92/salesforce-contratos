public without sharing class ContratoSeedService {
    public class SeedResult {
        public List<Id> contratoIds = new List<Id>();
        public Map<Id, Integer> clauseCountByContrato = new Map<Id, Integer>();
    }

    public static SeedResult createSampleContracts() {
        SeedResult result = new SeedResult();

        Map<String, Id> templateIdByCategory = loadTemplateIdsByCategory();
        Map<String, String> tipoByCategory = loadTipoContratoByCategory();
        Map<String, String> serviceByCategory = loadServiceByCategory();

        String stageName = loadStageName();
        String stamp = Datetime.now().format('yyyyMMddHHmmss') + String.valueOf(Datetime.now().getTime());

        Database.DMLOptions dmlOptions = new Database.DMLOptions();
        dmlOptions.DuplicateRuleHeader.allowSave = true;

        Account acc;
        List<Account> existingAcc = [
            SELECT Id, Name
            FROM Account
            WHERE Name LIKE 'SEED Contratos PDF %'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (!existingAcc.isEmpty()) {
            acc = existingAcc[0];
        } else {
            acc = new Account(
                Name = 'SEED Contratos PDF ' + stamp,
                BillingStreet = 'Rua Teste, 100',
                BillingCity = 'Belo Horizonte',
                BillingState = 'MG',
                BillingPostalCode = '30100-000',
                Phone = '31' + String.valueOf(Math.abs(Crypto.getRandomInteger()))
            );
            acc.setOptions(dmlOptions);
            insert acc;
        }

        Contact con;
        List<Contact> existingCon = [
            SELECT Id, LastName, Email
            FROM Contact
            WHERE AccountId = :acc.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (!existingCon.isEmpty()) {
            con = existingCon[0];
        } else {
            con = new Contact(
                LastName = 'Responsavel Contrato',
                AccountId = acc.Id,
                Email = 'seed.contrato.' + stamp + '@example.com',
                Phone = '31999999999',
                Title = 'Diretor'
            );
            con.setOptions(dmlOptions);
            insert con;
        }

        List<String> categories = new List<String>{'monitoramento','assistencia','parecer','diagnostico'};

        List<Opportunity> opps = new List<Opportunity>();
        Map<String, String> categoryByOppName = new Map<String, String>();
        for (String category : categories) {
            String oppName = 'SEED Opp SYS ' + category + ' ' + stamp;
            Opportunity opp = new Opportunity(
                Name = oppName,
                StageName = stageName,
                CloseDate = Date.today(),
                AccountId = acc.Id,
                Amount = 100000
            );
            String servico = serviceByCategory.get(category);
            if (!String.isBlank(servico)) {
                opp.Servico__c = servico;
            }
            opp.Contato_Contrato__c = con.Id;
            opp.setOptions(dmlOptions);
            opps.add(opp);
            categoryByOppName.put(oppName, category);
        }
        insert opps;

        List<Contrato__c> contratos = new List<Contrato__c>();
        for (Opportunity opp : opps) {
            String category = categoryByOppName.get(opp.Name);
            Contrato__c c = new Contrato__c();
            c.Oportunidade__c = opp.Id;

            Id templateId = templateIdByCategory.get(category);
            if (templateId != null) {
                c.Contrato_Padrao__c = templateId;
            }

            String tipo = tipoByCategory.get(category);
            if (!String.isBlank(tipo)) {
                c.Tipo_Contrato__c = tipo;
            }

            c.setOptions(dmlOptions);
            contratos.add(c);
        }
        insert contratos;

        Set<Id> contratoIds = new Set<Id>();
        for (Contrato__c c : contratos) {
            contratoIds.add(c.Id);
            result.contratoIds.add(c.Id);
        }

        ContratoTemplateService.reloadClauses(contratoIds);

        for (AggregateResult ar : [
            SELECT Contrato__c cId, COUNT(Id) total
            FROM Clausula__c
            WHERE Contrato__c IN :contratoIds
            GROUP BY Contrato__c
        ]) {
            result.clauseCountByContrato.put((Id) ar.get('cId'), (Integer) ar.get('total'));
        }

        return result;
    }

    private static Map<String, Id> loadTemplateIdsByCategory() {
        Map<String, Id> outMap = new Map<String, Id>();
        for (Contrato_Padrao__c template : [SELECT Id, Name, Ativo__c FROM Contrato_Padrao__c WHERE Ativo__c = true]) {
            String category = detectCategory(template.Name);
            if (!String.isBlank(category) && !outMap.containsKey(category)) {
                outMap.put(category, template.Id);
            }
        }
        return outMap;
    }

    private static Map<String, String> loadTipoContratoByCategory() {
        Map<String, String> outMap = new Map<String, String>();
        for (Schema.PicklistEntry pe : Contrato__c.Tipo_Contrato__c.getDescribe().getPicklistValues()) {
            if (!pe.isActive()) continue;
            String category = detectCategory(pe.getValue());
            if (!String.isBlank(category) && !outMap.containsKey(category)) {
                outMap.put(category, pe.getValue());
            }
        }
        return outMap;
    }

    private static Map<String, String> loadServiceByCategory() {
        Map<String, String> outMap = new Map<String, String>();

        String diagnosticoFallback = null;
        for (Schema.PicklistEntry pe : Opportunity.Servico__c.getDescribe().getPicklistValues()) {
            if (!pe.isActive()) continue;
            String value = pe.getValue();
            String category = detectCategory(value);
            if (String.isBlank(category)) continue;

            if (category == 'diagnostico' && normalize(value).contains('pleito')) {
                if (diagnosticoFallback == null) diagnosticoFallback = value;
                continue;
            }

            if (!outMap.containsKey(category)) {
                outMap.put(category, value);
            }
        }

        return outMap;
    }

    private static String loadStageName() {
        for (OpportunityStage st : [
            SELECT MasterLabel, IsWon, SortOrder
            FROM OpportunityStage
            WHERE IsActive = true
            ORDER BY SortOrder ASC
        ]) {
            if (st.IsWon) return st.MasterLabel;
        }

        for (OpportunityStage st : [
            SELECT MasterLabel, SortOrder
            FROM OpportunityStage
            WHERE IsActive = true
            ORDER BY SortOrder ASC
            LIMIT 1
        ]) {
            return st.MasterLabel;
        }

        return 'Prospecting';
    }

    private static String detectCategory(String input) {
        String n = normalize(input);
        if (String.isBlank(n)) return null;
        if (n.contains('monitoramento')) return 'monitoramento';
        if (n.contains('parecer')) return 'parecer';
        if (n.contains('diagn')) return 'diagnostico';
        if (n.contains('judicial') || n.contains('assist') || n.contains('processo')) return 'assistencia';
        return null;
    }

    private static String normalize(String input) {
        if (String.isBlank(input)) return '';
        String outText = input.toLowerCase();
        outText = outText.replaceAll('[^a-z0-9+ ]', ' ');
        outText = outText.replaceAll('\\s+', ' ').trim();
        return outText;
    }
}
