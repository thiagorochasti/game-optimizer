# 🎮 Game Performance Optimizer

Fecha automaticamente aplicativos configurados quando você inicia um jogo (ex: Steam) e os reabre quando você termina. Projetado para melhorar o desempenho dos jogos liberando recursos do sistema.

![Platform](https://img.shields.io/badge/plataforma-Windows%2010%2F11-blue.svg)
![PowerShell](https://img.shields.io/badge/powershell-5.1%2B-blue.svg)
![License](https://img.shields.io/badge/licença-MIT-green.svg)

---

## 📖 O que é?

O Game Performance Optimizer é uma ferramenta leve baseada em PowerShell que roda silenciosamente em segundo plano e automaticamente:

1. **Detecta** quando você inicia um aplicativo de jogo (Steam, Epic Games, etc.)
2. **Fecha** aplicativos que consomem muitos recursos (navegadores, Discord, Spotify, etc.)
3. **Para** serviços desnecessários do Windows (opcional)
4. **Reabre** tudo automaticamente quando você fecha o jogo

Nenhuma intervenção manual necessária - simplesmente funciona! 🚀

---

## ✨ Principais Funcionalidades

- **🔍 Detecção Inteligente de Processos** - Extrai automaticamente informações de inicialização dos atalhos da pasta Inicializar
- **🎯 Suporte a Múltiplos Gatilhos** - Monitora vários aplicativos (Steam, Epic Games, Photoshop, etc.)
- **⚙️ Gerenciamento de Serviços** - Opcionalmente para serviços do Windows durante jogos (DiagTrack, SysMain, BITS, etc.)
- **🔄 Reinicialização Automática** - Reabre aplicativos fechados com os argumentos corretos ao sair
- **📊 Logs Robustos** - Logs detalhados para solução de problemas
- **🖥️ Gerenciamento Fácil** - Interface interativa baseada em menu para instalação, atualizações e configuração
- **🛡️ Detecção Genérica de Atalhos** - Funciona com QUALQUER aplicativo que tenha atalho na pasta Inicializar

---

## 📦 Instalação

### Opção 1: Instalação Rápida (Recomendado)

1. Baixe a versão mais recente: **[GamePerformanceOptimizer-v1.0.zip](../../releases/latest)**
2. Extraia o arquivo ZIP
3. Execute `Setup.ps1` (clique com botão direito → Executar com PowerShell)
4. Siga o assistente interativo para selecionar quais aplicativos gerenciar

### Opção 2: Usando a Interface do Gerenciador

1. Baixe e extraia o ZIP
2. Execute `GameOptimizer-Manager.bat`
3. Selecione a opção **[1] Instalar Game Optimizer**
4. Siga o assistente de configuração

---

## 🎮 Como Funciona

### Cenário de Exemplo

**Antes de Jogar:**
- Você tem Chrome (50 abas), Discord, Spotify e outros apps rodando
- Seu sistema está usando ~8GB de RAM

**Você Inicia a Steam:**
1. Game Optimizer detecta a Steam iniciando
2. Fecha automaticamente Chrome, Discord, Spotify
3. Para serviços desnecessários do Windows (se habilitado)
4. Seu sistema agora tem ~4GB de RAM disponível para jogos

**Você Fecha a Steam:**
1. Game Optimizer detecta que a Steam foi fechada
2. Reabre automaticamente Chrome, Discord, Spotify com os argumentos corretos
3. Reinicia os serviços do Windows
4. Tudo volta ao normal

---

## 🛠️ Interface de Gerenciamento

Execute `GameOptimizer-Manager.bat` para acesso fácil a:

```
========================================
 Game Performance Optimizer v3.5
========================================

  Status: INSTALADO
  Estado: Running

  [1] Ver Status Detalhado
  [2] Atualizar/Reiniciar Servico
  [3] Reconfigurar (mudar apps)
  [4] Ver Logs
  [5] Desinstalar
  [0] Sair

========================================
  Escolha uma opcao:
```

---

## ⚙️ Configuração

O arquivo `config.json` (criado durante a instalação) contém todas as configurações:

```json
{
  "triggerProcess": ["steam"],
  "processesToManage": [
    "chrome",
    "msedge",
    "discord",
    "spotify",
    "slack"
  ],
  "processesToReopenOnly": [
    "chrome",
    "discord",
    "spotify"
  ],
  "servicesToManage": [
    "DiagTrack",
    "SysMain",
    "BITS",
    "DoSvc"
  ],
  "settings": {
    "steamCheckInterval": 5,
    "enableLogging": true,
    "enableServiceManagement": true,
    "reopenDelay": 3
  }
}
```

### Opções de Configuração

| Configuração | Descrição |
|--------------|-----------|
| `triggerProcess` | Aplicativos que ativam a otimização (ex: `steam`, `epicgames`) |
| `processesToManage` | Aplicativos a fechar durante jogos |
| `processesToReopenOnly` | Aplicativos que devem ser reabertos após jogos |
| `servicesToManage` | Serviços do Windows a parar durante jogos |
| `steamCheckInterval` | Com que frequência verificar se o gatilho está rodando (segundos) |
| `enableLogging` | Habilitar/desabilitar logs |
| `enableServiceManagement` | Habilitar/desabilitar gerenciamento de serviços do Windows |
| `reopenDelay` | Atraso antes de reabrir apps (segundos) |

---

## 📋 Requisitos

- **SO:** Windows 10 ou Windows 11
- **PowerShell:** 5.1 ou superior (pré-instalado no Windows 10/11)
- **Privilégios:** Administrador (apenas para instalação)

---

## 🐛 Solução de Problemas

### Apps não estão fechando?

1. Verifique os logs: `GameOptimizer-Manager.bat` → Opção **[4]**
2. Verifique se o nome do processo corresponde exatamente (ex: `chrome` não `chrome.exe`)
3. Certifique-se de ter permissão para fechar o processo
4. Verifique se o app está rodando com privilégios elevados

### Apps não estão reabrindo?

- **Detecção de atalhos** extrai automaticamente informações de inicialização para apps na pasta Inicializar
- Para apps **não** na pasta Inicializar, usa-se WMI como fallback para capturar argumentos
- Verifique os logs por mensagens **"Extracted from Startup shortcut"**
- Se a reabertura falhar, verifique se o app requer argumentos específicos

### Erros de gerenciamento de serviços?

- Execute a instalação como **Administrador**
- Certifique-se de que os serviços não são críticos para o funcionamento do Windows
- Desabilite o gerenciamento de serviços no `config.json` se necessário:
  ```json
  "settings": {
    "enableServiceManagement": false
  }
  ```

### Tarefa não está rodando?

1. Abra o Agendador de Tarefas
2. Procure por **"GamePerformanceOptimizer"**
3. Clique com botão direito → **Executar** para testar manualmente
4. Verifique a aba **Histórico** para erros

---

## 🔧 Desinstalação

1. Execute `GameOptimizer-Manager.bat`
2. Selecione a opção **[5] Desinstalar**
3. Confirme a remoção

**Ou** execute `Uninstall-GameOptimizer.bat` diretamente.

---

## 🤝 Contribuindo

Contribuições são bem-vindas! Sinta-se à vontade para enviar um Pull Request.

### Configuração de Desenvolvimento

1. Clone o repositório
2. Copie `config.sample.json` para `config.json`
3. Modifique os scripts conforme necessário
4. Teste usando `GameOptimizer.ps1` diretamente

---

## 📄 Licença

Este projeto é open source e está disponível sob a [Licença MIT](LICENSE).

---

## 📞 Suporte

Para problemas, dúvidas ou solicitações de recursos:
- 🐛 [Abra uma issue](../../issues)
- 💬 [Inicie uma discussão](../../discussions)

---

## ⭐ Mostre Seu Apoio

Se você achar este projeto útil, considere dar uma estrela no GitHub!

---

**Feito com ❤️ para ajudar gamers a obter o melhor desempenho**
