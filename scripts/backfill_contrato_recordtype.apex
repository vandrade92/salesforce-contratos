Map<String, Id> rtByName = new Map<String, Id>();
for (RecordType rt : [
    SELECT Id, Name
    FROM RecordType
    WHERE SObjectType = 'Contrato__c'
    AND Name IN ('Monitoramento Remoto', 'Assistencia Tecnica Judicial', 'Elaboracao de Parecer', 'Diagnostico de Contrato')
]) {
    rtByName.put(rt.Name, rt.Id);
}

List<Contrato__c> updates = new List<Contrato__c>();
for (Contrato__c c : [SELECT Id, Tipo_Contrato__c, RecordTypeId FROM Contrato__c WHERE RecordTypeId = null]) {
    String tipo = (c.Tipo_Contrato__c == null) ? '' : c.Tipo_Contrato__c.toLowerCase();
    Id targetRt;

    if (tipo.contains('monitor')) {
        targetRt = rtByName.get('Monitoramento Remoto');
    } else if (tipo.contains('assist')) {
        targetRt = rtByName.get('Assistencia Tecnica Judicial');
    } else if (tipo.contains('parecer') || tipo.contains('elabora')) {
        targetRt = rtByName.get('Elaboracao de Parecer');
    } else if (tipo.contains('diagn')) {
        targetRt = rtByName.get('Diagnostico de Contrato');
    }

    if (targetRt != null) {
        c.RecordTypeId = targetRt;
        updates.add(c);
    }
}

if (!updates.isEmpty()) {
    update updates;
}

System.debug('Backfill record type concluido. Registros atualizados: ' + updates.size());
