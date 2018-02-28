pragma solidity 0.4.18;

import "./DebtToken.sol";
import "./DebtRegistry.sol";

contract DiversifyOrder {

    address owner;
    uint256 principal; //this should be the money the creditor sent to debtor
    uint256 ownerShare; //this should be the share of the principal that the owner does not wish to divest
    uint256 endTimestamp; //this is the timestamp when all debt is expected ot be repaid.
    DebtToken token;
    DebtRegistry registry;
    bytes32 agreementId;
    uint paymentExpected;

    address termsContract; //anyone who invests should verify that they agree to the terms described herein
    
    mapping (address => uint) shares;
    uint totalInvested;
    address[] investors;

    bool acceptInvestments;
    bool acceptPayouts;

    modifier acceptableInvesment() {if (acceptInvestments && msg.sender != owner) {_;}}
    modifier acceptablePayout() {if (acceptPayouts) {_;}}

    event TokenReceived(uint tokenId);
    event InvestmentPeriodEnded(uint timestamp);
    event PayoutRound(uint amount);

    function DiversifyOrder(DebtToken _token, DebtRegistry _registry, bytes32 _agreementId, uint _principal, uint _ownerShare, uint256 timestamp) {
        require(principal > ownerShare);
        principal = _principal;
        ownerShare = _ownerShare;
        owner = msg.sender;
        token = DebtToken(_token);
        registry = DebtRegistry(_registry);
        endTimestap = _timestamp;
        agreementId = _agreementId;
    }

    function verifyToken(uint tokenId) {
        require(token.tokenIdToOwner(tokenId) == this);
        termsContract = registry.getTermsContract(bytes32(tokenId));
        require(termsContract.getValueRepaidToDate() == 0);
        paymentExpected = termsContract.getExpectedRepaymentValue(agreementId, endTimestamp);
        require(paymentExpected > principal);
        investors.push(owner);
        shares[owner] = ownerShare;
        acceptInvestments = true;
        TokenReceived(tokenId);
    }

    function invest() //must invest before first repayment. may change this restriction later
    acceptableInvestment()
    payable 
    {
        if (termsContract.getValueRepaidToDate() != 0) {
            forceEndInvestments();
            msg.sender.transfer(msg.value);
            return;
        }
        if (shares[msg.sender] == 0) {
            investors.push(msg.sender);
        }
        uint value = msg.value;
        if (totalInvested + value > principal - ownerShare) {
            value = value - (totalInvested - principal + ownerShare);
            acceptingInvestments = false;
            msg.sender.transfer(msg.value - value);
            acceptPayouts = true;
            InvestmentPeriodEnded(now);
        }
        totalInvested += value;
        owner.transfer(value);
        shares[msg.sender] += value;
        
    }

    function refund(uint amount) //can get refunded before first payment
    acceptableInvestment()
    payable
    {
        require(shares[msg.sender] >= amount);
        totalInvested -= amount;
        shares[msg.sender] -= amount;
        msg.sender.transfer(amount);
    }

    function forceEndInvestments() { // can be called once contract starts to get repaid
        require(termsContract.getValueRepaidToDate() != 0 && !acceptPayouts);
        if (totalInvestment < principal - ownerShare) {
            shares[owner] += principal - ownerShare - totalInvestment; //owner failed to divest his investment before payout
        }
        acceptInvestments = false;
        acceptPayouts = true;
        InvestmentPeriodEnded(now);
    }

    function payout()
    acceptablePayout()
    payable
    {
        uint256 total = this.balance;
        for (uint i = 0; i < investors.length(); i += 1) {
            investors[i].transfer(shares[investors[i]]/principal * total);
        }
        PaymentRound(total);
    }

}