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
SECONDS=0
clear

# Configuration
# main configuration
git_branch=$1
testnet_name=testnet2
testnet2_wallet='"peace loyal duck burden climb bright hint little ribbon near depth stick"'

# input/output tests
amount=11
fee=5
num_inputs=1
num_outputs=1
wait_for_gen=1  # number of secs to wait for each block generated after sending to send_address

# stress tests
num_of_stress_txs=10      # num of how many txs pr stress test
num_of_stress_tests=1  # stress test is done this many times
amount_stress=10

#start daemon and initiate log file
now=$(date +"%Y-%m-%d-%H:%M:%S")
logfile=dvt-tests-$now.log
echo -e "\n\n\nDeVault wallet transaction test script\n" > $logfile
echo -e "DEVAULT TX TESTING\n"
# print Configuration
#check if git_branch is set
if [ -z "$git_branch" ];
  then
    echo -ne "git branch empty not building wallet\033[0K\r"
  else
    if ! test -f "devaultd"; then
      echo -ne "devaultd doesnt exist will build.\033[0K\r"
      git clone -b $git_branch https://github.com/devaultcrypto/devault >> $logfile
      mkdir build
      cd build
      cmake -DBUILD_QT=0 -Wno-dev ../devault . #>> $logfile
      make  -s -j4 #>> $logfile
      cd ..
      echo -ne "copying devaultd and devault-cli\033[0K\r"
      cp build/devaultd .
      cp build/devault-cli .
      rm -rf devault build
      sleep 0.2
    fi;
    echo -ne "devaultd exists will not build\033[0K\r"
fi;

if ! test -f "devaultd";
  then
    echo -ne "devaultd not found\033[0K\r"
    exit
fi;
clear
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

echo -e "\n\n\nDeVault wallet transaction test script\n" > $logfile
echo -e "amount: $amount\nfee: $fee\nnum_inputs: $num_inputs" >> $logfile
echo -e "num_outputs: $num_outputs \nnum_of_stress_tests $num_of_stress_tests" >> $logfile
echo -e "num_of_stress_tx $num_of_stress_txs\namount_stress $amount_stress\n" >> $logfile

./devaultd -testnet -daemon -bypasspassword >> $logfile
sleep 2 #give daemon time to start

# generate inputs for tests
num_of_utxo_needed=$(($num_inputs*$num_outputs+$num_of_stress_txs*$num_of_stress_tests))
num_utxo="0"
echo -ne "Checking if enough utxo in base wallet...\033[0K\r"
until [ $num_utxo -gt $num_of_utxo_needed ]
  do
    unspent=$(./devault-cli -testnet -rpcwallet=wallet.dat listunspent)
    num_utxo=$(echo $unspent | jq '. | length')
    echo -ne "utxo in base wallet: $num_utxo, utxo needed: $num_of_utxo_needed\033[0K\r"
    ./devault-cli -testnet -rpcwallet=wallet.dat generate 100 > /dev/null
    sleep 1
  done;

 #generate receiving_wallet if it doesnt exist
if  [[ ! -f '/home/'$USER'/.devault/'$testnet_name'/wallets/receiving_wallet.dat' ]]
  then
    echo -ne "creating receiving_wallet\033[0K\r"
    ./devault-cli -testnet createwallet receiving_wallet.dat >> $logfile
fi;
./devault-cli -testnet loadwallet receiving_wallet.dat >> $logfile


# add basic info to log file
./devault-cli -testnet -rpcwallet=wallet.dat getinfo >> $logfile
echo balance: >> $logfile
./devault-cli -testnet -rpcwallet=wallet.dat getbalance >> $logfile

#get UNSPENT UTXO
#echo "listUNSPENT" >> $logfile
UNSPENT=$(./devault-cli -testnet -rpcwallet=wallet.dat listunspent)
#echo -e "\nUNSPENTs" >> $logfile
NUM_UTXO=$(echo $UNSPENT | jq '. | length')
echo "number of UTXO: $NUM_UTXO" >> $logfile
#echo $UNSPENT | jq ".[].txid" >> $logfile

echo -e "\n       ------------" >> $logfile

