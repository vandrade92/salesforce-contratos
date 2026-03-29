# Contexto do Projeto - Automacao de Contratos (Salesforce)

Atualizado em: 2026-03-29
Repositorio: https://github.com/vandrade92/salesforce-contratos
Branch principal: main

## 1) Objetivo
Centralizar criacao, customizacao e geracao de contratos no objeto `Contrato__c`, com base na `Opportunity` fechada/ganha, com:
- modelo padrao por tipo de servico,
- clausulas clonaveis e editaveis por contrato,
- geracao de PDF (preview e versao final),
- geracao de DOCX editavel.

`Propostas__c` nao participa do fluxo. A proposta esta em `Opportunity`.

## 2) Escopo Implementado
- Biblioteca de modelos:
  - `Contrato_Padrao__c`
  - `Clausula_Padrao__c`
- Instancia negociada:
  - `Contrato__c`
  - `Clausula__c`
- Inicializacao automatica do contrato com snapshot de dados da oportunidade/conta/contato.
- Clonagem de clausulas padrao para clausulas editaveis.
- Renderizacao de PDF via Visualforce e Apex.
- Geracao final em `Files` (`ContentVersion`) com controle de versao.
- Geracao de DOCX em `Files` (com quadro resumo em tabela e paginacao).
- Numeracao automatica das clausulas ativas.
- Layouts por tipo de registro em `Opportunity` e `Contrato__c`.
- Mapeamento automatico de `Opportunity.Servico__c` para `RecordType` da oportunidade.

## 3) Objetos e Relacoes
### 3.1 Biblioteca padrao
- `Contrato_Padrao__c` (modelo do contrato)
- `Clausula_Padrao__c` (filho de `Contrato_Padrao__c`)

### 3.2 Contrato operacional
- `Contrato__c` (vinculo principal com `Oportunidade__c`)
- `Clausula__c` (filho de `Contrato__c`)
  - referencia a clausula de origem: `Origem_Clausula_Padrao__c`

### 3.3 Campos de controle importantes em `Contrato__c`
- `Contrato_Padrao__c`
- `Tipo_Contrato__c`
- `Inicializado__c`
- `Versao_Documento__c`
- `Data_Geracao_Final__c`
- `Arquivo_Final_Id__c`

## 4) Mapeamento de Servico
Categoria detectada por texto em `Opportunity.Servico__c`:
- monitoramento remoto -> `monitoramento`
- assistencia tecnica judicial / acao judicial -> `assistencia`
- elaboracao de parecer tecnico -> `parecer`
- diagnostico de contrato / diagnostico + pleito -> `diagnostico`

Esse mapeamento alimenta:
1. `Opportunity.RecordTypeId` (trigger antes de insert/update)
2. `Contrato__c.Tipo_Contrato__c` e `Contrato__c.Contrato_Padrao__c` (default no before de `Contrato__c`)

Arquivos-chave:
- `force-app/main/default/classes/OpportunityRecordTypeService.cls`
- `force-app/main/default/classes/ContratoTemplateService.cls`
- `force-app/main/default/triggers/OpportunityTrigger.trigger`
- `force-app/main/default/triggers/ContratoTrigger.trigger`

## 5) Fluxo Ponta a Ponta
1. Usuario preenche `Opportunity` com campos comerciais/contratuais.
2. Trigger da oportunidade ajusta `RecordType` conforme `Servico__c`.
3. Contrato e criado (via botao/automacao da org).
4. Trigger de `Contrato__c`:
   - before: define tipo/template e valida dados minimos.
   - after: inicializa snapshot e clona clausulas padrao.
5. Usuario pode editar `Clausula__c` no contrato.
6. Usuario pode:
   - Visualizar PDF (`Visualizar Contrato`)
   - Gerar PDF final em Files (`Gerar Versao Final`)
   - Gerar DOCX em Files (`Gerar DOCX`)
   - Recarregar clausulas do padrao (`Recarregar Clausulas do Padrao`)

## 6) Campos Obrigatorios na Opportunity (validacao de criacao do contrato)
Base (todas as categorias):
- Conta
- Contato do Contrato
- Servico
- Numero da Proposta
- Data de Envio da Proposta
- Dona da Obra
- Municipio da Obra

Monitoramento:
- Quantidade de Visitas
- Valor Mensal Monitoramento
- Prazo Minimo Pleito (dias)
- Prazo Pagamento (dias)
- Valor Unico Pleito
- Taxa Sucesso Pleito (%)

Diagnostico:
- Prazo Minimo Pleito (dias)
- Prazo Pagamento (dias)
- Valor Unico Pleito
- Taxa Sucesso Pleito (%)

Assistencia Judicial:
- Prazo Pagamento (dias)
- Valor Unico Pleito
- Taxa Sucesso Pleito (%)

Parecer:
- Prazo Parecer (dias)
- Prazo Parecer (extenso)

