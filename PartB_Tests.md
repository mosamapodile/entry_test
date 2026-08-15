# Part B: Test Scenarios Guide

**Marks:** 6 of 100 - 3 for at least one test of your own that passes, and 3 for
the **Thinking Like An Attacker** section at the bottom.

The auto-marker already runs its own test suite against your contracts. This
section is about whether *you* can think like a tester.

**You only need to write TWO tests of your own** - one per contract - in the
`test/` directory. There is a worked example in `test/example.test.js` you can
copy from. Quality over quantity: one thoughtful test beats ten copies of the
happy path.

Run them with:

```bash
npx hardhat test
```

---

## Test Scenario 1: FreelanceBountyBoard
**Target:** `contracts/FreelanceBountyBoard.sol`

### 1.1 The test I wrote

- **Test file and name:**
- **What it checks:**
- **Steps:**
- **Expected result:**
- **Does it pass?** [yes / no / partly]

Test file and name: test/customBounty.test.js — "Should prevent non-employer from approving and paying a bounty"

What it checks: Ensures strict access control on approveAndPay, verifying that an unauthorized account (non-employer) cannot trigger payouts or claim funds.

Steps:

    Employer posts a bounty with 1 ETH reward.

    A freelancer applies and submits work for the bounty.

    A third-party account (attacker) attempts to call approveAndPay(bountyId).

Expected result: The transaction reverts with a custom error or message like "Not the employer", and contract ETH balance remains securely locked in escrow.

Does it pass? yes

### 1.2 A scenario I did NOT have time to test

Describe one thing that could go wrong with this contract that neither you nor
the auto-marker checked. You do not have to write the code - just show you can
see the gap.


I did not test an edge case where an employer attempts to call cancelBounty while a freelancer's submission is actively under review, or where a malicious freelancer submits a contract with a reverting receive() function to permanently block approveAndPay. If freelancer.call{value: reward}("") fails because the freelancer's contract intentionally reverts on incoming ETH transfers, approveAndPay will revert repeatedly, preventing the employer from completing the bounty state lifecycle.

---

## Test Scenario 2: DecentralisedRaffle
**Target:** `contracts/DecentralisedRaffle.sol`

### 2.1 The test I wrote

- **Test file and name:**
- **What it checks:**
- **Steps:**
- **Expected result:**
- **Does it pass?** [yes / no / partly]

Test file and name: test/customRaffle.test.js — "Should correctly aggregate player ticket weights for multiple entries"

What it checks: Verifies that purchasing multiple tickets correctly updates playerEntries[msg.sender], updates uniquePlayerCount once per address, and appends the exact weighted number of entries to the players array.

Steps:

    Player 1 sends 0.03 ETH (3x MINIMUM_ENTRY).

    Inspect playerEntries[player1], uniquePlayerCount, and players.length.

Expected result: playerEntries[player1] equals 3, uniquePlayerCount equals 1, and players.length equals 3.

Does it pass? yes

### 2.2 The hard one

Testing a raffle is awkward because the winner changes every run. **How would
you write a test for a function whose result you cannot predict?** What can you
assert that is true no matter who wins?

(Hint: look at how the marker's own "pays 90% of the pot" test handles this -
it is in `grading/tests/DecentralisedRaffle.grading.test.js` and you are welcome
to read it.)

[Write your response here]

Instead of asserting who wins, you assert invariant properties that must hold true regardless of the winner's identity:

    State Invariants: The total contract ETH balance after selectWinner() drops to 0 (or exactly the retained admin fee percentage), and raffleActive sets to false.

    Conservation of Value: The winner's address balance increases by exactly 90% of the total ticket pot, while the contract owner's balance increases by exactly 10%.

    Participant Membership: The selected winner address must be present in the players array (players.includes(winner) == true)

---

## Thinking Like An Attacker (3 marks)

Pick **one** of your two contracts. If you wanted to steal from it or break it,
what would you try first?

- **Contract:**
- **My attack:**
- **Does it work against my implementation?** [yes / no / not sure]
- **If it works, what would fix it?**

An honest "yes, this attack works against my code, and here is the fix" scores
full marks here. Claiming your contract is perfect scores nothing.

Contract: DecentralisedRaffle

My attack: Validator Re-org / Block Withholding Attack & MEV Front-Running. As a player holding tickets in the raffle, if I am also an Ethereum validator (or work alongside a block builder), I can simulate the execution of selectWinner() off-chain right before publishing a block. If the pseudo-random calculation (keccak256(block.timestamp, block.prevrandao, players.length) % players.length) chooses another player as the winner, I can intentionally discard/withhold my block. Discarding the block changes the next block's timestamp and prevrandao, giving me a fresh roll on the random draw in the next slot.

Does it work against my implementation? yes

If it works, what would fix it? Replacing the on-chain block attribute hash with Chainlink VRF (Verifiable Random Function). Chainlink VRF uses an off-chain oracle that generates a random number and submits an on-chain cryptographic proof that cannot be previewed, manipulated, or influenced by block builders or validators.

---

## Checklist

- [ x] At least one test of my own in `test/`
- [ x] `npx hardhat test` runs without crashing
- [ x] I filled in the attacker section above
