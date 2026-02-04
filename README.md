# 🚀 Game Performance Optimizer (Universal)

**Transforme seu PC em uma máquina de foco.** 
Otimize o desempenho fechando aplicativos pesados automaticamente quando você abre seus jogos ou programas de trabalho.

> **Versão 3.5 [Universal]:** Agora funciona com QUALQUER aplicativo (Steam, Photoshop, VS Code, etc) e suporta múltiplos gatilhos!

![License](https://img.shields.io/badge/license-MIT-green.svg)
![Platform](https://img.shields.io/badge/platform-Windows%2010%2F11-blue.svg)

---

## ✨ O que ele faz?

1. **Monitora em Silêncio:** Fica rodando em segundo plano (consumindo quase 0 memória).
2. **Ativa Automaticamente:** Assim que você abre um "App Gatilho" (ex: abrir o jogo *Cyberpunk* ou o *Premiere*), ele entra em ação.
3. **Libera Recursos:** Fecha navegadores, Discord, Spotify e outros devoradores de RAM.
4. **Restaura Tudo:** Quando você fecha o jogo, ele reabre todos os seus apps e os deixa exatamente como estavam.

## 📥 Como Instalar

1. Vá na aba **[Releases](../../releases)** aqui do GitHub.
2. Baixe o arquivo `GamePerformanceOptimizer-v3.5.zip`.
3. Extraia a pasta.
4. Clique duas vezes em `Install-GameOptimizer.bat`.
   - *Vai pedir permissão de administrador para criar a tarefa agendada.*

## ⚙️ Como Configurar (Passo a Passo)

O instalador agora tem um **Assistente Visual**:

### Passo 1: Escolha os Gatilhos
Selecione QUAIS aplicativos devem ativar o modo foco.
- *Exemplo:* Marque `steam`, `epicgames` e `photoshop`.
- Se qualquer um deles abrir, a otimização começa.

### Passo 2: O que fechar?
Selecione o que deve ser encerrado para liberar memória.
- *Exemplo:* `chrome`, `msedge`, `discord`, `spotify`.
- (Opcional) Marque "Otimizar Serviços do Windows" para pausar serviços inúteis (SysMain, DiagTrack, etc).

## 🎮 Exemplo de Uso

**Cenário Gamer:**
1. Você configurou a **Steam** como gatilho.
2. Você abre a Steam.
3. O Otimizador fecha o Chrome (que estava com 50 abas) e o Discord.
4. Você joga com FPS mais estável.
5. Você fecha a Steam.
6. O Chrome e o Discord abrem sozinhos novamente.

**Cenário Produtividade:**
1. Você configura o **Visual Studio Code** como gatilho.
2. Ao abrir o VS Code, ele fecha o Spotify e o navegador para você focar.

## 🛠️ Resolução de Problemas

**O instalador não abre?**
- Clique com o botão direito no arquivo `.bat` ou `.ps1` -> Propriedades -> Marque "Desbloquear" se houver.
- Tenha certeza que extraiu o ZIP, não rode de dentro do ZIP.

**Espanso / Apps de Sistema:**
- O otimizador já sabe lidar com apps complexos como o Espanso, capturando os argumentos de inicialização corretamente.

## 🤝 Contribuindo

Sinta-se livre para abrir Issues ou Pull Requests. O projeto é 100% PowerShell nativo e fácil de entender.

---
*Desenvolvido para ser leve, rápido e invisível.*
