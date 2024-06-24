pragma solidity ^0.8.0;

// Samoladas Triantafyllos (AM: 168)

contract RewardMileage {
    address public owner;
    bool public paused;

    // Modifier to allow only owner to execute that function
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner of this contract can execute this function");
        _;
    }
    
    // Modifier to allow execution of functions only when Reward System is not paused
    modifier whenNotPaused() {
        require(!paused, "Reward system is paused");
        _;
    }

    // Constructor
    constructor() {
        owner = msg.sender;
    }
    
    // Destructor (owner only)
    function selfDestruct() public onlyOwner {
        selfdestruct(payable(owner));
    }

    struct Vehicle {
        uint ownerId;
        string make;
        string model;
        uint emissionLevel; // 1: Electric, 2: Hybrid, 3: Low-emission
    }
    mapping(uint => Vehicle) public vehicles;
    
    struct User {
        uint totalPoints;
    }
    mapping(address => User) public users;
    
    struct Business {
        string name;
        uint uniqueIdentifier;
    }
    mapping(uint => Business) public businesses;
    
    event PointsEarned(address indexed user, uint points, string make, string model);
    event LeaderboardShown(address[] users, uint[] points);
    
    // Register your vehicle by providing your address, the car Make, model and its Emission level 
    // Only one vehicle per user is allowed.. if you register a 2nd vehicle, it will replace the previous one.
    function registerVehicle(uint myOwnerId, string memory myMake, string memory myModel, uint myEmissionLevel) external {
        require((myEmissionLevel > 0) && (myEmissionLevel <= 3), "The Emission level needs to be Electric(1), Hybrid(2) or Low-Emission(3)");
        vehicles[myOwnerId] = Vehicle(myOwnerId, myMake, myModel, myEmissionLevel);
    }
    
    // Report mileage by providing your address and the distance driven
    function reportMileage(uint myOwnerId, uint distanceDriven) external whenNotPaused {
        require(myOwnerId == vehicles[myOwnerId].ownerId, "Vehicle not registered");
        
        uint multiplier;
        if (vehicles[myOwnerId].emissionLevel == 1) {
          // Electric 
          multiplier = 8;
        } else if (vehicles[myOwnerId].emissionLevel == 2) {
          // Hybrid
          multiplier = 4;
        } else {
          // Low-emission
          multiplier = 1;
        }
        uint points = multiplier * distanceDriven;
        users[msg.sender].totalPoints += points;
        updateLeaderboard(msg.sender);
        
        emit PointsEarned(msg.sender, points, vehicles[myOwnerId].make, vehicles[myOwnerId].model);
    }
    
    // Redeem points by providing the amount of points you need to redeem and in which business you need to redeem them to
    function redeemPoints(uint myPoints, uint businessId) external whenNotPaused {
        require(users[msg.sender].totalPoints >= 1000, "You need more than 1000 points to be able to redeem them");
        require(users[msg.sender].totalPoints >= myPoints, "You don't have this amount of points yet..");
        require(businesses[businessId].uniqueIdentifier == businessId, "Business not registered");
        
        users[msg.sender].totalPoints -= myPoints;
        updateLeaderboard(msg.sender);
        
        // Integration with an oracle to provide a Randomly generated
        // discount voucher to be used in that particular business 
        // after the points redemption
    } 
    
    // Register business by providing a Name and an ID of the business(address)
    function registerBusiness(string memory businessName, uint businessId) external {
        businesses[businessId] = Business(businessName, businessId);
    }
    
    // Pause reward system (owner only)
    function pauseRewardSystem() external onlyOwner {
        paused = true;
    }
    
    // Unpause reward system (owner only)
    function unpauseRewardSystem() external onlyOwner {
        paused = false;
    }
    
    // Leaderboard
    address[] public topUsers;
    mapping(address => uint) public userIndex;
    
    // Update the positions in the leaderboard
    function updateLeaderboard(address user) internal {
        uint userPoints = users[user].totalPoints;

        if (userIndex[user] == 0) {
            // New user, insert at the end
            topUsers.push(user);
            userIndex[user] = topUsers.length;
        }

        // sort based on points
        for (uint i = userIndex[user] - 1; i > 0; i--) {
            if (users[topUsers[i - 1]].totalPoints >= userPoints) break;

            (topUsers[i], topUsers[i - 1]) = (topUsers[i - 1], topUsers[i]);
            userIndex[topUsers[i]] = i + 1;
            userIndex[topUsers[i - 1]] = i;
        }

        // keep the top 10, throw the 11th out
        if (topUsers.length > 10) {
            userIndex[topUsers[10]] = 0;
            topUsers.pop();
        }
    }

    // Get the top 10 users in the leaderboard
    function getTopUsers() external returns (address[] memory, uint[] memory) {
        uint[] memory points = new uint[](topUsers.length);
        for (uint i = 0; i < topUsers.length; i++) {
            points[i] = users[topUsers[i]].totalPoints;
        }
        emit LeaderboardShown(topUsers, points);
        return (topUsers, points);
    }
}
