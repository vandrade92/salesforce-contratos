@IsTest
private class ContratoControllersTest {
    @TestSetup
    static void setupData() {
        String oppServicoParecer = getRequiredPicklistValue(
            Opportunity.Servico__c.getDescribe(),
            'monitoramento',
            'Opportunity.Servico__c'
        );
        String origemParecer = getRequiredPicklistValue(
            Contrato_Padrao__c.Servico_Origem__c.getDescribe(),
            'monitoramento',
            'Contrato_Padrao__c.Servico_Origem__c'
        );
        Account acc = new Account(
            Name = 'Cliente VF LTDA',
            CNPJ__c = '98.765.432/0001-11',
            BillingStreet = 'Av. B, 200',
            BillingCity = 'Sao Paulo',
            BillingState = 'SP',
            BillingPostalCode = '01000-000',
            Phone = '1130000000'
        );
        insert acc;

        Contact con = new Contact(
            LastName = 'Contato VF',
            AccountId = acc.Id,
            Email = 'contato@vf.com',
            Phone = '11977777777',
            Title = 'Gerente'
        );
        insert con;

        Opportunity opp = new Opportunity(
            Name = 'Opp Parecer VF',
            StageName = getAnyOpportunityStage(),
            CloseDate = Date.today().addDays(20),
            AccountId = acc.Id,
            Servico__c = oppServicoParecer,
            Contato_Contrato__c = con.Id,
            Proposta__c = 99000,
            Data_Envio_Proposta__c = Date.today(),
            Amount = 99000,
            Dona_da_Obra__c = 'Projeto Teste',
            Municipio_Obra__c = 'Sao Paulo',
            Prazo_Minimo_Pleito_Dias__c = 30,
            Prazo_Pagamento_Dias__c = 15,
            Valor_Unico_Pleito__c = 10000,
            Taxa_Sucesso_Pleito__c = 5,
            Quantidade_Visitas__c = 1,
            Valor_Mensal_Monitoramento__c = 5000,
            Data_Assinatura_Contrato__c = Date.today().addDays(1)
        );
        insert opp;

        Contrato_Padrao__c template = new Contrato_Padrao__c(
            Name = 'Template Monitoramento',
            Ativo__c = true,
            Servico_Origem__c = origemParecer,
            Versao__c = 1
        );
        insert template;

        insert new Clausula_Padrao__c(
            Contrato_Padrao__c = template.Id,
            Secao__c = '1',
            Titulo__c = 'Objeto',
            Ordem__c = 1,
            Texto_Base__c = 'Linha 1\nLinha 2',
            Obrigatoria__c = true,
            Ativa__c = true
        );

        Contrato__c contrato = new Contrato__c(
            Oportunidade__c = opp.Id,
            Contrato_Padrao__c = template.Id,
            Observacoes_Contrato__c = 'Observacao de teste'
        );
        insert contrato;
    }

    @IsTest
    static void testPdfControllerLoadsContractAndClauses() {
        Contrato__c contrato = [SELECT Id FROM Contrato__c LIMIT 1];

        Test.setCurrentPage(Page.ContratoPdf);
        ApexPages.currentPage().getParameters().put('id', contrato.Id);

        Test.startTest();
        ContratoPdfController ctrl = new ContratoPdfController();
        Test.stopTest();

        System.assertNotEquals(null, ctrl.contrato);
        System.assertEquals(1, ctrl.clausulas.size());
        System.assertNotEquals(null, ctrl.getNumeroContrato());
    }

