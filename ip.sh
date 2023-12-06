#!/bin/bash

# A função get_interfaces() obtém e retorna as interfaces de rede disponíveis no sistema.
get_interfaces() {
    # Usa o comando 'ifconfig' para obter informações sobre as interfaces de rede.
    # Filtra as linhas que contêm a palavra 'BROADCAST' usando 'grep'.
    # Usa 'cut' para extrair o nome da interface, considerando ':' como o delimitador e pegando a primeira parte.
    ifconfig | grep BROADCAST | cut -d ":" -f1
}

# A função config_manual_VM1() gera um menu interativo para a configuração manual de interfaces de rede.
config_manual_VM1() {

    # Obtém os nomes das interfaces de rede disponíveis.
    INTERFACES=$(get_interfaces)

    # Define o nome do arquivo que será gerado dinamicamente.
    ARQUIVO="interfaces.sh"

    # Cria ou atualiza o arquivo 'interfaces.sh'.
    touch "$ARQUIVO"

    # Adiciona parte do código ao arquivo 'interfaces.sh' para criar o menu.
    echo -e -n " dialog --title 'Seleção da VM a ser configurada' --menu 'Selecione uma opção' 10 50 0 " >> "$ARQUIVO"

    # Adiciona opções ao menu para cada interface de rede disponível.
    COUNT=1
    for ITEM in $INTERFACES; do
        echo -n "    $ITEM" "'INTERFACE $COUNT' " >> "$ARQUIVO"
        COUNT=$((COUNT + 1))
    done

    # Adiciona opções adicionais ao menu.
    cat >> "$ARQUIVO" << EOT
    ROUTE  'Default Gateway e Roteamento' DNS  'Domain Name Server' VOLTAR  'Retornar ao menu anterior' SAIR '' 2> conf_manual.txt 
    
    opt=\$(cat conf_manual.txt)
    case \$opt in  
    "ROUTE")
        route
        ;;
EOT

    # Adiciona a lógica para cada interface de rede selecionada no menu.
    for ITEM in $INTERFACES; do
        cat >> "$ARQUIVO" << EOT
    "$ITEM") 
        interfaces $ITEM
        ;; 
EOT
    done

    # Adiciona o restante do código ao arquivo 'interfaces.sh'.
    echo "
        "DNS")
        dns
        ;;
        "VOLTAR")
        op_VM1
        ;;
        "SAIR")
        exit
        ;;
        *) exit
    esac 
" >> "$ARQUIVO" 

    # Executa o arquivo 'interfaces.sh'.
    . $ARQUIVO

    # Remove o arquivo 'interfaces.sh' após a execução.
    rm ./conf_manual.txt
    rm ./interfaces.sh
}


# A função interfaces() configura manualmente uma interface de rede com base nas informações fornecidas pelo usuário.
interfaces() {
    IP=""
    MASCARA=""
    GATEWAY=""
    SENHA=""
    
    # Usa o comando 'dialog' para criar um formulário interativo e coletar informações do usuário.
    dialog \
        --backtitle "CONFIGURAÇÃO DAS INTERFACES" \
        --title "INTERFACE" \
        --form "Digite as informações pedidas" 0 0 0 \
        "Digite o IP:"          1 1 "$IP"        1 13 16 0 \
        "Digite a máscara:"     2 1 "$MASCARA"   2 18 16 0 \
        "Digite o gateway:"     3 1 "$GATEWAY"   3 18 16 0 \
        "Digite a senha:" 4 0 "$SENHA" 4 16 16 0 \
        2> info_interfaces.txt

    INFO="info_interfaces.txt"

    # Verifica se o arquivo de informações está vazio e encerra o script se estiver.
    if [ ! -s $INFO ]; then
        rm $INFO
        echo -e "\nFechando dialog ..."
        sleep 3
        exit
    fi

    # Lê as informações do arquivo 'info_interfaces.txt'.
    IP=$(head -n 1 "$INFO")
    MASCARA=$(sed -n '2p' "$INFO")
    GATEWAY=$(sed -n '3p' "$INFO")
    SENHA=$(sed -n '4p' "$INFO")     

    # Desativa a interface de rede.
    echo $SENHA | sudo -S ip link set dev $1 down

    # Configura o IP, a máscara e o gateway da interface de rede.
    echo $SENHA | sudo -S ifconfig $1 $IP netmask $MASCARA
    echo $SENHA | sudo route add default gw $GATEWAY dev $1 

    # Ativa a interface de rede.
    echo $SENHA | sudo -S ip link set dev $1 up

    # Exibe uma caixa de diálogo informando que as configurações estão sendo realizadas.
    dialog \
        --title 'Aguarde' \
        --infobox '\n Configurações de interfaces sendo realizadas... ' \
        0 0

    # Aguarda por 3 segundos.
    sleep 3

    # Obtém as configurações da interface de rede e exibe em uma caixa de mensagem.
    CONF=$(ifconfig $1)
    dialog \
        --title 'INTERFACE'\
        --ok-label 'Voltar'\
        --msgbox "$CONF" \
         0 0  

    if [ $? = 0 ]; then 
        config_manual_VM1
    fi
    # Remove o arquivo de informações.
    rm $INFO
}
