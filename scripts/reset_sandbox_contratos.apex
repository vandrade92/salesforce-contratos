Map<String, String> serviceByCategory = new Map<String, String>();
String diagnosticoComPleito;
for (Schema.PicklistEntry pe : Opportunity.Servico__c.getDescribe().getPicklistValues()) {
    if (!pe.isActive()) {
        continue;
    }

    String value = pe.getValue();
    String normalized = value == null
        ? ''
        : value.toLowerCase().replaceAll('[^a-z0-9+ ]', ' ').replaceAll('\\s+', ' ').trim();

    String category;
    if (normalized.contains('monitoramento')) {
        category = 'monitoramento';
    } else if (normalized.contains('parecer')) {
        category = 'parecer';
    } else if (normalized.contains('diagn')) {
        category = 'diagnostico';
    } else if (normalized.contains('judicial') || normalized.contains('assist') || normalized.contains('processo')) {
        category = 'assistencia';
    } else {
        category = null;
    }

    if (String.isBlank(category)) {
        continue;
    }

    if (category == 'diagnostico' && normalized.contains('pleito')) {
        if (diagnosticoComPleito == null) {
            diagnosticoComPleito = value;
        }
        continue;
    }

    if (!serviceByCategory.containsKey(category)) {
        serviceByCategory.put(category, value);
    }
}
if (!serviceByCategory.containsKey('diagnostico') && diagnosticoComPleito != null) {
    serviceByCategory.put('diagnostico', diagnosticoComPleito);
}

Map<String, String> tipoByCategory = new Map<String, String>();
for (Schema.PicklistEntry pe : Contrato__c.Tipo_Contrato__c.getDescribe().getPicklistValues()) {
    if (!pe.isActive()) {
        continue;
    }

    String value = pe.getValue();
    String normalized = value == null
        ? ''
        : value.toLowerCase().replaceAll('[^a-z0-9+ ]', ' ').replaceAll('\\s+', ' ').trim();

    String category;
    if (normalized.contains('monitoramento')) {
        category = 'monitoramento';
    } else if (normalized.contains('parecer')) {
        category = 'parecer';
    } else if (normalized.contains('diagn')) {
        category = 'diagnostico';
    } else if (normalized.contains('judicial') || normalized.contains('assist') || normalized.contains('processo')) {
        category = 'assistencia';
    } else {
        category = null;
    }

    if (!String.isBlank(category) && !tipoByCategory.containsKey(category)) {
        tipoByCategory.put(category, value);
    }
}

Map<String, Id> templateByCategory = new Map<String, Id>();
for (Contrato_Padrao__c t : [SELECT Id, Name FROM Contrato_Padrao__c WHERE Ativo__c = true]) {
    String normalized = t.Name == null
        ? ''
        : t.Name.toLowerCase().replaceAll('[^a-z0-9+ ]', ' ').replaceAll('\\s+', ' ').trim();

    String category;
    if (normalized.contains('monitoramento')) {
        category = 'monitoramento';
    } else if (normalized.contains('parecer')) {
        category = 'parecer';
    } else if (normalized.contains('diagn')) {
        category = 'diagnostico';
    } else if (normalized.contains('judicial') || normalized.contains('assist') || normalized.contains('processo')) {
        category = 'assistencia';
    } else {
        category = null;
    }

    if (!String.isBlank(category) && !templateByCategory.containsKey(category)) {
        templateByCategory.put(category, t.Id);
    }
}

String wonStage = null;
for (OpportunityStage st : [
    SELECT MasterLabel, IsWon, SortOrder
    FROM OpportunityStage
    WHERE IsActive = true
    ORDER BY SortOrder
]) {
    if (st.IsWon) {
        wonStage = st.MasterLabel;
        break;
    }
}
if (wonStage == null) {
    for (OpportunityStage st : [
        SELECT MasterLabel
        FROM OpportunityStage
        WHERE IsActive = true
        ORDER BY SortOrder
        LIMIT 1
    ]) {
        wonStage = st.MasterLabel;
    }
}
if (wonStage == null) {
    wonStage = 'Prospecting';
}

List<Contrato__c> existingContracts = [SELECT Id FROM Contrato__c];
if (!existingContracts.isEmpty()) {
    Database.delete(existingContracts, false);
}

