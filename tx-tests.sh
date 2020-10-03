#!/bin/bash
#
# DeVault wallet tx tests script by pest
#
# the script requires a address with lots of devault to start with.
# it then uses this address to
# sends num_inputs to a new address in a new wallet and then
# send amount*num_inputs/num_outputs to num_outputs addresses from a
# list of receiving addresses gievn in output_addresses.txt
# to output_addresses.
#
# amount set in configuration is send in each input and then
# the total amount of inputs is divided by num_outputs when send.
# notice that bash doesnt like float so only whole int amounts are sent.
# so the total amount of inputs must be large enough to cover atleast 1 dvt
# + fee pr output.
# fee set in configuration is added to amount when send to send_address.
#
# logs output to: dvt-tests-DATE-TIME.log
#
# pest

clear
# Configuration
inputs_from=$1
inputs_to=$2
outsputs_from=$3
outputs_to=$4
git_branch=$5
testnet_name=testnet2
amount=4
fee=2
num_inputs=2
num_outputs=2

num_gen_blocks=10 # blocks generated after sending to send_address
wait_for_gen=1  # number of secs to wait for each block generated after sending to send_address

testnet2_wallet='"peace loyal duck burden climb bright hint little ribbon near depth stick"'

echo -e '
\033[33;9m

____________   _______________  _______________  ___
\______ \   \ /   /\__    ___/  \__    ___/\   \/  /
 |    |  \   Y   /   |    |       |    |    \     /
 |    `   \     /    |    |       |    |    /     \
/_______  /\___/     |____|       |____|   /___/\  \
        \/                                       \_/
______________________ ____________________
\__    ___/\_   _____//   _____/\__    ___/
  |    |    |    __)_ \_____  \   |    |
  |    |    |        \/        \  |    |
  |____|   /_______  /_______  /  |____|
                   \/        \/
   by     p e s t
\033[0m
'

#check if git_branch is set
#if [ -z "$git_branch" ];
#  then
#    git clone -b $git_branch https://github.com/devaultcrypto/devault
#    mkdir build
#    cd build
#    cmake ../devault .
#    make -j24
#    cd ..
#    cp build/devaultd .
#    cp build/devault-cli .
#    rm -r devault
#fi

#start daemon and initiate log file
now=$(date +"%Y-%m-%d-%H:%M:%S")
logfile=dvt-tests-$now.log
echo -e "DEVAULT TX TESTING\n"
# print Configuration
echo -e "\n\n\nDeVault wallet transaction test script\n" > $logfile
echo -e "amount: $amount\nfee: $fee\nnum_inputs: $num_inputs\nnum_outputs: $num_outputs\n" >> $logfile

#first run check
FILE=~/.devault/$testnet_name/wallets/receiving_wallet.dat
if ! test -f "$FILE";
  then
    echo "first run, creating base wallet and receiving_wallet.dat";
    #start daemon and create base wallet
    echo -e "\nStarting daemon in from this dir" >> $logfile
    ./devaultd -testnet -daemon -bypasspassword #-seedphrase=$testnet2_wallet
    sleep 2 #give daemon time to start
    ./devault-cli -testnet createwallet receiving_wallet.dat; >> $logfile
  else
    # start daemon
    ./devaultd -testnet -daemon -bypasspassword #>> $logfile
    sleep 2 #give daemon time to start
    echo loading receiving_wallet.dat
    ./devault-cli -testnet loadwallet receiving_wallet.dat >> $logfile
fi

# add basic info to log file
./devault-cli -testnet -rpcwallet=wallet.dat getinfo >> $logfile
echo balance: >> $logfile
./devault-cli -testnet -rpcwallet=wallet.dat getbalance >> $logfile

#get UNSPENT UTXO
#echo "listUNSPENT" >> $logfile
#UNSPENT=$(./devault-cli -testnet -rpcwallet=wallet.dat listunspent)
#echo -e "\nUNSPENTs" >> $logfile
#NUM_UTXO=$(echo $UNSPENT | jq '. | length')
#echo "number of UTXO: $NUM_UTXO" >> $logfile
#echo $UNSPENT | jq ".[].txid" >> $logfile


echo -e "\n       ------------" >> $logfile

#main loop
x=0 # TX counter
for ((i=1; i<=$num_inputs; i++))
  do
    for o in $(seq 1 $num_outputs);
      do
        x=$((x+1))
        echo Test \#$x: TX with $i inputs and $o outputs

        # for $o outputs make list of $i inputs and send tx
        echo -e "\nTX with $i inputs and $o outputs" >> $logfile

        #make new wallet + address and send $i outputs to it
        send_wallet=SENDWALLET-i$i-o$o-$now.dat
        echo -e "\n"$send_wallet >> $logfile
        echo ./devault-cli -testnet createwallet $send_wallet >> $logfile
        ./devault-cli -testnet createwallet $send_wallet >> $logfile
        send_address=$(./devault-cli -testnet -rpcwallet=$send_wallet getnewaddress)
        echo send_address $send_address >> $logfile

        # send amount of inputs to send_address
        for ii in $(seq 1 $i);
        do
          amount_w_fee=$((($amount+$fee)*$o/$i))
          send_string="./devault-cli -testnet -rpcwallet=wallet.dat sendtoaddress $send_address $amount_w_fee"
          echo $send_string #>> $logfile
          $send_string #> /dev/null
        done;

        is_spendable=""
        # generate blocks to make tx spendable
        until [ "${is_spendable: -4}" = "true" ];
        do
          ./devault-cli -testnet -rpcwallet=wallet.dat generate 1  > /dev/null
          sleep $wait_for_gen
          #check if spendable
          unspent=$(./devault-cli -testnet -rpcwallet=$send_wallet listunspent)
          echo $unspent >> $logfile
          is_spendable=$( echo $unspent | jq ".[].spendable" )
          echo $is_spendable >> $logfile
        done;

        # outputs balance and wallet info to see if spendable
        echo send_wallet balance #>> $logfil
        ./devault-cli -testnet -rpcwallet=$send_wallet  getbalance  #>> $logfile
        ./devault-cli -testnet -rpcwallet=$send_wallet  listunspent #>> $logfile

        # make list of output addresses needed
        outputs=""
        for oo in $(seq 1 $o);
          do
            send_amount=$(($amount*$i/$o))
            echo send amount $send_amount inputs $i outputs $o >> $logfile
            #amount=$((amount-$fee))
            output_address_string='./devault-cli -testnet -rpcwallet=receiving_wallet.dat getnewaddress'
            output_address=$(eval $output_address_string)
            echo outputs_address is  $output_address >> $logfile
            outputs+='\"'$output_address'\":'$amount','
        done;
        outputs='"{'${outputs::-1}'}"';

        # load send_wallet and sendmany to $o outputs
        sendmany_string='./devault-cli -testnet -rpcwallet='
        sendmany_string+=$send_wallet
        sendmany_string+=' sendmany "" '
        sendmany_string+=$outputs
        echo $sendmany_string #>> $logfile
        eval $sendmany_string #>> $logfile

      # generate blocks to make tx spendable
      for b in $(seq 1 $num_gen_blocks);
      do
        sleep $wait_for_gen
        ./devault-cli -testnet -rpcwallet=wallet.dat generate 1  >/dev/null
      done;
    done;
done;

    echo -e "\n       ------------"

# end script
echo -e "\nout of loop"
echo -e "\nStop daemon\n"
./devault-cli -testnet stop
end_time=$(date +"%Y-%m-%d-%H:%M:%S")
echo start time: $now, end time: $end_time >> $logfile
# END OF SCRIPT
