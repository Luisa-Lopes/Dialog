#!/bin/bash

# A função autoip() solicita ao usuário informações para configurar automaticamente as interfaces de rede.
autoip(){

    ENDIP=""
    MASCARA=""
    INTERFACE=""
    GATIP=""
    PASSWORD=""

    # Utiliza o comando 'dialog' para criar um formulário interativo e coletar informações do usuário.
    dialog\
         --cancel-label "Voltar" \
         --backtitle "AUTOIP" \
         --title "CONF IP" \
         --form "Digite as informações pedidas"  15 50 0 \
       "Endereço IP:"      1 1   "$ENDIP"        1 13 16 0 \
       "Máscara de rede:"  2 1   "$MASCARA"      2 17 16 0 \
       "Interface:"        3 1   "$INTERFACE"    3 11 11 0 \
       "IP Gateway:"       4 1   "$GATIP"        4 13 16 0 \
       "Senha do Computador:" 5 1 "$PASSWORD"     5 21 15 0 \
       2> ipauto.txt  # Redireciona as respostas do usuário para um arquivo chamado 'ipauto.txt'.

    VALUES="ipauto.txt"

    if [ ! -s $VALUES ]; then 
        rm ./ipauto.txt
        op_VM1
    fi 
    
    # Lê as informações do arquivo 'ipauto.txt'.
    ENDIP=$(sed -n '1p' "$VALUES")
    MASCARA=$(sed -n '2p' "$VALUES")
    INTERFACE=$(sed -n '3p' "$VALUES") 
    GATIP=$(sed -n '4p' "$VALUES")
    PASSWORD=$(sed -n '5p' "$VALUES")

   
    # Cria um script chamado 'ipauto.sh' com comandos para configurar a rede.
    cat > 'ipauto.sh' << EOT
        sleep 10
        echo "$PASSWORD" | sudo -S ifconfig $INTERFACE $ENDIP netmask $MASCARA
        echo "$PASSWORD" | sudo -S route add default gw $GATIP dev $INTERFACE
        sleep 10
EOT
    
    # Define permissões de execução para o script 'ipauto.sh'.
    chmod +x ipauto.sh  

    # Abre um terminal xterm e executa o script 'ipauto.sh'.
    xterm -e './ipauto.sh' & sleep 3

    rm ./ipauto.sh
    rm ./ipauto.txt
}
