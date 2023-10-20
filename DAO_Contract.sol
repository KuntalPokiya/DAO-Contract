// SPDX License-Identifier: GPL-3.0
pragma solidity >=0.7.0 < 0.9.0;

contract demo {

    struct Proposal{
        uint id;
        string description;
        uint amount;
        address payable receipient;
        uint votes;
        uint end;
        bool isExecuted;
    }

    mapping(address=>bool) private isInvestor;
    mapping(address=>uint) public numOfShares;
    mapping(address=>mapping(uint=>bool)) public isVoted;
    mapping(uint=>Proposal) public proposalList;
    address[] public investorsList;

    uint public totalShares;
    uint public avaibleFunds;
    uint public contributionTimeEnds;
    uint public nextProposalID;
    uint public voteTime;
    uint public quorum;
    address public manager;
    
    constructor(uint _contributionTimeEnds,uint _voteTime,uint _quorum)
    {
        require(_quorum>0 && _quorum<100,"Not valid values");
        contributionTimeEnds=block.timestamp+_contributionTimeEnds;
        voteTime=_voteTime;
        quorum=_quorum;
        manager=msg.sender;
    }

    modifier onlyInvestor(){
        require(isInvestor[msg.sender]==true,"You are not an Investor");
        _;
    }

     modifier onlyManager(){
        require(manager==msg.sender,"You are not the Manager");
        _;
    }

    function contribution() public payable{
        require(contributionTimeEnds>=block.timestamp,"Contribution period has been ended");
        require(msg.value>0,"Send more than 0 ether");
        isInvestor[msg.sender]=true;
        numOfShares[msg.sender]+=msg.value;
        totalShares+=msg.value;
        avaibleFunds+=msg.value;
        investorsList.push(msg.sender);
    }

    function reedemShare(uint amount) public onlyInvestor(){
        require(numOfShares[msg.sender]>=amount,"You don't have enough shares");
        require(avaibleFunds>=amount,"Not enough Funds");
        numOfShares[msg.sender]-=amount;
        if(numOfShares[msg.sender]==0)
        {
            isInvestor[msg.sender]=false;
        }
        avaibleFunds-=amount;
        payable (msg.sender).transfer(amount);
    }

    function transferShare(uint amount,address toHim) public onlyInvestor()
    {
      require(numOfShares[msg.sender]>=amount,"You don't have enough shares");
        require(avaibleFunds>=amount,"Not enough Funds");
        numOfShares[msg.sender]-=amount; 
         if(numOfShares[msg.sender]==0)
        {
            isInvestor[msg.sender]=false;
        }
        numOfShares[toHim]+=amount;
        isInvestor[toHim]=true;
        investorsList.push(toHim); 
    }

    function createProposal(string calldata description,uint amount,address payable receipient) public onlyManager()
    {
        require(avaibleFunds>=amount,"Not enough Funds");
        proposalList[nextProposalID]=Proposal(nextProposalID,description,amount,receipient,0,block.timestamp+voteTime,false);
        nextProposalID++; 
    }

    function voteProposal(uint proposalID) public onlyInvestor(){
        Proposal storage proposal = proposalList[proposalID];
        require(((proposal.votes*100)/totalShares)>=quorum,"Majority does not support");
    proposal.isExecuted=true;
    avaibleFunds-=proposal.amount;
    _transfer(proposal.amount,proposal.receipient);
    }

    function _transfer(uint amount,address payable receipient) private{
        receipient.transfer(amount);
    }

    function ProposalList() public view returns(Proposal[] memory)
    {
        Proposal[] memory arr= new Proposal[](nextProposalID-1);
        for(uint i=0;i<nextProposalID;i++)
        {
            arr[i]=proposalList[i];
        }
        return arr;
    }

}