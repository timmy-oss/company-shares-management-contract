

# @title Company Shares Management Smart Contract
# @author Timileyin Pelumi http://github.com/timmy-oss
# @notice This smart contract manages the sale and purchase of a company's shares. It can be used for handling a company's initial public offering
# @notice Users can buy, sell, and transfer company shares




event Buy:
    sender : address
    amount : uint256

event Sell:
    sender  : address
    amount : uint256




event Transfer:
    sender : address
    receiver : address
    amount : uint256

event PayVendor:
    vendor : address
    amount : uint256


totalShares  : public(uint256)
holdings : public(HashMap[address, uint256])
company : public(address)
sharesLocked : bool
price : public(uint256)

@external
def __init__( _totalShares : uint256, _price : uint256, _sharesLocked : bool ):

    assert _totalShares > 0, 'Total shares must be greater than zero'
    self.sharesLocked = _sharesLocked
    self.price = _price
    self.company =  msg.sender
    self.totalShares = _totalShares
    self.holdings[self.company] = _totalShares


@external
def lockShares():

    #@dev Lock the shares and prevent transfers and purchases only

    assert msg.sender == self.company
    assert  not self.sharesLocked
    self.sharesLocked = True

@external
def unlockShares():

    #@dev does the opposite of lockShares

    assert msg.sender == self.company
    assert self.sharesLocked
    self.sharesLocked = False

@external
@payable
def buyShares():

    #@dev buyShares: The amount is calculated from the amount of ether sent

    assert msg.sender != self.company
    assert msg.value >= self.price
    assert self.holdings[self.company] > 0 , 'Out of shares to sell'
    assert not self.sharesLocked, 'Shares are currrently locked'
    buyOrder : uint256 = msg.value / self.price
    assert self.holdings[self.company] > buyOrder , 'Not enough shares to meet order'
    self.holdings[self.company] -= buyOrder
    self.holdings[msg.sender] += buyOrder
    log Buy(msg.sender, buyOrder)


@external
def sellShares( _amount : uint256):

    #@dev sell an amount of shares back to the company in exchange for ethers
    #@param _amount : Amount of shares to sell

    assert msg.sender != self.company
    assert self.holdings[msg.sender] > 0, 'No shares detected'
    assert self.holdings[msg.sender] >= _amount , 'Insufficient shares'
    sellOrder : uint256 = self.price * _amount
    assert self.balance >= sellOrder, 'Insufficient funds to settle order'
    self.holdings[msg.sender] -= _amount
    self.holdings[self.company] += _amount
    send(msg.sender, _amount)
    log Sell(msg.sender, sellOrder)


@external
def transferShares( _receiver : address, _amount : uint256):

    #@dev transfer some shares from the sender to the receiver
    #@param _receiver : The receiver of the transferred shares
    #@param _amount : The amount of the shares to transfer

    assert msg.sender != self.company
    assert not self.sharesLocked, 'Shares are locked'
    assert _receiver != ZERO_ADDRESS
    assert self.holdings[msg.sender] >= _amount, 'Insufficient shares to complete transfer'
    self.sharesLocked = True
    self.holdings[msg.sender] -= _amount
    self.holdings[_receiver] += _amount
    self.sharesLocked = False
    log Transfer( msg.sender, _receiver, _amount)


@external
def payVendor(_amount: uint256, _vendor : address):

    #@dev Pay a vendor for services rendered to the company
    #@param _vendor : The address of the vendor to be paid
    #@param _amount : The amount of ether to be sent to the vendor

    assert msg.sender == self.company
    assert self.balance >= _amount, 'Insufficient balance'
    send(_vendor, _amount )
    log PayVendor( _vendor, _amount)

@internal
@view
def _debt() -> uint256:
    return (self.totalShares - self.holdings[self.company]) * self.price

@internal
@view
def _worth() -> uint256:
    return self.balance - self._debt()

@external
def worth() -> uint256:

    #@dev Get the worth of the company in ethers

    return self._worth()

@external
def debt() -> uint256:

    #@dev Get the outstanding debt of the company in ethers

    return self._debt()




















