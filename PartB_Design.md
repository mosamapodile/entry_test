# Part B: Design Document

**Marks:** 4 of 100 - the **Randomness** section below is read and marked. The
rest of this document is not scored, but it is read when we talk to you, so
answer it properly.

**Section 1: FreelanceBountyBoard**
**Section 2: DecentralisedRaffle**

Short, specific answers beat long vague ones. Three honest sentences score better
than a page of general security talk. If you ran out of time on something, say
so here - describing what you would have done still earns marks. Pretending it
is finished does not.

---

## WHY I BUILT IT THIS WAY

### 1. Data Structure Choices

- Where did you use a `mapping`, and where did you need an array instead?
- How did you record raffle entries so that a player who enters three times has
  three times the chance of winning?
- How did you count unique players separately from total entries?


In FreelanceBountyBoard, a mapping(uint256 => Bounty) was used for O(1) lookups by ID, while dynamic arrays tracked candidate applicants and listed active bounty IDs. In DecentralisedRaffle, playerEntries mapped addresses to individual ticket counts for instant balance lookups, whereas a dynamic players array stored every entry address sequentially so index selection remained properly weighted during draws.

To give a player three times the chance of winning, their wallet address was pushed to the dynamic players array 3 separate times (once for each ticket purchased). Because the random winning index is chosen across the full array length (randomIndex = hash % players.length), holding 3 array positions triples their probability of being picked.

Unique players were tracked using a dedicated uniquePlayerCount state variable. When enterRaffle() was called, the contract checked playerEntries[msg.sender]. If the existing entry count was 0, uniquePlayerCount was incremented by 1 before adding the new entries to playerEntries[msg.sender].
---

### 2. Security Measures

- **Reentrancy:** show the order of operations in `approveAndPay`. Which line
  updates the status, and which line sends the ETH? Why that order?
- **Access control:** which functions are owner-only or employer-only, and what
  would go wrong without those checks?
- **Input validation:** what did you reject, and where?


Reentrancy: show the order of operations in approveAndPay. Which line updates the status, and which line sends the ETH? Why that order?

In approveAndPay, state changes strictly precede external transfers following the Checks-Effects-Interactions (CEI) pattern:
// Effect: State update happens FIRST
bounty.status = Status.Completed;

// Interaction: External ETH transfer happens SECOND
(bool ok, ) = freelancer.call{value: amountToPay}("");
require(ok, "Transfer failed");

selectWinner, pause, and unpause are owner-only, while approveAndPay and cancelBounty are employer-only. Without owner checks, any participant could draw the raffle early or halt contract operations. Without employer checks, unauthorized users could approve low-quality work, cancel other people's bounties, or steal locked escrow funds.

The contracts reject zero-value payments on bounty creation (msg.value > 0), underpriced raffle entries (msg.value < MINIMUM_ENTRY), premature raffle draws (block.timestamp < raffleStartTime + RAFFLE_DURATION), insufficient unique participants (uniquePlayerCount < 3), and non-matching skills during freelancer applications.
---

### 3. Randomness - Be Honest Here (4 marks)

You were allowed to use block data for the raffle draw. This section is where
you show you understand what that costs.

- What exactly does your randomness depend on?
- **Who can manipulate it, and how?** Name the actor and the action.
- What would you use in production instead, and why is that better?


The randomness depends on on-chain block metadata hashed using keccak256(abi.encodePacked(block.timestamp, block.prevrandao, players.length)) % players.length

Block validators/proposers can simulate the raffle draw off-chain before producing a block. If the winning index does not favor them, the validator can discard or delay proposing the block, forcing the draw into a future block with a different prevrandao and timestamp. MEV searchers can also front-run selectWinner() calls by submitting high-gas transactions to alter players.length right before execution.

In production, I would use Chainlink VRF (Verifiable Random Function). Chainlink generates a random number off-chain along with an on-chain verifiable cryptographic proof, preventing validators, players, or contract owners from altering the outcome
---

### 4. Trade-offs & Future Improvements

- What did you not finish, or knowingly do the quick way?
- What would you add with another day? (dispute resolution, refunds, prize
  tiers, gas optimisation)



What did you not finish, or knowingly do the quick way?

I knowingly used an unbound for loop to reset playerEntries mapping values during selectWinner(). While functional for low user counts, it is inefficient for large numbers of entrants.

What would you add with another day? (dispute resolution, refunds, prize tiers, gas optimisation)

