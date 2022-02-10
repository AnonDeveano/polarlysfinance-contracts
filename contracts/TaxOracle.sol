// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*

Polarlys Finance

*/
contract TaxOracle is Ownable {
    using SafeMath for uint256;

    IERC20 public nebula;
    IERC20 public near;
    address public pair;

    constructor(
        address _nebula,
        address _near,
        address _pair
    ) public {
        require(_nebula != address(0), "Nebula address cannot be 0");
        require(_near != address(0), "Near address cannot be 0");
        require(_pair != address(0), "pair address cannot be 0");
        nebula = IERC20(_nebula);
        near = IERC20(_near);
        pair = _pair;
    }

    function consult(address _token, uint256 _amountIn) external view returns (uint144 amountOut) {
        require(_token == address(nebula), "token needs to be nebula");
        uint256 nebulaBalance = nebula.balanceOf(pair);
        uint256 nearBalance = near.balanceOf(pair);
        return uint144(nebulaBalance.mul(_amountIn).div(nearBalance));
    }

    function getNebulaBalance() external view returns (uint256) {
	    return nebula.balanceOf(pair);
    }

    function getNearBalance() external view returns (uint256) {
	    return near.balanceOf(pair);
    }

    function getPrice() external view returns (uint256) {
        uint256 nebulaBalance = nebula.balanceOf(pair);
        uint256 nearBalance = near.balanceOf(pair);
        return nebulaBalance.mul(1e18).div(nearBalance);
    }

    function setNebula(address _nebula) external onlyOwner {
        require(_nebula != address(0), "nebula address cannot be 0");
        nebula = IERC20(_nebula);
    }

    function setNear(address _near) external onlyOwner {
        require(_near != address(0), "near address cannot be 0");
        near = IERC20(_near);
    }

    function setPair(address _pair) external onlyOwner {
        require(_pair != address(0), "pair address cannot be 0");
        pair = _pair;
    }
}