    @IsTest
    static void testPdfControllerBranchesAndHtmlHelper() {
        Contrato__c contrato = [
            SELECT Id, Name
            FROM Contrato__c
            LIMIT 1
        ];
        contrato.Numero_Contrato_Externo__c = 'EXT-001';
        contrato.Numero_Proposta__c = '180000';
        contrato.Data_Base__c = Date.newInstance(2026, 3, 10);
        update contrato;

        Test.setCurrentPage(Page.ContratoPdf);
        ApexPages.currentPage().getParameters().put('id', contrato.Id);
        ContratoPdfController withId = new ContratoPdfController();

        System.assertEquals('EXT-001', withId.getNumeroContrato());
        System.assertEquals(contrato.Name, withId.getNumeroContratoCabecalho());
        System.assertEquals('180000_2026', withId.getNumeroPropostaCabecalho());
        System.assertEquals('A&lt;B<br/>C', withId.toHtml('A<B\nC'));
        System.assertEquals('', withId.toHtml(null));
        System.assertNotEquals(null, withId.getDataGeracao());

        Test.setCurrentPage(Page.ContratoPdf);
        ContratoPdfController withoutId = new ContratoPdfController();
        System.assertEquals(null, withoutId.contrato);
        System.assertEquals(0, withoutId.clausulas.size());
        System.assertEquals(null, withoutId.getNumeroContrato());
        System.assertEquals(null, withoutId.getNumeroContratoCabecalho());
        System.assertEquals(null, withoutId.getNumeroPropostaCabecalho());
    }

    @IsTest
    static void testPdfControllerInlineSubtitleUsesNestedNumbering() {
        Contrato__c contrato = [SELECT Id FROM Contrato__c LIMIT 1];

        Clausula__c clause = [
            SELECT Id, Texto__c
            FROM Clausula__c
            WHERE Contrato__c = :contrato.Id
            LIMIT 1
        ];
        clause.Texto__c =
            'Forma de Pagamento\n' +
            'O valor sera pago conforme condicoes comerciais.\n' +
            'Mora\n' +
            'Havendo atraso de pagamento acima de 05 dias uteis.\n' +
            'O pagamento da multa sera devido no documento subsequente.';
        update clause;

        Test.setCurrentPage(Page.ContratoPdf);
        ApexPages.currentPage().getParameters().put('id', contrato.Id);

        ContratoPdfController ctrl = new ContratoPdfController();

        System.assert(ctrl.clauseViews.size() > 0);
        ContratoPdfController.ClauseView view = ctrl.clauseViews[0];
        System.assertEquals(5, view.lines.size());
        System.assertEquals('1.1.', view.lines[0].prefix);
        System.assertEquals('1.1.1.', view.lines[1].prefix);
        System.assertEquals('1.2.', view.lines[2].prefix);
        System.assertEquals('1.2.1.', view.lines[3].prefix);
        System.assertEquals('1.2.2.', view.lines[4].prefix);
    }

    @IsTest
    static void testPdfControllerReplacesPrazoPagamentoPlaceholder() {
        Contrato__c contrato = [
            SELECT Id, Prazo_Pagamento_Dias__c
            FROM Contrato__c
            LIMIT 1
        ];
        contrato.Prazo_Pagamento_Dias__c = 12;
        update contrato;

        Clausula__c clause = [
            SELECT Id, Titulo__c, Texto__c
            FROM Clausula__c
            WHERE Contrato__c = :contrato.Id
            LIMIT 1
        ];
        clause.Titulo__c = 'Forma de Pagamento';
        clause.Texto__c = 'Pagamento em ate XX dias apos emissao da nota fiscal.';
        update clause;

        Test.setCurrentPage(Page.ContratoPdf);
        ApexPages.currentPage().getParameters().put('id', contrato.Id);

        ContratoPdfController ctrl = new ContratoPdfController();
        System.assert(ctrl.clauseViews.size() > 0);
        System.assertEquals('Pagamento em ate 12 dias apos emissao da nota fiscal.', ctrl.clauseViews[0].lines[0].text);
    }

