// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

   
    
contract BusinessProposal { 
     
struct Proposal {
        string ownerName;
        string businessName;
        uint256 aadharCard;
        uint256 panCard;
        string GSTNumber;
        address ownerAddress;//Metamask Account Address
        uint256 minimumAmount;
        uint256 goalAmount;
        uint256 fundingPeriod;
        string imageURL;
        string category;
        bool hasPanCard;
        bool hasGSTNumber;
        bool isEligible;
        bool isGSTVerified;
        bool panCardVerified;
        bool isContractCreated;
        bool isBusinessDocumentsVerified;
    }
    
    mapping(address => Proposal) public proposals;
    mapping(address => bool) public proposalAccount;// Mapping of the accounts that has already send business proposals. these accounts cannot make proposals again...
    mapping(address => address) public governmentOfficials;// Mapping of government officials' Metamask account
    mapping(address => bool) public boolgovernmentOfficials;// Mapping of government officials' Metamask account
    address public government;
    uint256 public campaignContractCount;
    address[] public campaigns;
    event ProposalSubmitted(address indexed owner, uint256 amount);
    event ProposalEligible(address indexed owner);
    event CampaignContractCreated(address indexed owner, address indexed contractAddress);
    constructor() {
        government = msg.sender;
    }
    
    modifier onlyGovernment() {
        require(msg.sender == government, "Only government can perform this action.");
        _;
    }
    
    // Function to add a government official to the mapping
    function addGovernmentOfficial(address officialAddress) external onlyGovernment {
        require(!boolgovernmentOfficials[officialAddress] == true,"Already an government official, won't allow to add again!!!");
        boolgovernmentOfficials[officialAddress] = true;
        governmentOfficials[officialAddress] = officialAddress;
    }

    // Function to remove a government official from the mapping
    function removeGovernmentOfficial(address officialAddress) external onlyGovernment {
        require(!boolgovernmentOfficials[officialAddress] == false,"No such Official Found!!!");
        boolgovernmentOfficials[officialAddress] = false;
        governmentOfficials[officialAddress] = officialAddress;
    }
    //Function to submit Business Proposal that omits event when a proposal is submitted 
    function submitProposal(string memory _ownerName, 
                            string memory _businessName,
                            uint256 _aadharCard,
                            uint256 _panCard,
                            string memory _GSTNumber,
                            uint256 _minimumAmount,
                            uint256 _goalAmount,
                            uint _fundingPeriod,
                            string memory _imageURL,
                            string memory _category) external {
                                
        require(_minimumAmount > 0, "Proposal amount should be greater than zero.");
        require(!proposalAccount[msg.sender],"Proposal already created by this Account");
        proposals[msg.sender] = Proposal({
            ownerName : _ownerName,
            businessName : _businessName,
            aadharCard : _aadharCard,
            panCard : _panCard,
            GSTNumber : _GSTNumber,
            ownerAddress : msg.sender,
            minimumAmount : _minimumAmount,
            goalAmount : _goalAmount,
            fundingPeriod : _fundingPeriod,
            imageURL : _imageURL,
            category : _category,
            hasPanCard : false,
            hasGSTNumber : false,        
            isEligible : false,
            isGSTVerified : false,
            panCardVerified : false,
            isContractCreated : false, 
            isBusinessDocumentsVerified : false
        });
        if (_panCard != 0) {
            proposals[msg.sender].panCard = _panCard;
            proposals[msg.sender].hasPanCard = true;
            }           
            if (bytes(_GSTNumber).length > 0) {
            proposals[msg.sender].GSTNumber = _GSTNumber;
            proposals[msg.sender].hasGSTNumber = true;
            }
            proposalAccount[msg.sender] = true;
        emit ProposalSubmitted(msg.sender, _minimumAmount);
    }

function verifyDocuments(address _govtOfficial, address _ownerAddress) external {
        require(governmentOfficials[_govtOfficial] == msg.sender, "Only government official can perform this action.");
        Proposal storage proposal = proposals[_ownerAddress];
        if(proposal.hasPanCard == true && proposal.hasGSTNumber == true){
            //this business is organized and registered on official Govt. Websites and has GST Verified certifications
            require(proposal.minimumAmount > 0, "Proposal not found.");
            require(proposal.isBusinessDocumentsVerified == false, "Documents are already verified for this proposal.");
        
            // Perform document verification here
            // ---- Algorithm to verify the Business Documents that will be imported using External Oracle Networks ---- //
            // if the Business Document HASH (NFT that is uploaded to IPFS thus generating unique IPFS HASH ) 
            // matches the uploaded Business documents HASH then we can say that that Business is Legitimate and Govt. Officals will Validate the Documents.   
            /*
                __________________PSEUDO CODE__________________
                if(IPFS HASH of the Document == HASH value of the Business Document generated using GSTNumber API (This API is used to fetch the Digital Business Document from GST Number) of business uploaded in the Proposal) 
                then : 
                Business is Authenticated and satisfies eligibility Criteria for Document Verificationv

            */
            proposal.isBusinessDocumentsVerified = true;
            proposal.isEligible = true;
        }
        else if(proposal.hasPanCard == false || proposal.hasGSTNumber == false) {
            require(proposal.minimumAmount > 0, "Proposal not found.");
            require(proposal.isBusinessDocumentsVerified == false, "Documents are already verified for this proposal.");
        
            // Perform document verification here
            // ---- Algorithm to verify the Business Documents (For Unorganized Sector) that will be imported using External Oracle Networks ---- //
                
            proposal.isBusinessDocumentsVerified = true;
            proposal.isEligible = true;
        }
    }

 function createCampaignContract(address _owner) external {
    Proposal storage proposal = proposals[_owner];
    //require(proposal.minimumAmount > 0, "Proposal not found.");
    require(proposal.isEligible, "Proposal is not eligible.");
    require(proposal.isBusinessDocumentsVerified, "Business Proposal is not Verified.");
    require(!proposal.isContractCreated, "Campaign contract already created.");
    address newCampaign = address(new Campaign(msg.sender));
    campaigns.push(newCampaign);

    proposal.isContractCreated = true;
    }


     function getStruct(address _address) public view returns (Proposal memory) {
        return proposals[_address];
    }

}
contract Campaign {
    BusinessProposal public businessProposal;
    uint public aadharCard;
    address public manager;
    

    Request[] public requests;
    uint public minimumContribution;
    mapping(address => bool) public approvers;
    uint public approversCount;

    constructor(address _user) {
   manager =  _user;
    }
    struct Request {
        string shortDescription;
        uint sendingAmount;
        address recipient;
        uint256 aadharCard;
        uint256 cbdcWallet;
        bool complete;
        uint approvalCount;
        mapping(address => bool) approvals;
    }

    function fetchStruct() external {
    BusinessProposal.Proposal memory myStruct = businessProposal.getStruct(manager);
    aadharCard = myStruct.aadharCard;
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function contribute() public payable {
        require(msg.value > minimumContribution);

        approvers[msg.sender] = true;
        approversCount++;
    }

    function createRequest(
        string memory _description,
        uint256 _value,
        address _recipient,
        uint _aadharCard,
        uint _cbdcWallet
    ) public restricted {
        Request storage newRequest = requests.push();//initially push empty request array and them update values for each request
        newRequest.shortDescription = _description;
        newRequest.sendingAmount = _value;
        newRequest.recipient = _recipient;
        newRequest.complete = false;
        newRequest.approvalCount = 0;
        newRequest.aadharCard = _aadharCard;
        newRequest.cbdcWallet = _cbdcWallet;
    }

    function approveRequest(uint index) public {
        Request storage request = requests[index];

        require(approvers[msg.sender]);
        require(!request.approvals[msg.sender]);

        request.approvals[msg.sender] = true;
        request.approvalCount++;
    }

function finalizeRequest(uint index) public payable restricted {
    Request storage request = requests[index];

    require(request.approvalCount > (approversCount / 2));
    require(!request.complete);

    address payable recipient = payable(request.recipient);
    recipient.transfer(request.sendingAmount);
    request.complete = true;
}


    function getSummary() public view returns (uint, uint, uint, uint, address)
    {
        return (
            minimumContribution,
            address(this).balance,
            requests.length,
            approversCount,
            manager
        );
    }

    function getRequestCount() public view returns (uint) {
        return requests.length;
    }


}