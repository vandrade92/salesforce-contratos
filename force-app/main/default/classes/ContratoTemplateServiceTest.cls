@IsTest
private class ContratoTemplateServiceTest {
    @TestSetup
    static void setupData() {
        String oppServicoMonitoramento = getRequiredServiceValue(
            new List<String>{ 'Monitoramento Remoto' },
            'monitoramento'
        );
        String oppServicoDiagnostico = getRequiredServiceValue(
            new List<String>{ 'Diagnóstico de Contrato', 'Diagnóstico + Pleito' },
            'diagnostico'
        );

        String origemMonitoramento = getRequiredPicklistValue(
            Contrato_Padrao__c.Servico_Origem__c.getDescribe(),
            'monitoramento',
            'Contrato_Padrao__c.Servico_Origem__c'
        );
        String origemDiagnostico = getRequiredPicklistValue(
            Contrato_Padrao__c.Servico_Origem__c.getDescribe(),
            'diagnostico',
            'Contrato_Padrao__c.Servico_Origem__c'
        );
        String origemParecer = getRequiredPicklistValue(
            Contrato_Padrao__c.Servico_Origem__c.getDescribe(),
            'parecer',
            'Contrato_Padrao__c.Servico_Origem__c'
        );

        String tipoMonitoramento = getRequiredPicklistValue(
            Contrato__c.Tipo_Contrato__c.getDescribe(),
            'monitoramento',
            'Contrato__c.Tipo_Contrato__c'
        );
        String tipoDiagnostico = getRequiredPicklistValue(
            Contrato__c.Tipo_Contrato__c.getDescribe(),
            'diagnostico',
            'Contrato__c.Tipo_Contrato__c'
        );
        String tipoParecer = getRequiredPicklistValue(
            Contrato__c.Tipo_Contrato__c.getDescribe(),
            'parecer',
            'Contrato__c.Tipo_Contrato__c'
        );

        Account acc = new Account(
            Name = 'Cliente Exemplo LTDA',
            CNPJ__c = '12.345.678/0001-99',
            BillingStreet = 'Rua A, 100',
            BillingCity = 'Belo Horizonte',
            BillingState = 'MG',
            BillingPostalCode = '30100-000',
            Phone = '3130000000'
        );
        insert acc;

        Contact con = new Contact(
            LastName = 'Representante',
            AccountId = acc.Id,
            Email = 'representante@cliente.com',
            Phone = '31999999999',
            Title = 'Diretor'
        );
        insert con;

        Opportunity oppMonitoramento = new Opportunity(
            Name = 'Opp Monitoramento',
            StageName = getAnyOpportunityStage(),
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id,
            Servico__c = oppServicoMonitoramento,
            Contato_Contrato__c = con.Id,
            Proposta__c = 150000,
            Data_Envio_Proposta__c = Date.today(),
            Amount = 150000,
            Dona_da_Obra__c = 'Usina Exemplo',
            Municipio_Obra__c = 'Nova Lima',
            Prazo_Parecer_Dias__c = 20,
            Prazo_Parecer_Dias_Extenso__c = 'vinte',
            Prazo_Minimo_Pleito_Dias__c = 45,
            Prazo_Pagamento_Dias__c = 15,
            Valor_Unico_Pleito__c = 25000,
            Taxa_Sucesso_Pleito__c = 12.5,
            Quantidade_Visitas__c = 2,
            Valor_Mensal_Monitoramento__c = 12000,
            Data_Assinatura_Contrato__c = Date.today().addDays(1)
        );

        Opportunity oppDiagnostico = new Opportunity(
            Name = 'Opp Diagnostico',
            StageName = getAnyOpportunityStage(),
            CloseDate = Date.today().addDays(15),
            AccountId = acc.Id,
            Servico__c = oppServicoDiagnostico,
            Contato_Contrato__c = con.Id,
            Proposta__c = 85000,
            Data_Envio_Proposta__c = Date.today(),
            Amount = 85000,
            Dona_da_Obra__c = 'Obra Diagnostico',
            Municipio_Obra__c = 'Contagem',
            Prazo_Parecer_Dias__c = 30,
            Prazo_Parecer_Dias_Extenso__c = 'trinta',
            Prazo_Minimo_Pleito_Dias__c = 60,
            Prazo_Pagamento_Dias__c = 12,
            Valor_Unico_Pleito__c = 30000,
            Taxa_Sucesso_Pleito__c = 10,
            Data_Assinatura_Contrato__c = Date.today().addDays(2)
        );

        insert new List<Opportunity>{ oppMonitoramento, oppDiagnostico };

        Contrato_Padrao__c templateMonitoramento = new Contrato_Padrao__c(
            Name = tipoMonitoramento,
            Ativo__c = true,
            Servico_Origem__c = origemMonitoramento,
            Versao__c = 1
        );
        insert templateMonitoramento;

        Contrato_Padrao__c templateDiagnostico = new Contrato_Padrao__c(
            Name = tipoDiagnostico,
            Ativo__c = true,
            Servico_Origem__c = origemDiagnostico,
            Versao__c = 1
        );
        insert templateDiagnostico;

        Contrato_Padrao__c templateParecer = new Contrato_Padrao__c(
            Name = tipoParecer,
            Ativo__c = true,
            Servico_Origem__c = origemParecer,
            Versao__c = 1
        );
        insert templateParecer;

        insert new List<Clausula_Padrao__c>{
            new Clausula_Padrao__c(
                Contrato_Padrao__c = templateMonitoramento.Id,
                Secao__c = '1',
                Titulo__c = 'OBJETO',
                Ordem__c = 1,
                Texto_Base__c = 'Texto base junto a XXXXXX',
                Obrigatoria__c = true,
                Ativa__c = true
            ),
            new Clausula_Padrao__c(
                Contrato_Padrao__c = templateMonitoramento.Id,
                Secao__c = '2',
                Titulo__c = 'REMUNERACAO E FORMA DE PAGAMENTO',
                Ordem__c = 2,
                Texto_Base__c = 'Prazo XXXXXX valor XXXXXX taxa XXXXXX',
                Obrigatoria__c = true,
                Ativa__c = true
            ),
            new Clausula_Padrao__c(
                Contrato_Padrao__c = templateDiagnostico.Id,
                Secao__c = '1',
                Titulo__c = 'Escopo Diagnostico',
                Ordem__c = 1,
                Texto_Base__c = 'Texto diagnostico',
                Obrigatoria__c = true,
                Ativa__c = true
            ),
            new Clausula_Padrao__c(
                Contrato_Padrao__c = templateParecer.Id,
                Secao__c = '1',
                Titulo__c = 'Escopo Parecer',
                Ordem__c = 1,
                Texto_Base__c = 'Texto parecer',
                Obrigatoria__c = true,
                Ativa__c = true
            )
        };
    }

