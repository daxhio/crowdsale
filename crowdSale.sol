pragma solidity ^0.8.0;

//SPDX-License-Identifier:Unlicensed

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
* @title Ownable
* @dev The Ownable contract has an owner address, and provides basic authorization control
* functions, this simplifies the implementation of "user permissions".
*/
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
  * @dev The Ownable constructor sets the original `owner` of the contract to the sender
  * account.
  */
  constructor()  {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
  * @return the address of the owner.
  */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
  * @return true if `msg.sender` is the owner of the contract.
  */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
  * @dev Allows the current owner to relinquish control of the contract.
  * @notice Renouncing to ownership will leave the contract without an owner.
  * It will not be possible to call the functions with the `onlyOwner`
  * modifier anymore.
  */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
  * @dev Allows the current owner to transfer control of the contract to a newOwner.
  * @param newOwner The address to transfer ownership to.
  */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
  * @dev Transfers control of the contract to a newOwner.
  * @param newOwner The address to transfer ownership to.
  */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}


contract crowdSale is IERC20, Ownable, Context {
    string public constant name = "CROWDSALE";
    string public constant symbol = "CROWD";
    
    uint8 public constant decimals = 18;
    uint32 public constant txFee = 1; // 1% burn every tx
    uint256 private _totalSupply;
    uint256 public availableTokens = 500 * 10 ** uint(decimals); // half the supply will be minted in the crowdsale
    uint256 public constant rate = 20; // 20 tokens per ether
    
    bool public crowdSaleOpen;

    using SafeMath for uint256;
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) ethSent;
    
    constructor() {
        _totalSupply = 500 * 10 ** uint(decimals);
        _balances[_msgSender()] = _totalSupply; // half the supply goes to owner for liquidity
        crowdSaleOpen = true; // once deployed crowdsale starts
    }
    
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);    
        return true;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue));
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0);
        
        _balances[sender] = _balances[sender].sub(amount);
        
        uint256 burnt;
        if (amount < 100) {
          burnt = 0; // don't have floating point numbers in solidity
        } else {
          burnt = amount.mul(txFee).div(100);
        }
        
        _balances[recipient] = _balances[recipient].add(amount).sub(burnt);
        _totalSupply = _totalSupply.sub(burnt);
        emit Transfer(sender, recipient, (amount-burnt));
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(amount <= _balances[owner], "amount to approve must be less than or equal to account balance");
        
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    // function to receive eth for crowdsale
    // 500 tokens which are 50% of the supply are allocated for crowdsale 
    
    receive() external payable {
        require(crowdSaleOpen == true, "Crowdsale is over");
        require(msg.value > 0, "Can't send 0 wei");
        
        uint256 tokens = (msg.value).mul(rate);
        require(tokens <= availableTokens, "Can't buy more than allocated");
        
        ethSent[_msgSender()] = ethSent[_msgSender()].add(msg.value);
        availableTokens = availableTokens.sub(tokens);
        
        _totalSupply = _totalSupply.add(tokens);
        _balances[_msgSender()] = _balances[_msgSender()].add(tokens);
        
        emit Transfer(address(0), _msgSender(), tokens);
    }
    
    function endCrowdSale() external onlyOwner() {
        require(crowdSaleOpen == true); // so this function can't be called again
        crowdSaleOpen = false;
        if (availableTokens > 0) {
            emit Transfer(address(this), address(0), availableTokens); // burn the unsold tokens
            availableTokens = 0;
        }
    }
    
    // owner can withdraw funds after crowdsale
    
    function WithdrawEth() onlyOwner() public {
        require(crowdSaleOpen == false, "Can't withdraw while crowdsale is ongoing"); 
        require(address(this).balance > 0, "Can't withdraw negative or zero");
        payable(_msgSender()).transfer(address(this).balance);
    }
}