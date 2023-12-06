#!/bin/bash

source iperf.sh
source autoip.sh
source dns.sh
source ip.sh

# A função process() exibe uma caixa de mensagem com a lista de processos e pergunta ao usuário se deseja matar um processo.
process() {

    ./testeProc.sh &
    # Obtém a lista de processos usando o comando 'ps'.
    PROCESSOS=$(ps)

    # Utiliza o comando 'dialog' para exibir uma caixa de mensagem com a lista de processos.
    dialog \
        --begin 1 20\
        --title 'Processos' \
        --msgbox "$PROCESSOS" 10 40 \
        --and-widget  --yesno  '\n Gostaria de matar um processo?' 8 30 

    # Verifica a resposta do usuário (0 indica 'Sim', 1 indica 'Não').
    if [ $? = 0 ]; then 
        dialog --inputbox 'Digite O PID:' 0 0  2>/tmp/pid.txt
        PID=$( cat /tmp/pid.txt )
        kill $PID
        
        dialog --title 'Aguarde' --sleep 3 --infobox '\nMatando o processo...' 0 0
        
        PROCESSO=$(ps)
        dialog \
            --ok-label "Voltar" \
            --title 'Processos' \
            --msgbox "$PROCESSO" 10 40 
            
         if [ $? = 0 ]; then 
            op_VM1
         fi
    else
        op_VM1
    fi
}

# A função route() exibe uma caixa de mensagem com a lista de rotas usando o comando 'ip ro'.
route() {
    # Obtém a lista de rotas usando o comando 'ip ro'.
    ROUTE=$(ip ro)
   
    # Utiliza o comando 'dialog' para exibir uma caixa de mensagem com a lista de rotas.
    dialog \
        --ok-label "Voltar" \
        --title 'ROUTER'\
        --msgbox "$ROUTE" \
        0 0  
    if [ $? = 0 ]; then 
         config_manual_VM1
         fi
}

# A função conf_list() exibe uma caixa de mensagem com informações de configuração do sistema.
conf_list() {
    # Utiliza o comando 'dialog' para exibir uma caixa de mensagem com informações de configuração do sistema.
    CONF=$(cat /proc/version)
    
    dialog \
        --ok-label "Voltar" \
        --title 'Lista de Configurações do sistema'\
        --msgbox "$CONF" \
        0 0
        
     if [ $? = 0 ]; then 
        op_VM1
     fi
        
}

# A função op_VM1() exibe um menu para configuração da máquina virtual 1 (VM1).
op_VM1() {

    # Utiliza o comando 'dialog' para criar uma caixa de diálogo com um menu. 
    # Define o tamanho da caixa de diálogo (0 indica tamanho automático)
    # Redireciona a escolha do usuário para um arquivo temporário.
    
    dialog \
        --title 'Tecla de controle VM1'\
        --menu 'Escolha uma Opção'\
        0 0 0 \
        AUTOIP 'Configuração automática das Interfaces de Rede'\
        IP 'Configuração Manual das Interfaces de Rede'\
        PROC 'Listar e matar Processos'\
        CONF 'Listar configurações de sistemas'\
        IPERF 'Enviar arquivo com IPERF'\
        VOLTAR 'Retornar ao menu principal'\
        SAIR ''\
        2> /tmp/op  

    # Lê a opção escolhida pelo usuário do arquivo temporário.
    opt=$(cat /tmp/op)

    # Utiliza uma estrutura de caso para determinar a ação a ser executada com base na opção escolhida.
    case $opt in
        "AUTOIP")
            autoip  # Chama a função 'autoip' para configurar automaticamente as interfaces de rede.
            ;;
        "IP")
            config_manual_VM1  # Chama a função 'config_manual_VM1' para configuração manual das interfaces de rede.
            ;;
        "PROC")
            process  # Chama a função 'process' para listar e matar processos.
            ;;
        "CONF")
            conf_list  # Chama a função 'conf_list' para listar configurações de sistemas     
            ;;
        "IPERF")
            iperf  # Chama a função 'iperf' para enviar arquivo com IPERF.
            ;;
        "VOLTAR")
            main  # Retorna ao menu principal chamando a função 'main'.
            ;;
        "SAIR")
            exit  # Sai do script se a opção escolhida for 'SAIR'.
            ;;
        *) exit  # Sai do script se a opção não for reconhecida.
    esac
  
}


main()
{
    # Utiliza o comando 'dialog' para criar uma caixa de dialogo com um menu.
    # Define o tamanho da caixa de diálogo (linhas, colunas, 0 indica altura dinâmica).
    # Define a opção VM1 no menu com a descrição 'Máquina virtual 1'.
    # Define a opção VM2 no menu com a descrição 'Máquina virtual 2'. 
    # Define a opção 'SAIR' no menu e redireciona a escolha para um arquivo temporário.
    
    dialog \
    --title 'Selecao da VM a ser configurada'\
    --menu 'Selecione uma oção' 10 50 0 \
    VM1 'Máquina virtual 1'\
    VM2 'Máquina virtual 2'\
    SAIR '' \
    2> /tmp/select_vm 

    # Lê a opção escolhida pelo usuário do arquivo temporário.
    opt=$(cat /tmp/select_vm)

    sleep 4
    # Utiliza uma estrutura de caso para determinar a ação a ser executada com base na opção escolhida.
    case $opt in
        "VM1")
            op_VM1  # Chama a função op_VM1 se a opção escolhida for "VM1".
            ;;
        "VM2")
            dialog --msgbox 'Escolha da VM2' 5 40  # Exibe uma caixa de mensagem se a opção escolhida for "VM2".
            ;;
        "SAIR")
            exit  # Sai do script se a opção escolhida for "SAIR".
            ;;
        *) exit  # Sai do script se a opção não for reconhecida.
    esac

    # Remove o arquivo temporário usado para armazenar a escolha do usuário.
    rm /tmp/select_vm
}

main

