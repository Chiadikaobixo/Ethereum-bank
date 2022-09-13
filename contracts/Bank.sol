// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Bank {
    struct User {
        string bankName;
        string password;
        uint256 balance;
        uint256 createdAt;
        address userAddress;
        string accountType;
    }

    struct Transaction {
        uint256 amount;
        address destination;
        uint256 date;
    }

    struct InterestTime {
        uint256 date;
    }

    // bank name
    string nameBank;
    
    // mapping of address to password
    mapping(address => User) public userDetail;
    // mapping of address to transaction
    mapping(address => Transaction) public _lastTransactions;
    // mapping of address to interestTime
    mapping(address => InterestTime) private _dueInterest;
    // mapping of address to password
    mapping(address => bytes32) private passwords;
    // mapping of address to boolean
    mapping(address => bool) private time;

    User[] private users;
    Transaction[] private transaction;
    InterestTime[] private interestTime;

    modifier restricted() {
        require(msg.sender != address(0), "You cannot use a zero address");
        require(accountExist(msg.sender), "Account address does not exist");
        _;
    }
    
    /**
     * @dev constructor takes the string and set the nameBank
    */
    constructor() {
        nameBank = "Ethereum Bank";
    }

    /**
     * @dev The following two functions allow the contract to accept ETH deposits
     * directly from a wallet without calling a function
    */
    receive() external payable {}

    fallback() external payable {}

    /**
     * @dev accountExists verifies if an address has a password ie, the address is
     * registered with Ethereum bank
     */
    function accountExist(address _address) public view returns (bool) {
        // return true if password exist
        return passwords[_address] != bytes32(0);
    }

    /**
     * @dev createAccount creates a user account
     */
    function createAccount(string memory password) public payable {
        // zero address "0x000000000..."
        require(msg.sender != address(0), "You cannot use a zero address");
        require(msg.value != 0, "Can not deposit 0 amount");
        require(msg.value >= 0.1 ether, "Insufficient amount");
        require(!accountExist(msg.sender), "You already have an account");

        User storage createUser = users.push();
        createUser.bankName = nameBank;
        createUser.password = password;
        createUser.userAddress = msg.sender;
        createUser.createdAt = block.timestamp;
        passwords[msg.sender] = keccak256(abi.encodePacked(password));

        if (msg.value >= 0.1 ether) {
            createUser.accountType = "Savings Account";
        }
        if (msg.value >= 0.5 ether) {
            createUser.accountType = "Current Account";
        }
        if (msg.value >= 10 ether) {
            createUser.accountType = "Off-shore Account";
        }

        createUser.balance = msg.value;
        userDetail[msg.sender] = createUser;

        // updates transaction history
        updateTransaction();
        // update time to keep track of when a user is eligible to cliam intereset
        eligibleInterest();
    }

    /**
     * deposit eth to the Ethereum Bank unbehalf of the user account
     */
    function deposit() public payable restricted {
        require(msg.value != 0, "Cannot deposit 0");
        userDetail[msg.sender].balance += msg.value;
        // updates transaction history
        updateTransaction();
    }

    /**
     * @dev withdraw the amount of eth from the contract to the users address
     */
    function withdraw(uint256 amount) public payable restricted {
        require(getBalance() >= msg.value, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        userDetail[msg.sender].balance -= amount;

        // updates transaction history
        Transaction storage userTransaction = transaction.push();
        userTransaction.amount = amount;
        userTransaction.destination = msg.sender;
        userTransaction.date = block.timestamp;
        _lastTransactions[msg.sender] = userTransaction;

        // update time to keep track of when a user is eligible to cliam intereset
        eligibleInterest();
    }

    /**
     * @dev returns 5% on interest of your savings after 100days of no transaction
     */
    function claimInterest() public payable restricted {
        require(
            time[msg.sender] == false,
            "you have already withdrew your interest"
        );
        require(
            block.timestamp > _dueInterest[msg.sender].date + 5 minutes,
            "You are not eligible for interest"
        );
        uint256 interestRate = (userDetail[msg.sender].balance * 5) / 100;
        payable(msg.sender).transfer(interestRate);
        time[msg.sender] = true;
    }

    /**
     * @dev bankTranfer: transfers eth from the Ethereum Bank users account to
     * another user account
     */
    function bankTransfer(address to, uint256 amount)
        public
        payable
        restricted
    {
        require(getBalance() >= amount, "Insufficient balance");
        // 1% transfer charges per transaction within the Ethereum Bank
        uint256 tax = (amount * 1) / 100;
        uint256 totalAmount = amount + tax;
        // debit from the senders account
        userDetail[msg.sender].balance -= totalAmount;
        // transfer to address;
        userDetail[to].balance += amount;
        
        // updates transaction history
        Transaction storage userTransaction = transaction.push();
        userTransaction.amount = amount;
        userTransaction.destination = to;
        userTransaction.date = block.timestamp;
        _lastTransactions[msg.sender] = userTransaction;

         // update time to keep track of when a user is eligible to cliam intereset
        eligibleInterest();
    }

    /**
     * @dev interTransfers eth from the Ethereum Bank users account to
     * an etheruem address
     * Note: the address `to` can be a registered Ethereum Bank user or not.
     */
    function interTransfer(address to, uint256 amount)
        public
        payable
    {
        require(msg.sender != address(0), "You cannot use a zero address");
        require(getBalance() >= amount, "Insufficient balance");
        // 2% transfer charges per transaction to an ethereum address
        uint256 tax = (amount * 2) / 100;
        uint256 totalAmount = amount + tax;
        // debit from the senders account
        userDetail[msg.sender].balance -= totalAmount;
        // transfer to the receiver
        payable(to).transfer(amount);
        
        // updates transaction history
        Transaction storage userTransaction = transaction.push();
        userTransaction.amount = amount;
        userTransaction.destination = to;
        userTransaction.date = block.timestamp;
        _lastTransactions[msg.sender] = userTransaction;

         // update time to keep track of when a user is eligible to cliam intereset
        eligibleInterest();
    }

    /**
     * @dev allTransactions returns all transaction history of a user (msg.sender)
     */
    function alltransction() public view returns (Transaction[] memory) {
        return transaction;
    }

    /**
     * @dev getBalance returns the amount of eth a user (msg.sender) has in account
     */
    function getBalance() public view returns (uint256) {
        require(
            accountExist(msg.sender),
            "Account address does not exist, Create and account"
        );
        return userDetail[msg.sender].balance;
    }

    /**
     * @dev updateTransaction: this function returns the transaction history of a user
     */
    function updateTransaction() private restricted {
        Transaction storage userTransaction = transaction.push();
        userTransaction.amount = msg.value;
        userTransaction.destination = msg.sender;
        userTransaction.date = block.timestamp;
        _lastTransactions[msg.sender] = userTransaction;
    }

    /**
    * @dev eligibleInterest: this function returns the last withdrawal time of a user
    */
    function eligibleInterest()private restricted{
        InterestTime storage user = interestTime.push();
        user.date = block.timestamp;
        _dueInterest[msg.sender] = user;
    }
}