// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "hardhat/console.sol";

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
    event itemSold(uint256 id, address buyer, uint256 price);
    
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
        
        console.log('Check Owner');
        console.log('sender', msg.sender);
        console.log('token id', _tokenId);
        console.log('balance', balanceOf(msg.sender, _tokenId));
        console.log('token supply', _uris[_tokenId]);

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

     modifier AmountPurchasementIsValid(uint256 _price) {
        console.log('Check balance');
        console.log(msg.sender);
        console.log(msg.value);
        console.log(_price);
        require(
            msg.value >= _price * 1000000000000,
            "Amount is not valid"
        );
        _;
    }

    modifier AmountRentalIsValid(uint256 _price) {
        console.log('Check balance');
        console.log(msg.sender);
        console.log(msg.value);
        console.log(_price);
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
        console.log('Item is not in rental reriod');
        console.log(_tokenId);
        console.log(_owner);
        console.log(_datetime);
        console.log(_itemsForRent[_tokenId][_owner].expirationTime);
        require(
            _itemsForRent[_tokenId][_owner].expirationTime < _datetime,
            "Item is in rental period"
        );
        _;
    }

    constructor()
        ERC1155(
            "https://ipfs.io/ipfs/bafybeihjjkwdrxxjnuwevlqtqmh3iegcadc32sio4wmo7bv2gbf34qs34a/{id}.json"
        )
    {
        
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

        console.log('Minted');
        console.log(_uri);
        console.log(msg.sender);
        console.log(address(this));
        console.log(_supply);

        emit Minted(tokenId, _uri, msg.sender, address(this), _supply);

        return _tokenIds.current();
    }

    function shareOwnership(uint256 _tokenId, uint256 _supply, uint256 _datetime) ItemIsNotInRentalPeriod(_tokenId, msg.sender, _datetime) ItemIsNotRented(_tokenId, msg.sender, 0) public {        
        console.log("Share ownership");
        console.log(_tokenId);
        console.log(_supply);
        console.log(_datetime);
        console.log(msg.sender);

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
        
        console.log('Minted');
        console.log(_uris[_tokenId]);
        console.log(msg.sender);
        console.log(address(this));
        console.log(_supply);

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
        console.log("Safe transfer form");
        console.log('from', from);
        console.log('to', to);
        console.log('token id', id);
        console.log('amount', amount);
        console.log("balance from:");
        console.log(balanceOf(from, id));
        console.log("balance to:");
        console.log(balanceOf(to, id));

        _safeTransferFrom(from, to, id, amount, data);
    }

    function buy(
        uint256 _tokenId,
        uint256 _quantity,
        address payable _seller,
        uint256 _datetime
    ) external payable BuyerIsValid(_tokenId, _seller) ItemIsNotInRentalPeriod(_tokenId, _seller, _datetime) AmountPurchasementIsValid(_itemsForSale[_tokenId][_seller].price) ItemIsAvailableForBuy(_tokenId, _seller) {
        safeTransferFrom(_seller, msg.sender, _tokenId, _quantity, "0x0");
        _itemsForSale[_tokenId][_seller].isSold = true;
        _seller.transfer(msg.value);
    }
    
    function rent(
        uint256 _tokenId,
        uint256 _day,
        address payable _owner,
        uint256 _datetime
    ) external payable ItemIsNotInRentalPeriod(_tokenId, _owner, _datetime) UserIsValid(_tokenId, _owner) AmountRentalIsValid(_itemsForRent[_tokenId][_owner].price * _day) ItemIsAvailableForRent(_tokenId, _owner, _datetime) {
        _itemsForRent[_tokenId][_owner].expirationTime = (_day * 86400000) + _datetime;
        _itemsForRent[_tokenId][_owner].user = msg.sender;

        console.log("Rent");
        console.log(_itemsForRent[_tokenId][_owner].expirationTime);
        console.log(_itemsForRent[_tokenId][_owner].user);
        
        _owner.transfer(msg.value);
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

        console.log("Rent");
        console.log(itemForRent.expirationTime);
        console.log(itemForRent.user);
        console.log("Owner List");
        for(uint256 i = 0; i < _ownerList.length; i++) {
            console.log(_ownerList[i]);
        }
        console.log("Share List");
        for(uint256 i = 0; i < _shareList.length; i++) {
            console.log(_shareList[i]);
        }
                    
        console.log("Transfer List");
        for(uint256 i = 0; i < _ownerList.length; i++) {
            console.log(msg.value);
            console.log(_shareList[i]);
            console.log(_supplies[_tokenId]);
            console.log(msg.value * _shareList[i] / _supplies[_sharedOwnershipMapping[_tokenId]]);
            console.log('...');
            if(balanceOf(_ownerList[i], _sharedOwnershipMapping[_tokenId]) == _shareList[i]) {
                _ownerList[i].transfer(msg.value * _shareList[i] / _supplies[_sharedOwnershipMapping[_tokenId]]);
            }
        }
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