    @IsTest
    static void testPdfControllerReplacesPrazoPagamentoFromOpportunityFallback() {
        Opportunity opp = [
            SELECT Id, Prazo_Pagamento_Dias__c
            FROM Opportunity
            LIMIT 1
        ];
        opp.Prazo_Pagamento_Dias__c = 30;
        update opp;

        Contrato__c contrato = [
            SELECT Id, Oportunidade__c, Prazo_Pagamento_Dias__c
            FROM Contrato__c
            LIMIT 1
        ];
        contrato.Oportunidade__c = opp.Id;
        contrato.Prazo_Pagamento_Dias__c = null;
        update contrato;

        Clausula__c clause = [
            SELECT Id, Titulo__c, Texto__c
            FROM Clausula__c
            WHERE Contrato__c = :contrato.Id
            LIMIT 1
        ];
        clause.Titulo__c = 'Forma de Pagamento';
        clause.Texto__c = 'Pagamento em ate XX dias apos emissao da nota fiscal.';
        update clause;

        Test.setCurrentPage(Page.ContratoPdf);
        ApexPages.currentPage().getParameters().put('id', contrato.Id);

        ContratoPdfController ctrl = new ContratoPdfController();
        System.assert(ctrl.clauseViews.size() > 0);
        System.assertEquals('Pagamento em ate 30 dias apos emissao da nota fiscal.', ctrl.clauseViews[0].lines[0].text);
    }

    @IsTest
    static void testPdfControllerReplacesBracketPlaceholdersFromContratoData() {
        Contrato__c contrato = [
            SELECT Id,
                   Oportunidade__c,
                   Prazo_Minimo_Pleito_Dias__c,
                   Valor_Unico_Pleito__c,
                   Taxa_Sucesso_Pleito__c,
                   Dona_da_Obra__c,
                   Municipio_Obra__c
            FROM Contrato__c
            LIMIT 1
        ];
        contrato.Prazo_Minimo_Pleito_Dias__c = 35;
        contrato.Valor_Unico_Pleito__c = 25000;
        contrato.Taxa_Sucesso_Pleito__c = 12.5;
        contrato.Dona_da_Obra__c = 'Cliente Final XPTO';
        contrato.Municipio_Obra__c = 'Curitiba';
        update contrato;

        Clausula__c clause = [
            SELECT Id, Titulo__c, Texto__c
            FROM Clausula__c
            WHERE Contrato__c = :contrato.Id
            LIMIT 1
        ];
        clause.Titulo__c = 'Objeto';
        clause.Texto__c =
            'Prazo minimo de [inserir numero de dias] corridos.\n' +
            'Valor unico de [inserir valor] e taxa de [inserir porcentagem].\n' +
            'Cliente final: [inserir nome do cliente final] no municipio de [inserir nome do municipio].';
        update clause;

        Test.setCurrentPage(Page.ContratoPdf);
        ApexPages.currentPage().getParameters().put('id', contrato.Id);

        ContratoPdfController ctrl = new ContratoPdfController();
        System.assert(ctrl.clauseViews.size() > 0);
        System.assertEquals(3, ctrl.clauseViews[0].lines.size());
        System.assertEquals('Prazo minimo de 35 corridos.', ctrl.clauseViews[0].lines[0].text);
        System.assert(ctrl.clauseViews[0].lines[1].text.contains('R$'));
        System.assert(ctrl.clauseViews[0].lines[1].text.contains('12'));
        System.assert(ctrl.clauseViews[0].lines[1].text.contains('%'));
        System.assert(ctrl.clauseViews[0].lines[2].text.contains('Cliente Final XPTO'));
        System.assert(ctrl.clauseViews[0].lines[2].text.contains('Curitiba'));
        System.assertEquals(-1, ctrl.clauseViews[0].lines[2].text.indexOf('[inserir'));
    }

