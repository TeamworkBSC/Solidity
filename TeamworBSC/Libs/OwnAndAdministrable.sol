
pragma solidity >=0.6.0;
// SPDX-License-Identifier: MIT

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * The owner can also add wallets that are allowed to execude specific functions tagged with onlyAdmin
 * This way we can renounce contract ownership but still be able to do a few maintaining and anti fraut
 * measures like changing fees, liquidity or including/excluding a wallet from fees. 
 */
contract OwnAndAdministrable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
    
    mapping(address => bool) admins;
    address[] adminList;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);


    /**
     * @dev Initializes the contract setting the deployer as the initial owner and adding him to admin list.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        admins[_owner] = true;
        adminList.push(_owner);
        emit OwnershipTransferred(address(0), msgSender);
        emit AdminAdded(_owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(validatePermissions(false,true), "Ownable: caller is not the owner");
        _;
    }
    
    modifier onlyAdmin() {
        require(validatePermissions(true,false), "Ownable: caller is not an admin");
        _;
    }
    
    modifier adminOrOwner() {
        require(validatePermissions(true,true), "Ownable: caller is not an admin or owner");
        _;
    }
    
    function validatePermissions(bool checkOwner, bool checkAdmin) private view returns (bool) {
        bool returnValue = false;
        
        // Contract locked -> can't use this
        if(now > _lockTime) return false;
        
        if(checkOwner && _owner == _msgSender()) returnValue = true;
        if(checkAdmin && admins[_msgSender()] == true) returnValue  = true;
        return returnValue;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    function addAdmin(address admin) public virtual onlyOwner {
        admins[admin] = true;
        adminList.push(admin);
        emit AdminAdded(admin);
    }
    
    function removeAdmin(address admin) public virtual onlyOwner {
        for (uint256 i = 0; i < adminList.length; i++) {
            if (adminList[i] == admin) {
                adminList[i] = adminList[adminList.length - 1];
                admins[admin] = false;
                adminList.pop();
                break;
            }
        }
        emit AdminAdded(admin);
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}