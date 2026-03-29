List<Contrato__c> updates = new List<Contrato__c>();
for (Contrato__c c : [SELECT Id, Tipo_Contrato__c FROM Contrato__c]) {
    if (String.isBlank(c.Tipo_Contrato__c)) continue;
    String t = c.Tipo_Contrato__c.toLowerCase();
    String normalized;
    if (t.contains('monitor')) {
        normalized = 'Monitoramento Remoto';
    } else if (t.contains('assist')) {
        normalized = 'Assist?ncia T?cnica em Processo Judicial';
    } else if (t.contains('parecer')) {
        normalized = 'Elabora??o de Parecer';
    } else if (t.contains('diagn')) {
        normalized = 'Diagn?stico de Contrato';
    }
    if (normalized != null && c.Tipo_Contrato__c != normalized) {
        c.Tipo_Contrato__c = normalized;
        updates.add(c);
    }
}
if (!updates.isEmpty()) {
    update updates;
}
System.debug('Tipos normalizados: ' + updates.size());
