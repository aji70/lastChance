// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC721 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;

    uint256 private totalTokens = 1000;
    mapping(address => uint256) private balances;
    mapping(uint256 => address) private tokenOwners;
    mapping(address => mapping(address => bool)) private operators;

    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public lastStakeTime;
    mapping(address => uint256) public rewardPerToken;
    mapping(address => uint256) public rewardsEarned;
    mapping(address => uint256) public rewardsPaid;

    uint256 public totalStaked;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);


    event Transfer(address indexed from, address indexed to, uint256 tokenId);
    event Approval(address indexed owner, address indexed operator, uint256 tokenId);

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function totalSupply() public view returns (uint256) {
        return totalTokens;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return tokenOwners[tokenId];
    }

    function approve(address operator, uint256 tokenId) public {
        require(msg.sender == ownerOf(tokenId), "Not the owner of the token");
        operators[msg.sender][operator] = true;
        emit Approval(msg.sender, operator, tokenId);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return operators[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(from == msg.sender || isApprovedForAll(from, msg.sender), "Not approved to transfer");
        require(ownerOf(tokenId) == from, "Token not owned by sender");
        
        balances[from] -= 1;
        balances[to] += 1;
        tokenOwners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function mint(address to, uint256 tokenId) public {
        require(balances[to] == 0, "Recipient already owns a token");
        require(tokenOwners[tokenId] == address(0), "Token already minted");

        balances[to] = 1;
        tokenOwners[tokenId] = to;
        totalTokens += 1;

        emit Transfer(address(0), to, tokenId);
    }

    function burn(uint256 tokenId) public {
    address owner = ownerOf(tokenId);
    require(owner == msg.sender || isApprovedForAll(owner, msg.sender), "Not approved to burn");
    
    balances[owner] -= 1;
    delete tokenOwners[tokenId];
    totalTokens -= 1;

    emit Transfer(owner, address(0), tokenId);
}

function stake(uint256 tokenId) public{
    address owner = ownerOf(tokenId);
    require(ownerOf(tokenId) == msg.sender || isApprovedForAll(ownerOf(tokenId), msg.sender), "Not approved to transfer");
    require(ownerOf(tokenId) == ownerOf(tokenId) , "Token not owned by sender");
    transferFrom(owner, address(this), tokenId);
    approve(owner, tokenId);
     stakedBalance[msg.sender] += 1;
     uint256 rewards = rewardsEarned[msg.sender] + (stakedBalance[msg.sender] * (rewardPerToken[msg.sender] - rewardsPaid[msg.sender]));
         lastStakeTime[msg.sender] = block.timestamp;
         rewardPerToken[msg.sender] += rewards / stakedBalance[msg.sender];
         rewardsEarned[msg.sender] = 0;

         // Update contract data
         totalStaked += 1;

         emit Staked(msg.sender, 1);

}
function unstake(uint256 tokenId) external {
    require(from == msg.sender || isApprovedForAll(from, msg.sender), "Not approved to transfer");
        require(ownerOf(tokenId) == from, "Token not owned by sender");
        
        require(ownerOf(tokenId) == address(this), "NFT is not staked");
        require((msg.sender).getApproved(tokenId) == address(this), "You must approve this contract to unstake your NFT");

        // Calculate rewards earned
        uint256 rewards = rewardsEarned[msg.sender] + (stakedBalance[msg.sender] * (rewardPerToken[msg.sender] - rewardsPaid[msg.sender]));

        // Update user data
        stakedBalance[msg.sender] -= 1;
        rewardPerToken[msg.sender] += rewards / stakedBalance[msg.sender];
        rewardsEarned[msg.sender] = rewards;
        rewardsPaid[msg.sender] = rewards;
        lastStakeTime[msg.sender] = block.timestamp;

        // Update contract data
        totalStaked -= 1;

        // Transfer NFT back to owner
        (msg.sender).safeTransferFrom(address(this), msg.sender, tokenId);

        emit Unstaked(msg.sender, 1);
        }
}
