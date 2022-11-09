## Ethereum Bank
#### Ethereum bank is a smart contract bank, you can think of it as a normal bank but it operates on ether.     

This is a smart contract that allows a user to create an account with the Ethereum Bank. A bytes32 password is required for the account creation, the password will be hashed off-chain, and then set onchain.      
1. users can withdraw ethereum at any point in time in respect to their account balance        
2. users are eligible for a one time interest of their total account balance, this is only available to users who have not debited their account in the pass 100 days. newly created account must be up to 100 days before being aligible for interest       
3. interest differs to different users, in respect to their account status    
4. users can deposit to their ethereum bank account     
5. users can transfer eth to other users of the ethereum bank     
6. users can do an inter tranfer from their ethereum bank account to a user ethereum address     
7. users can change their account password      

### account status    
#### Savings Account    
0.1 ether minimum deposit and eligible for 2% interest rate    

#### Current Account    
0.5 ether minimum deposit and eligible for 3% interest rate    

#### Off-shore Account   
10 ether minimum deposit and eligible for 5% interest rate  

[Deployed contract on Goerli Etherscan.](https://goerli.etherscan.io/address/0x45aa685e3788C79C7529c16C7215e772BA47E2A1 "bank")    