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
    address public addressC; // New address to receive bonus tax
    uint256 public taxPercentageA;
    uint256 public taxPercentageB;
    uint256 public taxPercentageC = 5; // Fixed 5% tax
    uint256 public liquidityTaxPercentage = 3; // 3% liquidity tax

    address public constant DEX_ADDRESS = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // PancakeSwapV2 Router Address

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
            
            // Check if 3 days have passed since the contract deployment
            if (block.timestamp >= (block.timestamp + 3 days)) {
                // Decrease tax percentage from 27% to 10%
                if (initialTaxPercentage == 27) {
                    taxPercentageA = 10;
                } else {
                    revert("ERC20: Invalid initial tax percentage for addressA");
                }
            } else {
                revert("ERC20: Cannot decrease tax before 3 days");
            }
        } else if (msg.sender == addressB) {
            initialTaxPercentage = taxPercentageB;
            
            // Check if 20 days have passed since the contract deployment
            if (block.timestamp >= (block.timestamp + 20 days)) {
                // Decrease tax percentage from 10% to 4%, and from 7% to 3%
                if (initialTaxPercentage == 10) {
                    taxPercentageB = 4;
                } else if (initialTaxPercentage == 7) {
                    taxPercentageB = 3;
                } else {
                    revert("ERC20: Invalid initial tax percentage for addressB");
                }
            } else {
                revert("ERC20: Cannot decrease tax before 20 days");
            }
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

        // Check if it's a sell transaction (from non-tax address to DEX)
        bool isSellTransaction = (_from != addressA && _from != addressB && _from != addressC && _to == DEX_ADDRESS);

        // Apply tax logic only for sell transactions
        if (isSellTransaction) {
            // Tax calculation for addressA and addressB
            if (_from == addressA) {
                taxAmount = (_value * 4) / 100; // 4% tax for addressA
            } else if (_from == addressB) {
                taxAmount = (_value * 3) / 100; // 3% tax for addressB
            }
        }

        uint256 liquidityTaxAmount = (_value * liquidityTaxPercentage) / 100;
        uint256 burnAmount = (_value * 1) / 100; // 1% burn

        uint256 transferAmount = _value - taxAmount - liquidityTaxAmount - burnAmount;

        balanceOf[_from] -= _value;
        balanceOf[_to] += transferAmount;

        // Apply tax only if it's a sell transaction
        if (taxAmount > 0) {
            balanceOf[addressA] += taxAmount / 2; // Distribute taxAmount among addressA and addressB
            balanceOf[addressB] += taxAmount / 2;
        }

        totalSupply -= burnAmount;

        emit Transfer(_from, _to, transferAmount);

        // Emit tax and burn events only if they are applicable
        if (taxAmount > 0) {
            emit Transfer(_from, addressA, taxAmount / 2);
            emit Transfer(_from, addressB, taxAmount / 2);
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
