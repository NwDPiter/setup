# Wake-on-LAN (WoL) - Configuração e Teste

Scripts para configurar e testar Wake-on-LAN em sistemas Linux.

## Arquivos

- **wake.sh** - Script de configuração do WoL
- **test-wol.sh** - Script para testar WoL

---

## 1️⃣ Configuração Inicial (wake.sh)

### O que faz?

O script `wake.sh` automatiza a configuração completa de Wake-on-LAN:

1. Instala `ethtool` (se necessário)
2. Detecta interfaces de rede
3. Valida status atual do WoL
4. Ativa WoL na interface escolhida
5. Configura netplan para persistência
6. Aplica as configurações

### Como usar?

```bash
sudo ./wake.sh
```

O script é interativo e vai:
- Listar interfaces de rede disponíveis
- Pedir para escolher qual configurar
- Verificar e ativar WoL se necessário
- Configurar arquivo de rede
- Mostrar instruções finais

---

## 2️⃣ Configuração BIOS

⚠️ **IMPORTANTE** - Antes de testar, configure sua BIOS:

### Opções necessárias:

#### 1. **Reiniciar por PME (Power Management Event): HABILITADO**
   - Permite que a placa de rede acorde a máquina
   - Geralmente em: Power Management → Wake on LAN

#### 2. **Função EUP (Energy Efficient Processor): DESABILITADO**
   - Permite que a placa mantenha energia mínima
   - Necessário para escutar pacotes quando desligado

---

## 3️⃣ Testando Wake-on-LAN (test-wol.sh)

### Opções disponíveis:

```
1) Testar WoL (enviar Magic Packet)
2) Verificar informações de rede do PC local
3) Verificar status WoL do PC local
0) Sair
```

### Como usar?

```bash
./test-wol.sh
```

### Testar de outro PC

Para acordar o PC remotamente:

```bash
wakeonlan -i <BROADCAST> -p <PORTA> <MAC>
```

**Exemplo:**
```bash
wakeonlan -i 192.168.1.255 -p 7 AA:BB:CC:DD:EE:FF
```

---

## 📋 Como descobrir informações do seu PC?

### Descobrir MAC Address

```bash
ip a
# ou específico:
ip a show eno1 | grep "link/ether"
```

**Resultado esperado:** `link/ether aa:bb:cc:dd:ee:ff brd ff:ff:ff:ff:ff:ff`

### Descobrir Endereço de Broadcast

```bash
ip -br a
```

**Resultado esperado:**
```
eno1  UP  192.168.1.100/24
```

Do IP/NETMASK, calcula o broadcast:
- IP: `192.168.1.100` / NETMASK: `24`
- Broadcast: `192.168.1.255`

### Outros exemplos de cálculo:

| IP/NETMASK | Broadcast |
|:--|:--|
| 192.168.1.0/24 | 192.168.1.255 |
| 192.168.0.0/25 | 192.168.0.127 |
| 10.0.0.0/22 | 10.0.3.255 |

---

## ⚙️ Fluxo Completo

### Configuração (1ª vez)

1. Execute: `sudo ./wake.sh`
2. Configure BIOS
3. Reinicie o PC
4. Teste com: `./test-wol.sh`

### Teste de funcionamento

**PC A (aquele que você quer acordar):**
```bash
sudo ./wake.sh  # Configure uma vez
```

**PC B (outro PC para acordar o PC A):**
```bash
./test-wol.sh
# Escolha opção 1 e forneça:
# - MAC do PC A
# - Broadcast da rede
# - Porta (7 ou 8)
```

---

## 🔧 Troubleshooting

### WoL não funciona?

1. **Verifique BIOS:**
   - "Reiniciar por PME" deve estar HABILITADO
   - "Função EUP" deve estar DESABILITADO

2. **Verifique status WoL:**
   ```bash
   sudo ethtool eno1 | grep Wake-on
   # Deve mostrar: Wake-on: g (ativado)
   ```

3. **Verifique conectividade:**
   ```bash
   ping -b 192.168.1.255  # Ping para o broadcast
   ```

4. **Reinstale drivers da placa:**
   ```bash
   sudo apt update
   sudo apt install --reinstall linux-modules-extra-$(uname -r)
   ```

---

## 📚 Referências

- Documentação ethtool: `man ethtool`
- Documentação wakeonlan: `man wakeonlan`
- Netplan docs: https://netplan.io/

---

## 📝 Notas

- Scripts testados em Ubuntu 20.04+ e Debian 11+
- Requer conexão à rede (não funciona via WiFi em alguns casos)
- O PC deve estar completamente desligado, não em suspensão
- Alguns roteadores podem bloqucar Magic Packets por padrão

