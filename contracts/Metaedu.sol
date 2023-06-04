// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Metaedu is ERC1155, ERC1155Holder {
    event CheckOwner(
        address indexed user,
        uint256 indexed tokenId
    );
    event CheckBalance(
        address indexed user,
        uint256 balance,
        uint256 price
    );
    event Minted(
        uint256 indexed tokenId,
        string uri,
        address indexed owner,
        address indexed nftAddress,
        uint256 supply
    );
    event ShareOwnership(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 supply
    );
    event ItemAddedForSale(
        uint256 tokenId,
        address owner,
        uint256 supply,
        uint256 price
    );
    event ItemAddedForRent(
        uint256 tokenId,
        address owner,
        uint256 supply,
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
    event ItemRentFraction(
        address user,
        address payable[] ownerList,
        uint256[] shareList,
        uint256 tokenId,
        uint256 price,
        uint256 day
    ); 
    event AmountTransfered(
        address from,
        address to,
        uint256 amount,
        bool result
    ); 
    
    struct ItemForSale {
        uint256 tokenId;
        uint256 supply;
        address payable seller;
        uint256 price;
        bool isSold;
    }

    struct ItemForRent {
        uint256 tokenId;
        uint256 supply;
        address payable owner;
        address user;
        uint256 price;
        uint256 expirationTime;
    }

    address public _ownerAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    mapping(uint256 => string) private _uris;
    mapping(uint256 => uint256) private _supplies;
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
            _supplies[_tokenId] == 1,
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

     modifier AmountPurchaseIsValid(uint256 _price) {
        require(
            msg.value >= _price * 1000000000000,
            "Amount is not valid"
        );
        _;
    }

    modifier AmountRentalIsValid(uint256 _price) {
        require(
            msg.value >= _price * 1000000000000,
            "Amount is not valid"
        );
        _;
    }

    modifier ItemIsAvailableForSale(uint256 _tokenId, uint256 _supply) {
        uint256 itemSupply = balanceOf(msg.sender, _tokenId);
        uint256 sellItemSupply = _itemsForSale[_tokenId][msg.sender].supply;
        uint256 availableItemSupply = itemSupply - sellItemSupply;
        require(
            availableItemSupply > _supply,
            "Item is not available for sale"
        );
        _;
    }

    modifier ItemIsNotInRentalPeriod(uint256 _tokenId, address _owner, uint256 _datetime) {
        require(
            _itemsForRent[_tokenId][_owner].expirationTime < _datetime,
            "Item is in rental period"
        );
        _;
    }

    constructor(address _owner)
        ERC1155(
            "https://ipfs.io/ipfs/bafybeihjjkwdrxxjnuwevlqtqmh3iegcadc32sio4wmo7bv2gbf34qs34a/{id}.json"
        )
    {
        _ownerAddress = _owner;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function mint(uint256 _supply, string memory _uri) public returns(uint256){
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        _mint(msg.sender, tokenId, _supply, "");
        _uris[tokenId] = _uri;
        _supplies[tokenId] = _supply;

        emit Minted(tokenId, _uri, msg.sender, address(this), _supply);

        return _tokenIds.current();
    }

    function shareOwnership(uint256 _tokenId, uint256 _supply, uint256 _datetime) ItemIsNotInRentalPeriod(_tokenId, msg.sender, _datetime) ItemIsNotRented(_tokenId, msg.sender, 0) public {        
        safeTransferFrom(
            msg.sender,
            _ownerAddress,
            _tokenId,
            1,
            "0x0"
        );

        _tokenIds.increment();
        _mint(msg.sender, _tokenIds.current(), _supply, "");
        _uris[_tokenIds.current()] = _uris[_tokenId];
        _supplies[_tokenIds.current()] = _supply;
        _sharedOwnershipMapping[_tokenId] = _tokenIds.current();

        emit Minted(_tokenIds.current(), _uris[_tokenId], msg.sender, address(this), _supply);

        _itemsForRent[_tokenId][_ownerAddress] = ItemForRent({
            tokenId: _tokenId,
            supply: _supply,
            owner: payable(_ownerAddress),
            user: _ownerAddress,
            price: _itemsForRent[_tokenId][msg.sender].price,
            expirationTime: 0
        });

        emit ShareOwnership(_tokenId, msg.sender, _supply);
    }

    function sharedOwnershipTokenId(uint256 _tokenId) public view returns (uint256) {
        return _sharedOwnershipMapping[_tokenId];
    }

    function supply(uint256 _tokenId) public view returns (uint256) {
        return _supplies[_tokenId];
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
        _safeTransferFrom(from, to, id, amount, data);
    }

    function buy(
        uint256 _tokenId,
        uint256 _quantity,
        address payable _seller,
        uint256 _datetime
    ) external payable BuyerIsValid(_tokenId, _seller) ItemIsNotInRentalPeriod(_tokenId, _seller, _datetime) AmountPurchaseIsValid(_itemsForSale[_tokenId][_seller].price) ItemIsAvailableForBuy(_tokenId, _seller) {
        (bool sent, bytes memory data) = _seller.call{value: msg.value}("");

        emit AmountTransfered(msg.sender, _seller, msg.value, sent);

        safeTransferFrom(_seller, msg.sender, _tokenId, _quantity, "0x0");
        _itemsForSale[_tokenId][_seller].isSold = true;

        emit ItemBuy(msg.sender, _seller, _tokenId, msg.value);
    }
    
    function rent(
        uint256 _tokenId,
        uint256 _day,
        address payable _owner,
        uint256 _datetime
    ) external payable ItemIsNotInRentalPeriod(_tokenId, _owner, _datetime) UserIsValid(_tokenId, _owner) AmountRentalIsValid(_itemsForRent[_tokenId][_owner].price * _day) ItemIsAvailableForRent(_tokenId, _owner, _datetime) {
        (bool sent, bytes memory data) = _owner.call{value: msg.value}("");

        emit AmountTransfered(msg.sender, _owner, msg.value, sent);

        _itemsForRent[_tokenId][_owner].expirationTime = (_day * 86400000) + _datetime;
        _itemsForRent[_tokenId][_owner].user = msg.sender; 

        emit ItemRent(msg.sender, _owner, _tokenId, msg.value, _day);
    }

    function rentFraction(
        uint256 _tokenId,
        uint256 _day,
        address payable[] memory _ownerList,
        uint256[] memory _shareList,
        uint256 _datetime
    ) external payable ItemIsNotInRentalPeriod(_tokenId, _ownerAddress, _datetime) UserIsValid(_tokenId, _ownerAddress) AmountRentalIsValid(_itemsForRent[_tokenId][_ownerAddress].price * _day) ItemIsAvailableForRent(_tokenId, _ownerAddress, _datetime) {
        ItemForRent memory itemForRent = _itemsForRent[_tokenId][_ownerAddress];

        itemForRent.expirationTime = (_day * 86400000) + _datetime;
        itemForRent.user = msg.sender;

        for(uint256 i = 0; i < _ownerList.length; i++) {
            if(balanceOf(_ownerList[i], _sharedOwnershipMapping[_tokenId]) == _shareList[i]) {
                (bool sent, bytes memory data) = _ownerList[i].call{value: msg.value * _shareList[i] / _supplies[_sharedOwnershipMapping[_tokenId]]}("");

                emit AmountTransfered(msg.sender, _ownerList[i], msg.value * _shareList[i] / _supplies[_sharedOwnershipMapping[_tokenId]], sent);
            }
        }

        emit ItemRentFraction(msg.sender, _ownerList, _shareList, _tokenId, msg.value, _day);
    }

    function putItemForSale(
        uint256 _tokenId,
        uint256 _price,
        uint256 _supply,
        uint256 _datetime
    ) external ItemIsNotInRentalPeriod(_tokenId, msg.sender, _datetime) OnlyItemOwner(_tokenId) returns (uint256) {
        _itemsForSale[_tokenId][msg.sender] = ItemForSale({
            tokenId: _tokenId,
            supply: _supply,
            seller: payable(msg.sender),
            price: _price,
            isSold: false
        });

        emit ItemAddedForSale(_tokenId, msg.sender, _supply, _price);

        return _tokenId;
    }

    function putItemForRent(
        uint256 _tokenId,
        uint256 _price,
        uint256 _supply,
        uint256 _datetime
    ) external ItemIsNotInRentalPeriod(_tokenId, msg.sender, _datetime) OnlyItemOwner(_tokenId) OnlyNonFungible(_tokenId) returns (uint256) {
        _itemsForRent[_tokenId][msg.sender] = ItemForRent({
            tokenId: _tokenId,
            supply: _supply,
            owner: payable(msg.sender),
            user: msg.sender,
            price: _price,
            expirationTime: 0
        });

        emit ItemAddedForRent(_tokenId, msg.sender, _supply, _price);

        return _tokenId;
    }
}