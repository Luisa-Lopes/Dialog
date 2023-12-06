#!/bin/bash

# A função dns() solicita ao usuário informações para configurar servidores DNS.
dns() {

    DNS1=""
    DNS2=""
    PASSWORD=""
    # Utiliza o comando 'dialog' para criar um formulário interativo e coletar informações do usuário.
    dialog\
         --backtitle "CONF DNS" \
         --title "CONF DNS" \
         --form "Digite as informações pedidas"  0 0 0 \
       "Primeiro DNS:"  1 1 "$DNS1" 1 14 13 0 \
       "Segundo DNS:"   2 1 "$DNS2" 2 13 14 0 \
       "Senha:"   3 0 "$PASSWORD" 3 9 14 0 \
       2> confdns.txt  # Redireciona as respostas do usuário para um arquivo chamado 'confdns.txt'.

    VALUES="confdns.txt"
    
    if [ ! -s $VALUES ]; then 
        rm ./confdns.txt
        exit
    fi 

    # Lê as informações do arquivo 'confdns.txt'.
    DNS1=$(sed -n '1p' "$VALUES")
    DNS2=$(sed -n '2p' "$VALUES")
    PASSWORD=$(sed -n '3p' "$VALUES")

    
    # Cria um script chamado 'confdns.sh' com comandos para configurar os servidores DNS.
    cat > 'confdns.sh' << EOT
        #!/bin/bash
        
         sleep 3
         "\n"
         echo "$PASSWORD" | sudo -S sh -c 'echo nameserver $DNS1 | tee /etc/resolv.conf'
         sleep 3
         echo "$PASSWORD" | sudo -S sh -c 'echo nameserver $DNS2 | tee -a /etc/resolv.conf'
         sleep 10
EOT
    

    # Define permissões de execução para o script 'confdns.sh'.
    echo "$PASSWORD" | sudo -S chmod 777 confdns.sh  
    
   
    # Abre um terminal xterm e executa o script 'confdns.sh' e remove o arquivo confdns.txt após a execução.
    xterm -e './confdns.sh' & sleep 3 &&  ./confdns.txt
    
    # Exibe uma caixa de diálogo informando que as configurações estão sendo realizadas.
    dialog \
        --title 'Aguarde' \
         --sleep 10 \
        --infobox '\n Configurações estão realizadas... ' \
        0 0

    if [ $? = 0 ]; then 
        config_manual_VM1
    fi
    
    
}
