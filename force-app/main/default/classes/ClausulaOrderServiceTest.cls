@IsTest
private class ClausulaOrderServiceTest {
    @IsTest
    static void testRenumberAfterDelete() {
        Contrato__c contrato = new Contrato__c();
        insert contrato;

        List<Clausula__c> clauses = new List<Clausula__c>{
            new Clausula__c(Contrato__c = contrato.Id, Titulo__c = 'A', Ordem__c = 1, Texto__c = 'Texto A', Ativa__c = true),
            new Clausula__c(Contrato__c = contrato.Id, Titulo__c = 'B', Ordem__c = 2, Texto__c = 'Texto B', Ativa__c = true),
            new Clausula__c(Contrato__c = contrato.Id, Titulo__c = 'C', Ordem__c = 3, Texto__c = 'Texto C', Ativa__c = true)
        };
        insert clauses;

        delete clauses[1];

        List<Clausula__c> persisted = [
            SELECT Id, Ordem__c
            FROM Clausula__c
            WHERE Contrato__c = :contrato.Id AND Ativa__c = true
            ORDER BY Ordem__c ASC
        ];

        System.assertEquals(2, persisted.size());
        System.assertEquals(1, Integer.valueOf(persisted[0].Ordem__c));
        System.assertEquals(2, Integer.valueOf(persisted[1].Ordem__c));
    }

    @IsTest
    static void testRenumberAfterUpdateAndDeactivate() {
        Contrato__c contrato = new Contrato__c();
        insert contrato;

        List<Clausula__c> clauses = new List<Clausula__c>{
            new Clausula__c(Contrato__c = contrato.Id, Titulo__c = 'A', Ordem__c = 10, Texto__c = 'Texto A', Ativa__c = true),
            new Clausula__c(Contrato__c = contrato.Id, Titulo__c = 'B', Ordem__c = 30, Texto__c = 'Texto B', Ativa__c = true),
            new Clausula__c(Contrato__c = contrato.Id, Titulo__c = 'C', Ordem__c = 20, Texto__c = 'Texto C', Ativa__c = true)
        };
        insert clauses;

        List<Clausula__c> ordered = [
            SELECT Id, Ordem__c
            FROM Clausula__c
            WHERE Contrato__c = :contrato.Id AND Ativa__c = true
            ORDER BY Ordem__c ASC
        ];

        System.assertEquals(3, ordered.size());
        System.assertEquals(1, Integer.valueOf(ordered[0].Ordem__c));
        System.assertEquals(2, Integer.valueOf(ordered[1].Ordem__c));
        System.assertEquals(3, Integer.valueOf(ordered[2].Ordem__c));

        ordered[2].Ordem__c = 1;
        update ordered[2];

        ordered = [
            SELECT Id, Ordem__c
            FROM Clausula__c
            WHERE Contrato__c = :contrato.Id AND Ativa__c = true
            ORDER BY Ordem__c ASC
        ];

        System.assertEquals(1, Integer.valueOf(ordered[0].Ordem__c));
        System.assertEquals(2, Integer.valueOf(ordered[1].Ordem__c));
        System.assertEquals(3, Integer.valueOf(ordered[2].Ordem__c));

        ordered[0].Ativa__c = false;
        update ordered[0];

        List<Clausula__c> activeOnly = [
            SELECT Id, Ordem__c
            FROM Clausula__c
            WHERE Contrato__c = :contrato.Id AND Ativa__c = true
            ORDER BY Ordem__c ASC
        ];

        System.assertEquals(2, activeOnly.size());
        System.assertEquals(1, Integer.valueOf(activeOnly[0].Ordem__c));
        System.assertEquals(2, Integer.valueOf(activeOnly[1].Ordem__c));
    }
}