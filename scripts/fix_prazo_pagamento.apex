Integer contratosAtualizados = 0;
Integer clausulasAtualizadas = 0;

List<Contrato__c> contratos = [
    SELECT Id, Prazo_Pagamento_Dias__c, Oportunidade__r.Prazo_Pagamento_Dias__c
    FROM Contrato__c
    WHERE Prazo_Pagamento_Dias__c = null
      AND Oportunidade__r.Prazo_Pagamento_Dias__c != null
];

for (Contrato__c c : contratos) {
    c.Prazo_Pagamento_Dias__c = c.Oportunidade__r.Prazo_Pagamento_Dias__c;
}

if (!contratos.isEmpty()) {
    update contratos;
    contratosAtualizados = contratos.size();
}

List<Clausula__c> clausulas = [
    SELECT Id,
           Titulo__c,
           Texto__c,
           Contrato__r.Prazo_Pagamento_Dias__c,
           Contrato__r.Oportunidade__r.Prazo_Pagamento_Dias__c
    FROM Clausula__c
    WHERE Ativa__c = true
];

List<Clausula__c> clausulasToUpdate = new List<Clausula__c>();
for (Clausula__c cl : clausulas) {
    if (String.isBlank(cl.Texto__c) || cl.Texto__c.indexOf('XX') < 0) {
        continue;
    }

    String title = cl.Titulo__c == null ? '' : cl.Titulo__c.toLowerCase();
    if (!(title.contains('pagamento') || title.contains('remuner'))) {
        continue;
    }

    Decimal prazo = cl.Contrato__r.Prazo_Pagamento_Dias__c;
    if (prazo == null && cl.Contrato__r.Oportunidade__r != null) {
        prazo = cl.Contrato__r.Oportunidade__r.Prazo_Pagamento_Dias__c;
    }
    if (prazo == null) {
        continue;
    }

    String dias = String.valueOf(prazo.setScale(0));
    String novoTexto = cl.Texto__c.replaceAll('\\bXX\\b(?=\\s+dias?)', dias);
    if (novoTexto != cl.Texto__c) {
        cl.Texto__c = novoTexto;
        clausulasToUpdate.add(cl);
    }
}

if (!clausulasToUpdate.isEmpty()) {
    update clausulasToUpdate;
    clausulasAtualizadas = clausulasToUpdate.size();
}

System.debug('FIX_PRAZO_RESULT contratosAtualizados=' + contratosAtualizados + ' clausulasAtualizadas=' + clausulasAtualizadas);