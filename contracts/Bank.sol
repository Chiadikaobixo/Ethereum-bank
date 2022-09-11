// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


contract Bank {
    struct User{
        string bankName;
        string password;
        uint256 balance;
        uint256 date;
        string accountType;
    }
     
    struct Transaction{
        uint256 amount;
        address destination;
        uint256 date;
    }
    
    // 
    string nameBank;
    // 
    address recipient;
    
    // mapping of address to password
    mapping(address => User) public _fetchUser;
    // mapping of addess to transaction
    mapping(address => Transaction) public _lastTransactions;
    // 
    mapping(address => bytes32) public passwords;
   
    User[] public users;
    Transaction[] public transaction;

    constructor() payable {
        // bank name
        nameBank = "Ethereum Bank";
    }


    // The following two functions allow the contract to accept ETH deposits
    // directly from a wallet without calling a function
    receive() external payable {}

    fallback() external payable {}

    /**
     * @dev accountExists verifies if an address has a password
    */
    function accountExist(address _address) public view returns(bool) {
        // return true if password exist
        return passwords[_address] != bytes32(0);
    }
    
    /**
    * @dev createAccount creates a user account 
    */
    function createAccount(string memory password )public payable {
        // zero address "0x000000000..."
        require(msg.sender != address(0), "You cannot use a zero address");
        require(msg.value != 0, "Can not deposit 0 amount");
        require(msg.value >= 0.1 ether, "Insufficient amount");
        require(!accountExist(msg.sender), "You already have an account");
        User storage createUser = users.push();
        createUser.bankName = nameBank;
        createUser.password = password;
        // createUser.recipient = payable (msg.sender);
        createUser.date = block.timestamp;
        passwords[msg.sender] = keccak256(abi.encodePacked(password));
        if(msg.value >= 0.1 ether){
            createUser.accountType = "Savings Account";
        }
        if(msg.value >= 0.5 ether){
            createUser.accountType = "Current Account";
        }
        if(msg.value >= 10 ether){
            createUser.accountType = "Off-shore Account";
        }
        createUser.balance = msg.value;
        _fetchUser[msg.sender] = createUser;
    }
    
     
    /**
     * deposit eth to the contract address unbehalf of the user account
    */
    function deposit()public payable {
        require(msg.sender != address(0), "You cannot use a zero address");
        require(msg.value != 0, "Cannot deposit 0");
        require(accountExist(msg.sender), "Account address does not exist");
        _fetchUser[msg.sender].balance += msg.value;
        Transaction storage userTransaction = transaction.push();
        userTransaction.amount = msg.value;
        userTransaction.destination = msg.sender;
        userTransaction.date = block.timestamp;
        _lastTransactions[msg.sender] = userTransaction;
    }

    /**
     * @dev withdraw the amount of eth from the contract to the users address 
    */
    function withdraw(uint amount) public payable {
        require(msg.sender != address(0), "You cannot use a zero address");
        require(accountExist(msg.sender), "Account address does not exist");
        require(getAccountBalance() >= msg.value, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        _fetchUser[msg.sender].balance -= amount;
    }
    
    /**
    * @dev allTransactions returns all transaction history of the owner
    */
    function alltransction() public view returns (Transaction[] memory) {
        return transaction;
    }
     
     /**
     * @dev getAccountBalance returns the amount of eth a user has in account
     */
    function getAccountBalance() public view returns(uint){
        require(accountExist(msg.sender), "Account address does not exist, Create and account");
        return  _fetchUser[msg.sender].balance;
    }
}