#main loop
x=0 # TX counter
for ((i=1; i<=$num_inputs; i++))
  do
    for o in $(seq 1 $num_outputs);
      do
        x=$((x+1))
        echo -ne "Running test #$x: TX with $i inputs and $o outputs\033[0K\r"

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
          echo $amount \+ $fee \*$o \/$i = >> $logfile
          amount_input=$(( ($amount+$fee)*$o/$i ))
          echo $amount_input >> $logfile
          send_string="./devault-cli -testnet -rpcwallet=wallet.dat sendtoaddress $send_address $amount_input"
          echo $send_string >> $logfile
          $send_string > /dev/null
        done;

        is_spendable=""
        # generate blocks to make tx spendable
        until [ "${is_spendable: -4}" = "true" ];
        do
          ./devault-cli -testnet -rpcwallet=wallet.dat generate 1  > /dev/null
          sleep $wait_for_gen
          #check if spendable
          unspent=$(./devault-cli -testnet -rpcwallet=$send_wallet listunspent)
          is_spendable=$( echo $unspent | jq ".[].spendable" )
        done;

        # outputs balance and wallet info to see if spendable
        echo send_wallet balance >> $logfile
        ./devault-cli -testnet -rpcwallet=$send_wallet  getbalance  >> $logfile
        ./devault-cli -testnet -rpcwallet=$send_wallet  listunspent >> $logfile

        # make list of output addresses needed
        outputs=""
        for oo in $(seq 1 $o);
          do
            send_amount=$(($amount*$i/$o))
            echo send amount $send_amount inputs $i outputs $o >> $logfile
            output_address_string='./devault-cli -testnet -rpcwallet=receiving_wallet.dat getnewaddress'
            output_address=$(eval $output_address_string)
            echo outputs_address is  $output_address >> $logfile
            outputs+='\"'$output_address'\":'$amount','
        done;
        outputs='"{'${outputs::-1}'}"';

        # load send_wallet and sendmany to $o outputs
        sendmany_string='./devault-cli -testnet -rpcwallet='$send_wallet' sendmany "" '$outputs
        echo $sendmany_string >> $logfile
        tx=$( eval $sendmany_string )

      # generate blocks to make tx spendable
      until [ "${is_spendable: -4}" = "true" ];
        do
          ./devault-cli -testnet -rpcwallet=wallet.dat generate 1  > /dev/null
          sleep $wait_for_gen
          #check if spendable
          unspent=$(./devault-cli -testnet -rpcwallet=$send_wallet listunspent)
          is_spendable=$( echo $unspent | jq ".[].spendable" )
        done;

        # output tx info
        tx_info=$(eval './devault-cli -testnet -rpcwallet=receiving_wallet.dat gettransaction '$tx)
        hex=$(echo $tx_info | jq ".hex")
        tx_info=$(eval './devault-cli -testnet decoderawtransaction '$hex)
        echo hex: $hex >> $logfile
#        num_vin=$(echo $tx_info | jq '.vin | length')
#        num_vout=$(echo $tx_info | jq '.vout | length')
#        echo -e "\nvin $num_vin i $i vout $num_vout o $o\n"
    done;
done;

echo -e "\n       ------------" >> $logfile

# stress tests. send a lot of tx
echo Stress tests >> $logfile
for i in $(seq 1 $num_of_stress_tests);
do
  x=$((x+1))
  echo -ne "Test #$x: Stress test with $num_of_stress_txs of $amount_stress DVT TXs\033[0K\r"
  for i in $(seq 1 $num_of_stress_txs);
    do
      send_string="./devault-cli -testnet -rpcwallet=wallet.dat sendtoaddress $send_address $amount_stress"
      #echo $send_string >> $logfile
      #$send_string  >> $logfile
  done;
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
  done;
  echo -e "\n       ------------" >> $logfile


# empty receiving_wallet, stop, cleanup and end script
receiving_wallet_balance=$(./devault-cli -testnet -rpcwallet=receiving_wallet.dat getbalance)
receiving_wallet_balance=${receiving_wallet_balance%.*}
receiving_wallet_balance=$(($receiving_wallet_balance-$fee))
base_wallet_address=$(./devault-cli -testnet -rpcwallet=wallet.dat getnewaddress)
send_string="./devault-cli -testnet -rpcwallet=receiving_wallet.dat sendtoaddress $base_wallet_address $receiving_wallet_balance "" "" true"
$send_string >> $logfile

echo -en "Stop daemon\033[0K\r"
./devault-cli -testnet stop >> $logfile
rm '/home/'$USER'/.devault/'$testnet_name'/wallets/SEND'*
end_time=$(date +"%Y-%m-%d-%H:%M:%S")
echo start time: $now, end time: $end_time >> $logfile
duration=$SECONDS
echo "Testing done in $(($duration / 60)) minutes and $(($duration % 60)) seconds."
# END OF SCRIPT
