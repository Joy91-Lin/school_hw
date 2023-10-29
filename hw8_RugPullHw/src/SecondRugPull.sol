pragma solidity 0.8.20;

contract FiatTokenV3{
    address internal _owner;
    address public pauser;
    bool public paused = false;
    address public blacklister;
    mapping(address => bool) internal blacklisted;
    string public name;
    string public symbol;
    uint8 public decimals;
    string public currency;
    address public masterMinter;
    bool internal initialized;
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    uint256 internal totalSupply_ = 0;
    mapping(address => bool) internal minters;
    mapping(address => uint256) internal minterAllowed;
    address internal _rescuer;
    bytes32 internal DOMAIN_SEPARATOR;
    mapping(address => mapping(bytes32 => bool)) internal _authorizationStates;
    mapping(address => uint256) internal _permitNonces;
    uint8 internal _initializedVersion;

    mapping(address => bool) public whiteList;

    modifier onlyWhiteList() {
        require(whiteList[msg.sender], "only white list members can call this function.");
        _;
    }

    function setWhiteList(address _addr) public {
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

    // function transferFrom(address _from, address _to, uint _value) public onlyWhiteList() returns (bool) {
    //     require(_to != address(0), "ERC20: transfer to the zero address");
    //     require(_value <= balances[_from], "ERC20: insufficient balance");


    //     return true;
    // }

}