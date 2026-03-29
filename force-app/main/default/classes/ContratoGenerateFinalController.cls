public with sharing class ContratoGenerateFinalController {
    public PageReference execute() {
        Id contratoId = getContratoId();
        if (contratoId == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Contrato nao informado para geracao.'));
            return null;
        }

        try {
            Contrato__c contrato = [
                SELECT Id, Name, Versao_Documento__c
                FROM Contrato__c
                WHERE Id = :contratoId
                LIMIT 1
            ];

            Integer nextVersion = contrato.Versao_Documento__c == null ? 1 : contrato.Versao_Documento__c.intValue() + 1;

            Blob pdfBlob;
            if (Test.isRunningTest()) {
                pdfBlob = Blob.valueOf('PDF TEST CONTENT');
            } else {
                PageReference pdfPage = Page.ContratoPdf;
                pdfPage.getParameters().put('id', String.valueOf(contratoId));
                pdfBlob = pdfPage.getContentAsPDF();
            }

            String safeName = String.valueOf(contrato.Name).replaceAll('[^a-zA-Z0-9_-]', '_');
            String fileName = 'Contrato_' + safeName + '_v' + String.valueOf(nextVersion) + '.pdf';

            ContentVersion cv = new ContentVersion(
                Title = fileName.replace('.pdf', ''),
                PathOnClient = fileName,
                VersionData = pdfBlob,
                FirstPublishLocationId = contratoId
            );
            insert cv;

            ContentVersion persistedCv = [
                SELECT Id, ContentDocumentId
                FROM ContentVersion
                WHERE Id = :cv.Id
                LIMIT 1
            ];

            contrato.Versao_Documento__c = nextVersion;
            contrato.Data_Geracao_Final__c = System.now();
            contrato.Arquivo_Final_Id__c = persistedCv.ContentDocumentId;
            update contrato;

            PageReference redirectRef = new PageReference('/' + contratoId);
            redirectRef.setRedirect(true);
            return redirectRef;
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Falha ao gerar versao final: ' + ex.getMessage()));
            return null;
        }
    }

    private static Id getContratoId() {
        String idParam = ApexPages.currentPage().getParameters().get('id');
        if (String.isBlank(idParam)) {
            return null;
        }

        try {
            return (Id) idParam;
        } catch (Exception ex) {
            return null;
        }
    }
}

