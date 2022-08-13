// SPDX-License-Identifier: agpl-3.0
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

interface IERC721 {
    function mint(address to) external;
}

contract AssetManagement is Ownable {
    mapping(address => bool) public activeTokens;
    address[] private contracts;

    mapping(address => bool) public deposited;

    mapping(bytes32 => bool) transactions;

    address public WETH;
    address public BANKCARDNFT;

    uint256 public lastTokenId;

    event Deposit(address sender, address token, uint256 value);
    event DepositForRepay(address sender, address token, uint256 value);
    event Widthdraw(
        address reciver,
        address token,
        uint256 value,
        string action,
        bytes32 transactionId
    );
    event WidthdrawETH(
        address reciver,
        uint256 value,
        string action,
        bytes32 transactionId
    );
    event ActiveToken(address token);
    event PauseToken(address token);
    event ChangeSigner(address signer, bool flag);
    event FeeChange(uint256 fee);

    constructor(address _weth, address _bankCardNFT) {
        activeTokens[_weth] = true;
        contracts.push(_weth);
        WETH = _weth;
        BANKCARDNFT = _bankCardNFT;
    }

    function deposit(address token, uint256 amount) external {
        require(amount > 0, "Deposit: amount can not be 0");
        if (!deposited[msg.sender]) {
            _mintNFT(msg.sender);
            deposited[msg.sender] = true;
        }
        require(activeTokens[token], "Deposit: token not support");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, token, amount);
    }

    function depositForRepay(address token, uint256 amount) external {
        require(amount > 0, "DepositForRepay: amount can not be 0");
        if (!deposited[msg.sender]) {
            _mintNFT(msg.sender);
            deposited[msg.sender] = true;
        }
        require(activeTokens[token], "DepositForRepay: token not support");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit DepositForRepay(msg.sender, token, amount);
    }

    function depositETHForRepay() external payable {
        require(msg.value > 0, "DepositETHForRepay: amount  zero");
        if (!deposited[msg.sender]) {
            _mintNFT(msg.sender);
            deposited[msg.sender] = true;
        }
        IWETH(WETH).deposit{value: msg.value}();
        emit DepositForRepay(msg.sender, WETH, msg.value);
    }

    function depositETH() external payable {
        require(msg.value > 0, "DepositETH: amount  zero");
        if (!deposited[msg.sender]) {
            _mintNFT(msg.sender);
            deposited[msg.sender] = true;
        }
        IWETH(WETH).deposit{value: msg.value}();
        emit Deposit(msg.sender, WETH, msg.value);
    }

    function withdraw(
        bytes32 transactionId,
        address token,
        address to,
        uint256 amount,
        string memory action
    ) external onlyOwner {
        IERC20(token).transfer(to, amount);
        emit Widthdraw(to, token, amount, action, transactionId);
    }

    function withdrawETH(
        bytes32 transactionId,
        address to,
        uint256 amount,
        string memory action
    ) external onlyOwner {
        IWETH(WETH).withdraw(amount);
        _safeTransferETH(to, amount);
        emit WidthdrawETH(to, amount, action, transactionId);
    }

    function activeToken(address token) external onlyOwner {
        require(!activeTokens[token], "AddToken: token already supported");
        contracts.push(token);
        activeTokens[token] = true;
        emit ActiveToken(token);
    }

    function pauseToken(address token) external onlyOwner {
        require(activeTokens[token], "PauseToken: token not active");
        activeTokens[token] = false;
        emit PauseToken(token);
    }

    function supportTokens() external view returns (address[] memory) {
        return contracts;
    }

    function userWalletBalance(address user)
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256
        )
    {
        uint256[] memory balances = new uint256[](contracts.length);
        for (uint256 i = 0; i < contracts.length; i++) {
            balances[i] = IERC20(contracts[i]).balanceOf(user);
        }
        uint256 ETHBalance = user.balance;
        return (contracts, balances, ETHBalance);
    }

    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "ETH_TRANSFER_FAILED");
    }

    function _mintNFT(address to) internal {
        IERC721(BANKCARDNFT).mint(to);
    }

    fallback() external payable {
        revert("Fallback not allowed");
    }

    /**
     * @dev Only WETH contract is allowed to transfer ETH here. Prevent other addresses to send Ether to this contract.
     */
    receive() external payable {
        require(msg.sender == address(WETH), "Receive not allowed");
    }
}