    @IsTest
    static void testPdfControllerBracketPlaceholderSpacingAndMunicipioAccent() {
        Contrato__c contrato = [
            SELECT Id,
                   Dona_da_Obra__c,
                   Municipio_Obra__c,
                   Taxa_Sucesso_Pleito__c
            FROM Contrato__c
            LIMIT 1
        ];
        contrato.Dona_da_Obra__c = 'Cliente Final XPTO';
        contrato.Municipio_Obra__c = 'Belo Horizonte';
        contrato.Taxa_Sucesso_Pleito__c = 4.2;
        update contrato;

        Clausula__c clause = [
            SELECT Id, Titulo__c, Texto__c
            FROM Clausula__c
            WHERE Contrato__c = :contrato.Id
            LIMIT 1
        ];
        clause.Titulo__c = 'Objeto';
        clause.Texto__c =
            'Taxa de [inserir porcentagem]sobre o sucesso.\n' +
            'A CONTRATANTE junto Ã [ inserir nome do cliente final ], no municipio de[inserir nome do municÃ­pio].';
        update clause;

        Test.setCurrentPage(Page.ContratoPdf);
        ApexPages.currentPage().getParameters().put('id', contrato.Id);

                ContratoPdfController ctrl = new ContratoPdfController();
        System.assert(ctrl.clauseViews.size() > 0);
        String renderedText = '';
        for (ContratoPdfController.ClauseLineView line : ctrl.clauseViews[0].lines) {
            renderedText += line.text + ' ';
        }
        System.assert(renderedText.contains('%'), renderedText);
        System.assert(renderedText.toLowerCase().contains('sucesso'), renderedText);
        System.assert(renderedText.contains('Cliente Final XPTO'), renderedText);
        System.assert(renderedText.contains('Belo Horizonte'), renderedText);
        System.assertEquals(-1, renderedText.indexOf('[inserir'));
    }

    @IsTest
    static void testPdfControllerOmitsNumberingInSignatureBlock() {
        Contrato__c contrato = [SELECT Id FROM Contrato__c LIMIT 1];

        Clausula__c clause = [
            SELECT Id, Titulo__c, Texto__c
            FROM Clausula__c
            WHERE Contrato__c = :contrato.Id
            LIMIT 1
        ];
        clause.Titulo__c = 'Disposicoes Gerais';
        clause.Texto__c =
            'Lei Aplicavel e Foro. A parte podera acionar no foro competente.\n' +
            'E, ESTANDO ASSIM JUSTAS contratadas, celebram as partes este Contrato.\n' +
            'Nova Lima - MG,16/03/2026.\n' +
            'Parte Contratante:\n' +
            '________________________________________\n' +
            'Testemunhas:\n' +
            'Nome:\n' +
            'RG:\n' +
            'CPF:';
        update clause;

        Test.setCurrentPage(Page.ContratoPdf);
        ApexPages.currentPage().getParameters().put('id', contrato.Id);

        ContratoPdfController ctrl = new ContratoPdfController();
        System.assert(ctrl.clauseViews.size() > 0);

        ContratoPdfController.ClauseView view = ctrl.clauseViews[0];
        System.assertEquals('1.1.', view.lines[0].prefix);
        System.assertEquals('', view.lines[1].prefix);
        System.assertEquals('', view.lines[2].prefix);
        System.assertEquals('', view.lines[3].prefix);
        System.assertEquals('', view.lines[4].prefix);
        System.assertEquals('', view.lines[5].prefix);
        System.assertEquals('', view.lines[6].prefix);
        System.assertEquals('', view.lines[7].prefix);
        System.assertEquals('', view.lines[8].prefix);
    }

