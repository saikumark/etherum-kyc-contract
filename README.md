Instructions to Start the BlockChain And Deploying the smart contract
1.	Open two sessions, one for Geth and another for truffle commands.
2.	On Geth session, go to the home directory 
ex: cd /home/chvss/
And create test directory in it with mkdir test
Place the Init.json file and run the below command to create genisis block 
geth --datadir ./datadir init Init.json

After successful the log looks like below
 

3.	Then we need to enter into into geth console with the below command
geth --networkid 2019 --datadir datadir --rpc --rpcapi 'web3,eth,net' --rpccorsdomain '*' --rpcaddr 0.0.0.0 --rpcport 8545 --port 30303  --allow-insecure-unlock console

After successful execution it looks as below
 

4.	We need to create the account with the following command
personal.newAccount()

After successful execution it looks as below
 

5.	Unlock it with the password
personal.unlockAccount(eth.accounts[0],"password")

After successful execution it looks as below
 



6.	Start the miner to have account balance
miner.start(1)

After successful execution it looks as below


7.	After few blocks added  and generated the ethash verification code, stop the mining
miner.stop()
 


8.	Go to other session and create new folder as KYC-SC and execute ‘truffle init’ command. Which will create below set of folders and file. 
contracts  migrations  test  truffle-config.js
9.	Copy KYC.sol file under contracts and proceed with next step.
10.	Execute the below command to compile contract
truffle compile

After successful execution it looks as below
 


11.	 To deploy deploy  the contract on blockchain use the below command
truffle migrate --network development

After successful execution it looks as below on the current session.

 


12.	On Geth seesion after deploying the contract is as below. We can find the message as “Submitted contract creation”.
 


13.	Exit from the geth session by executing “exit” command



