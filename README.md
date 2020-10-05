# devault-tx-tests
Tx tests for devaultcore

DeVault wallet tx tests bash script by pest   

USAGE: ./tx-tests.sh git_branch    
DEPENDENCIES: uses jq for handling JSON outputs

NOTE: Changed to use regtest network for faster utco generation   

will clone and build devault core from git_branch.   
then populate the wallet with the needed utxo and make a receiving wallet.   
for each test it will create a new wallet and populate it with utxo for   
for the inputs and then send the outputs to new addresses in receiving_wallet   
the number of inputs and outputs, the amount send in each output and other settings   
can be set in the top of the script file   

it will use devaultd and devault-cli from the local dir if you call the script without branch.   

 let me know if you prefer to set the configuration as commandline options   

 logs output to: dvt-tests-DATE-TIME.log   

 pest   
