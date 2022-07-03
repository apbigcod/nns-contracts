pragma solidity >=0.8.4;

import "./PriceOracle.sol";
import "./BaseRegistrarImplementation.sol";
import "./StringUtils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../resolvers/Resolver.sol";

contract ENSRegistrarController is Ownable {
    using StringUtils for *;

    bytes4 constant private INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 constant private COMMITMENT_CONTROLLER_ID = bytes4(
        keccak256("price(string)") ^
        keccak256("available(string)") ^
        keccak256("register(string,address,address)")
    );

    BaseRegistrarImplementation base;
    PriceOracle prices;
    IERC721 ensRegistrar;

    event NameRegistered(string name, bytes32 indexed label, address indexed owner, uint cost);
    event NewPriceOracle(address indexed oracle);

    constructor(BaseRegistrarImplementation _base, PriceOracle _prices, IERC721 _ensRegistrar) {
        base = _base;
        prices = _prices;
        ensRegistrar = _ensRegistrar;
    }

    function price(string memory name) view public returns(uint) {
        return prices.price(name);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);        
    }

    function valid(string memory name) public pure returns(bool) {
        return name.strlen() >= 1;
    }

    function register(string memory name, address resolver, address addr) public payable {
        uint cost = price(name);
        bytes32 label = keccak256(bytes(name));
        uint256 tokenId = uint256(label);

        require(msg.value >= cost, "you're too cheap");
        require(ensRegistrar.ownerOf(tokenId) == msg.sender, "not the owner of the domain");

        if(resolver != address(0)) {
            // Set this contract as the (temporary) owner, giving it
            // permission to set up the resolver.
            base.register(tokenId, address(this));

            // The nodehash of this label
            bytes32 nodehash = keccak256(abi.encodePacked(base.baseNode(), label));
            // Set the resolver
            base.ens().setResolver(nodehash, resolver);

            // Configure the resolver
            if (addr != address(0)) {
                Resolver(resolver).setAddr(nodehash, addr);
            }

            // Now transfer full ownership to the expected owner
            base.reclaim(tokenId, msg.sender);
            base.transferFrom(address(this), msg.sender, tokenId);
        } else {
            require(addr == address(0));
            base.register(tokenId, msg.sender);
        }

        emit NameRegistered(name, label, msg.sender, cost);

        // Refund any extra payment
        if(msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }

    function setPriceOracle(PriceOracle _prices) public onlyOwner {
        prices = _prices;
        emit NewPriceOracle(address(prices));
    }

    function available(string memory name) public view returns(bool) {
        bytes32 label = keccak256(bytes(name));
        return valid(name) && base.available(uint256(label));
    }
}