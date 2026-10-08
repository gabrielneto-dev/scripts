#!/usr/bin/env bash

read -rp "Digite a porta que deseja verificar: " PORTA

# Valida a porta
if ! [[ "$PORTA" =~ ^[0-9]+$ ]] || \
   (( 10#$PORTA < 1 || 10#$PORTA > 65535 )); then
    echo "Porta inválida! Informe um número entre 1 e 65535."
    exit 1
fi

PORTA=$((10#$PORTA))

echo ""
echo "Verificando porta $PORTA..."

# Verifica processos TCP e UDP
PROCESSOS=$(sudo lsof -nP -t -iTCP:"$PORTA" -sTCP:LISTEN 2>/dev/null
            sudo lsof -nP -t -iUDP:"$PORTA" 2>/dev/null)

PROCESSOS=$(echo "$PROCESSOS" | sort -u | sed '/^$/d')

if [[ -z "$PROCESSOS" ]]; then
    echo "✅ Nenhum processo encontrado na porta $PORTA."
    exit 0
fi

echo ""
echo "Processos encontrados:"
echo "----------------------------------------"

ps -p "$(echo "$PROCESSOS" | paste -sd, -)" \
   -o pid,user,comm,args

echo "----------------------------------------"

# Exibe containers que publicam a porta
if command -v docker >/dev/null 2>&1; then
    echo ""
    echo "Containers Docker com essa porta publicada:"
    docker ps --format '{{.Names}} | {{.Ports}}' |
       grep -E "(^|[:, ])${PORTA}->" || true
fi

echo ""
read -rp "Deseja finalizar esses processos? (s/N): " RESPOSTA

if [[ ! "$RESPOSTA" =~ ^[sS]$ ]]; then
    echo "Operação cancelada."
    exit 0
fi

echo ""
echo "Encerrando processos..."

while read -r PID; do
    [[ -z "$PID" ]] && continue

    if sudo kill -TERM "$PID"; then
        echo "Sinal de encerramento enviado ao PID $PID."
    else
        echo "Falha ao encerrar PID $PID."
    fi
done <<< "$PROCESSOS"

sleep 1

echo ""
if sudo lsof -nP -iTCP:"$PORTA" -sTCP:LISTEN \
    -iUDP:"$PORTA" 2>/dev/null | grep -q .; then
    echo "⚠️ A porta $PORTA ainda pode estar em uso."
    echo "O processo pode ter sido reiniciado automaticamente."
else
    echo "✅ Porta $PORTA sem processos detectados."
fi

