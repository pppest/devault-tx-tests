# devault-tx-tests
Tx tests for devaultcore

 DeVault wallet tx tests script by pest   

USAGE: ./tx-tests.sh git_branch build_flags   

will clone and build devault core from git_branch with build_flags   
then populate the wallet with the needed utxo   
then make a receiving wallet and start the tests   
for each test it ill create a new wallet and populate it with utxo for   
for the inputs and then send the outputs to new addresses in receiving_wallet   
the number of inputs and outputs, the amount send in each output and other seetings   
can be set in the configuration in the top of the file   
   
 let me know if you prefer to set the configuration as commandline options   

 logs output to: dvt-tests-DATE-TIME.log   

 pest   