        @IsTest
    static void testPdfControllerUsesRomanNumeralsForBulletItems() {
        Contrato__c contrato = [SELECT Id FROM Contrato__c LIMIT 1];

        Clausula__c clause = [
            SELECT Id, Titulo__c, Texto__c
            FROM Clausula__c
            WHERE Contrato__c = :contrato.Id
            LIMIT 1
        ];
        clause.Titulo__c = 'Escopo';
        clause.Texto__c =
            'Considera-se Pleito:\n' +
            '- Solicitar aumento de valores unitarios extraordinarios.\n' +
            '- Solicitar reequilibrio de custos de compressao do cronograma.\n' +
            '- Solicitar prorrogacao de prazo com custos associados.\n' +
            'Sucesso resultado de negociacoes posteriores baseadas no envio dos pleitos;\n' +
            'Reequilibrios decorrentes de impedimentos do Contratante para Faturamento Direto;\n' +
            'Solicitacoes de direito do Contratado por decisao estrategica da construtora.\n' +
            'Nao se considera Pleito:\n' +
            '- Solicitacoes ordinarias de inclusao de servicos extra escopo;\n' +
            '- Reajustes contratuais;\n' +
            '- Ajuste anual de precos contratuais.\n' +
            'Cabera exclusivamente a CONTRATANTE a decisao de elaboracao.';
        update clause;

        Test.setCurrentPage(Page.ContratoPdf);
        ApexPages.currentPage().getParameters().put('id', contrato.Id);

        ContratoPdfController ctrl = new ContratoPdfController();
        System.assert(ctrl.clauseViews.size() > 0);

        ContratoPdfController.ClauseView view = ctrl.clauseViews[0];
        System.assertEquals('1.1.', view.lines[0].prefix);
        System.assertEquals('i.', view.lines[1].prefix);
        System.assertEquals('ii.', view.lines[2].prefix);
        System.assertEquals('iii.', view.lines[3].prefix);
        System.assertEquals('iv.', view.lines[4].prefix);
        System.assertEquals('v.', view.lines[5].prefix);
        System.assertEquals('vi.', view.lines[6].prefix);

        System.assertEquals('1.2.', view.lines[7].prefix);
        System.assertEquals('i.', view.lines[8].prefix);
        System.assertEquals('ii.', view.lines[9].prefix);
        System.assertEquals('iii.', view.lines[10].prefix);
        System.assertEquals('1.3.', view.lines[11].prefix);
    }

    @IsTest
    static void testGenerateDocxCreatesFile() {
        Contrato__c contrato = [
            SELECT Id
            FROM Contrato__c
            LIMIT 1
        ];

        Test.setCurrentPage(Page.ContratoGerarDocx);
        ApexPages.currentPage().getParameters().put('id', contrato.Id);

        Test.startTest();
        ContratoGenerateDocxController controller = new ContratoGenerateDocxController();
        PageReference result = controller.execute();
        Test.stopTest();

        System.assertNotEquals(null, result);

        ContentVersion generated = [
            SELECT Id, PathOnClient
            FROM ContentVersion
            WHERE FirstPublishLocationId = :contrato.Id
            AND PathOnClient LIKE 'Contrato_DOCX_%'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assert(generated.PathOnClient.endsWith('.docx'));

        Integer links = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :contrato.Id
        ];
        System.assert(links > 0);
    }

    @IsTest
    static void testGenerateDocxWithoutIdReturnsNull() {
        Test.setCurrentPage(Page.ContratoGerarDocx);
        ContratoGenerateDocxController controller = new ContratoGenerateDocxController();
        System.assertEquals(null, controller.execute());
    }