if (Schema.getGlobalDescribe().containsKey('Propostas__c')) {
    List<SObject> existingPropostas = Database.query('SELECT Id FROM Propostas__c');
    if (!existingPropostas.isEmpty()) {
        Database.delete(existingPropostas, false);
    }
}

List<Opportunity> existingOpps = [SELECT Id FROM Opportunity];
if (!existingOpps.isEmpty()) {
    Database.delete(existingOpps, false);
}

List<Contact> existingSeedContacts = [SELECT Id FROM Contact WHERE Email LIKE 'contrato.%@profitto.teste'];
if (!existingSeedContacts.isEmpty()) {
    Database.delete(existingSeedContacts, false);
}

List<Account> existingSeedAccounts = [SELECT Id FROM Account WHERE Name LIKE 'BASE CONTRATO - %'];
if (!existingSeedAccounts.isEmpty()) {
    Database.delete(existingSeedAccounts, false);
}

List<Map<String, Object>> configs = new List<Map<String, Object>>{
    new Map<String, Object>{
        'category' => 'monitoramento',
        'label' => 'Monitoramento Remoto',
        'accountName' => 'BASE CONTRATO - MONITORAMENTO',
        'cnpj' => '11.111.111/0001-11',
        'street' => 'Av. das Nacoes, 1200 - Sala 101',
        'city' => 'Belo Horizonte',
        'state' => 'MG',
        'postalCode' => '30110-000',
        'accountPhone' => '3133001100',
        'firstName' => 'Carlos',
        'lastName' => 'Menezes',
        'title' => 'Diretor de Contratos',
        'email' => 'contrato.monitoramento@profitto.teste',
        'contactPhone' => '31988881100',
        'cpf' => '123.456.789-00',
        'amount' => 180000,
        'proposta' => 180000,
        'visitas' => 4,
        'valorMensal' => 12000,
        'prazoParecerDias' => 20,
        'prazoParecerExtenso' => 'vinte',
        'prazoMinPleito' => 60,
        'prazoPagamento' => 30,
        'valorPleito' => 85000,
        'taxaSucesso' => 5,
        'donaObra' => 'Complexo Industrial Serra Azul',
        'municipioObra' => 'Nova Lima/MG',
        'modalidade' => 'Mensal (monitoramento remoto) e global (elaboracao de pleitos)',
        'prazoVigencia' => '12 (doze) meses, contados da assinatura.',
        'objeto' => 'Monitoramento remoto com elaboracao de pleitos e relatorios tecnicos.'
    },
    new Map<String, Object>{
        'category' => 'assistencia',
        'label' => 'Assistencia Tecnica Judicial',
        'accountName' => 'BASE CONTRATO - ASSISTENCIA',
        'cnpj' => '22.222.222/0001-22',
        'street' => 'Rua Juridica, 450 - 8o andar',
        'city' => 'Sao Paulo',
        'state' => 'SP',
        'postalCode' => '04567-000',
        'accountPhone' => '1133002200',
        'firstName' => 'Fernanda',
        'lastName' => 'Almeida',
        'title' => 'Gerente Juridico',
        'email' => 'contrato.assistencia@profitto.teste',
        'contactPhone' => '11977772200',
        'cpf' => '234.567.890-11',
        'amount' => 240000,
        'proposta' => 240000,
        'visitas' => 2,
        'valorMensal' => 0,
        'prazoParecerDias' => 25,
        'prazoParecerExtenso' => 'vinte e cinco',
        'prazoMinPleito' => 45,
        'prazoPagamento' => 20,
        'valorPleito' => 95000,
        'taxaSucesso' => 7.5,
        'donaObra' => 'Corredor Logistico Oeste',
        'municipioObra' => 'Campinas/SP',
        'modalidade' => 'Global',
        'prazoVigencia' => '18 (dezoito) meses, contados da assinatura.',
        'objeto' => 'Assistencia tecnica para processo judicial e suporte tecnico especializado.'
    },
    new Map<String, Object>{
        'category' => 'parecer',
        'label' => 'Elaboracao de Parecer Tecnico',
        'accountName' => 'BASE CONTRATO - PARECER',
        'cnpj' => '33.333.333/0001-33',
        'street' => 'Alameda Tecnica, 95 - Bloco B',
        'city' => 'Curitiba',
        'state' => 'PR',
        'postalCode' => '80010-000',
        'accountPhone' => '4133003300',
        'firstName' => 'Marcelo',
        'lastName' => 'Pinto',
        'title' => 'Coordenador de Engenharia',
        'email' => 'contrato.parecer@profitto.teste',
        'contactPhone' => '41966663300',
        'cpf' => '345.678.901-22',
        'amount' => 78000,
        'proposta' => 78000,
        'visitas' => 1,
        'valorMensal' => 0,
        'prazoParecerDias' => 15,
        'prazoParecerExtenso' => 'quinze',
        'prazoMinPleito' => 30,
        'prazoPagamento' => 15,
        'valorPleito' => 32000,
        'taxaSucesso' => 3.5,
        'donaObra' => 'Terminal Metropolitano Leste',
        'municipioObra' => 'Curitiba/PR',
        'modalidade' => 'Global',
        'prazoVigencia' => '6 (seis) meses, contados da assinatura.',
        'objeto' => 'Elaboracao de parecer tecnico com analise documental e conclusoes especializadas.'
    },
    new Map<String, Object>{
        'category' => 'diagnostico',
        'label' => 'Diagnostico de Contrato',
        'accountName' => 'BASE CONTRATO - DIAGNOSTICO',
        'cnpj' => '44.444.444/0001-44',
        'street' => 'Av. Central, 770 - Torre Sul',
        'city' => 'Rio de Janeiro',
        'state' => 'RJ',
        'postalCode' => '20040-020',
        'accountPhone' => '2133004400',
        'firstName' => 'Patricia',
        'lastName' => 'Souza',
        'title' => 'Gerente de PMO',
        'email' => 'contrato.diagnostico@profitto.teste',
        'contactPhone' => '21955554400',
        'cpf' => '456.789.012-33',
        'amount' => 98000,
        'proposta' => 98000,
        'visitas' => 2,
        'valorMensal' => 0,
        'prazoParecerDias' => 18,
        'prazoParecerExtenso' => 'dezoito',
        'prazoMinPleito' => 40,
        'prazoPagamento' => 25,
        'valorPleito' => 41000,
        'taxaSucesso' => 4.2,
        'donaObra' => 'Projeto Expansao Linha Costeira',
        'municipioObra' => 'Niteroi/RJ',
        'modalidade' => 'Global',
        'prazoVigencia' => '9 (nove) meses, contados da assinatura.',
        'objeto' => 'Diagnostico contratual com levantamento de riscos, desvios e oportunidades de pleito.'
    }
};

