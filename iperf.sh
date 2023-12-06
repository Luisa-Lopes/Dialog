#!/bin/bash


# A função iperf() cria uma interface interativa para configurar e executar testes iperf entre um cliente e um servidor.
iperf() {

    CLIENTNAME=""
    CLIENTIP=""
    CLIENTPASSWORD=""
    SERVERNAME=""
    SERVERIP=""
    SERVERPASSWORD=""

    # Usa o comando 'dialog' para criar um formulário interativo e coletar informações do usuário.
    dialog  \
        --cancel-label "Voltar" \
	    --backtitle "Linux User Management" \
	    --title "Useradd" \
	    --form "Create a new user" \
        15 50 0 \
	    "Nome do cliente:"     1 1 "$CLIENTNAME"        1 17 15 0 \
	    "IP do cliente:"       2 1 "$CLIENTIP"          2 15 15 0 \
	    "Senha do cliente:"    3 1 "$CLIENTPASSWORD"    3 17 15 0 \
	    "Nome do servidor:"     4 1 "$SERVERNAME"        4 18 15 0 \
        "Ip do servidor:"       5 1 "$SERVERIP"          5 16 15 0 \
        "Senha do servidor:"    6 0 "$SERVERPASSWORD"    6 19 15 0 \
        2> valuesuser.txt

    VALUES="valuesuser.txt"
    
    if [ ! -s $VALUES ]; then 
        rm ./valuesuser.txt
        op_VM1
    fi 

    # Lê as informações do arquivo 'valuesuser.txt'.
    CLIENTNAME=$(head -n 1 "$VALUES")
    CLIENTIP=$(sed -n '2p' "$VALUES")
    CLIENTPASSWORD=$(sed -n '3p' "$VALUES") 
    SERVERNAME=$(sed -n '4p' "$VALUES")
    SERVERIP=$(sed -n '5p' "$VALUES") 
    SERVERPASSWORD=$(sed -n '6p' "$VALUES")

    # Usa o comando 'dialog' para criar um menu interativo para selecionar o tipo de teste a ser realizado.
    dialog \
	    --title 'Tipo de arquivo que deseja enviar'\
        --menu 'Selecione uma opção' \
		10 50 0 \
        ARQUIVO 'Arquivo' \
        VOICE  'Voice'\
		VOLTAR  'Retornar ao menu anterior'\
		SAIR '' 2> /tmp/select_type
		
		
		opt=$(cat /tmp/select_type)
			case $opt in
                "ARQUIVO")
                    # Chama a função 'files' passando as informações do usuário.
                    files $CLIENTNAME $CLIENTIP $CLIENTPASSWORD $SERVERNAME $SERVERIP $SERVERPASSWORD
                    ;;
                "VOICE")
                    # Chama a função 'voice' passando as informações do usuário.
                    voice $CLIENTNAME $CLIENTIP $CLIENTPASSWORD $SERVERNAME $SERVERIP $SERVERPASSWORD
                    ;;
         		"VOLTAR")
         		    # Retorna 'voltar' indicando a intenção de voltar ao menu anterior.
         		    iperf
         		    ;;
         		"SAIR")
         		    # Encerra o script.
         		    break
         		    ;;
         		*) 
         		    exit
         		    ;;
      		esac 
    # Remove arquivos temporários.
    rm /tmp/select_type valuesuser.txt
}

