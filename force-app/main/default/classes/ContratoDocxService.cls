public without sharing class ContratoDocxService {
    private static final String RESUMO_TABLE_TOKEN = '__RESUMO_TABLE__';
    private static final List<String> BOLD_KEYWORDS = new List<String>{ 'CONTRATANTE', 'CONTRATADA' };

    private class DocxParagraph {
        public String text;
        public Boolean bold;
        public Boolean underline;
        public String align;
        public Integer after;

        public DocxParagraph(String text, Boolean bold, Boolean underline, String align, Integer after) {
            this.text = text;
            this.bold = bold;
            this.underline = underline;
            this.align = align;
            this.after = after;
        }
    }

    private class DocxRun {
        public String text;
        public Boolean bold;
        public Boolean underline;
        public Boolean highlight;

        public DocxRun(String text, Boolean bold, Boolean underline, Boolean highlight) {
            this.text = text;
            this.bold = bold == true;
            this.underline = underline == true;
            this.highlight = highlight == true;
        }
    }

    private class KeywordMatch {
        public Integer start;
        public Integer endIndex;

        public KeywordMatch(Integer start, Integer endIndex) {
            this.start = start;
            this.endIndex = endIndex;
        }
    }

    public static Blob buildFromController(ContratoPdfController ctrl) {
        List<DocxParagraph> paragraphs = new List<DocxParagraph>();

        if (ctrl == null || ctrl.contrato == null) {
            paragraphs.add(new DocxParagraph('Contrato nao informado.', false, false, 'left', 180));
            return buildArchive(paragraphs, 'Contrato nao informado', '');
        }

        String resumoTableXml = buildResumoTableXml(ctrl);
        appendHeader(paragraphs, ctrl);
        appendResumo(paragraphs);
        appendClausulas(paragraphs, ctrl);

        String title = 'Contrato ' + nvl(ctrl.contrato.Name);
        return buildArchive(paragraphs, title, resumoTableXml);
    }

    private static void appendHeader(List<DocxParagraph> paragraphs, ContratoPdfController ctrl) {
        paragraphs.add(new DocxParagraph('CONTRATO DE PRESTACAO DE SERVICOS N' + String.valueOf('\u00BA') + ' ' + nvl(ctrl.getNumeroContratoCabecalho()), true, false, 'center', 100));
        paragraphs.add(new DocxParagraph('PROPOSTA N' + String.valueOf('\u00BA') + ' ' + nvl(ctrl.getNumeroPropostaCabecalho()), true, false, 'center', 260));
    }

    private static void appendResumo(List<DocxParagraph> paragraphs) {
        paragraphs.add(new DocxParagraph('QUADRO RESUMO', true, false, 'center', 200));
        paragraphs.add(new DocxParagraph(RESUMO_TABLE_TOKEN, false, false, 'left', 60));
        paragraphs.add(new DocxParagraph('', false, false, 'left', 130));
        paragraphs.add(new DocxParagraph('CLAUSULAS', true, false, 'left', 200));
    }

    private static void appendClausulas(List<DocxParagraph> paragraphs, ContratoPdfController ctrl) {
        if (ctrl.clauseViews == null || ctrl.clauseViews.isEmpty()) {
            paragraphs.add(new DocxParagraph('Sem clausulas ativas para este contrato.', false, false, 'left', 140));
            return;
        }

        for (ContratoPdfController.ClauseView view : ctrl.clauseViews) {
            paragraphs.add(new DocxParagraph(nvl(view.getHeading()), true, false, 'left', 120));

            for (ContratoPdfController.ClauseLineView line : view.lines) {
                if (line == null) {
                    continue;
                }

                if (line.styleClass == 'signature-witness-block') {
                    paragraphs.add(new DocxParagraph('TESTEMUNHAS:', true, true, 'left', 110));
                    paragraphs.add(new DocxParagraph('________________________________________', false, false, 'left', 80));
                    paragraphs.add(new DocxParagraph('Nome:', false, false, 'left', 80));
                    paragraphs.add(new DocxParagraph('RG:', false, false, 'left', 80));
                    paragraphs.add(new DocxParagraph('CPF:', false, false, 'left', 80));
                    paragraphs.add(new DocxParagraph('', false, false, 'left', 80));
                    paragraphs.add(new DocxParagraph('________________________________________', false, false, 'left', 80));
                    paragraphs.add(new DocxParagraph('Nome:', false, false, 'left', 80));
                    paragraphs.add(new DocxParagraph('RG:', false, false, 'left', 80));
                    paragraphs.add(new DocxParagraph('CPF:', false, false, 'left', 120));
                    continue;
                }

                String prefix = String.isBlank(line.prefix) ? '' : line.prefix + ' ';
                String text = prefix + nvl(line.text);

                Boolean bold = line.styleClass == 'subtitle' || line.styleClass == 'signature-role' || line.styleClass == 'signature-name';
                Boolean underline = line.styleClass == 'subtitle' || line.styleClass == 'signature-role';
                String align = line.styleClass == 'signature-city-date' ? 'center' : 'both';
                Integer spacing = line.styleClass == 'signature-line' ? 40 : 110;

                if (line.styleClass == 'signature-line' && String.isBlank(line.text)) {
                    text = '________________________________________';
                    align = 'left';
                }

                if (line.styleClass == 'signature-intro') {
                    align = 'both';
                    spacing = 170;
                }

                paragraphs.add(new DocxParagraph(text, bold, underline, align, spacing));
            }

            paragraphs.add(new DocxParagraph('', false, false, 'left', 160));
        }
    }

    private static Blob buildArchive(List<DocxParagraph> paragraphs, String title, String resumoTableXml) {
        String documentXml = buildDocumentXml(paragraphs, resumoTableXml);
        Compression.ZipWriter zipWriter = new Compression.ZipWriter();
        zipWriter.addEntry('[Content_Types].xml', Blob.valueOf(buildContentTypesXml()));
        zipWriter.addEntry('_rels/.rels', Blob.valueOf(buildRelsXml()));
        zipWriter.addEntry('docProps/core.xml', Blob.valueOf(buildCoreXml(title)));
        zipWriter.addEntry('docProps/app.xml', Blob.valueOf(buildAppXml()));
        zipWriter.addEntry('word/document.xml', Blob.valueOf(documentXml));
        zipWriter.addEntry('word/_rels/document.xml.rels', Blob.valueOf(buildWordDocumentRelsXml()));
        zipWriter.addEntry('word/footer1.xml', Blob.valueOf(buildFooterXml()));
        return zipWriter.getArchive();
    }

    private static String buildDocumentXml(List<DocxParagraph> paragraphs, String resumoTableXml) {
        String xml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
            '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" ' +
            'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">' +
            '<w:body>';

        for (DocxParagraph paragraph : paragraphs) {
            if (paragraph != null && paragraph.text == RESUMO_TABLE_TOKEN) {
                xml += String.isBlank(resumoTableXml) ? '' : resumoTableXml;
            } else {
                xml += buildParagraphXml(paragraph);
            }
        }

        xml += '<w:sectPr>' +
            '<w:footerReference w:type="default" r:id="rIdFooter1"/>' +
            '<w:pgSz w:w="11906" w:h="16838"/>' +
            '<w:pgMar w:top="1417" w:right="1134" w:bottom="1417" w:left="1134" w:header="708" w:footer="708" w:gutter="0"/>' +
            '<w:pgNumType w:start="1"/>' +
            '</w:sectPr>' +
            '</w:body></w:document>';

        return xml;
    }

    private static String buildParagraphXml(DocxParagraph paragraph) {
        String text = paragraph == null ? '' : normalizeDocText(nvl(paragraph.text));
        String align = paragraph == null || String.isBlank(paragraph.align) ? 'left' : paragraph.align;
        Integer after = paragraph == null || paragraph.after == null ? 100 : paragraph.after;

        String xml = '<w:p><w:pPr>' +
            '<w:jc w:val="' + escapeXml(align) + '"/>' +
            '<w:spacing w:after="' + String.valueOf(after) + '" w:line="300" w:lineRule="auto"/>' +
            '</w:pPr>';
        xml += buildRunsXml(parseStyledRuns(text, paragraph != null && paragraph.bold == true, paragraph != null && paragraph.underline == true));
        xml += '</w:p>';

        return xml;
    }

    private static String buildResumoTableXml(ContratoPdfController ctrl) {
        if (ctrl == null || ctrl.contrato == null) {
            return '';
        }

        List<String> valoresLines = new List<String>{'4.1. Valores:'};
        for (String item : ctrl.getResumoValoresItens()) {
            if (!String.isBlank(item)) {
                valoresLines.add(item);
            }
        }

        List<String> repContratanteLines = new List<String>{
            'Assuntos Comerciais e Tecnicos:',
            'Nome: ' + nvl(ctrl.getContatoContratanteNome()),
            'Telefone: ' + nvl(ctrl.getContatoContratanteTelefone()),
            'E-mail: ' + nvl(ctrl.getContatoContratanteEmail())
        };
        List<String> repContratadaLines = new List<String>{
            'Assuntos Comerciais e Tecnicos:',
            'Nome: ' + nvl(ctrl.getContatoContratadaNome()),
            'Telefone: ' + nvl(ctrl.getContatoContratadaTelefone()),
            'E-mail: ' + nvl(ctrl.getContatoContratadaEmail())
        };

        String xml = '<w:tbl>' +
            '<w:tblPr>' +
                '<w:tblW w:w="5000" w:type="pct"/>' +
                '<w:tblCellMar>' +
                    '<w:top w:w="75" w:type="dxa"/>' +
                    '<w:left w:w="90" w:type="dxa"/>' +
                    '<w:bottom w:w="75" w:type="dxa"/>' +
                    '<w:right w:w="90" w:type="dxa"/>' +
                '</w:tblCellMar>' +
                '<w:tblBorders>' +
                    '<w:top w:val="single" w:sz="8" w:space="0" w:color="1F1F1F"/>' +
                    '<w:left w:val="single" w:sz="8" w:space="0" w:color="1F1F1F"/>' +
                    '<w:bottom w:val="single" w:sz="8" w:space="0" w:color="1F1F1F"/>' +
                    '<w:right w:val="single" w:sz="8" w:space="0" w:color="1F1F1F"/>' +
                    '<w:insideH w:val="single" w:sz="6" w:space="0" w:color="1F1F1F"/>' +
                    '<w:insideV w:val="single" w:sz="6" w:space="0" w:color="1F1F1F"/>' +
                '</w:tblBorders>' +
            '</w:tblPr>' +
            '<w:tblGrid><w:gridCol w:w="6500"/><w:gridCol w:w="6500"/></w:tblGrid>';

        xml += buildSectionRow('1. Parte Contratante');
        xml += buildTwoColRow('1.1. Razao Social: ' + nvl(ctrl.contrato.Contratante_Razao_Social__c), '1.2. CNPJ: ' + nvl(ctrl.contrato.Contratante_CNPJ__c));
        xml += buildSingleRow('1.3. Endereco/Sede: ' + nvl(ctrl.contrato.Contratante_Endereco_Completo__c));
        xml += buildSingleRow('1.4. Qualificacao/Representante Legal: ' + nvl(ctrl.getRepresentanteContratanteResumo()));

        xml += buildSectionRow('2. Parte Contratada');
        xml += buildTwoColRow('2.1. Nome/Razao Social: ' + nvl(ctrl.getParteContratadaNome()), '2.2. CNPJ: ' + nvl(ctrl.getParteContratadaCnpj()));
        xml += buildSingleRow('2.3. Endereco/Sede: ' + nvl(ctrl.getParteContratadaEndereco()));
        xml += buildSingleRow('2.4. Qualificacao/Representante Legal: ' + nvl(ctrl.getParteContratadaRepresentante()));

        xml += buildSectionRow('3. Objeto da Prestacao de Servicos');
        xml += buildSingleRow('3.1. Descricao dos Servicos: ' + nvl(ctrl.getDescricaoServicosResumo()));
        xml += buildSingleRow('3.2. Descricao da Obra Para a Qual Serao Prestados os Servicos: ' + nvl(ctrl.contrato.Descricao_Obra__c));
        xml += buildSingleRow('3.3. Local da Obra: ' + nvl(ctrl.contrato.Local_Obra__c));

        xml += buildSectionRow('4. Preco Contratual');
        xml += buildTwoColRow(valoresLines, new List<String>{'4.2. Data-Base: ' + formatDate(ctrl.contrato.Data_Base__c)});
        xml += buildTwoColRow('4.3. Modalidade: ' + nvl(ctrl.getModalidadeResumo()), '4.4. Indice de Correcao Monetaria: ' + nvl(ctrl.contrato.Indice_Correcao_Monetaria__c));

        xml += buildSectionRow('5. Prazo');
        xml += buildSingleRow('5.1. Prazo de Vigencia: ' + nvl(ctrl.getPrazoVigenciaResumo()));

        xml += buildSectionRow('6. Multas');
        xml += buildTwoColRow('6.1. Por Termino Motivado', nvl(ctrl.getMultaTerminoResumo()));
        xml += buildTwoColRow('6.2. Por Quebra da Obrigacao de Sigilo', nvl(ctrl.getMultaSigiloResumo()));

        xml += buildSectionRow('7. Representantes');
        xml += buildTwoColRow('7.1. Parte Contratante', repContratanteLines);
        xml += buildTwoColRow('7.2. Parte Contratada', repContratadaLines);

        xml += buildSectionRow('8. Anexos');
        xml += buildSingleRow('Anexo I - Proposta Comercial');

        xml += buildSectionRow('9. Disposicoes Adicionais');
        xml += buildSingleRow('9.1. ' + nvl(ctrl.getDisposicoesAdicionaisResumo()));

        xml += '</w:tbl>';
        return xml;
    }

    private static String buildSectionRow(String title) {
        return '<w:tr>' +
            '<w:tc>' +
                '<w:tcPr>' +
                    '<w:tcW w:w="13000" w:type="dxa"/>' +
                    '<w:gridSpan w:val="2"/>' +
                    '<w:shd w:val="clear" w:color="auto" w:fill="D9D9D9"/>' +
                '</w:tcPr>' +
                buildCellParagraphXml(nvl(title), true, false) +
            '</w:tc>' +
        '</w:tr>';
    }

    private static String buildSingleRow(String text) {
        return '<w:tr>' +
            '<w:tc>' +
                '<w:tcPr><w:tcW w:w="13000" w:type="dxa"/><w:gridSpan w:val="2"/></w:tcPr>' +
                buildCellParagraphXml(nvl(text), false, false) +
            '</w:tc>' +
        '</w:tr>';
    }

    private static String buildTwoColRow(String left, String right) {
        return buildTwoColRow(new List<String>{ nvl(left) }, new List<String>{ nvl(right) });
    }

    private static String buildTwoColRow(String left, List<String> rightLines) {
        return buildTwoColRow(new List<String>{ nvl(left) }, rightLines);
    }

    private static String buildTwoColRow(List<String> leftLines, List<String> rightLines) {
        return '<w:tr>' +
            '<w:tc><w:tcPr><w:tcW w:w="6500" w:type="dxa"/></w:tcPr>' + buildCellParagraphsXml(leftLines) + '</w:tc>' +
            '<w:tc><w:tcPr><w:tcW w:w="6500" w:type="dxa"/></w:tcPr>' + buildCellParagraphsXml(rightLines) + '</w:tc>' +
        '</w:tr>';
    }

    private static String buildCellParagraphsXml(List<String> lines) {
        if (lines == null || lines.isEmpty()) {
            return buildCellParagraphXml('', false, false);
        }

        String xml = '';
        for (Integer i = 0; i < lines.size(); i++) {
            String line = lines[i];
            Boolean emphasizeHeader = i == 0 && line != null && line.endsWith(':');
            xml += buildCellParagraphXml(nvl(line), emphasizeHeader, emphasizeHeader);
        }
        return xml;
    }

    private static String buildCellParagraphXml(String text, Boolean bold, Boolean underline) {
        String safeText = normalizeDocText(nvl(text));
        String xml = '<w:p><w:pPr><w:spacing w:after="30" w:line="290" w:lineRule="auto"/></w:pPr>';
        xml += buildRunsXml(parseStyledRuns(safeText, bold == true, underline == true));
        xml += '</w:p>';
        return xml;
    }

    private static String buildRunsXml(List<DocxRun> runs) {
        if (runs == null || runs.isEmpty()) {
            return '<w:r><w:t></w:t></w:r>';
        }

        String xml = '';
        for (DocxRun run : runs) {
            if (run == null || run.text == null || run.text.length() == 0) {
                continue;
            }
            xml += buildRunXml(run);
        }

        return String.isBlank(xml) ? '<w:r><w:t></w:t></w:r>' : xml;
    }

    private static String buildRunXml(DocxRun run) {
        String safeText = nvl(run.text);
        Boolean preserveSpace = safeText.startsWith(' ') || safeText.endsWith(' ') || safeText.contains('  ');
        String preserveAttr = preserveSpace ? ' xml:space="preserve"' : '';

        String xml = '<w:r>';
        xml += buildRunPropertiesXml(run.bold == true, run.underline == true, run.highlight == true);
        xml += '<w:t' + preserveAttr + '>' + escapeXml(safeText) + '</w:t>';
        xml += '</w:r>';
        return xml;
    }

    private static String buildRunPropertiesXml(Boolean bold, Boolean underline, Boolean highlight) {
        if (bold != true && underline != true && highlight != true) {
            return '';
        }

        String xml = '<w:rPr>';
        if (bold == true) {
            xml += '<w:b/>';
        }
        if (underline == true) {
            xml += '<w:u w:val="single"/>';
        }
        if (highlight == true) {
            xml += '<w:highlight w:val="yellow"/>';
        }
        xml += '</w:rPr>';
        return xml;
    }

    private static List<DocxRun> parseStyledRuns(String text, Boolean baseBold, Boolean baseUnderline) {
        List<DocxRun> runs = new List<DocxRun>();
        if (text == null || text.length() == 0) {
            runs.add(new DocxRun('', baseBold, baseUnderline, false));
            return runs;
        }

        Integer cursor = 0;
        while (cursor < text.length()) {
            Integer openIdx = text.indexOf('[', cursor);
            if (openIdx < 0) {
                appendKeywordRuns(runs, text.substring(cursor), baseBold, baseUnderline, false);
                break;
            }

            Integer closeIdx = text.indexOf(']', openIdx + 1);
            if (closeIdx < 0) {
                appendKeywordRuns(runs, text.substring(cursor), baseBold, baseUnderline, false);
                break;
            }

            if (openIdx > cursor) {
                appendKeywordRuns(runs, text.substring(cursor, openIdx), baseBold, baseUnderline, false);
            }

            appendKeywordRuns(runs, text.substring(openIdx, closeIdx + 1), true, baseUnderline, true);
            cursor = closeIdx + 1;
        }

        if (runs.isEmpty()) {
            runs.add(new DocxRun('', baseBold, baseUnderline, false));
        }
        return runs;
    }

    private static void appendKeywordRuns(List<DocxRun> runs, String text, Boolean baseBold, Boolean baseUnderline, Boolean highlight) {
        if (runs == null || text == null || text.length() == 0) {
            return;
        }

        Integer cursor = 0;
        while (cursor < text.length()) {
            KeywordMatch match = findNextKeyword(text, cursor);
            if (match == null) {
                addRun(runs, text.substring(cursor), baseBold, baseUnderline, highlight);
                return;
            }

            if (match.start > cursor) {
                addRun(runs, text.substring(cursor, match.start), baseBold, baseUnderline, highlight);
            }

            addRun(runs, text.substring(match.start, match.endIndex), true, baseUnderline, highlight);
            cursor = match.endIndex;
        }
    }

    private static KeywordMatch findNextKeyword(String text, Integer startOffset) {
        if (text == null || text.length() == 0 || startOffset == null || startOffset < 0 || startOffset >= text.length()) {
            return null;
        }

        KeywordMatch bestMatch;
        for (String keyword : BOLD_KEYWORDS) {
            if (String.isBlank(keyword)) {
                continue;
            }

            Integer searchFrom = startOffset;
            while (searchFrom < text.length()) {
                Integer idx = text.indexOf(keyword, searchFrom);
                if (idx < 0) {
                    break;
                }

                Integer endIdx = idx + keyword.length();
                if (isKeywordBoundary(text, idx, endIdx)) {
                    if (bestMatch == null || idx < bestMatch.start) {
                        bestMatch = new KeywordMatch(idx, endIdx);
                    }
                    break;
                }

                searchFrom = idx + 1;
            }
        }

        return bestMatch;
    }

    private static Boolean isKeywordBoundary(String text, Integer startIdx, Integer endIdx) {
        Boolean leftBoundary = startIdx == 0 || !isWordChar(text.substring(startIdx - 1, startIdx));
        Boolean rightBoundary = endIdx >= text.length() || !isWordChar(text.substring(endIdx, endIdx + 1));
        return leftBoundary && rightBoundary;
    }

    private static Boolean isWordChar(String value) {
        if (String.isBlank(value)) {
            return false;
        }

        String charValue = value.substring(0, 1);
        if (charValue == '_') {
            return true;
        }

        if ('0123456789'.contains(charValue)) {
            return true;
        }

        return charValue.toLowerCase() != charValue.toUpperCase();
    }

    private static void addRun(List<DocxRun> runs, String text, Boolean bold, Boolean underline, Boolean highlight) {
        if (runs == null || text == null || text.length() == 0) {
            return;
        }

        Boolean resolvedBold = bold == true;
        Boolean resolvedUnderline = underline == true;
        Boolean resolvedHighlight = highlight == true;

        if (!runs.isEmpty()) {
            DocxRun last = runs[runs.size() - 1];
            if (last != null &&
                last.bold == resolvedBold &&
                last.underline == resolvedUnderline &&
                last.highlight == resolvedHighlight) {
                last.text += text;
                return;
            }
        }

        runs.add(new DocxRun(text, resolvedBold, resolvedUnderline, resolvedHighlight));
    }

    private static String buildContentTypesXml() {
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
            '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' +
            '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' +
            '<Default Extension="xml" ContentType="application/xml"/>' +
            '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>' +
            '<Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/>' +
            '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>' +
            '<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>' +
            '</Types>';
    }

    private static String buildRelsXml() {
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
            '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>' +
            '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>' +
            '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>' +
            '</Relationships>';
    }

    private static String buildWordDocumentRelsXml() {
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
            '<Relationship Id="rIdFooter1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer" Target="footer1.xml"/>' +
            '</Relationships>';
    }

    private static String buildFooterXml() {
        String runPr = '<w:rPr><w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:cs="Arial"/><w:sz w:val="18"/><w:szCs w:val="18"/></w:rPr>';
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
            '<w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">' +
            '<w:p>' +
            '<w:pPr><w:jc w:val="center"/></w:pPr>' +
            '<w:r>' + runPr + '<w:t xml:space="preserve">Pagina </w:t></w:r>' +
            '<w:r>' + runPr + '<w:fldChar w:fldCharType="begin"/></w:r>' +
            '<w:r>' + runPr + '<w:instrText xml:space="preserve"> PAGE </w:instrText></w:r>' +
            '<w:r>' + runPr + '<w:fldChar w:fldCharType="separate"/></w:r>' +
            '<w:r>' + runPr + '<w:t>1</w:t></w:r>' +
            '<w:r>' + runPr + '<w:fldChar w:fldCharType="end"/></w:r>' +
            '<w:r>' + runPr + '<w:t xml:space="preserve"> de </w:t></w:r>' +
            '<w:r>' + runPr + '<w:fldChar w:fldCharType="begin"/></w:r>' +
            '<w:r>' + runPr + '<w:instrText xml:space="preserve"> NUMPAGES </w:instrText></w:r>' +
            '<w:r>' + runPr + '<w:fldChar w:fldCharType="separate"/></w:r>' +
            '<w:r>' + runPr + '<w:t>1</w:t></w:r>' +
            '<w:r>' + runPr + '<w:fldChar w:fldCharType="end"/></w:r>' +
            '</w:p>' +
            '</w:ftr>';
    }

    private static String buildCoreXml(String title) {
        String nowUtc = Datetime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
            '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" ' +
            'xmlns:dc="http://purl.org/dc/elements/1.1/" ' +
            'xmlns:dcterms="http://purl.org/dc/terms/" ' +
            'xmlns:dcmitype="http://purl.org/dc/dcmitype/" ' +
            'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' +
            '<dc:title>' + escapeXml(nvl(title)) + '</dc:title>' +
            '<dc:creator>Salesforce</dc:creator>' +
            '<cp:lastModifiedBy>Salesforce</cp:lastModifiedBy>' +
            '<dcterms:created xsi:type="dcterms:W3CDTF">' + nowUtc + '</dcterms:created>' +
            '<dcterms:modified xsi:type="dcterms:W3CDTF">' + nowUtc + '</dcterms:modified>' +
            '</cp:coreProperties>';
    }

    private static String buildAppXml() {
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
            '<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" ' +
            'xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">' +
            '<Application>Salesforce</Application>' +
            '<DocSecurity>0</DocSecurity>' +
            '<ScaleCrop>false</ScaleCrop>' +
            '</Properties>';
    }

    private static String escapeXml(String value) {
        if (String.isBlank(value)) {
            return '';
        }

        String clean = value;
        clean = clean.replace('&', '&amp;');
        clean = clean.replace('<', '&lt;');
        clean = clean.replace('>', '&gt;');
        clean = clean.replace('"', '&quot;');
        clean = clean.replace('\'', '&apos;');
        return clean;
    }

    private static String formatDate(Date value) {
        return value == null ? '' : value.format();
    }

    private static String normalizeDocText(String text) {
        if (String.isBlank(text)) {
            return '';
        }

        String output = text;
        output = output.replaceAll('([a-z0-9])(?=(CONTRATADA|CONTRATANTE|CLIENTE))', '$1 ');
        output = output.replaceAll('(?<=(CONTRATADA|CONTRATANTE|CLIENTE))(?=[a-z])', ' ');
        output = output.replaceAll('\\s+', ' ').trim();
        return output;
    }

    private static String nvl(String value) {
        return String.isBlank(value) ? '' : value;
    }
}
