// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ERC20Token
 * @dev A simple ERC20 token with customizable tax percentages.
 */
contract ERC20Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public addressA;
    address public addressB;
    address public addressC; // New address to receive taxPercentageC
    uint256 public taxPercentageA;
    uint256 public taxPercentageB;
    uint256 public taxPercentageC = 5; // Fixed 5% tax
    uint256 public liquidityTaxPercentage = 3; // 3% liquidity tax

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Constructor function to initialize the ERC20 token.
     * @param _name The name of the token.
     * @param _symbol The symbol of the token.
     * @param _decimals The number of decimals for token balances.
     * @param _initialSupply The initial supply of tokens.
     * @param _addressA Address for tax calculations.
     * @param _addressB Address for tax calculations.
     * @param _addressC Address for tax calculations.
     * @param _taxPercentageA Initial tax percentage for addressA.
     * @param _taxPercentageB Initial tax percentage for addressB.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply,
        address _addressA,
        address _addressB,
        address _addressC,
        uint256 _taxPercentageA,
        uint256 _taxPercentageB
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply * (10**uint256(_decimals));
        addressA = _addressA;
        addressB = _addressB;
        addressC = _addressC;
        taxPercentageA = _taxPercentageA;
        taxPercentageB = _taxPercentageB;
        balanceOf[msg.sender] = totalSupply;
    }

    /**
     * @dev Function to decrease tax percentage after specific days.
     * The tax percentages are decreased at different time intervals.
     */
    function decreaseTaxPercentage() external {
        require(msg.sender == addressA || msg.sender == addressB, "ERC20: Only addressA and addressB can decrease tax percentage");

        uint256 initialTaxPercentage;
        if (msg.sender == addressA) {
            initialTaxPercentage = taxPercentageA;
        } else {
            initialTaxPercentage = taxPercentageB;
        }

        // check provvisorio! ancora de settare
        if (block.timestamp >= (block.timestamp + 3 days)) {
            // Decrease tax percentage
            if (initialTaxPercentage == 26) {
                if (msg.sender == addressA) {
                    taxPercentageA = 10;
                } else {
                    taxPercentageB = 10;
                }
            }
            // check provvisorio! ancora de settare
            else if (block.timestamp >= (block.timestamp + 27 days)) {
                // Decrease tax percentage
                if (initialTaxPercentage == 10) {
                    if (msg.sender == addressA) {
                        taxPercentageA = 4;
                    } else {
                        taxPercentageB = 4;
                    }
                } else if (initialTaxPercentage == 4) {
                    if (msg.sender == addressA) {
                        taxPercentageA = 3;
                    } else {
                        taxPercentageB = 3;
                    }
                } else {
                    revert("ERC20: Tax percentage can only be decreased from 26% to 10%, then from 10% to 4%, and finally from 4% to 3%");
                }
            } else {
                revert("ERC20: Cannot decrease tax before 27 days");
            }
        } else {
            revert("ERC20: Cannot decrease tax before 27 days");
        }
    }

    /**
     * @dev Internal function to handle token transfers.
     * @param _from The address transferring tokens.
     * @param _to The recipient address.
     * @param _value The amount of tokens to transfer.
     */
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "ERC20: Transfer to the zero address");
        require(balanceOf[_from] >= _value, "ERC20: Insufficient balance");

        uint256 taxAmount = 0;

        // Check if both sender and receiver are not in the tax system (P2P transaction)
        if (_from != addressA && _from != addressB && _from != addressC &&
            _to != addressA && _to != addressB && _to != addressC) {
            // P2P transaction, no tax applied
        } else {
            // Tax calculation for addressA, addressB, or addressC
            if (msg.sender == addressA) {
                taxAmount = (_value * taxPercentageA) / 100;
            } else if (msg.sender == addressB) {
                taxAmount = (_value * taxPercentageB) / 100;
            } else if (msg.sender == addressC) {
                taxAmount = (_value * taxPercentageC) / 100;
            }
        }

        uint256 liquidityTaxAmount = (_value * liquidityTaxPercentage) / 100;
        uint256 burnAmount = (_value * 1) / 100; // 1% burn

        uint256 transferAmount = _value - taxAmount - liquidityTaxAmount - burnAmount;

        balanceOf[_from] -= _value;
        balanceOf[_to] += transferAmount;

        // Apply tax only if it's not a P2P transaction
        if (taxAmount > 0) {
            balanceOf[addressA] += taxAmount / 3; // Distribute taxAmount equally among addressA, addressB, and addressC
            balanceOf[addressB] += taxAmount / 3;
            balanceOf[addressC] += taxAmount / 3;
        }

        totalSupply -= burnAmount;

        emit Transfer(_from, _to, transferAmount);

        // Emit tax and burn events only if they are applicable
        if (taxAmount > 0) {
            emit Transfer(_from, addressA, taxAmount / 3);
            emit Transfer(_from, addressB, taxAmount / 3);
            emit Transfer(_from, addressC, taxAmount / 3);
        }
        emit Transfer(_from, address(0), burnAmount); // Burn event
    }

   
    function transfer(address _to, uint256 _value) external returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

 
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        require(allowance[_from][msg.sender] >= _value, "ERC20: Insufficient allowance");
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
}