    @IsTest
    static void testInitializationOnInsert() {
        String tipoMonitoramento = getRequiredPicklistValue(
            Contrato__c.Tipo_Contrato__c.getDescribe(),
            'monitoramento',
            'Contrato__c.Tipo_Contrato__c'
        );

        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            WHERE Name = 'Opp Monitoramento'
            LIMIT 1
        ];

        Contrato__c contrato = new Contrato__c(
            Oportunidade__c = opp.Id
        );

        Test.startTest();
        insert contrato;
        Test.stopTest();

        Contrato__c persisted = [
            SELECT Id,
                   Inicializado__c,
                   Tipo_Contrato__c,
                   Contrato_Padrao__c,
                   Contratante_Razao_Social__c,
                   Contratante_CNPJ__c,
                   Contratante_Email__c,
                   Numero_Proposta__c,
                   Valor_Total_Servico__c,
                   Dona_da_Obra__c,
                   Municipio_Obra__c,
                   Prazo_Minimo_Pleito_Dias__c,
                   Prazo_Pagamento_Dias__c,
                   Valor_Unico_Pleito__c,
                   Taxa_Sucesso_Pleito__c,
                   Quantidade_Visitas__c,
                   Valor_Mensal_Monitoramento__c
            FROM Contrato__c
            WHERE Id = :contrato.Id
            LIMIT 1
        ];

        System.assertEquals(true, persisted.Inicializado__c);
        System.assertEquals(tipoMonitoramento, persisted.Tipo_Contrato__c);
        System.assertNotEquals(null, persisted.Contrato_Padrao__c);
        System.assertEquals('Cliente Exemplo LTDA', persisted.Contratante_Razao_Social__c);
        System.assertEquals('12.345.678/0001-99', persisted.Contratante_CNPJ__c);
        System.assertEquals('representante@cliente.com', persisted.Contratante_Email__c);
        System.assertNotEquals(null, persisted.Numero_Proposta__c);
        System.assertEquals(150000, persisted.Valor_Total_Servico__c);
        System.assertEquals('Usina Exemplo', persisted.Dona_da_Obra__c);
        System.assertEquals('Nova Lima', persisted.Municipio_Obra__c);
        System.assertEquals(45, persisted.Prazo_Minimo_Pleito_Dias__c);
        System.assertEquals(15, persisted.Prazo_Pagamento_Dias__c);
        System.assertEquals(25000, persisted.Valor_Unico_Pleito__c);
        System.assertEquals(12.5, persisted.Taxa_Sucesso_Pleito__c);
        System.assertEquals(2, persisted.Quantidade_Visitas__c);
        System.assertEquals(12000, persisted.Valor_Mensal_Monitoramento__c);

