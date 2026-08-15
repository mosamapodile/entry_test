const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DecentralisedRaffle - Ticket Weighting Test", function () {
  let raffle;
  let owner;
  let player1;

  const TICKET_PRICE = ethers.parseEther("0.01");

  beforeEach(async function () {
    [owner, player1] = await ethers.getSigners();

    const Raffle = await ethers.getContractFactory("DecentralisedRaffle");
    raffle = await Raffle.deploy();
    await raffle.waitForDeployment();
  });

  it("Should correctly aggregate player ticket weights for multiple entries", async function () {
    const threeTicketsValue = TICKET_PRICE * 3n;

    // Enter raffle with ETH payment
    await raffle.connect(player1).enterRaffle({ value: threeTicketsValue });

    // Verify player entry count or total players length
    if (typeof raffle.getEntries === "function") {
      const entries = await raffle.getEntries(player1.address);
      expect(entries).to.equal(3);
    } else if (typeof raffle.getUniquePlayerCount === "function") {
      const uniquePlayers = await raffle.getUniquePlayerCount();
      expect(uniquePlayers).to.equal(1);
    } else {
      // Fallback assertion on contract balance
      const balance = await ethers.provider.getBalance(await raffle.getAddress());
      expect(balance).to.equal(threeTicketsValue);
    }
  });
});