List<Account> accountsToInsert = new List<Account>();
for (Map<String, Object> cfg : configs) {
    accountsToInsert.add(new Account(
        Name = (String) cfg.get('accountName'),
        CNPJ__c = (String) cfg.get('cnpj'),
        BillingStreet = (String) cfg.get('street'),
        BillingCity = (String) cfg.get('city'),
        BillingState = (String) cfg.get('state'),
        BillingPostalCode = (String) cfg.get('postalCode'),
        Phone = (String) cfg.get('accountPhone')
    ));
}
insert accountsToInsert;

List<Contact> contactsToInsert = new List<Contact>();
for (Integer i = 0; i < configs.size(); i++) {
    Map<String, Object> cfg = configs[i];
    contactsToInsert.add(new Contact(
        FirstName = (String) cfg.get('firstName'),
        LastName = (String) cfg.get('lastName'),
        AccountId = accountsToInsert[i].Id,
        Title = (String) cfg.get('title'),
        Email = (String) cfg.get('email'),
        Phone = (String) cfg.get('contactPhone'),
        MobilePhone = (String) cfg.get('contactPhone')
    ));
}
insert contactsToInsert;

List<Opportunity> oppsToInsert = new List<Opportunity>();
for (Integer i = 0; i < configs.size(); i++) {
    Map<String, Object> cfg = configs[i];
    String category = (String) cfg.get('category');

    String servico = serviceByCategory.get(category);
    System.assert(!String.isBlank(servico), 'Servico__c nao encontrado para categoria: ' + category);

    Opportunity opp = new Opportunity(
        Name = 'OPP CONTRATO - ' + (String) cfg.get('label'),
        StageName = wonStage,
        CloseDate = Date.today().addDays(5 + i),
        AccountId = accountsToInsert[i].Id,
        Contato_Contrato__c = contactsToInsert[i].Id,
        Servico__c = servico,
        Amount = Decimal.valueOf(String.valueOf(cfg.get('amount'))),
        Proposta__c = Decimal.valueOf(String.valueOf(cfg.get('proposta'))),
        Data_Envio_Proposta__c = Date.today().addDays(-7),
        Quantidade_Visitas__c = Decimal.valueOf(String.valueOf(cfg.get('visitas'))),
        Valor_Mensal_Monitoramento__c = Decimal.valueOf(String.valueOf(cfg.get('valorMensal'))),
        Dona_da_Obra__c = (String) cfg.get('donaObra'),
        Municipio_Obra__c = (String) cfg.get('municipioObra'),
        Prazo_Parecer_Dias__c = Decimal.valueOf(String.valueOf(cfg.get('prazoParecerDias'))),
        Prazo_Parecer_Dias_Extenso__c = (String) cfg.get('prazoParecerExtenso'),
        Prazo_Minimo_Pleito_Dias__c = Decimal.valueOf(String.valueOf(cfg.get('prazoMinPleito'))),
        Prazo_Pagamento_Dias__c = Decimal.valueOf(String.valueOf(cfg.get('prazoPagamento'))),
        Valor_Unico_Pleito__c = Decimal.valueOf(String.valueOf(cfg.get('valorPleito'))),
        Taxa_Sucesso_Pleito__c = Decimal.valueOf(String.valueOf(cfg.get('taxaSucesso'))),
        Data_Assinatura_Contrato__c = Date.today()
    );
    oppsToInsert.add(opp);
}
insert oppsToInsert;

