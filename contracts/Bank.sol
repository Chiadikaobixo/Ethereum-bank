// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Bank {
    struct User {
        string bankName;
        string password;
        uint256 balance;
        uint256 date;
        address recipient;
        string accountType;
    }

    struct Transaction {
        uint256 amount;
        address destination;
        uint256 date;
    }

    //
    string nameBank;
    //
    // address recipient;

    // mapping of address to password
    mapping(address => User) public _fetchUser;
    // mapping of address to transaction
    mapping(address => Transaction) public _lastTransactions;
    // mapping of address to password
    mapping(address => bytes32) public passwords;
    //
    mapping(address => bool) public time;

    User[] public users;
    Transaction[] public transaction;

    modifier restricted() {
        require(msg.sender != address(0), "You cannot use a zero address");
        require(accountExist(msg.sender), "Account address does not exist");
        _;
    }

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
        createUser.recipient = msg.sender;
        createUser.date = block.timestamp;
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
        _fetchUser[msg.sender] = createUser;

        // updates transaction history
        updateTransaction();
    }

    /**
     * deposit eth to the Ethereum Bank unbehalf of the user account
     */
    function deposit() public payable restricted {
        require(msg.value != 0, "Cannot deposit 0");
        _fetchUser[msg.sender].balance += msg.value;
        // updates transaction history
        updateTransaction();
    }

    /**
     * @dev withdraw the amount of eth from the contract to the users address
     */
    function withdraw(uint256 amount) public payable restricted {
        require(getAccountBalance() >= msg.value, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        _fetchUser[msg.sender].balance -= amount;
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
            block.timestamp > _lastTransactions[msg.sender].date + 100 days,
            "You are not eligible for interest"
        );
        uint256 interestRate = (_fetchUser[msg.sender].balance * 5) / 100;
        payable(msg.sender).transfer(interestRate);
        time[msg.sender] = true;
    }

    /**
     * @dev bankTranfer: transfers eth from the Ethereum Bank users account to
     * another user account
     */
    function bankTransfer(address _address, uint256 amount)
        public
        payable
        restricted
    {
        require(getAccountBalance() >= msg.value, "Insufficient balance");
        // 1% transfer charges per transaction within the Ethereum Bank
        uint256 tax = (amount * 1) / 100;
        uint256 totalAmount = amount + tax;
        // debit from the senders account
        _fetchUser[msg.sender].balance -= totalAmount;
        // transfer to address;
        _fetchUser[_address].balance += amount;
    }

    /**
     * @dev interTransfers eth from the Ethereum Bank users account to
     * an etheruem address
     * Note: the address can be a registered Ethereum Bank user or not.
     */
    function interTransfer(address to, uint256 amount)
        public
        payable
        restricted
    {
        // 2% transfer charges per transaction to an ethereum address
        uint256 tax = (amount * 2) / 100;
        uint256 totalAmount = amount + tax;
        // debit from the senders account
        _fetchUser[msg.sender].balance -= totalAmount;
        // transfer to the receiver
        payable(to).transfer(amount);
    }

    /**
     * @dev allTransactions returns all transaction history of a user
     */
    function alltransction() public view returns (Transaction[] memory) {
        return transaction;
    }

    /**
     * @dev getAccountBalance returns the amount of eth a user has in account
     */
    function getAccountBalance() public view returns (uint256) {
        require(
            accountExist(msg.sender),
            "Account address does not exist, Create and account"
        );
        return _fetchUser[msg.sender].balance;
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
}
