// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Ticketing {
    address public owner;

    struct Event {
        uint256 date;
        uint256 totalTickets;
        uint256 ticketPrice;
        uint256 ticketsSold;
    }

    //similar to Map<K, V>
    mapping(string => Event) private events;
    mapping(string => mapping(address => bool)) private tickets;
    mapping(address => string[]) private ownedTickets;

    //Modifiers are reusable functions where we can implement constraints and return an error in case true
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    //the sender is the requester's address
    constructor() {
        owner = msg.sender;
    }

    function createEvent(string memory name, uint256 date, uint256 totalTickets, uint256 ticketPrice) public onlyOwner {
        require(events[name].date == 0, "Event already exists");
        
        events[name] = Event({
            date: date,
            totalTickets: totalTickets,
            ticketPrice: ticketPrice,
            ticketsSold: 0
        });
    }

    function getEventDetails(string memory name) public view returns (uint256, uint256, uint256, uint256) {
        Event memory evt = events[name];
        require(evt.date != 0, "Event does not exist");

        return (evt.date, evt.totalTickets, evt.ticketPrice, evt.totalTickets - evt.ticketsSold);
    }

    //public means it can be called by any user
    //payable means this function claims ethers to be executed (msg.value)
    function purchaseTicket(string memory eventName) public payable {
        uint256 currentDate = block.timestamp;
        
        Event storage evt = events[eventName];
        require(evt.date != 0, "Event does not exist");
        require(evt.ticketsSold < evt.totalTickets, "Sold out");
        require(currentDate < evt.date, "Event has already finished");
        require(msg.value == evt.ticketPrice, "Incorrect Ether value");
        require(!tickets[eventName][msg.sender], "Ticket already purchased");

        evt.ticketsSold++;
        tickets[eventName][msg.sender] = true;
        ownedTickets[msg.sender].push(eventName);
    }

    function listOwnedTickets() public view returns (string[] memory) {
        return ownedTickets[msg.sender];
    }

    function transferTicket(string memory eventName, address to) public {
        require(tickets[eventName][msg.sender], "You do not own this ticket");
        require(!tickets[eventName][to], "Recipient already owns this ticket");

        tickets[eventName][msg.sender] = false;
        tickets[eventName][to] = true;

        for (uint256 i = 0; i < ownedTickets[msg.sender].length; i++) {
            //using keccak256 to generate a hash, because string comparison in solity is not eficient
            if (keccak256(abi.encodePacked(ownedTickets[msg.sender][i])) == keccak256(abi.encodePacked(eventName))) {
                ownedTickets[msg.sender][i] = ownedTickets[msg.sender][ownedTickets[msg.sender].length - 1];
                ownedTickets[msg.sender].pop();
                break;
            }
        }

        ownedTickets[to].push(eventName);
    }
}