Fonte: `ContratoTemplateService.collectRequiredOpportunityFields`.

## 7) Assinatura e Dados Contratuais
- `Data_Assinatura_Contrato__c` deve ser preenchida no `Contrato__c` (nao na oportunidade).
- O campo existe em `Opportunity` por legado, mas nao e exigido para o fluxo e nao deve ser usado para operacao atual.

Dados da CONTRATADA (fixos no controller):
- Nome: PROFITTO GESTAO DE CONTRATOS LTDA
- CNPJ: 42.966.005/0001-13
- Endereco e representante fixos no codigo

Fonte: `force-app/main/default/classes/ContratoPdfController.cls`.

## 8) Clausulas, Numeracao e Formatacao
- Clausulas ativas (`Ativa__c=true`) sao renderizadas.
- Numeracao automatica da ordem (`Ordem__c`) por contrato ao inserir/atualizar/deletar clausulas.
- Lista com algarismos romanos em itens internos (i, ii, iii...).
- Normalizacao de espacos e correcoes de colagem de placeholders no texto.

Arquivos-chave:
- `force-app/main/default/triggers/ClausulaTrigger.trigger`
- `force-app/main/default/classes/ClausulaOrderService.cls`
- `force-app/main/default/classes/ContratoPdfController.cls`

## 9) Geracao de Documentos
### 9.1 PDF
- Preview: pagina VF `ContratoPdf`.
- Final: `ContratoGenerateFinalController` gera blob PDF, grava em `ContentVersion`, incrementa `Versao_Documento__c` e atualiza metadados no contrato.

### 9.2 DOCX
- `ContratoGenerateDocxController` usa `ContratoDocxService`.
- Inclui cabecalho, quadro resumo em tabela, clausulas e secao de assinaturas.
- Rodape com paginacao (PAGE / NUMPAGES).

Arquivos-chave:
- `force-app/main/default/pages/ContratoPdf.page`
- `force-app/main/default/classes/ContratoGenerateFinalController.cls`
- `force-app/main/default/classes/ContratoGenerateDocxController.cls`
- `force-app/main/default/classes/ContratoDocxService.cls`

## 10) Botoes no Contrato
Em `Contrato__c`:
- `Visualizar Contrato`
- `Gerar Versao Final`
- `Gerar DOCX`
- `Recarregar Clausulas do Padrao`

Metadata:
- `force-app/main/default/objects/Contrato__c/webLinks/*.webLink-meta.xml`

## 11) Layouts e Record Types
### Opportunity
Layouts por record type:
- Layout Monitoramento Remoto
- Layout Assistencia Judicial
- Layout Elaboracao de Parecer
- Layout Diagnostico de Contrato

### Contrato__c
Layouts por tipo de contrato, com botoes e secoes especificas.

## 12) Seeds e Massa de Teste
Opcoes disponiveis:
1. Classe Apex de seed: `ContratoSeedService.createSampleContracts()`
2. Script agressivo de reset: `scripts/reset_sandbox_contratos.apex`
   - APAGA oportunidades e contratos existentes antes de recriar dados de teste.
   - Usar com cuidado em sandbox.

## 13) Como Continuar em Outro Computador
1. Instalar Node.js e Salesforce CLI.
2. Clonar repo:
   - `git clone https://github.com/vandrade92/salesforce-contratos.git`
   - `cd salesforce-contratos`
3. Instalar dependencias:
   - `npm install`
4. Autenticar sandbox:
   - `sf org login web --alias minha-sandbox --instance-url https://test.salesforce.com`
5. Deploy:
   - `sf project deploy start --target-org minha-sandbox --source-dir force-app`
6. (Opcional) Testes:
   - `sf apex run test --target-org minha-sandbox --test-level RunLocalTests --wait 30`

Atalho de onboarding do projeto:
- `npm run sandbox:setup`

## 14) Pontos de Atencao
- Existem metadados com historico de encoding em labels antigos. Evitar renome manual sem planejamento.
- `scripts/reset_sandbox_contratos.apex` e destrutivo para dados de teste existentes.
- Se um servico novo for criado em `Opportunity.Servico__c`, atualizar mapeamento em:
  - `OpportunityRecordTypeService`
  - `ContratoTemplateService` (categoria/tipo contrato)

## 15) Checklist Rapido de Troubleshooting
- Contrato nao inicializou:
  - verificar `Oportunidade__c`, `Tipo_Contrato__c`, `Contrato_Padrao__c`, `Inicializado__c`.
- Erro de campos faltando ao criar contrato:
  - validar campos obrigatorios por categoria na `Opportunity`.
- Clausulas fora de ordem:
  - salvar qualquer alteracao em clausula para disparar renumeracao automatica.
- Campo aparecendo fora do esperado em tela:
  - validar layout por record type + hard refresh do navegador.

---
Se este documento ficar defasado, atualizar junto com qualquer mudanca estrutural no fluxo de contratos.
