# @title Vyper basic Multisignature wallet - WARNING: NOT AUDITED USE AT YOUR OWN RISK
# @author Kevin Foesenek


# Events for the registration of payments and changes in owners and threshold
receive_payment: event({_from: indexed(address), _value: wei_value})
send_payment: event({_to: indexed(address), _value: wei_value})
remove_owner: event({removed: indexed(address)})
add_owner: event({added: indexed(address)})
change_threshold: event({newThreshold: uint256})

# State Variables
owners: public(address[5]) 
owner_index: public(uint256)
threshold: public(uint256)

# Variables removal owners
ownerRemove_proposed_index: uint256
ownerRemove_proposed: public({owner: address, agreed: uint256, refused: uint256, accepted: bool}[uint256])
ownerRemove_proposed_agree: public({agreed_by: address[int128]}[uint256])
ownerRemove_proposed_refuse: public({refused_by: address[int128]}[uint256])

# Variables adjust threshold
threshold_proposed_index: uint256
threshold_proposed: public({threshold: uint256, agreed: uint256, refused: uint256, accepted: bool}[uint256])
threshold_proposed_agree: public({agreed_by: address[int128]}[uint256])
threshold_proposed_refuse: public({refused_by: address[int128]}[uint256])

# Variables for payments and agreement of payments
payment_proposal_index: public(uint256) # index number for the proposal mapping
payment_proposals: public({to_address: address, value: wei_value, data: bytes[4096], maxgas: uint256,
                    agreed: uint256, refused: uint256, requestor: address, closed: bool}[uint256]) # mapping where key is a number representing a struct
payment_proposals_agree: public({agreed_by: address[int128]}[uint256])
payment_proposals_refuse: public({refused_by: address[int128]}[uint256])

# Variables for the daily limit function(s)
dailylimit_proposed_index: uint256
dailylimit_proposed: public({amount: wei_value, agreed: uint256, refused: uint256, accepted: bool}[uint256])
dailylimit: public(wei_value)
dailylimit_restAmount: public(wei_value)
dailylimit_newendtime: timestamp
dailylimit_endtime: public(timestamp)
dailylimit_proposedAgree: public({agreed_by: address[int128]}[uint256])
dailylimit_proposedRefuse: public({refused_by: address[int128]}[uint256])

# Constructor
@public
def __init__(_threshold: uint256):
        self.owners[0] = msg.sender # initial owner is msg.sender (add owners using the function add_owners)
        self.owner_index += 1
        assert _threshold <= 5 # limit on the threshold so it can't be set higher then the maximum number of owners
        self.threshold = _threshold # threshold of owners to agree on a payment

# Default function: registering the payment of ETH to the contract
@public
@payable
def __default__():
    log.receive_payment(msg.sender, msg.value)
    pass
  
# Function to add owners: note that every owner of the wallet can add owners 
@public
@payable
def owners_add(_owners: address[4]):
    
    for i in range(5):
        if self.owners[i] == msg.sender:
            for x in range(4):
                if _owners[x] != 0x0000000000000000000000000000000000000000:
        
                    number_check: uint256 = 0
        
                    for z in range(5):
                        if number_check == 0:
                            if self.owners[z] == 0x0000000000000000000000000000000000000000:
                                self.owners[z] = _owners[x]
                                self.owner_index += 1
                                number_check += 1
                                log.add_owner(_owners[x])
                            
# Function to propose the removal of owners
@public
@payable
def owners_proposeRemove(owner: address):
    
    number_owners: uint256 = self.owner_index
    removal_index: uint256 = self.ownerRemove_proposed_index   
    agreed: uint256 = self.ownerRemove_proposed[removal_index].agreed

    for i in range(5):
        if self.owners[i] == msg.sender:
            for x in range(5):
                if self.owners[x] == owner:
                    assert number_owners -1 >= 1
                    self.ownerRemove_proposed[removal_index].owner = owner
                    self.ownerRemove_proposed[removal_index].accepted = False
                    self.ownerRemove_proposed_agree[removal_index].agreed_by[agreed] = msg.sender
                    self.ownerRemove_proposed[removal_index].agreed += 1
                    removal_index += 1
                    self.ownerRemove_proposed_index = removal_index