# A função files() configura e executa testes iperf para transferência de arquivos entre um cliente e um servidor.
files() {

    NCONNNECTIONS=""
    BUFFER=""
    TCP=""
    PORTSERVER=""
    SOCKET=""
    FORMAT=""
    TIME=""

    # Usa o comando 'dialog' para criar um formulário interativo e coletar informações do usuário.
    dialog \
	    --backtitle "Iperf3" \
	    --title "Especificações do iperf cliente" \
	    --form "Digite as informações pedidas" 15 60 0 \
	    "Número de conexões:"                 1 1	"$NCONNNECTIONS" 	1 20 30 0 \
	    "Comprimento do buffer:"              2 1	"$BUFFER"  	2 23 27 0 \
	    "Tamanho máximo do segmento TCP:"     3 1	"$TCP"  	3 33 17 0 \
	    "A porta do servidor:"                4 1	"$PORTSERVER" 	4 21 29 0 \
        "Tamanho do buffer de socket:"        5 1 "$SOCKET" 5 30 20 0 \
        "Especificar o formato para imprimir 'k' 'K' 'm' 'M' " 6 1 "$FORMAT" 7 0 25 0 \
        "Tempo para transmitir:" 8 1 "$TIME" 8 23 27 0 \
        2> fileoptions.txt

    FILEOP="fileoptions.txt"
    
    if [ ! -s $FILEOP ]; then 
        rm fileoptions.txt
        exit
    fi 

    # Lê as informações do arquivo 'fileoptions.txt'.
    NCONNNECTIONS=$(head -n 1 "$FILEOP")
    BUFFER=$(sed -n '2p' "$FILEOP")
    TCP=$(sed -n '3p' "$FILEOP") 
    PORTSERVER=$(sed -n '4p' "$FILEOP")
    SOCKET=$(sed -n '5p' "$FILEOP") 
    FORMAT=$(sed -n '6p' "$FILEOP")
    TIME=$(sed -n '6p' "$FILEOP")

    # Verifica se o endereço IP do cliente não é "192.168.20.4".
    if [ "$2" != "192.168.20.4" ]; then 
        # Cria um script chamado 'fileClient.sh' com comandos para executar o teste iperf no cliente usando SSH.
        cat > 'fileClient.sh' << EOT
    sleep 3
    sshpass -p '$3' ssh -tt $1@$2 << EOF
    iperf -c $5 -P $NCONNNECTIONS -i $BUFFER $TCP -p $PORTSERVER -w $SOCKET -f $FORMAT -t $TIME
    sleep 3
    EOF 
EOT
    else 
        # Cria um script chamado 'fileClient.sh' com comandos para executar o teste iperf no cliente sem SSH.
        cat > 'fileClient.sh' << EOT
    sleep 20
    iperf -c $5 -P $NCONNNECTIONS -i $BUFFER $TCP -p $PORTSERVER -w $SOCKET -f $FORMAT -t $TIME
    sleep 3
EOT
    fi

    # Verifica se o endereço IP do servidor não é "192.168.20.4".
    if [ "$5" != "192.168.20.4" ]; then
        # Cria um script chamado 'fileServer.sh' com comandos para executar o servidor iperf usando SSH.
        cat > 'fileServer.sh' << EOT
        sleep 3
        sshpass -p '$6' ssh -tt $4@$5 << EOF
        iperf -s
        EOF
        sleep 3
EOT
    else
        # Cria um script chamado 'fileServer.sh' com comandos para executar o servidor iperf sem SSH.
        cat > 'fileServer.sh' << EOT
    sleep 3
    iperf -s
    EOF
    sleep 3
EOT
    fi
    
    # Define permissões de execução para os scripts criados.
    chmod +x fileServer.sh 
    chmod +x fileClient.sh 
     
    # Abre terminais xterm para executar os scripts do servidor e do cliente.
    xterm -e './fileServer.sh' & sleep 3 && xterm -e './fileClient.sh'

    # Remove arquivos temporários.
    rm ./fileoptions.txt fileServer.sh fileClient.sh
    
}