With another day, I would implement an epoch-based mapping strategy (mapping(uint256 => mapping(address => uint256))) to eliminate array cleanup loops entirely. I would also add an arbiter-backed dispute resolution system for FreelanceBountyBoard, multi-tier prize distributions (e.g., 60/25/15) for the raffle, and Chainlink Automation for hands-free winner selection.

---

## REAL-WORLD DEPLOYMENT CONCERNS

> [!NOTE]
> These are **written questions only**. You are not deploying anything, and you
> do not need a wallet, a faucet or any test ETH to answer them. Reason it
> through in prose.

### 1. Gas Costs

- Which of your functions is the most expensive, and why?
- Roughly what would it cost a user at 20 gwei, with ETH at $3,000? (Use the
  same arithmetic as Part A Question 2.)
- Is that affordable for the users you would actually be building this for? If
  not, what would you change?


Which of your functions is the most expensive, and why?selectWinner() is the most expensive function because it executes dynamic state cleanup loop iterations (delete playerEntries[...]), resets dynamic arrays, and triggers cold external ETH transfers.Roughly what would it cost a user at 20 gwei, with ETH at $3,000? (Use the same arithmetic as Part A Question 2.)At an estimated ~100,000 gas units:$\text{Gas Fee (ETH)} = 100,000 \times (20 \times 10^{-9}) = 0.002\text{ ETH}$$\text{Cost (USD)} = 0.002 \times \$3,000 = \$6.00$Is that affordable for the users you would actually be building this for? If not, what would you change?A $6.00 transaction fee is too high for small-ticket micro-raffles or low-value freelance work. To fix this, I would deploy the contract to an Ethereum Layer 2 network (such as Arbitrum or Base) where transaction fees remain below $0.05.

---

### 2. Scalability

**What happens when the raffle has 10,000 entries?**

- Which part of `selectWinner` gets slower or more expensive as the array grows?
- What breaks first?


Which part of selectWinner gets slower or more expensive as the array grows?

The state cleanup loop (for (uint256 i = 0; i < playerCount; i++) { delete playerEntries[players[i]]; }) grows linearly O(N) relative to the total entry count.

What breaks first?

At 10,000 entries, the gas required to complete the loop exceeds the maximum block gas limit (30,000,000 gas). selectWinner() runs out of gas and constantly reverts, causing a Denial of Service (DoS) where funds become permanently locked in the contract.

---

### 3. User Experience

**How would you make this usable for someone who has never held a wallet?**

- What is the hardest step for a first-time user?
- If you *were* deploying this for real, which testnet would you try it on
  first, and how would a tester get test ETH? (Describe it - you are not doing
  it.)


What is the hardest step for a first-time user?

The hardest step is setting up a Web3 wallet, securing a seed phrase, and obtaining base native ETH to pay for transaction gas fees before interacting with the application.

If you were deploying this for real, which testnet would you try it on first, and how would a tester get test ETH? (Describe it - you are not doing it.)

I would deploy onto the Sepolia Testnet. A tester would install a browser extension wallet (like MetaMask), copy their account address, and request free testnet ETH from a Sepolia faucet (such as Google Cloud or Alchemy Sepolia Faucets).

---

## MY LEARNING APPROACH

### Resources I Used

Be specific. "The Cyfrin course" is not a resource; "Blockchain Basics, The
Oracle Problem" is. List 3-5.


Solidity Documentation: "Units and Global Variables" & "Security Considerations (CEI Pattern)".

Cyfrin Updraft: "Foundry Fundamentals - Smart Contract Security & Weak Randomness".

OpenZeppelin Docs: "ReentrancyGuard & Pausable Circuit Breakers".

SWC Registry: "SWC-120: Weak Sources of Randomness from Chain Attributes".

---

### Challenges Faced

- The biggest thing you got stuck on
- How you got unstuck
- What you know now that you did not this morning

The biggest thing you got stuck on

Accurately tracking unique players versus total entries while managing weighted tickets without iterating through mappings.

How you got unstuck

I separated responsibilities: using the dynamic players array strictly for weighted index selection, and using playerEntries mapping lookups to check existing entry balances prior to updating uniquePlayerCount.

What you know now that you did not this morning

I now understand why block.prevrandao is unsuitable for production lotteries and how essential Checks-Effects-Interactions (CEI) ordering is for secure ETH transfers.

---

### What I'd Learn Next


Integrating Chainlink VRF v2.5 and Chainlink Automation for automated, secure draws.

Supporting ERC-20 tokens (like USDC/DAI) alongside native ETH payouts.

Writing comprehensive unit and invariant fuzz tests in Foundry (vm.warp, vm.prank).

---