# Function to agree with the removal of owners and removal if the number of agreements == threshold
@public
@payable
def owners_agreeRemove(remove_proposal: uint256):  

    owner: address = self.ownerRemove_proposed[remove_proposal].owner
    agreed: uint256 = self.ownerRemove_proposed[remove_proposal].agreed
    number_owners: uint256 = self.owner_index        
    status: bool = self.ownerRemove_proposed[remove_proposal].accepted
    
    assert status == False 
    for i in range(5):
        if self.owners[i] == msg.sender:        
        
            loop_index: uint256  
            
            for x in range(5):  
                assert self.ownerRemove_proposed_agree[remove_proposal].agreed_by[x] != msg.sender
                loop_index += 1
                if loop_index == 5:
                    self.ownerRemove_proposed_agree[remove_proposal].agreed_by[agreed] = msg.sender
                    agreed += 1
                    self.ownerRemove_proposed[remove_proposal].agreed = agreed
                    if agreed == self.threshold:
                        for z in range(5):
                            if self.owners[z] == owner:
                                assert number_owners - 1 >= 1
                                del self.owners[z] 
                                number_owners = number_owners - 1 
                                self.owner_index = number_owners
                                self.ownerRemove_proposed[remove_proposal].accepted = True
                                log.remove_owner(owner)

# Function to refuse the removal of owners and the closing of the proposal if the number of refusals == threshold
@public
@payable
def owners_refuseRemove(remove_proposal: uint256):
    
    owner: address = self.ownerRemove_proposed[remove_proposal].owner
    refused: uint256 = self.ownerRemove_proposed[remove_proposal].refused
    number_owners: uint256 = self.owner_index        
    status: bool = self.ownerRemove_proposed[remove_proposal].accepted
    
    assert status == False 
    for i in range(5):
        if self.owners[i] == msg.sender:
        
            loop_index: uint256  
            
            for x in range(5):  
                assert self.ownerRemove_proposed_refuse[remove_proposal].refused_by[x] != msg.sender
                loop_index += 1
                if loop_index == 5:
                    self.ownerRemove_proposed_refuse[remove_proposal].refused_by[refused] = msg.sender
                    refused += 1
                    self.ownerRemove_proposed[remove_proposal].refused = refused
                    if refused == self.threshold:
                        self.ownerRemove_proposed[remove_proposal].accepted = True    

# Function to propose new thesholds
@public
@payable
def threshold_propose(thresholdnew: uint256):
    
    newthreshold_index: uint256 = self.threshold_proposed_index
    agreed: uint256 = self.threshold_proposed[thresholdnew].agreed
    
    for i in range(5):
        if self.owners[i] == msg.sender:
            self.threshold_proposed[newthreshold_index].threshold = thresholdnew
            self.threshold_proposed_agree[newthreshold_index].agreed_by[agreed] = msg.sender
            self.threshold_proposed[newthreshold_index].accepted = False
            self.threshold_proposed[newthreshold_index].agreed += 1
            newthreshold_index += 1
            self.threshold_proposed_index = newthreshold_index

# Function to agree with new thresholds and the adjustment of the threshold if the number of agreements == prior threshold
@public
@payable
def threshold_agreePropose(proposal: uint256):  
    
    thresholdnew: uint256 = self.threshold_proposed[proposal].threshold
    agreed: uint256 = self.threshold_proposed[proposal].agreed
    status: bool = self.threshold_proposed[proposal].accepted
    
    assert status == False 
    for i in range(5):
        if self.owners[i] == msg.sender:
        
            loop_index: uint256  
            
            for x in range(5):  
                assert self.threshold_proposed_agree[proposal].agreed_by[x] != msg.sender
                loop_index += 1
                if loop_index == 5:
                    self.threshold_proposed_agree[proposal].agreed_by[agreed] = msg.sender
                    agreed += 1
                    self.threshold_proposed[proposal].agreed = agreed
                    if agreed == self.threshold:
                        self.threshold = thresholdnew
                        status = True
                        self.threshold_proposed[proposal].accepted = status
                        log.change_threshold(thresholdnew)
 
