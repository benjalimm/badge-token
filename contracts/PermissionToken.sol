pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../interfaces/IPermissionToken.sol";
import "../interfaces/IEntity.sol";
import "../interfaces/IBadgeRecoveryOracle.sol";
import "./NonTransferableERC721.sol";
import "./CommonErrors.sol";

contract PermissionToken is NonTransferableERC721, IPermissionToken {
    using Counters for Counters.Counter;
    string public constant VERSION = "1.0";

    //** Token info ** \\
    Counters.Counter private _ids;

    // ** Permission info ** \\

    // *** User to permission level mapping *** //

    /// 0 - NO PERMISSION
    /// 1 - ADMIN: Can reward Badges
    /// 2 - SUPER ADMIN: Can reward Badges and issue admin permission
    /// 3 - GENESIS: ONLY ONE EXISTS. User has all privilege + can issue super admin permission

    // ***  *** //

    mapping(address => uint256) public adminToPermLevel;
    mapping(address => uint256) public ownerReverseRecord;

    //** Pertinent addressess ** \\
    address public entity;

    constructor(string memory _entityName, address _entity)
        NonTransferableERC721(
            concat(_entityName, " - Permission token"),
            concat(_entityName, "_PERM_TOKEN")
        )
    {
        entity = _entity;
    }

    function concat(string memory s1, string memory s2)
        private
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(s1, s2));
    }

    // ** Modifiers ** \\
    modifier entityOnly() {
        if (msg.sender != entity)
            revert Unauthorized("Only entity can call this");
        _;
    }

    // ** Token functions ** \\
    function privateMint(address _owner, string memory tokenURI)
        private
        returns (uint256)
    {
        // 1. Increment the id counter
        _ids.increment();

        // 2. Assign the id to the tokenURI
        uint256 newItemId = _ids.current();

        // 3. Mint the token
        _mint(_owner, newItemId);

        // 4. Set reverse record
        ownerReverseRecord[_owner] = newItemId;

        // 5. Set the tokenURI
        _setTokenURI(newItemId, tokenURI);
        return newItemId;
    }

    function mintAsEntity(
        address assignee,
        uint256 level,
        string memory tokenURI
    ) external payable override entityOnly returns (uint256) {
        if (ownerReverseRecord[assignee] != 0) {
            revert Failure("Owner already has a token");
        }
        adminToPermLevel[assignee] = level;
        return privateMint(assignee, tokenURI);
    }

    function revokePermission(address revokee) external override entityOnly {
        uint256 id = ownerReverseRecord[revokee];

        if (id == 0) {
            revert Failure("Owner does not have a token");
        }

        // Delete records
        delete adminToPermLevel[revokee];
        delete ownerReverseRecord[revokee];

        // Burn id
        _burn(id);
    }

    // Simulate owner of contract
    function owner() public view returns (address) {
        return IEntity(entity).getGenUser();
    }

    // ** Getter functions ** \\
    function getEntity() external view override returns (address) {
        return entity;
    }

    function getPermStatusForAdmin(address admin)
        external
        view
        override
        returns (uint256 lvl)
    {
        lvl = adminToPermLevel[admin];
    }

    // ** Setter functions ** \\
    function setNewEntity(address _entity) external override entityOnly {
        entity = _entity;
    }
}
