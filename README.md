# Salesforce DX Project

Projeto base para desenvolvimento em Salesforce (SFDX format).

## Estrutura

- `force-app`: código fonte (Apex, LWC, objetos, etc.)
- `manifest/package.xml`: manifesto para retrieve/deploy por metadata API
- `config/project-scratch-def.json`: definição de Scratch Org

## Comandos úteis (quando instalar Salesforce CLI)

```bash
sf org login web --alias devhub --set-default-dev-hub
sf org create scratch --definition-file config/project-scratch-def.json --alias projeto-scratch --set-default --duration-days 7
sf project deploy start
sf apex run test --result-format human --code-coverage --wait 10
```

## Fluxo para org sandbox existente

Quando sua sandbox estiver pronta, rode:

```bash
npm run sandbox:setup
```

Se quiser pular deploy e testes nesse primeiro sincronismo:

```bash
powershell -ExecutionPolicy Bypass -File scripts/run-sandbox-flow.ps1 -SkipDeploy -SkipTests
```