# Function to refuse new thresholds and closing of the proposal if the number of refusals == threshold
@public
@payable
def threshold_refusePropose(proposal: uint256):                   
                    
    thresholdnew: uint256 = self.threshold_proposed[proposal].threshold
    refused: uint256 = self.threshold_proposed[proposal].refused
    status: bool = self.threshold_proposed[proposal].accepted

    assert status == False 
    for i in range(5):
        if self.owners[i] == msg.sender:
        
            loop_index: uint256 
            
            for x in range(5):  
                assert self.threshold_proposed_refuse[proposal].refused_by[x] != msg.sender
                loop_index += 1
                if loop_index == 5:
                    self.threshold_proposed_refuse[proposal].refused_by[refused] = msg.sender
                    refused += 1
                    self.threshold_proposed[proposal].refused = refused
                    if refused == self.threshold:
                        status = True
                        self.threshold_proposed[proposal].accepted = status

# Function for proposing payments
@public
@payable
def payment_propose(to: address, amount: wei_value, data: bytes[4096], maxgas: uint256):
    for i in range(5): # Maximum number of owners (here 5) is hard coded 
        if self.owners[i] == msg.sender:
        
            index: uint256 = self.payment_proposal_index
            agreed_req: uint256 = 0
            self.payment_proposals[index].to_address = to 
            self.payment_proposals[index].value = amount 
            self.payment_proposals[index].closed = False
            self.payment_proposals[index].requestor = msg.sender
            self.payment_proposals[index].data = data
            self.payment_proposals[index].maxgas = maxgas
            self.payment_proposals_agree[index].agreed_by[agreed_req] = msg.sender
            agreed_req += 1
            self.payment_proposals[index].agreed = agreed_req
            self.payment_proposal_index = index + 1

# Function for refusing a payment proposal      
@public
@payable
def payment_refusePropose(proposal: uint256):
    
    refused_req: uint256 = self.payment_proposals[proposal].refused
    status: bool = self.payment_proposals[proposal].closed
    
    assert status == False
    for i in range(5): # Maximum number of owners (here 5) is hard coded
        if self.owners[i] == msg.sender:
        
            loop_index: uint256  
            
            for x in range(5):  
                assert self.payment_proposals_refuse[proposal].refused_by[x] != msg.sender
                loop_index += 1
                if loop_index == 5:
                    self.payment_proposals_refuse[proposal].refused_by[refused_req] = msg.sender
                    refused_req += 1
                    self.payment_proposals[proposal].refused = refused_req
                    if self.payment_proposals[proposal].refused == self.threshold:
                        status = True
                        self.payment_proposals[proposal].closed = status

# Function for agreement and payment of the proposal   
@public
@payable
def payment_agreePropose(proposal: uint256):
    to: address = self.payment_proposals[proposal].to_address
    amount: wei_value = self.payment_proposals[proposal].value
    agreed_req: uint256 = self.payment_proposals[proposal].agreed
    status: bool = self.payment_proposals[proposal].closed
    data: bytes[4096] = self.payment_proposals[proposal].data
    maxgas: uint256 = self.payment_proposals[proposal].maxgas

    assert status == False
    for i in range(5): # Maximum number of owners (here 5) is hard coded
        if self.owners[i] == msg.sender:

            loop_index: uint256

            for x in range(5): # Maximum number of owners (here 5) is hard coded 
                assert self.payment_proposals_agree[proposal].agreed_by[x] != msg.sender
                loop_index += 1
                if loop_index == 5:
                    self.payment_proposals_agree[proposal].agreed_by[agreed_req] = msg.sender   
                    agreed_req += 1
                    self.payment_proposals[proposal].agreed = agreed_req
                    if self.payment_proposals[proposal].agreed == self.threshold:
                            raw_call (to, data, outsize=4096, gas = maxgas, value=amount)  # Outsize is a fixed parameter in vyper
                            status = True
                            self.payment_proposals[proposal].closed = status
                            log.send_payment(to, msg.value)
                                
