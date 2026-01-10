// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title PriceDiscovery
 * @notice Simple TWAP-style oracle aggregator.
 */
contract PriceDiscovery is Ownable {
    struct Observation {
        uint256 timestamp;
        uint256 price; // scaled 1e18
    }

    Observation[] public observations;
    uint256 public window; // seconds

    event ObservationRecorded(uint256 price, uint256 timestamp);
    event WindowUpdated(uint256 window);

    constructor(uint256 _window) Ownable(msg.sender) {
        require(_window > 0, "Bad window");
        window = _window;
    }

    function recordObservation(uint256 price) external onlyOwner {
        require(price > 0, "Bad price");
        observations.push(Observation({ timestamp: block.timestamp, price: price }));
        emit ObservationRecorded(price, block.timestamp);
    }

    function setWindow(uint256 _window) external onlyOwner {
        require(_window > 0, "Bad window");
        window = _window;
        emit WindowUpdated(_window);
    }

    function getTwap() external view returns (uint256) {
        uint256 cutoff = block.timestamp - window;
        uint256 sum;
        uint256 count;
        for (uint256 i = observations.length; i > 0; i--) {
            Observation memory obs = observations[i - 1];
            if (obs.timestamp < cutoff) break;
            sum += obs.price;
            count++;
        }
        return count == 0 ? 0 : sum / count;
    }
}
