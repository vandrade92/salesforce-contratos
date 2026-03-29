public with sharing class ContratoGenerateDocxController {
    public PageReference execute() {
        Id contratoId = getContratoId();
        if (contratoId == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Contrato nao informado para geracao do DOCX.'));
            return null;
        }

        try {
            ContratoPdfController pdfController = new ContratoPdfController();
            if (pdfController.contrato == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Contrato nao localizado para geracao do DOCX.'));
                return null;
            }

            Blob docxBlob = ContratoDocxService.buildFromController(pdfController);
            String safeName = String.valueOf(pdfController.contrato.Name).replaceAll('[^a-zA-Z0-9_-]', '_');
            String stamp = Datetime.now().format('yyyyMMdd_HHmmss');
            String fileName = 'Contrato_DOCX_' + safeName + '_' + stamp + '.docx';

            ContentVersion cv = new ContentVersion(
                Title = fileName.replace('.docx', ''),
                PathOnClient = fileName,
                VersionData = docxBlob,
                FirstPublishLocationId = contratoId
            );
            insert cv;

            PageReference redirectRef = new PageReference('/' + contratoId);
            redirectRef.setRedirect(true);
            return redirectRef;
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Falha ao gerar DOCX: ' + ex.getMessage()));
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
