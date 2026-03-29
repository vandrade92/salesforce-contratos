public with sharing class ContratoReloadClausesController {
    public Id contratoId { get; private set; }

    public ContratoReloadClausesController() {
        this.contratoId = getContratoId();
    }

    public PageReference confirmReload() {
        if (contratoId == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Contrato nao informado para recarga.'));
            return null;
        }

        try {
            ContratoTemplateService.reloadClauses(new Set<Id>{ contratoId });
            PageReference redirectRef = new PageReference('/' + contratoId);
            redirectRef.setRedirect(true);
            return redirectRef;
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Falha ao recarregar clausulas: ' + ex.getMessage()));
            return null;
        }
    }

    public PageReference cancel() {
        if (contratoId == null) {
            return new PageReference('/lightning/page/home');
        }
        PageReference redirectRef = new PageReference('/' + contratoId);
        redirectRef.setRedirect(true);
        return redirectRef;
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

