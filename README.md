# devault-tx-tests
Tx tests for devaultcore

 DeVault wallet tx tests script by pest   
   
 the script requires a address with lots of devault to start with.   
 for testnet2 you can start with this:    
 "peace loyal duck burden climb bright hint little ribbon near depth stick"   
 it then uses this address to   
 sends num_inputs to a new address in a new wallet and then   
 send amount*num_inputs/num_outputs to num_outputs addresses.      
   
 amount set in configuration is send in each input and then   
 the total amount of inputs is divided by num_outputs when send.   
 notice that bash doesnt like float so only whole int amounts are sent.   
 so the total amount of inputs must be large enough to cover atleast 1 dvt+fee pr output.   
 fee set in configuration is added to amount when send to send_address.   
 can give balance when sendind if input txs hasnt been confirmed so dont set wait time too low.   
   
   
 logs output to: dvt-tests-DATE-TIME.log   
   
 pest   