List<Contrato__c> contratosToInsert = new List<Contrato__c>();
for (Integer i = 0; i < configs.size(); i++) {
    Map<String, Object> cfg = configs[i];
    String category = (String) cfg.get('category');

    Contrato__c c = new Contrato__c(
        Oportunidade__c = oppsToInsert[i].Id,
        Tipo_Contrato__c = tipoByCategory.get(category),
        Contrato_Padrao__c = templateByCategory.get(category),
        Modalidade_Contrato__c = (String) cfg.get('modalidade'),
        Indice_Correcao_Monetaria__c = 'IPCA/IBGE',
        Prazo_Vigencia_Descricao__c = (String) cfg.get('prazoVigencia'),
        Objeto_Servicos__c = (String) cfg.get('objeto'),
        Descricao_Obra__c = 'Contrato referente ao empreendimento ' + (String) cfg.get('donaObra'),
        Local_Obra__c = (String) cfg.get('municipioObra'),
        Representante_Legal_CPF__c = (String) cfg.get('cpf'),
        Observacoes_Contrato__c = 'Registro criado automaticamente para homologacao do fluxo contratual.',
        Descricao_Componente_1__c = 'Escopo principal',
        Valor_Componente_1__c = Decimal.valueOf(String.valueOf(cfg.get('amount'))),
        Descricao_Componente_2__c = 'Componente complementar',
        Valor_Componente_2__c = Decimal.valueOf(String.valueOf(cfg.get('valorPleito')))
    );
    contratosToInsert.add(c);
}
insert contratosToInsert;

Set<Id> contratoIds = new Set<Id>();
for (Contrato__c c : contratosToInsert) {
    contratoIds.add(c.Id);
}
ContratoTemplateService.reloadClauses(contratoIds);

System.debug('### TOTAL OPORTUNIDADES: ' + [SELECT COUNT() FROM Opportunity]);
System.debug('### TOTAL CONTRATOS: ' + [SELECT COUNT() FROM Contrato__c]);
System.debug('### TOTAL CLAUSULAS: ' + [SELECT COUNT() FROM Clausula__c]);

for (Opportunity opp : [
    SELECT Id, Name, Servico__c, Account.Name, Contato_Contrato__r.Name
    FROM Opportunity
    ORDER BY Name
]) {
    System.debug('### OPP: ' + opp.Id + ' | ' + opp.Name + ' | ' + opp.Servico__c + ' | Conta=' + opp.Account.Name + ' | Contato=' + opp.Contato_Contrato__r.Name);
}