    @IsTest
    static void testGenerateFinalVersionCreatesFileAndUpdatesContract() {
        Contrato__c contrato = [
            SELECT Id, Versao_Documento__c
            FROM Contrato__c
            LIMIT 1
        ];

        Test.setCurrentPage(Page.ContratoGerarVersaoFinal);
        ApexPages.currentPage().getParameters().put('id', contrato.Id);

        Test.startTest();
        ContratoGenerateFinalController controller = new ContratoGenerateFinalController();
        PageReference result = controller.execute();
        Test.stopTest();

        System.assertNotEquals(null, result);

        Contrato__c updatedContrato = [
            SELECT Versao_Documento__c, Data_Geracao_Final__c, Arquivo_Final_Id__c
            FROM Contrato__c
            WHERE Id = :contrato.Id
            LIMIT 1
        ];

        System.assertEquals(1, updatedContrato.Versao_Documento__c);
        System.assertNotEquals(null, updatedContrato.Data_Geracao_Final__c);
        System.assertNotEquals(null, updatedContrato.Arquivo_Final_Id__c);

        Integer links = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :contrato.Id
        ];
        System.assert(links > 0);
    }

    @IsTest
    static void testGenerateFinalWithoutIdReturnsNull() {
        Test.setCurrentPage(Page.ContratoGerarVersaoFinal);
        ContratoGenerateFinalController controller = new ContratoGenerateFinalController();
        System.assertEquals(null, controller.execute());
    }

    @IsTest
    static void testReloadControllerRebuildsClauses() {
        Contrato__c contrato = [SELECT Id FROM Contrato__c LIMIT 1];

        Clausula__c clause = [
            SELECT Id, Texto__c
            FROM Clausula__c
            WHERE Contrato__c = :contrato.Id
            LIMIT 1
        ];
        clause.Texto__c = 'Texto customizado para teste';
        update clause;

        Test.setCurrentPage(Page.ContratoRecarregarClausulas);
        ApexPages.currentPage().getParameters().put('id', contrato.Id);

        Test.startTest();
        ContratoReloadClausesController controller = new ContratoReloadClausesController();
        PageReference pr = controller.confirmReload();
        Test.stopTest();

        System.assertNotEquals(null, pr);

        Clausula__c reloaded = [
            SELECT Texto__c
            FROM Clausula__c
            WHERE Contrato__c = :contrato.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals('Linha 1\nLinha 2', reloaded.Texto__c);
    }

    @IsTest
    static void testReloadControllerWithoutIdAndCancelPaths() {
        Test.setCurrentPage(Page.ContratoRecarregarClausulas);
        ContratoReloadClausesController withoutId = new ContratoReloadClausesController();
        System.assertEquals(null, withoutId.confirmReload());
        System.assertEquals('/lightning/page/home', withoutId.cancel().getUrl());

        Contrato__c contrato = [SELECT Id FROM Contrato__c LIMIT 1];
        Test.setCurrentPage(Page.ContratoRecarregarClausulas);
        ApexPages.currentPage().getParameters().put('id', contrato.Id);
        ContratoReloadClausesController withId = new ContratoReloadClausesController();
        System.assertNotEquals(null, withId.cancel());
        System.assert(withId.cancel().getUrl().contains('/' + contrato.Id));
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

        Map<String, String> replacements = new Map<String, String>{
            '??????????????????????????????????????????' => 'a', '??????????????????????????????????????????' => 'a', '??????????????????????????????????????????' => 'a', '??????????????????????????????????????????' => 'a', '??????????????????????????????????????????' => 'a',
            '??????????????????????????????????????????' => 'e', '??????????????????????????????????????????' => 'e', '??????????????????????????????????????????' => 'e', '??????????????????????????????????????????' => 'e',
            '??????????????????????????????????????????' => 'i', '??????????????????????????????????????????' => 'i', '??????????????????????????????????????????' => 'i', '??????????????????????????????????????????' => 'i',
            '??????????????????????????????????????????' => 'o', '??????????????????????????????????????????' => 'o', '??????????????????????????????????????????' => 'o', '??????????????????????????????????????????' => 'o', '??????????????????????????????????????????' => 'o',
            '??????????????????????????????????????????' => 'u', '??????????????????????????????????????????' => 'u', '??????????????????????????????????????????' => 'u', '??????????????????????????????????????????' => 'u',
            '??????????????????????????????????????????' => 'c',
            '???????????????????????????????????????????????????????????????????????????????????????????????' => 'a', '???????????????????????????????????????????????????????????????????????????????????????????????' => 'a', '???????????????????????????????????????????????????????????????????????????????????????????????' => 'a', '???????????????????????????????????????????????????????????????????????????????????????????????' => 'a',
            '???????????????????????????????????????????????????????????????????????????????????????????????' => 'e', '???????????????????????????????????????????????????????????????????????????????????????????????' => 'e',
            '???????????????????????????????????????????????????????????????????????????????????????????????' => 'i',
            '???????????????????????????????????????????????????????????????????????????????????????????????' => 'o', '???????????????????????????????????????????????????????????????????????????????????????????????' => 'o', '???????????????????????????????????????????????????????????????????????????????????????????????' => 'o',
            '???????????????????????????????????????????????????????????????????????????????????????????????' => 'u',
            '???????????????????????????????????????????????????????????????????????????????????????????????' => 'c'
        };

        for (String source : replacements.keySet()) {
            output = output.replace(source, replacements.get(source));
        }

        output = output.replace('??????????????????????????????????????????????????????', '');
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







