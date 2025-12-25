1. A prtotocol ttthta allow user to deposit into a vault and in return, they reciver get rebase that represent thier underlaying balance.
2. Rase token -> balanceOf is dynami changging  bale over time.
   = balance hange linearly with time
   =mint tokens to our user every time they perform action

3.  interest ser rate for each user   based on some global interest rate of the protocol at the time the user join
- the global intrst rate can only be dereased/ and reward ealy adopbter

CCIP
forge install smartcontractkit/contracts-ccip --no-commit

// this create a way for us to be able to send cross chian transfer

it help use stimulate local for our testing formforking

//chainlink local

forge install smartcontractkit/chainlink-local@v0.2.7-beta
