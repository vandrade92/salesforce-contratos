public with sharing class ContratoPdfController {
    public Contrato__c contrato { get; private set; }
    public List<Clausula__c> clausulas { get; private set; }
    public List<ClauseView> clauseViews { get; private set; }

    private static final String CONTRATADA_NOME = 'PROFITTO GESTAO DE CONTRATOS LTDA';
    private static final String CONTRATADA_CNPJ = '42.966.005/0001-13';
    private static final String CONTRATADA_ENDERECO = 'Alameda Oscar Niemeyer, 222, sala 304, Vale do Sereno, Nova Lima/MG, CEP 34006-049';
    private static final String CONTRATADA_REPRESENTANTE = 'Rafael Fernandez, CPF: 070.799.206-04';
    private static final String CONTRATADA_CONTATO_NOME = 'Rafael Fernandez';
    private static final String CONTRATADA_CONTATO_TELEFONE = '(31) 3300-0000';
    private static final String CONTRATADA_CONTATO_EMAIL = 'contato@profitto.co';

    public class ClauseView {
        public Integer clauseNumber { get; set; }
        public String title { get; set; }
        public List<ClauseLineView> lines { get; set; }

        public ClauseView(Integer pClauseNumber, String title) {
            this.clauseNumber = pClauseNumber;
            this.title = title;
            this.lines = new List<ClauseLineView>();
        }

        public String getHeading() {
            String label = String.isBlank(title) ? '' : title.toUpperCase();
            return 'CLAUSULA ' + String.valueOf(clauseNumber) + '. ' + label;
        }
    }

    public class ClauseLineView {
        public String prefix { get; set; }
        public String text { get; set; }
        public String styleClass { get; set; }
        public Boolean bullet { get; set; }

        public ClauseLineView(String prefix, String text, String styleClass, Boolean bullet) {
            this.prefix = prefix;
            this.text = text;
            this.styleClass = styleClass;
            this.bullet = bullet;
        }
    }

    public ContratoPdfController() {
        this.clausulas = new List<Clausula__c>();
        this.clauseViews = new List<ClauseView>();
        loadData();
    }

    private void loadData() {
        Id contratoId = getContratoId();
        if (contratoId == null) {
            return;
        }

        this.contrato = [
            SELECT Id,
                   Name,
                   Numero_Contrato_Externo__c,
                   Numero_Proposta__c,
                   Tipo_Contrato__c,
                   Contratante_Razao_Social__c,
                   Contratante_CNPJ__c,
                   Contratante_Endereco_Completo__c,
                   Contratante_Cidade__c,
                   Contratante_Estado__c,
                   Contratante_CEP__c,
                   Contratante_Email__c,
                   Contratante_Telefone__c,
                   Representante_Legal_Nome__c,
                   Representante_Legal_Cargo__c,
                   Representante_Legal_CPF__c,
                   Modalidade_Contrato__c,
                   Data_Base__c,
                   Indice_Correcao_Monetaria__c,
                   Prazo_Vigencia_Descricao__c,
                   Prazo_Pagamento_Dias__c,
                   Prazo_Minimo_Pleito_Dias__c,
                   Objeto_Servicos__c,
                   Descricao_Obra__c,
                   Local_Obra__c,
                   Dona_da_Obra__c,
                   Municipio_Obra__c,
                   Valor_Total_Servico__c,
                   Quantidade_Visitas__c,
                   Valor_Mensal_Monitoramento__c,
                   Valor_Unico_Pleito__c,
                   Taxa_Sucesso_Pleito__c,
                   Descricao_Componente_1__c,
                   Valor_Componente_1__c,
                   Descricao_Componente_2__c,
                   Valor_Componente_2__c,
                   Data_Assinatura_Contrato__c,
                   Observacoes_Contrato__c,
                   Oportunidade__r.Name,
                   Oportunidade__r.Servico__c,
                   Oportunidade__r.Prazo_Pagamento_Dias__c,
                   Oportunidade__r.Proposta__c,
                   Oportunidade__r.Data_Envio_Proposta__c,
                   Oportunidade__r.Prazo_Minimo_Pleito_Dias__c,
                   Oportunidade__r.Valor_Unico_Pleito__c,
                   Oportunidade__r.Taxa_Sucesso_Pleito__c,
                   Oportunidade__r.Dona_da_Obra__c,
                   Oportunidade__r.Municipio_Obra__c
            FROM Contrato__c
            WHERE Id = :contratoId
            LIMIT 1
        ];

        this.clausulas = [
            SELECT Id,
                   Secao__c,
                   Titulo__c,
                   Ordem__c,
                   Texto__c
            FROM Clausula__c
            WHERE Contrato__c = :contratoId AND Ativa__c = true
            ORDER BY Ordem__c ASC, CreatedDate ASC
        ];

        buildClauseViews();
    }

    private void buildClauseViews() {
        this.clauseViews = new List<ClauseView>();
        Integer clauseNumber = 1;

        for (Clausula__c clause : clausulas) {
            ClauseView view = new ClauseView(clauseNumber, clause.Titulo__c);
            String renderedText = applyRuntimeClauseVariables(clause);
            view.lines.addAll(buildClauseLines(clauseNumber, renderedText));
            this.clauseViews.add(view);
            clauseNumber++;
        }
    }

    private String applyRuntimeClauseVariables(Clausula__c clause) {
        if (clause == null || String.isBlank(clause.Texto__c)) {
            return clause == null ? null : clause.Texto__c;
        }

        String output = clause.Texto__c;
        if (output.indexOf('XX') >= 0 && shouldApplyPaymentDays(clause)) {
            String paymentDays = getPrazoPagamentoDiasLabel();
            if (!String.isBlank(paymentDays)) {
                output = output.replaceAll('\\bXX\\b(?=\\s+dias?)', paymentDays);
            }
        }

        output = applyBracketPlaceholders(output);
        return normalizeCommonSpacingArtifacts(output);
    }

    private Boolean shouldApplyPaymentDays(Clausula__c clause) {
        String normalizedTitle = normalize(clause == null ? null : clause.Titulo__c);
        if (normalizedTitle == null) {
            return false;
        }

        return normalizedTitle.contains('pagamento') || normalizedTitle.contains('remuner');
    }
    private String getPrazoPagamentoDiasLabel() {
        if (contrato == null) {
            return null;
        }

        if (contrato.Prazo_Pagamento_Dias__c != null) {
            return String.valueOf(contrato.Prazo_Pagamento_Dias__c.setScale(0));
        }

        if (contrato.Oportunidade__r != null && contrato.Oportunidade__r.Prazo_Pagamento_Dias__c != null) {
            return String.valueOf(contrato.Oportunidade__r.Prazo_Pagamento_Dias__c.setScale(0));
        }

        return null;
    }

    private String getPrazoMinimoPleitoDiasLabel() {
        if (contrato == null) {
            return null;
        }

        if (contrato.Prazo_Minimo_Pleito_Dias__c != null) {
            return String.valueOf(contrato.Prazo_Minimo_Pleito_Dias__c.setScale(0));
        }

        if (contrato.Oportunidade__r != null && contrato.Oportunidade__r.Prazo_Minimo_Pleito_Dias__c != null) {
            return String.valueOf(contrato.Oportunidade__r.Prazo_Minimo_Pleito_Dias__c.setScale(0));
        }

        return null;
    }

    private String getValorUnicoPleitoLabel() {
        if (contrato == null) {
            return null;
        }

        Decimal value = contrato.Valor_Unico_Pleito__c;
        if (value == null && contrato.Oportunidade__r != null) {
            value = contrato.Oportunidade__r.Valor_Unico_Pleito__c;
        }

        return value == null ? null : formatCurrencyValue(value);
    }

    private String getTaxaSucessoPleitoLabel() {
        if (contrato == null) {
            return null;
        }

        Decimal value = contrato.Taxa_Sucesso_Pleito__c;
        if (value == null && contrato.Oportunidade__r != null) {
            value = contrato.Oportunidade__r.Taxa_Sucesso_Pleito__c;
        }

        if (value == null) {
            return null;
        }

        return value.setScale(2).format() + '%';
    }

    private String getClienteFinalLabel() {
        if (contrato == null) {
            return null;
        }

        return firstNonBlank(
            contrato.Dona_da_Obra__c,
            contrato.Oportunidade__r == null ? null : contrato.Oportunidade__r.Dona_da_Obra__c,
            contrato.Contratante_Razao_Social__c
        );
    }

    private String getMunicipioObraLabel() {
        if (contrato == null) {
            return null;
        }

        return firstNonBlank(
            contrato.Municipio_Obra__c,
            contrato.Oportunidade__r == null ? null : contrato.Oportunidade__r.Municipio_Obra__c,
            contrato.Local_Obra__c
        );
    }

    private String applyBracketPlaceholders(String input) {
        if (String.isBlank(input) || input.indexOf('[') < 0 || input.indexOf(']') < 0) {
            return input;
        }

        String output = input;
        output = replaceBracketPlaceholderByToken(output, 'dias', getPrazoMinimoPleitoDiasLabel());
        output = replaceBracketPlaceholderByToken(output, 'valor', getValorUnicoPleitoLabel());
        output = replaceBracketPlaceholderByToken(output, 'porcent', getTaxaSucessoPleitoLabel());
        output = replaceBracketPlaceholderByToken(output, 'cliente\\s*final', getClienteFinalLabel());
        output = replaceBracketPlaceholderByToken(output, 'munic', getMunicipioObraLabel());
        return output;
    }

    private static String normalizeCommonSpacingArtifacts(String input) {
        if (String.isBlank(input)) {
            return input;
        }

        String output = input;

        // Split merged words around case transitions:
        // e.g. "deNiteroi", "pelaCONTRATANTE", "CONTRATANTEpagarÃƒÂ¡", "CONTRATANTEÃƒÂ Parte".
        output = output.replaceAll('([\\p{Lu}]{2,})([\\p{Ll}])', '$1 $2');
        output = output.replaceAll('([\\p{Ll}])([\\p{Lu}])', '$1 $2');

        output = output.replaceAll('([\\p{L}\\d])([\\"\\u201C])(?=[\\p{L}])', '$1 $2');

        // Targeted recoveries from imported template texts.
        output = output.replaceAll('(?i)\\bAlÃƒÂ©mdas\\b', 'AlÃƒÂ©m das');
        output = output.replaceAll('(?i)\\bdosrespectivos\\b', 'dos respectivos');
        output = output.replaceAll('(?i)\\bassociadosem\\b', 'associados em');
        output = output.replaceAll('(?i)\\bescopoinvestiga', 'escopo investiga');
        output = output.replaceAll('(?i)\\bescoponenhuma\\b', 'escopo nenhuma');
        output = output.replaceAll('(?i)\\bescopoquaisquer\\b', 'escopo quaisquer');
        output = output.replaceAll('(?i)\\bempresaa\\b', 'empresa a');
        output = output.replaceAll('(?i)\\bpessoalsignificam\\b', 'pessoal significam');
        output = output.replaceAll('(?i)\\btermose\\b', 'termos e');
        output = output.replaceAll('(?i)\\bdesimples\\b', 'de simples');
        output = output.replaceAll('(?i)\\bContratopoder', 'Contrato poder');

        // Collapse accidental multiple spaces produced by fixes above.
        output = output.replaceAll(' {2,}', ' ');

        return output;
    }

    private static String replaceBracketPlaceholderByToken(String input, String tokenRegex, String replacement) {
        if (String.isBlank(input) || String.isBlank(tokenRegex) || String.isBlank(replacement)) {
            return input;
        }

        Pattern pattern = Pattern.compile('(?i)\\[[^\\]]*' + tokenRegex + '[^\\]]*\\]');
        Matcher matcher = pattern.matcher(input);
        if (!matcher.find()) {
            return input;
        }

        matcher = pattern.matcher(input);
        String output = '';
        Integer lastEnd = 0;
        while (matcher.find()) {
            output += input.substring(lastEnd, matcher.start());
            output += normalizeReplacementSpacing(input, matcher.start(), matcher.end(), replacement);
            lastEnd = matcher.end();
        }
        output += input.substring(lastEnd);
        return output;
    }

    private static String normalizeReplacementSpacing(String sourceText, Integer startIndex, Integer endIndex, String replacement) {
        if (sourceText == null || replacement == null) {
            return replacement;
        }

        String resolved = replacement;
        if (resolved.length() == 0) {
            return resolved;
        }

        if (startIndex != null && startIndex > 0) {
            String before = sourceText.substring(startIndex - 1, startIndex);
            if (isAlphaNumericChar(before) && isAlphaNumericChar(resolved.substring(0, 1))) {
                resolved = ' ' + resolved;
            }
        }

        if (endIndex != null && endIndex < sourceText.length()) {
            String after = sourceText.substring(endIndex, endIndex + 1);
            String lastChar = resolved.substring(resolved.length() - 1);
            if ((lastChar == '%' && isAlphaNumericChar(after)) ||
                (isAlphaNumericChar(lastChar) && isAlphaNumericChar(after))) {
                resolved += ' ';
            }
        }

        return resolved;
    }

    private static Boolean isAlphaNumericChar(String value) {
        if (String.isBlank(value)) {
            return false;
        }

        String charValue = value.substring(0, 1);
        if ('0123456789'.contains(charValue)) {
            return true;
        }

        return charValue.toLowerCase() != charValue.toUpperCase();
    }

    private List<ClauseLineView> buildClauseLines(Integer clauseNumber, String rawText) {
        List<ClauseLineView> lines = new List<ClauseLineView>();
        if (String.isBlank(rawText)) {
            return lines;
        }

        List<String> normalizedLines = new List<String>();
        for (String candidate : rawText.split('\\r?\\n')) {
            String cleaned = candidate == null ? null : candidate.trim();
            if (!String.isBlank(cleaned)) {
                normalizedLines.add(cleaned);
            }
        }

        if (normalizedLines.isEmpty()) {
            return lines;
        }

        Integer startIndex = 0;
        Integer sectionNumber = 1;
        Integer paragraphInSection = 0;
        Boolean hasLeadingSubtitle = false;

        if (isSubsectionTitle(normalizedLines[0])) {
            lines.add(new ClauseLineView(
                String.valueOf(clauseNumber) + '.1.',
                normalizedLines[0],
                'subtitle',
                false
            ));
            startIndex = 1;
            hasLeadingSubtitle = true;
        }

        Boolean listMode = false;
        Integer bulletIndex = 0;

        for (Integer i = startIndex; i < normalizedLines.size(); i++) {
            String line = normalizedLines[i];

            if (isSignatureBlockStart(line)) {
                addStandardSignatureSection(lines, line, extractSignatureCityDate(normalizedLines, i + 1));
                break;
            }

            if (shouldRenderWithoutPrefix(line)) {
                lines.add(new ClauseLineView('', line, 'paragraph', false));
                continue;
            }

            if (listMode && shouldEndBulletList(line) && !isExplicitBullet(line)) {
                listMode = false;
                bulletIndex = 0;
            }

            if (hasLeadingSubtitle && isInlineSubsectionTitle(normalizedLines, i, listMode)) {
                sectionNumber++;
                paragraphInSection = 0;

                lines.add(new ClauseLineView(
                    String.valueOf(clauseNumber) + '.' + String.valueOf(sectionNumber) + '.',
                    line,
                    'subtitle',
                    false
                ));
                continue;
            }

            if (!listMode && isExplicitBullet(line)) {
                listMode = true;
                bulletIndex = 0;
            }

            if (listMode) {
                bulletIndex++;
                lines.add(new ClauseLineView(toRomanLower(bulletIndex) + '.', stripBulletMarker(line), 'bullet', true));
                continue;
            }

            paragraphInSection++;
            String prefix;
            if (hasLeadingSubtitle) {
                prefix = String.valueOf(clauseNumber) + '.' + String.valueOf(sectionNumber) + '.' + String.valueOf(paragraphInSection) + '.';
            } else {
                prefix = String.valueOf(clauseNumber) + '.' + String.valueOf(paragraphInSection) + '.';
            }

            lines.add(new ClauseLineView(prefix, line, 'paragraph', false));

            if (isListIntro(line)) {
                listMode = true;
                bulletIndex = 0;
            }
        }

        return lines;
    }

    private static Boolean isInlineSubsectionTitle(List<String> lines, Integer index, Boolean listMode) {
        if (listMode || lines == null || index == null || index < 0 || index >= lines.size()) {
            return false;
        }

        String current = lines[index];
        if (!isSubsectionTitle(current)) {
            return false;
        }

        if (index + 1 >= lines.size()) {
            return false;
        }

        String nextLine = lines[index + 1];
        if (String.isBlank(nextLine)) {
            return false;
        }

        if (isSubsectionTitle(nextLine)) {
            return false;
        }

        return nextLine.length() >= 25;
    }

    private static Boolean isSubsectionTitle(String line) {
        if (String.isBlank(line)) {
            return false;
        }

        if (line.endsWith('.') || line.endsWith(':') || line.endsWith(';') || line.endsWith(',')) {
            return false;
        }

        if (line.length() > 80) {
            return false;
        }

        List<String> words = line.split('\\s+');
        return words.size() <= 8;
    }

    private static Boolean isListIntro(String line) {
        return !String.isBlank(line) && line.endsWith(':');
    }

    private static Boolean isSignatureBlockStart(String line) {
        if (String.isBlank(line)) {
            return false;
        }

        String lower = line.trim().toLowerCase();
        return lower.startsWith('e, estando') || lower.startsWith('e estando');
    }

    private void addStandardSignatureSection(List<ClauseLineView> lines, String introLine, String cityDateLine) {
        lines.add(new ClauseLineView('', introLine, 'signature-intro', false));
        lines.add(new ClauseLineView('', resolveSignatureCityDate(cityDateLine), 'signature-city-date', false));

        lines.add(new ClauseLineView('', 'PARTE CONTRATANTE:', 'signature-role', false));
        lines.add(new ClauseLineView('', '', 'signature-line', false));
        lines.add(new ClauseLineView('', resolveContratanteSignatureName(), 'signature-name', false));

        lines.add(new ClauseLineView('', 'PARTE CONTRATADA:', 'signature-role', false));
        lines.add(new ClauseLineView('', '', 'signature-line', false));
        lines.add(new ClauseLineView('', CONTRATADA_NOME, 'signature-name', false));

        lines.add(new ClauseLineView('', 'TESTEMUNHAS:', 'signature-witness-block', false));
    }

    private String extractSignatureCityDate(List<String> lines, Integer startIndex) {
        if (lines == null || startIndex == null) {
            return null;
        }

        for (Integer i = startIndex; i < lines.size(); i++) {
            String candidate = lines[i] == null ? null : lines[i].trim();
            if (String.isBlank(candidate)) {
                continue;
            }

            String normalized = normalize(candidate);
            String lower = candidate.toLowerCase();

            if ((normalized != null && normalized.startsWith('de ') && normalized.contains(' para ')) ||
                regexMatches(candidate, '(?i)^.*\\b\\d{2}/\\d{2}/\\d{4}\\.?$')) {
                return candidate;
            }

            if (lower.startsWith('parte contratante') ||
                lower.startsWith('parte contratada') ||
                lower.startsWith('testemunhas') ||
                isSignatureWitnessField(lower) ||
                isSignatureLinePlaceholder(candidate)) {
                break;
            }
        }

        return null;
    }

    private String resolveSignatureCityDate(String cityDateLine) {
        if (!String.isBlank(cityDateLine)) {
            return cityDateLine;
        }

        String origemCidade = contrato == null ? null : contrato.Contratante_Cidade__c;
        String origemEstado = contrato == null ? null : contrato.Contratante_Estado__c;
        String destino = contrato == null ? null : contrato.Local_Obra__c;

        String origem = String.isBlank(origemCidade) ? 'Nova Lima' : origemCidade;
        String origemUf = String.isBlank(origemEstado) ? '' : ' - ' + origemEstado;
        String destinoLabel = String.isBlank(destino) ? '________' : destino;
        String assinatura = contrato == null || contrato.Data_Assinatura_Contrato__c == null
            ? '__/__/____'
            : Datetime.newInstance(
                contrato.Data_Assinatura_Contrato__c,
                Time.newInstance(0, 0, 0, 0)
            ).format('dd/MM/yyyy');

        return 'De ' + origem + origemUf + ' para ' + destinoLabel + ',' + assinatura + '.';
    }

    private String resolveContratanteSignatureName() {
        if (contrato == null) {
            return '______________________________';
        }

        if (!String.isBlank(contrato.Representante_Legal_Nome__c)) {
            return contrato.Representante_Legal_Nome__c;
        }

        if (!String.isBlank(contrato.Contratante_Razao_Social__c)) {
            return contrato.Contratante_Razao_Social__c;
        }

        return '______________________________';
    }

    private static Boolean shouldRenderWithoutPrefix(String line) {
        if (String.isBlank(line)) {
            return true;
        }

        String trimmed = line.trim();
        String lower = trimmed.toLowerCase();

        if (lower.startsWith('parte contratante') ||
            lower.startsWith('parte contratada') ||
            lower.startsWith('testemunhas') ||
            lower.startsWith('nome:') ||
            lower.startsWith('rg:') ||
            lower.startsWith('cpf:')) {
            return true;
        }

        if (trimmed.contains('____') || regexMatches(trimmed, '^[_\\\\-\\\\s\\\\.]+$')) {
            return true;
        }

        if (regexMatches(trimmed, '(?i)^.*\\\\b\\\\d{2}/\\\\d{2}/\\\\d{4}\\\\.?$')) {
            return true;
        }

        return false;
    }
    private static Boolean isSignatureWitnessField(String lower) {
        if (String.isBlank(lower)) {
            return false;
        }

        return lower.startsWith('nome:') || lower.startsWith('rg:') || lower.startsWith('cpf:');
    }

    private static Boolean isSignatureLinePlaceholder(String trimmed) {
        if (String.isBlank(trimmed)) {
            return false;
        }

        return trimmed.contains('____') || regexMatches(trimmed, '^[_\\\\-\\\\s\\\\.]+$');
    }

    private static Boolean regexMatches(String input, String regex) {
        if (input == null || regex == null) {
            return false;
        }

        return Pattern.compile(regex).matcher(input).matches();
    }

    private static Boolean shouldEndBulletList(String line) {
        if (String.isBlank(line)) {
            return true;
        }

        if (isExplicitBullet(line)) {
            return false;
        }

        String n = normalize(line);
        if (n == null) {
            return true;
        }

        if (line.endsWith(':') || isSubsectionTitle(line)) {
            return true;
        }

        if (n.startsWith('nos casos') ||
            n.startsWith('considera-se') ||
            n.startsWith('considera se') ||
            n.startsWith('havendo ') ||
            n.startsWith('o pagamento') ||
            n.startsWith('caber') ||
            n.startsWith('a taxa ')) {
            return true;
        }

        return false;
    }
    private static Boolean isExplicitBullet(String line) {
        if (String.isBlank(line)) {
            return false;
        }

        String trimmed = line.trim();
        if (trimmed.startsWith('&bull;') || trimmed.startsWith('&#8226;')) {
            return true;
        }

        return trimmed.startsWith('-') || trimmed.startsWith('*') || startsWithUnicodeBullet(trimmed);
    }

    private static Boolean startsWithUnicodeBullet(String input) {
        if (String.isBlank(input)) {
            return false;
        }

        String first = input.substring(0, 1);
        return first == '\u2022' || first == '\u25CF' || first == '\u25AA' || first == '\u25E6';
    }

    private static String stripBulletMarker(String line) {
        if (String.isBlank(line)) {
            return line;
        }

        String trimmed = line.trim();
        if (!isExplicitBullet(trimmed)) {
            return trimmed;
        }

        String normalized = trimmed.replaceFirst('(?i)^(&bull;|&#8226;)\\s*', '');
        normalized = normalized.replaceFirst('^(?:[-*]|\\u2022|\\u25CF|\\u25AA|\\u25E6)+\\s*', '');
        return normalized.trim();
    }

    private static String toRomanLower(Integer value) {
        if (value == null || value <= 0) {
            return '';
        }

        List<Integer> magnitudes = new List<Integer>{1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1};
        List<String> symbols = new List<String>{'m', 'cm', 'd', 'cd', 'c', 'xc', 'l', 'xl', 'x', 'ix', 'v', 'iv', 'i'};

        Integer remaining = value;
        String output = '';

        for (Integer idx = 0; idx < magnitudes.size(); idx++) {
            Integer magnitude = magnitudes[idx];
            while (remaining >= magnitude) {
                output += symbols[idx];
                remaining -= magnitude;
            }
        }

        return output;
    }


    public String getNumeroContrato() {
        if (contrato == null) {
            return null;
        }

        return String.isBlank(contrato.Numero_Contrato_Externo__c)
            ? contrato.Name
            : contrato.Numero_Contrato_Externo__c;
    }

    public String getNumeroContratoCabecalho() {
        if (contrato == null) {
            return null;
        }

        return String.isBlank(contrato.Name) ? getNumeroContrato() : contrato.Name;
    }

    public String getNumeroPropostaCabecalho() {
        if (contrato == null) {
            return null;
        }

        String numero = contrato.Numero_Proposta__c;
        if (String.isBlank(numero) && contrato.Oportunidade__r != null && contrato.Oportunidade__r.Proposta__c != null) {
            numero = String.valueOf(contrato.Oportunidade__r.Proposta__c.setScale(0));
        }

        if (String.isBlank(numero)) {
            return null;
        }

        Date dataEnvio = contrato.Data_Base__c;
        if (dataEnvio == null && contrato.Oportunidade__r != null) {
            dataEnvio = contrato.Oportunidade__r.Data_Envio_Proposta__c;
        }

        if (dataEnvio == null) {
            return numero;
        }

        return numero + '_' + String.valueOf(dataEnvio.year());
    }

    public String getDataGeracao() {
        return Datetime.now().format('dd/MM/yyyy HH:mm');
    }

    public String getParteContratadaNome() {
        return CONTRATADA_NOME;
    }

    public String getParteContratadaCnpj() {
        return CONTRATADA_CNPJ;
    }

    public String getParteContratadaEndereco() {
        return CONTRATADA_ENDERECO;
    }

    public String getParteContratadaRepresentante() {
        return CONTRATADA_REPRESENTANTE;
    }

    public Boolean getIsMonitoramentoRemoto() {
        return getCategoriaContrato() == 'monitoramento';
    }

    public String getDescricaoServicosResumo() {
        if (contrato == null) {
            return null;
        }

        String categoria = getCategoriaContrato();
        if (categoria == 'monitoramento') {
            String visitas = contrato.Quantidade_Visitas__c == null
                ? 'N/A'
                : String.valueOf(contrato.Quantidade_Visitas__c.setScale(0));
            return 'Monitoramento Remoto (' + visitas + ' visitas) + Elaboracao de Pleitos';
        }
        if (categoria == 'assistencia') {
            return 'Assistencia Tecnica no Processo Judicial';
        }
        if (categoria == 'parecer') {
            return 'Elaboracao de Parecer Tecnico';
        }
        if (categoria == 'diagnostico') {
            return 'Elaboracao de diagnostico de contrato + Pleito';
        }

        return firstNonBlank(
            contrato.Objeto_Servicos__c,
            contrato.Tipo_Contrato__c,
            contrato.Oportunidade__r == null ? null : contrato.Oportunidade__r.Servico__c
        );
    }

    public String getRepresentanteContratanteResumo() {
        if (contrato == null) {
            return null;
        }

        String nome = contrato.Representante_Legal_Nome__c;
        String cpf = contrato.Representante_Legal_CPF__c;

        if (String.isBlank(nome) && String.isBlank(cpf)) {
            return null;
        }
        if (String.isBlank(nome)) {
            return 'CPF: ' + cpf;
        }
        if (String.isBlank(cpf)) {
            return nome;
        }
        return nome + ', CPF: ' + cpf;
    }

    public String getModalidadeResumo() {
        if (contrato == null) {
            return null;
        }

        String categoria = getCategoriaContrato();
        if (!String.isBlank(contrato.Modalidade_Contrato__c)) {
            if (categoria == 'assistencia' && normalize(contrato.Modalidade_Contrato__c) == 'global') {
                return 'Preco Global';
            }
            return contrato.Modalidade_Contrato__c;
        }

        if (categoria == 'monitoramento') {
            return 'Mensal (monitoramento remoto) e global (elaboracao de pleitos)';
        }
        if (categoria == 'assistencia') {
            return 'Preco Global';
        }

        return 'Global';
    }

    public String getMultaTerminoResumo() {
        if (getCategoriaContrato() == 'assistencia') {
            return '10% (dez por cento) do preco contratual.';
        }

        return '2% (dois por cento) do preco contratual.';
    }

    public String getMultaSigiloResumo() {
        return '1% (um por cento) do preco contratual, por evento.';
    }

    public Decimal getValorMonitoramentoMensal() {
        if (contrato == null) {
            return null;
        }
        return contrato.Valor_Mensal_Monitoramento__c;
    }

    public Decimal getValorPleitoResumo() {
        if (contrato == null) {
            return null;
        }

        if (contrato.Valor_Unico_Pleito__c != null) {
            return contrato.Valor_Unico_Pleito__c;
        }
        return contrato.Valor_Componente_2__c;
    }

    public String getLabelValorMonitoramento() {
        if (contrato == null || contrato.Quantidade_Visitas__c == null) {
            return 'Monitoramento Remoto';
        }

        return 'Monitoramento Remoto (' + String.valueOf(contrato.Quantidade_Visitas__c.setScale(0)) + ' visitas)';
    }

    public List<String> getResumoValoresItens() {
        List<String> itens = new List<String>();
        if (contrato == null) {
            return itens;
        }

        String categoria = getCategoriaContrato();
        if (categoria == 'monitoramento') {
            itens.add(getLabelValorMonitoramento() + ': ' + formatCurrencyValue(contrato.Valor_Mensal_Monitoramento__c));
            itens.add('Elaboracao de Pleitos: ' + formatCurrencyValue(getValorPleitoResumo()));
            return itens;
        }

        if (categoria == 'diagnostico') {
            Decimal valorDiagnostico = contrato.Valor_Componente_1__c == null ? contrato.Valor_Total_Servico__c : contrato.Valor_Componente_1__c;
            itens.add('Diagnostico do Contrato: ' + formatCurrencyValue(valorDiagnostico));
            itens.add('Elaboracao do Pleito: ' + formatCurrencyValue(getValorPleitoResumo()));
            return itens;
        }

        if (categoria == 'parecer') {
            Decimal valorParecer = contrato.Valor_Componente_1__c == null ? contrato.Valor_Total_Servico__c : contrato.Valor_Componente_1__c;
            itens.add('Elaboracao de Parecer Tecnico: ' + formatCurrencyValue(valorParecer));
            return itens;
        }

        if (categoria == 'assistencia') {
            itens.add('Preco Global: ' + formatCurrencyValue(contrato.Valor_Total_Servico__c));
            return itens;
        }

        itens.add('Valor Total: ' + formatCurrencyValue(contrato.Valor_Total_Servico__c));
        return itens;
    }

    public String getPrazoVigenciaResumo() {
        if (contrato == null) {
            return null;
        }

        if (!String.isBlank(contrato.Prazo_Vigencia_Descricao__c)) {
            return contrato.Prazo_Vigencia_Descricao__c;
        }

        String categoria = getCategoriaContrato();
        if (categoria == 'assistencia') {
            return 'Conforme a duracao do processo.';
        }
        if (categoria == 'diagnostico') {
            return 'Conforme condicoes estabelecidas no item 4.1 das condicoes gerais.';
        }

        return null;
    }

    public String getDisposicoesAdicionaisResumo() {
        String categoria = getCategoriaContrato();
        if (categoria == 'monitoramento') {
            return 'Nenhuma';
        }
        return 'NA';
    }

    public String getContatoContratanteNome() {
        return contrato == null ? null : contrato.Representante_Legal_Nome__c;
    }

    public String getContatoContratanteTelefone() {
        return contrato == null ? null : contrato.Contratante_Telefone__c;
    }

    public String getContatoContratanteEmail() {
        return contrato == null ? null : contrato.Contratante_Email__c;
    }

    public String getContatoContratadaNome() {
        return CONTRATADA_CONTATO_NOME;
    }

    public String getContatoContratadaTelefone() {
        return CONTRATADA_CONTATO_TELEFONE;
    }

    public String getContatoContratadaEmail() {
        return CONTRATADA_CONTATO_EMAIL;
    }

    public String toHtml(String input) {
        if (String.isBlank(input)) {
            return '';
        }

        String escaped = String.escapeSingleQuotes(input);
        escaped = escaped.replace('&', '&amp;');
        escaped = escaped.replace('<', '&lt;');
        escaped = escaped.replace('>', '&gt;');
        escaped = escaped.replace('\n', '<br/>');
        return escaped;
    }

    private static String firstNonBlank(String a, String b) {
        if (!String.isBlank(a)) {
            return a;
        }
        return b;
    }

    private static String firstNonBlank(String a, String b, String c) {
        if (!String.isBlank(a)) {
            return a;
        }
        if (!String.isBlank(b)) {
            return b;
        }
        return c;
    }

    private String getCategoriaContrato() {
        if (contrato == null) {
            return null;
        }

        String source = firstNonBlank(
            contrato.Tipo_Contrato__c,
            contrato.Oportunidade__r == null ? null : contrato.Oportunidade__r.Servico__c
        );
        String normalized = normalize(source);

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

    private static String formatCurrencyValue(Decimal amount) {
        if (amount == null) {
            return '';
        }

        return 'R$ ' + amount.setScale(2).format();
    }

    private static String normalize(String value) {
        if (String.isBlank(value)) {
            return null;
        }

        String output = value.toLowerCase();
        output = output.replaceAll('[^a-z0-9+ ]', ' ');
        output = output.replaceAll('\\s+', ' ').trim();
        return String.isBlank(output) ? null : output;
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