# Function proposal (new) dailylimit for payment without approval of the other owners
@public
@payable
def dailylimit_propose(amount: wei_value):
    
    index: uint256 = self.dailylimit_proposed_index
    
    for i in range(5): # Maximum number of owners (here 5) is hard coded
        if self.owners[i] == msg.sender:
            agreed: uint256 = self.dailylimit_proposed[index].agreed
            self.dailylimit_proposedAgree[index].agreed_by[agreed] = msg.sender
            self.dailylimit_proposed[index].amount = amount
            self.dailylimit_proposed[index].agreed += 1
            self.dailylimit_proposed[index].accepted = False
            index += 1
            self.dailylimit_proposed_index = index

# Function accept the (new) dailylimit -> if equal to threshold owners accept the new dailylimit is set (initial limit is zero)
@public
@payable
def dailylimit_agreePropose(proposal: uint256):
    
    amount: wei_value = self.dailylimit_proposed[proposal].amount
    agreed: uint256 = self.dailylimit_proposed[proposal].agreed
    status: bool = self.dailylimit_proposed[proposal].accepted
    
    assert status == False
    for i in range(5): # Maximum number of owners (here 5) is hard coded
        if self.owners[i] == msg.sender:
            loop_index: uint256 
            for x in range(5): # Maximum number of owners (here 5) is hard coded 
                assert self.dailylimit_proposedAgree[proposal].agreed_by[x] != msg.sender
                loop_index += 1
                if loop_index == 5:    
                    self.dailylimit_proposed[proposal].agreed += 1
                    self.dailylimit_proposedAgree[proposal].agreed_by[agreed] = msg.sender
                    if self.dailylimit_proposed[proposal].agreed == self.threshold:
                            self.dailylimit = amount
                            self.dailylimit_restAmount = self.dailylimit
                            self.dailylimit_endtime = block.timestamp
                            self.dailylimit_newendtime = block.timestamp
                            self.dailylimit_proposed[proposal].accepted = True 

# Function to refuse the proposed (new) dailylimit and the closing of the proposal if the number of refusals == threshold
@public
@payable
def dailylimit_refusePropose(proposal: uint256):
    
    amount: wei_value = self.dailylimit_proposed[proposal].amount
    refused: uint256 = self.dailylimit_proposed[proposal].refused
    status: bool = self.dailylimit_proposed[proposal].accepted
    
    assert status == False 
    for i in range(5):
        if self.owners[i] == msg.sender:
            loop_index: uint256  
            for x in range(5):  
                assert self.dailylimit_proposedRefuse[proposal].refused_by[x] != msg.sender
                loop_index += 1
                if loop_index == 5:
                    self.dailylimit_proposed[proposal].refused += 1
                    self.dailylimit_proposedRefuse[proposal].refused_by[refused] = msg.sender
                    if refused == self.threshold:
                        self.dailylimit_proposed[proposal].accepted = True

# Function for payment with the Dailylimit -> ONLY pays ETH -> daily limit is applicable for all owners together
@public
@payable
def dailylimit_Payment(to: address, amount: wei_value):
    
    rest_amount: wei_value = self.dailylimit_restAmount
    end: timestamp = self.dailylimit_endtime
    
    assert block.timestamp > end 
    assert amount <= rest_amount
    send(to, amount)
    rest_amount = rest_amount - amount
    self.dailylimit_restAmount = rest_amount
    self.dailylimit_newendtime = block.timestamp + 86400
    if self.dailylimit_restAmount == 0:
        end = block.timestamp + 86400
        self.dailylimit_endtime = end
        log.send_payment(to, msg.value)
        
# Internal function to reset the dailylimit_endtime after 24 hours of the last payment
@private
def dailylimit_resetEndtime():
    if self.dailylimit_endtime == self.dailylimit_newendtime:
        self.dailylimit_endtime = self.dailylimit_newendtime
        
# Internal function to reset the dailylimit_restAmount after a Day
@private
def dailylimit_resetAmount():
    if self.dailylimit_newendtime < block.timestamp:
        if self.dailylimit > self.dailylimit_restAmount:
            self.dailylimit_restAmount = self.dailylimit
          
