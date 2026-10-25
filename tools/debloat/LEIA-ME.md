# tools/debloat — limpeza segura e reversível de TVs Android via adb

Complementa o Free My TV: o app já desliga a lista do `HomeMode.DEBLOAT` ao trocar a tela inicial; estes scripts
desligam o que mais o inventário da sua TV mostrar, com **as mesmas proteções do app** (a lista `PROTECTED` é lida do
próprio `HomeMode.java`, então acompanha o upstream).

Cada TV tem um **perfil** em `perfis/` (a marca e o modelo ficam no perfil, não na ferramenta) e uma pasta própria em
`out/<ip>/`, fora do git, com o inventário e o registro do que foi desligado.

| Passo | Comando | Muda a TV? |
|---|---|---|
| 1. Inventário | `TV=<ip> ./tools/debloat/1-inventario.sh` | Não |
| 2. Perfil | escreva `tools/debloat/perfis/<marca-modelo>.txt` a partir de `out/<ip>/` | Não |
| 3. Simular | `TV=<ip> ./tools/debloat/2-aplicar.sh perfis/<perfil>.txt` | Não |
| 3. Aplicar | `TV=<ip> ./tools/debloat/2-aplicar.sh perfis/<perfil>.txt --valer` | Sim (`pm disable-user`, reversível) |
| 4. Testar | `TV=<ip> ./tools/debloat/3-testar.sh` | Reinicia |
| Desfazer tudo | `TV=<ip> ./tools/debloat/9-reverter.sh` | Religa |
| Desfazer um | `TV=<ip> ./tools/debloat/9-reverter.sh <pacote>` | Religa |

O `2-aplicar.sh` recusa, mesmo que esteja no perfil: a lista `PROTECTED` do Free My TV, peças do Android, serviços do
Google e a Play Store, menus de fábrica, apps que salvaram uma rede Wi-Fi (o Android apagaria a rede) e apps usados
pelas entradas HDMI e pelo tuner. Nunca use `pm uninstall` ou `pm clear` em app do sistema.

Perfis:

| Perfil | TV | Testado |
|---|---|---|
| [`tcl-c06.txt`](perfis/tcl-c06.txt) | TCL C06, Android TV 11 (AR2101), 1 GB | 25/10/2026 |

Depois de mudar um perfil, teste um pacote por vez: imagem, som, cada HDMI, TV aberta, controle, Wi-Fi e Play Store.
Bons candidatos a valer para toda TV da marca merecem ir para o `HomeMode.DEBLOAT` do upstream, com um PR.
