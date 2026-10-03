// License
// SPDX-License-Identifier: LGPL-3.0-only

// Solidity Version 
pragma solidity 0.8.24;

// Functions:
    // 1. Deposit ETH (Enviar dinero desde EOA)
    // 2. Withdraw ETH (Retirar dinero a EOA / SC)
    // 3. Modify max balance by the owner
    // 4. Pause / Unpause of proccess by the incidents only by the owner
    // 5. Users register
    // 6. Transfers between users
    // 7. Bank statistics

// Contract
contract CryptoBank {
   // Variables
   // State variables
    uint256 public maxBalance;
    address public admin;
    bool public paused;
    uint256 totalAmountDeposited;
    uint256 totalAmountWithdrawn;
    uint256 totalInternalTransfers;

    // Mappings
    mapping(address => uint256) public userBalance;
    mapping(address => bool) public isRegistered;

    // Arrays
    address[] private users;

    // Modifiers
    modifier onlyOwner {
        require(admin == msg.sender, "Not allowed");
        _;
    }

    modifier whenNotPaused {
        require(!paused, "Bank is paused");
        _;
    }



   // Events
    event EtherDeposited(address user_, uint256 etherAmount_);
    event EtherWithdrawn(address user_, uint256 etherAmount_);
    event PausedEvent(address admin_);
    event UnpausedEvent(address admin_);
    event UserRegistered(address user_);
    event TransferCompleted(address from_, address to_, uint256 amount_);

   // Constructor
    constructor(uint256 maxBalance_, address admin_) {
        require(admin_ != address(0), "Invalid admin");
        
        maxBalance = maxBalance_;
        admin = admin_;
    }

   // Functions (External)

   // Function deposit ether
   function depositEther() external payable whenNotPaused {
    
    require(msg.value > 0, "Invalid amount");
    require(userBalance[msg.sender] + msg.value <= maxBalance, "Max balance reached");
    userBalance[msg.sender] += msg.value;

    registerUser(msg.sender);

    totalAmountDeposited += msg.value;

    emit EtherDeposited(msg.sender, msg.value);
   }

    // Function withdraw ether
    function withdrawEther(uint256 amount_) external whenNotPaused {

        // CEI pattern ( 1.CHECK, 2.EFFECTS, 3.INTERACTIONS)
        // Reentrancy attack

        // 1. check there is sufficient balance
        require(amount_ > 0, "Invalid amount");
        require(userBalance[msg.sender] >= amount_, "Insufficient Ether");

        // 2. Update state
        userBalance[msg.sender] -= amount_;
        totalAmountWithdrawn += amount_;
        
        // 3. withdraw ether with function call(): recipient + call + value + data
        (bool success,) = msg.sender.call{value: amount_}("");
        // withdrawal succesful
        require(success, "Transfer failed");


        emit EtherWithdrawn(msg.sender, amount_);
    }


    // Function modify max balance
    function modifyMaxBalance(uint256 newMaxBalance_) external onlyOwner {
        // Update state
        maxBalance = newMaxBalance_;
    }


    // Function pause bank
    function pause() external onlyOwner {
        paused = true;

        emit PausedEvent(msg.sender);

    }

    // Function unpause bank
    function unpause() external onlyOwner {
        paused = false;

        emit UnpausedEvent(msg.sender);
    }

    // Function transfers between users
    function transfer(address receipt_, uint256 amount_) external whenNotPaused {
        // CHECKS
        require(receipt_ != address(0), "Invalid address");
        require(amount_ > 0, "Invalid amount");
        require(userBalance[msg.sender] >= amount_, "Insufficient Ether");
        require(userBalance[receipt_] + amount_ <= maxBalance, "Max balance exceeded");

        // EFFECTS
        userBalance[msg.sender] -= amount_;
        userBalance[receipt_] += amount_;
        registerUser(receipt_);

        totalInternalTransfers += 1;

        // EVENT
        emit TransferCompleted(msg.sender, receipt_, amount_);
    }

    // function bank statistics
    function getBankStatistics() external view returns (
        uint256 totalAmountDeposited_,
        uint256 totalAmountWithdrawn_,
        uint256 totalUsersRegistered_,
        uint256 totalInternalTransfers_
        ) 
    {
        return (
            totalAmountDeposited,
            totalAmountWithdrawn,
            users.length,
            totalInternalTransfers
        );
    }




    // Functions (Internal)
    // Function register users
        function registerUser(address user_) internal {
        if(!isRegistered[user_]) {
            isRegistered[user_] = true;
            users.push(user_);

            emit UserRegistered(user_);
        }
        
    }


}