        List<Clausula__c> clauses = [
            SELECT Ordem__c, Titulo__c, Texto__c
            FROM Clausula__c
            WHERE Contrato__c = :persisted.Id
            ORDER BY Ordem__c ASC
        ];

        System.assertEquals(2, clauses.size());
        System.assertEquals(1, clauses[0].Ordem__c);
        System.assertEquals(false, clauses[0].Texto__c.contains('XXXX'));
        System.assert(clauses[0].Texto__c.contains('Usina Exemplo'));
        System.assertEquals(false, clauses[1].Texto__c.contains('XXXX'));
    }

    @IsTest
    static void testManualOverrideIsKept() {
        String tipoMonitoramento = getRequiredPicklistValue(
            Contrato__c.Tipo_Contrato__c.getDescribe(),
            'monitoramento',
            'Contrato__c.Tipo_Contrato__c'
        );

        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            WHERE Name = 'Opp Monitoramento'
            LIMIT 1
        ];

        Contrato_Padrao__c monitoramentoTemplate = [
            SELECT Id
            FROM Contrato_Padrao__c
            WHERE Name = :tipoMonitoramento
            LIMIT 1
        ];

        Id monitoramentoRecordTypeId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Contrato__c'
              AND DeveloperName = 'Monitoramento_Remoto'
            LIMIT 1
        ].Id;

        Contrato__c contrato = new Contrato__c(
            Oportunidade__c = opp.Id,
            Tipo_Contrato__c = tipoMonitoramento,
            Contrato_Padrao__c = monitoramentoTemplate.Id
        );
        contrato.put('RecordTypeId', monitoramentoRecordTypeId);

        Test.startTest();
        insert contrato;
        Test.stopTest();

        Contrato__c persisted = [
            SELECT Tipo_Contrato__c, Contrato_Padrao__c
            FROM Contrato__c
            WHERE Id = :contrato.Id
            LIMIT 1
        ];

        System.assertEquals(tipoMonitoramento, persisted.Tipo_Contrato__c);
        System.assertEquals(monitoramentoTemplate.Id, persisted.Contrato_Padrao__c);

        Integer expectedClauseCount = [
            SELECT COUNT()
            FROM Clausula_Padrao__c
            WHERE Contrato_Padrao__c = :monitoramentoTemplate.Id
              AND Ativa__c = true
        ];

        Integer clauseCount = [
            SELECT COUNT()
            FROM Clausula__c
            WHERE Contrato__c = :contrato.Id
        ];
        System.assertEquals(expectedClauseCount, clauseCount);
    }

    @IsTest
    static void testReloadClauses() {
        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            WHERE Name = 'Opp Monitoramento'
            LIMIT 1
        ];

        Contrato__c contrato = new Contrato__c(
            Oportunidade__c = opp.Id
        );
        insert contrato;

        List<Clausula__c> originalClauses = [
            SELECT Id, Texto__c
            FROM Clausula__c
            WHERE Contrato__c = :contrato.Id
            ORDER BY Ordem__c ASC
        ];
        System.assertEquals(2, originalClauses.size());

        originalClauses[0].Texto__c = 'Texto alterado manualmente';
        originalClauses[0].Editada__c = true;
        update originalClauses[0];

        Test.startTest();
        ContratoTemplateService.reloadClauses(new Set<Id>{ contrato.Id });
        Test.stopTest();

        List<Clausula__c> reloadedClauses = [
            SELECT Texto__c, Editada__c
            FROM Clausula__c
            WHERE Contrato__c = :contrato.Id
            ORDER BY Ordem__c ASC
        ];

        System.assertEquals(2, reloadedClauses.size());
        System.assertEquals(false, reloadedClauses[0].Texto__c.contains('XXXX'));
        System.assert(reloadedClauses[0].Texto__c.contains('Usina Exemplo'));
        System.assertEquals(false, reloadedClauses[0].Editada__c);
    }

    @IsTest
    static void testReinitializeOnContextChangeUpdate() {
        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            WHERE Name = 'Opp Monitoramento'
            LIMIT 1
        ];

        Contrato__c contrato = new Contrato__c(
            Oportunidade__c = opp.Id
        );
        insert contrato;

        Contrato__c persisted = [
            SELECT Id, Inicializado__c
            FROM Contrato__c
            WHERE Id = :contrato.Id
            LIMIT 1
        ];
        System.assertEquals(true, persisted.Inicializado__c);

        persisted.Inicializado__c = false;
        update persisted;

        Contrato__c refreshed = [
            SELECT Inicializado__c
            FROM Contrato__c
            WHERE Id = :contrato.Id
            LIMIT 1
        ];
        System.assertEquals(true, refreshed.Inicializado__c);
    }

    @IsTest
    static void testApplyDynamicPlaceholdersForParecer() {
        String tipoParecer = getRequiredPicklistValue(
            Contrato__c.Tipo_Contrato__c.getDescribe(),
            'parecer',
            'Contrato__c.Tipo_Contrato__c'
        );

        Contrato__c contrato = new Contrato__c(
            Tipo_Contrato__c = tipoParecer,
            Contratante_Razao_Social__c = 'Cliente Alpha',
            Dona_da_Obra__c = 'Usina Beta',
            Municipio_Obra__c = 'Ipatinga',
            Prazo_Parecer_Dias__c = 30,
            Prazo_Parecer_Dias_Extenso__c = 'trinta',
            Contratante_Cidade__c = 'Belo Horizonte',
            Data_Assinatura_Contrato__c = Date.newInstance(2026, 3, 17)
        );

        String textoObjeto = ContratoTemplateService.applyDynamicPlaceholders(
            'Operacoes da XXXX junto a XXXX no municipio de XXXX',
            'OBJETO',
            contrato,
            null
        );
        System.assertEquals('Operacoes da Cliente Alpha junto a Usina Beta no municipio de Ipatinga', textoObjeto);

        String textoPrazo = ContratoTemplateService.applyDynamicPlaceholders(
            'Prazo de ate XXXX (XXXX) dias',
            'PRAZO',
            contrato,
            null
        );
        System.assertEquals('Prazo de ate 30 (trinta) dias', textoPrazo);
    }

    @IsTest
    static void testApplyDynamicPlaceholdersForPrazoPagamento() {
        Contrato__c contrato = new Contrato__c(
            Prazo_Pagamento_Dias__c = 10
        );

        String textoPagamento = ContratoTemplateService.applyDynamicPlaceholders(
            'O valor sera pago em ate XX dias apos emissao da nota fiscal.',
            'FORMA DE PAGAMENTO',
            contrato,
            null
        );

        System.assertEquals('O valor sera pago em ate 10 dias apos emissao da nota fiscal.', textoPagamento);
    }

    @IsTest
    static void testUnmappedServiceBlocksContractInsert() {
        Account acc = new Account(
            Name = 'Conta sem mapeamento',
            CNPJ__c = '11.111.111/0001-11'
        );
        insert acc;

        Contact con = new Contact(
            LastName = 'Contato sem mapeamento',
            AccountId = acc.Id
        );
        insert con;

        String unmappedService = getAnyUnmappedServiceValue();
        System.assertNotEquals(null, unmappedService, 'Nao foi encontrado servico nao mapeado para teste.');

        Opportunity opp = new Opportunity(
            Name = 'Opp Sem Mapeamento',
            StageName = getAnyOpportunityStage(),
            CloseDate = Date.today().addDays(7),
            AccountId = acc.Id,
            Servico__c = unmappedService,
            Contato_Contrato__c = con.Id,
            Proposta__c = 50000,
            Data_Envio_Proposta__c = Date.today(),
            Amount = 50000,
            Dona_da_Obra__c = 'Obra Teste',
            Municipio_Obra__c = 'Belo Horizonte',
            Data_Assinatura_Contrato__c = Date.today()
        );
        insert opp;

        Test.startTest();
        try {
            insert new Contrato__c(Oportunidade__c = opp.Id);
            System.assert(false, 'Era esperado bloqueio por servico nao mapeado.');
        } catch (DmlException ex) {
            System.assert(ex.getMessage().contains('nao mapeado'));
        }
        Test.stopTest();
    }

    @IsTest
    static void testMissingRequiredOpportunityFieldsBlocksContractInsert() {
        String monitoramento = getRequiredServiceValue(
            new List<String>{ 'Monitoramento Remoto' },
            'monitoramento'
        );

        Account acc = new Account(
            Name = 'Conta campos obrigatorios',
            CNPJ__c = '22.222.222/0001-22'
        );
        insert acc;

        Contact con = new Contact(
            LastName = 'Contato campos obrigatorios',
            AccountId = acc.Id
        );
        insert con;

        Opportunity opp = new Opportunity(
            Name = 'Opp Campos Faltantes',
            StageName = getAnyOpportunityStage(),
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id,
            Servico__c = monitoramento,
            Contato_Contrato__c = con.Id,
            Proposta__c = 70000,
            Data_Envio_Proposta__c = Date.today(),
            Amount = 70000,
            Dona_da_Obra__c = 'Obra X',
            Municipio_Obra__c = 'Contagem',
            Data_Assinatura_Contrato__c = Date.today()
        );
        insert opp;

        Test.startTest();
        try {
            insert new Contrato__c(Oportunidade__c = opp.Id);
            System.assert(false, 'Era esperado bloqueio por campos obrigatorios faltantes.');
        } catch (DmlException ex) {
            System.assert(ex.getMessage().contains('Preencha os campos obrigatorios na Oportunidade'));
            System.assert(ex.getMessage().contains('Quantidade de Visitas'));
            System.assert(ex.getMessage().contains('Valor Mensal Monitoramento'));
        }
        Test.stopTest();
    }

    private static String getRequiredPicklistValue(
        Schema.DescribeFieldResult fieldDescribe,
        String category,
        String fieldName
    ) {
        String value = findPicklistValueByCategory(fieldDescribe, category);
        System.assertNotEquals(
            null,
            value,
            'Valor de picklist nao encontrado para categoria "' + category + '" em ' + fieldName
        );
        return value;
    }

    private static String getRequiredServiceValue(List<String> preferredValues, String category) {
        Schema.DescribeFieldResult describeField = Opportunity.Servico__c.getDescribe();
        for (String preferredValue : preferredValues) {
            for (Schema.PicklistEntry entry : describeField.getPicklistValues()) {
                if (entry.isActive() && entry.getValue() == preferredValue) {
                    return entry.getValue();
                }
            }
        }

        return getRequiredPicklistValue(describeField, category, 'Opportunity.Servico__c');
    }

    private static String getAnyUnmappedServiceValue() {
        Set<String> mappedValues = new Set<String>{
            'Monitoramento Remoto',
            'Assist. Téc. em Processo Judicial',
            'Ação Judicial',
            'Elaboração de Parecer Técnico',
            'Diagnóstico de Contrato',
            'Diagnóstico + Pleito'
        };

        for (Schema.PicklistEntry entry : Opportunity.Servico__c.getDescribe().getPicklistValues()) {
            if (!entry.isActive()) {
                continue;
            }
            if (!mappedValues.contains(entry.getValue())) {
                return entry.getValue();
            }
        }

        return null;
    }

    private static String findPicklistValueByCategory(
        Schema.DescribeFieldResult fieldDescribe,
        String category
    ) {
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            if (!entry.isActive()) {
                continue;
            }

            if (category == detectCategory(entry.getValue())) {
                return entry.getValue();
            }
        }

        return null;
    }

    private static String detectCategory(String input) {
        String normalized = normalizeText(input);
        if (String.isBlank(normalized)) {
            return null;
        }

        if (normalized.contains('monitoramento')) {
            return 'monitoramento';
        }
        if (normalized.contains('parecer')) {
            return 'parecer';
        }
        if (normalized.contains('diagn')) {
            return 'diagnostico';
        }
        if (normalized.contains('judicial') || normalized.contains('assist') || normalized.contains('processo')) {
            return 'assistencia';
        }

        return null;
    }

    private static String normalizeText(String input) {
        if (String.isBlank(input)) {
            return '';
        }

        String output = input.toLowerCase();
        output = output.replace('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡', 'a').replace('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ', 'a').replace('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢', 'a').replace('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â£', 'a').replace('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¤', 'a');
        output = output.replace('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©', 'e').replace('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¨', 'e').replace('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Âª', 'e').replace('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â«', 'e');
        output = output.replace('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â­', 'i').replace('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬', 'i').replace('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â®', 'i').replace('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¯', 'i');
        output = output.replace('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â³', 'o').replace('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â²', 'o').replace('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â´', 'o').replace('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Âµ', 'o').replace('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¶', 'o');
        output = output.replace('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Âº', 'u').replace('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¹', 'u').replace('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â»', 'u').replace('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¼', 'u');
        output = output.replace('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â§', 'c');
        output = output.replaceAll('[^a-z0-9+ ]', ' ');
        output = output.replaceAll('\\s+', ' ').trim();

        return output;
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
