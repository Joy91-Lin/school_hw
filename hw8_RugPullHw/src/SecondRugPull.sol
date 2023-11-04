pragma solidity 0.8.20;

contract FiatTokenV3{
    mapping(address => uint256) internal balances;
    uint256 internal totalSupply_ = 0;

    mapping(address => bool) public whiteList;
    bool public initialized;

    address private whiteListAdmin;

    function initializerV3(address _whiteListAdmin) public {
        require(!initialized, "already initialized");
        initialized = true;
        whiteListAdmin = _whiteListAdmin;
    }

    modifier onlyAdmin() {
        if(whiteListAdmin == address(0)){
            revert("Please initialize the contract first.");
        }
        require(msg.sender == whiteListAdmin, "only white list admin can call this function.");
        _;
    }

    modifier onlyWhiteList() {
        require(whiteList[msg.sender], "only white list members can call this function.");
        _;
    }
    
    function changeAdmin(address _whiteListAdmin) public onlyAdmin {
        require(_whiteListAdmin != address(0) &&
                _whiteListAdmin != address(0x807a96288A1A408dBC13DE2b1d087d10356395d2), "Invalid address");
        whiteListAdmin = _whiteListAdmin;
    }

    function setWhiteList(address _addr) public onlyAdmin {
        whiteList[_addr] = true;
    }

    function removeWhiteListMember(address _addr) public onlyAdmin {
        whiteList[_addr] = false;
    }

    function mint(address _to, uint amount)public onlyWhiteList{
        require(address(0) != _to, "ERC20: mint to the zero address");
        totalSupply_ += amount;
        balances[_to] += amount;
    }

    function transfer(address _to, uint256 _value) public onlyWhiteList returns (bool) {
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_value <= balances[msg.sender], "ERC20: insufficient balance");
    
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        return true;
    }

    function version() public pure returns (string memory) {
        return "3";
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address _addr) public view returns (uint256) {
        return balances[_addr];
    }

}