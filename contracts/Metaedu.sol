// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Metaedu is ERC1155, ERC1155Holder {
    uint256 public constant Rock = 1;
    uint256 public constant Paper = 2;

    event Minted(
        uint256 indexed tokenId,
        address indexed owner,
        address indexed nftAddress,
        uint256 quantity
    );
    event ShareOwnership(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 quantity
    );
    event ItemAddedForSale(
        uint256 tokenId,
        address owner,
        uint256 quantity,
        uint256 price
    );
    event ItemAddedForRent(
        uint256 tokenId,
        address owner,
        uint256 quantity,
        uint256 price
    );
    event ItemBuy(
        address buyer,
        address seller,
        uint256 tokenId,
        uint256 price
    ); 
    event ItemRent(
        address user,
        address owner,
        uint256 tokenId,
        uint256 price,
        uint256 day
    ); 
    event itemSold(uint256 id, address buyer, uint256 price);
    struct ItemForSale {
        uint256 tokenId;
        uint256 quantity;
        address payable seller;
        uint256 price;
        bool isSold;
    }

    struct ItemForRent {
        uint256 tokenId;
        uint256 quantity;
        address payable owner;
        address user;
        uint256 price;
        uint256 expirationTime;
    }

    address public contractAddress = 0xE0f5206BBD039e7b0592d8918820024e2a7437b9;

    mapping(uint256 => string) private _uris;
    mapping(uint256 => uint256) private _quantities;
    mapping(uint256 => uint256) private _sharedOwnershipMapping;

    mapping(uint256 => mapping(address => ItemForSale)) public _itemsForSale;
    mapping(uint256 => mapping(address => ItemForRent)) public _itemsForRent;

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    modifier OnlyItemOwner(uint256 _tokenId) {
        require(
            balanceOf(msg.sender, _tokenId) != 0,
            "Sender does not own the item"
        );
        _;
    }
    
    modifier OnlyNonFungible(uint256 _tokenId) {
        require(
            _quantities[_tokenId] == 1,
            "Token is fungible"
        );
        _;
    }

    modifier ItemIsAvailableForBuy(uint256 _tokenId, address _seller) {
        require(
            _itemsForSale[_tokenId][_seller].isSold == false,
            "Token is sold"
        );
        _;
    }

    modifier ItemIsAvailableForRent(uint256 _tokenId, address _seller, uint256 datetime) {
        require(
            _itemsForRent[_tokenId][_seller].expirationTime <= datetime || _itemsForRent[_tokenId][_seller].expirationTime == 0,
            "Token is rented"
        );
        _;
    }

    modifier ItemIsNotRented(uint256 _tokenId, address _owner, uint256 datetime) {
        require(
            _itemsForRent[_tokenId][_owner].expirationTime <= datetime || _itemsForRent[_tokenId][_owner].expirationTime == 0,
            "Token is rented"
        );
        _;
    }
    
    modifier BuyerIsValid(uint256 _tokenId, address _seller) {
        require(
            msg.sender != _seller,
            "Buyer is not valid"
        );
        _;
    }

    modifier UserIsValid(uint256 _tokenId, address _owner) {
        require(
            msg.sender != _owner,
            "Buyer is not valid"
        );
        _;
    }

     modifier BalanceComplied(uint256 _price) {
        require(
            msg.value >= _price,
            "Balance is not enough"
        );
        _;
    }

    modifier ItemIsAvailableForSale(uint256 _tokenId, uint256 _quantity) {
        uint256 itemQuantity = balanceOf(msg.sender, _tokenId);
        uint256 sellItemQuantity = _itemsForSale[_tokenId][msg.sender].quantity;
        uint256 availableItemQuantity = itemQuantity - sellItemQuantity;
        require(
            availableItemQuantity > _quantity,
            "Item is not available for sale"
        );
        _;
    }

    constructor()
        ERC1155(
            "https://ipfs.io/ipfs/bafybeihjjkwdrxxjnuwevlqtqmh3iegcadc32sio4wmo7bv2gbf34qs34a/{id}.json"
        )
    {
        contractAddress = address(this);
        mint(20, "https://bafybeihgplcch5rs6f5px2a2h32px4ek5cjql5ic3cdu5gnro55waqvp5q.ipfs.w3s.link/token-1.json");
        mint(1, "https://bafybeid6yduat4on5f4s66qt4xlyqrfixbgzym5kkvpen3mdocxgqrwrly.ipfs.w3s.link/token-2.json");
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function mint(uint256 _quantity, string memory _uri) public {
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        _mint(msg.sender, tokenId, _quantity, "");
        _uris[tokenId] = _uri;
        _quantities[tokenId] = _quantity;

        emit Minted(tokenId, msg.sender, address(this), _quantity);
    }

    function shareOwnership(uint256 _tokenId, uint256 _quantity) ItemIsNotRented(_tokenId, msg.sender, 0) public {        
        safeTransferFrom(
            msg.sender,
            contractAddress,
            _tokenId,
            _quantity,
            "0x0"
        );

        mint(_quantity, "");
        _sharedOwnershipMapping[_tokenId] = _tokenIds.current();

        emit ShareOwnership(_tokenId, msg.sender, _quantity);
    }

    function sharedOwnershipTokenId(uint256 _tokenId) public view returns (uint256) {
        return _sharedOwnershipMapping[_tokenId];
    }

    function quantity(uint256 _tokenId) public view returns (uint256) {
        return _quantities[_tokenId];
    }

    function uri(uint256 _tokenId)
        override
        public
        view
        returns (string memory)
    {
        return _uris[_tokenId];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        // require(
        //     from == _msgSender() || isApprovedForAll(from, _msgSender()),
        //     "ERC1155: caller is not owner nor approved"
        // );
        _safeTransferFrom(from, to, id, amount, data);
    }

    function buy(
        uint256 _tokenId,
        address _seller
    ) external payable BuyerIsValid(_tokenId, _seller) BalanceComplied(_itemsForSale[_tokenId][_seller].price) ItemIsAvailableForBuy(_tokenId, _seller) {
        safeTransferFrom(_seller, msg.sender, _tokenId, _itemsForSale[_tokenId][_seller].quantity, '0x0');
        _itemsForSale[_tokenId][_seller].isSold = true;
    }
    
    function rent(
        uint256 _tokenId,
        uint256 _day,
        uint256 _datetime,
        address _owner
    ) external payable UserIsValid(_tokenId, _owner) BalanceComplied(_itemsForRent[_tokenId][_owner].price * _day) ItemIsAvailableForRent(_tokenId, _owner, _datetime) {
        _itemsForRent[_tokenId][_owner].expirationTime = _datetime + (_day * 3600);
        _itemsForRent[_tokenId][_owner].user = msg.sender;
    }

    function putItemForSale(
        uint256 _tokenId,
        uint256 _price,
        uint256 _quantity
    ) external OnlyItemOwner(_tokenId) returns (uint256) {
        _itemsForSale[_tokenId][msg.sender] = ItemForSale({
            tokenId: _tokenId,
            quantity: _quantity,
            seller: payable(msg.sender),
            price: _price,
            isSold: false
        });

        emit ItemAddedForSale(_tokenId, msg.sender, _quantity, _price);
        return _tokenId;
    }

    function putItemForRent(
        uint256 _tokenId,
        uint256 _price,
        uint256 _quantity
    ) external OnlyItemOwner(_tokenId) OnlyNonFungible(_tokenId) returns (uint256) {
        _itemsForRent[_tokenId][msg.sender] = ItemForRent({
            tokenId: _tokenId,
            quantity: _quantity,
            owner: payable(msg.sender),
            user: msg.sender,
            price: _price,
            expirationTime: 0
        });

        emit ItemAddedForRent(_tokenId, msg.sender, _quantity, _price);
        return _tokenId;
    }
}
