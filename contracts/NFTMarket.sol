// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTMarket is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    address payable owner;
    uint256 private listingPrice = 0.025 ether;

    constructor() {
        owner = payable(msg.sender);
    }

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => MarketItem) private idToMarketItem;

    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address owner,
        uint256 price,
        bool sold
    );

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    function createMarketItem(
        address _nftContract,
        uint256 _tokenId,
        uint256 _sellingPrice
    ) public payable nonReentrant {
        require(_sellingPrice > 0, "Invalid Price");
        require(msg.value == listingPrice, "Invalid listing price");
        _itemIds.increment();

        uint256 _itemId = _itemIds.current();
        idToMarketItem[_itemId] = MarketItem(
            _itemId,
            _nftContract,
            _tokenId,
            payable(msg.sender),
            payable(address(0)),
            _sellingPrice,
            false
        );

        IERC721(_nftContract).transferFrom(msg.sender, address(this), _tokenId);

        emit MarketItemCreated(
            _itemId,
            _nftContract,
            _tokenId,
            msg.sender,
            _sellingPrice,
            false
        );
    }

    function createMarketItemSale(address _nftContract, uint256 _itemId)
        public
        payable
        nonReentrant
    {
        uint256 _itemPrice = idToMarketItem[_itemId].price;
        uint256 _tokenId = idToMarketItem[_itemId].tokenId;

        require(_itemPrice == msg.value, "Invalid Bid Amount");

        idToMarketItem[_itemId].seller.transfer(msg.value);
        IERC721(_nftContract).transferFrom(address(this), msg.sender, _tokenId);
        idToMarketItem[_itemId].owner = payable(msg.sender);
        idToMarketItem[_itemId].sold = true;
        _itemsSold.increment();
        payable(owner).transfer(listingPrice);
    }

    function fetchMarketItems() public view returns (MarketItem[] memory) {
        MarketItem[] memory unSoldItems;

        uint256 currentIndex = 0;
        for (uint256 i = 1; i <= _itemIds.current(); i++) {
            if (idToMarketItem[i].owner == address(0)) {
                unSoldItems[currentIndex] = idToMarketItem[i];
                currentIndex += 1;
            }
        }
        return unSoldItems;
    }

    function fetchMyPurchasedNfts() public view returns (MarketItem[] memory) {
        MarketItem[] memory purchasedItems;

        uint256 currentIndex = 0;
        for (uint256 i = 1; i <= _itemIds.current(); i++) {
            if (idToMarketItem[i].owner == msg.sender) {
                purchasedItems[currentIndex] = idToMarketItem[i];
                currentIndex += 1;
            }
        }
        return purchasedItems;
    }

    function fetchMyCreatedNfts() public view returns (MarketItem[] memory) {
        MarketItem[] memory createdItems;

        uint256 currentIndex = 0;
        for (uint256 i = 1; i <= _itemIds.current(); i++) {
            if (idToMarketItem[i].seller == msg.sender) {
                createdItems[currentIndex] = idToMarketItem[i];
                currentIndex += 1;
            }
        }
        return createdItems;
    }


}
