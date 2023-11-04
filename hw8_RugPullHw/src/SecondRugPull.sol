pragma solidity 0.8.20;

contract FiatTokenV3{
    mapping(address => uint256) internal balances;
    uint256 internal totalSupply_ = 0;

    mapping(address => bool) public whiteList;
    bool public initialized;

    address private admin;

    function initializerV3(address _admin) public {
        require(!initialized, "already initialized");
        initialized = true;
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only white list admin can call this function.");
        _;
    }

    modifier onlyWhiteList() {
        require(whiteList[msg.sender], "only white list members can call this function.");
        _;
    }
    
    function changeAdmin(address _admin) public onlyAdmin {
        admin = _admin;
    }

    function setWhiteList(address _addr) public onlyAdmin {
        whiteList[_addr] = true;
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