# A função voice() coleta informações sobre os parâmetros do teste iperf relacionado ao envio de voz entre um cliente e um servidor.
voice() {

OPC=""
SEGMENTO=""
BANDA=""
CONNECTIONS=""
FORMATC=""
BUFFERC=""
TIMEC=""   
    
    # Usa o comando 'dialog' para criar um formulário interativo e coletar informações do usuário para o cliente.
    dialog \
	    --backtitle "Voice" \
	    --title "Especificações do envio de voz do cliente" \
	    --form "Digite as informações pedidas" 15 60 0 \
	    "Para TCP '' para UDP -u:"                   1 1	"$OPC" 	1 26 7 0 \
	    "Tamanho do segmento:"                      2 1	"$SEGMENTO"  	2 21 12 0 \
	    "Largura de Banda:"                         3 1	"$BANDA"  	3 18 15 0 \
	    "Número de conexões:"                       4 1	"$CONNECTIONS" 	4 20 13 0 \
        "Especificar o formato para imprimir 'k' 'K' 'm' 'M'"   5 1 "$FORMATC" 6 0 32 0 \
        "O comprimentos dos buffers:"                7 1 "$BUFFERC" 7 28 5 0 \
        "Tempo para transmitir:"                    8 1 "$TIMEC" 8 23 10 0 \
        2> voiceClient.txt

    VOICECLIENT="voiceClient.txt"
    
    if [ ! -s $VOICECLIENT ]; then 
        rm voiceClient.txt
        op_VM1
    fi 

    # Lê as informações do arquivo 'voiceClient.txt'.
    OPC=$(head -n 1 "$VOICECLIENT")
    SEGMENTO=$(sed -n '2p' "$VOICECLIENT") 
    BANDA=$(sed -n '3p' "$VOICECLIENT") 
    CONNECTIONS=$(sed -n '4p' "$VOICECLIENT")
    FORMATC=$(sed -n '5p' "$VOICECLIENT") 
    BUFFERC=$(sed -n '6p' "$VOICECLIENT")
    TIMEC=$(sed -n '6p' "$VOICECLIENT")

OPS=""
BUFFERS=""
BANDAS=""
CONNECTIONSS=""
FORMATS=""
BUFFERS="" 

    # Usa o comando 'dialog' novamente para criar um formulário interativo e coletar informações do usuário para o servidor.
     dialog \
	    --backtitle "Voice" \
	    --title "Especificações do envio de voz do servidor" \
	    --form "Digite as informações pedidas" 15 60 0 \
	    "Para TCP '' para UDP '-u':"                   1 1	"$OPS" 	1 28 5 0 \
	    "Tamanho do segmento:"                      2 1	"$BUFFERS"  	2 21 12 0 \
	    "Largura de Banda:"                         3 1	"$BANDAS"  	3 18 15 0 \
	    "Número de conexões:"                       4 1	"$CONNECTIONSS" 	4 20 13 0 \
        "Especificar o formato para imprimir 'k' 'K' 'm' 'M'"        5 1 "$FORMATS" 6 0 33 0 \
        "O comprimentos dos buffers:"                7 1 "$BUFFERS" 7 28 5 0 \
        2> voiceServer.txt

    VOICESERVER="voiceServer.txt"

    # Lê as informações do arquivo 'voiceServer.txt'.
    OPS=$(head -n 1 "$VOICESERVER")
    BUFFERS=$(sed -n '2p' "$VOICESERVER")
    BANDAS=$(sed -n '3p' "$VOICESERVER") 
    CONNECTIONSS=$(sed -n '4p' "$VOICESERVER")
    FORMATS=$(sed -n '5p' "$VOICESERVER")
    BUFFERS=$(sed -n '6p' "$VOICESERVER")


##Arquivo para o cliente

# Verifica se o endereço IP do cliente não é "172.24.10.4".
if [ "$2" != "172.24.10.4" ]; then 
        # Cria um script chamado 'voiceClient.sh' com comandos para executar o teste iperf no cliente usando SSH.
        cat > 'voiceClient.sh' << EOT
    sleep 3
    sshpass -p '$3' ssh -tt $1@$2
    iperf -c $5 $OPC -m $SEGMENTO -b $BANDA -P $CONNECTIONS -f $FORMATC -i $BUFFERC -t $TIMEC
    sleep 3
EOT
else 
        # Cria um script chamado 'voiceClient.sh' com comandos para executar o teste iperf no cliente sem SSH.
        cat > 'voiceClient.sh' << EOT
    sleep 3
    iperf -c $5 $OPC -m $SEGMENTO -b $BANDA -P $CONNECTIONS -f $FORMATC -i $BUFFERC -t $TIMEC
    sleep 3
EOT
fi


## Cria arquivo para o servidor

# Verifica se o endereço IP do servidor não é "172.24.10.4".
if [ "$5" != "172.24.10.4" ]; then
    # Cria um script chamado 'voiceServer.sh' com comandos para executar o servidor iperf usando SSH.
    cat > 'voiceServer.sh' << EOT
        sleep 3
        sshpass -p '$6' ssh -tt $4@$5 << EOF
        iperf -s $OPS -mss $BUFFERS -S $BANDAS -P $CONNECTIONSS -f $FORMATS -i $BUFFERS
        EOF
        sleep 3
EOT
else
    # Cria um script chamado 'voiceServer.sh' com comandos para executar o servidor iperf sem SSH.
    cat > 'voiceServer.sh' << EOT
    sleep 3
    iperf -s $OPS -mss $BUFFERS -S $BANDAS -P $CONNECTIONSS -f $FORMATS -i $BUFFERS
    sleep 3
EOT
fi
    
    # Define permissões de execução para os scripts criados.
    chmod +x voiceServer.sh 
    chmod +x voiceClient.sh 
     
    # Abre terminais xterm para executar os scripts do servidor e do cliente.
    xterm -e './voiceServer.sh' & sleep 3 && xterm -e './voiceClient.sh'

    # Remove arquivos temporários.
    rm ./voiceServer.sh ./
}
