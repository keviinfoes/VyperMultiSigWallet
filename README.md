# VyperMultiSigWallet

Vyper basic multisignature wallet - WARNING: NOT AUDITED USE AT YOUR OWN RISK


## Deploy the multisignature contract
Note: compile the contract using vyper vyper 0.1.0b7 -> the new version(s) of vyper contain a breaking change for the use of "del" and the syntax of mappings.

## Overview of the multisignature contract
The multisignature wallet contains multiple functions. Below is an overview of the parameters and functions of the contract.

The constructor does the following:
  1) set the owner to msg.sender
  2) take the threshold parameter

After deployment of the contract the following functions are available:

* Owner related functions
  * owners_add -> takes up to 4 addresses as input parameter. 
    * Sets new owners within the max number of owners. NOTE: every owner can add new owners without the agreement of the other owners.
  * owners_proposeRemove -> takes 1 address as input parameter.
    * Sets proposal for the removal of an owner.
  * owners_agreeRemove -> takes a proposal index 
    * Sets confirmation for removal proposal +1. If agree == threshold owner is removed. NOTE: every owner can agree once on every proposal.
  * owners_refuseRemove -> takes a proposal index.
    * Sets refusal for removal proposal +1. If refuse == threshold proposal is closed. NOTE: every owner can refuse once on every proposal.
    

* Threshold related functions
  * threshold_propose -> takes uint input parameter.
    * Sets proposal for a new threshold.
  * threshold_agreePropose -> takes a proposal index 
    * Sets confirmation for new threshold proposal +1. If agree == prior threshold the new threshold is set. NOTE: every owner can agree once on every proposal.
  * threshold_refusePropose -> takes a proposal index.
    * Sets refusal for new threshold proposal +1. If refuse == prior threshold the new threshold is set. NOTE: every owner can refuse once on every proposal.
    
* Multisig payment related functions
  * payment_propose -> takes: to address, amount in wei, data bytes[4096], maxgas.
    * Sets proposal for a new payment.
  * payment_agreePropose -> takes a proposal index 
    * Sets confirmation for payment proposal +1. If agree == threshold the payment is send. NOTE: every owner can agree once on every proposal.
  * payment_refusePropose -> takes a proposal index.
    * Sets refusal for payment proposal +1. If refuse == threshold the payment is send. NOTE: every owner can refuse once on every proposal.
    
* Dailylimit related functions
  * dailylimit_propose -> takes amount in wei.
    * Sets proposal for a new dailylimit.
  * dailylimit_agreePropose -> takes a proposal index 
    * Sets confirmation for new dailylimit proposal +1. If agree == threshold the new dailylimit is set. NOTE: every owner can agree once on every proposal.
  * dailylimit_refusePropose -> takes a proposal index.
    * Sets refusal for new dailylimit proposal +1. If refuse == threshold the new dailylimit is set. NOTE: every owner can refuse once on every proposal.
  * dailylimit_Payment -> takes to address and amount in wei.
    * Sends an ETH transaction within the dailylimit. The dailylimit is applicable for the owners collectively.
    
## License
This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details

   
