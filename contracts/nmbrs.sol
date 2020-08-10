/*
     NMBRS - An Ethereum lottery game

     Deployed at: 0xB1B0dEDC9B74e3C1FcBf07C3FAdFE730157cde08 (Rinkeby)
     Jackpot deployed at: 0xD0B94BAEa543FB6E59a2feFDB372a04b317C842d (Rinkeby)

*/

pragma solidity ^0.4.24;

import "github.com/smartcontractkit/chainlink/evm-contracts/src/v0.4/ChainlinkClient.sol";

contract Owned {
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) revert();
        _;
    }

    function transferOwnership(address _newOwner) onlyOwner public {
        newOwner = _newOwner;
    }
 
    function acceptOwnership() public {
        if (msg.sender == newOwner) {
           emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
        }
    }
 }
 
 
 library DSMath {
    function plus(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = plus(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = plus(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = plus(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = plus(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
    
}

interface ERC20 { 
    
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    
}

contract Jackpot is Owned {
    
     using DSMath for uint256;
     address public uDai = 0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa;
     address public gameContract;
     
     uint256 public jackpotAmount = 10000 ether;
     
     function widthdraw(uint amt) public onlyOwner {
         ERC20 theToken = ERC20(uDai);
         theToken.transfer(msg.sender,amt);
     }
     
     function jackpotFor(uint numPlayers) public { 
         require(msg.sender == gameContract); 
         
         ERC20 theToken = ERC20(uDai);
         theToken.transfer(msg.sender,jackpotAmount.wmul(numPlayers*1e18));
         
     }
     
     function setJackpot(uint amt) public onlyOwner {
         jackpotAmount = amt; 
     }
    
    function setGameContract(address gc) public onlyOwner {
        gameContract = gc; 
    }
    
}

 
 contract NmbrsCore is Owned, ChainlinkClient {
     
      using DSMath for uint256;
     
      uint256 public roundPool;
      uint256 public roundNumber; 
      
      uint256 public maxRound = 6 minutes;
      uint256 public roundStart; 
      uint256 public roundEnd; 
      uint256 public ticketCost = 1 ether; //NEW: Ticket cost (1 DAI)
      address public uDai = 0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa; //Rinkeby DAI address: This contract uses the DAI from Compound Faucet.
      address public jackpotContract; //Changes: A separate contract holds a fixed jackpot that is distributed per winner
      
      bytes32 public ALARM_CLOCK_ID = "4fff47c3982b4babba6a7dd694c9b204"; //NEW: For ChainLink
      bool enable_chainlink = false;
    
      bool public inRound = false;
      
      bool public gameStarted = false;
     
      mapping (uint256 => mapping(address => bool)) public hasVoted; 
      
      mapping (uint256 => uint256) public voteCount; 
     
      mapping (uint256 => uint256[9]) public popularity; 
    
      mapping (uint256 => mapping (uint256 => address[])) public confirmedVoters;
      
      mapping (uint256 => address) public allVoters; //NEW: Flat list of all voters [keyed by vote count] to simplify the case of a tie
      
      uint256 constant public MAX_UINT = 2**256 - 1; //NEW: For DAI approval and vote sorting
      
      
       constructor() public  {
        
         setPublicChainlinkToken();    
       }
     
     function startGame() public onlyOwner {
         uint256 time = now; 
         roundStart = time;
         roundEnd = roundStart+maxRound; 
         gameStarted = true; 
         inRound = true;
         
         
         if (enable_chainlink) {
            Chainlink.Request memory req = buildChainlinkRequest(ALARM_CLOCK_ID, this, this.fulfill.selector);
            req.addUint("until", now + 6 minutes);
            sendChainlinkRequestTo(0x7AFe1118Ea78C1eae84ca8feE5C65Bc76CcF879e, req, 1 ether);
         }
         
         emit roundStarted(roundNumber, roundEnd);  
         
     }
     
      function vote(uint256 v) public payable {
          require(!hasVoted[roundNumber][msg.sender]); 
          require(v > 0 && v < 10);
          //require(msg.value > 0); 
          require(now < roundEnd);
          
          require(gameStarted && inRound);
          
          //uint256 time = now; 
         // if (time >= roundStart && time < roundEnd)
            
          //uint256 split = msg.value;
          
          //Changes: For the hackathon, no tokens are needed to play. This comment can be removed to make a play of the game cost 1 DAI
          //ERC20 theToken = ERC20(uDai); 
          //require(theToken.transferFrom(msg.sender,address(this),ticketCost));
          //roundPool = roundPool.add(ticketCost); 
          
          //voteHashes[roundNumber][msg.sender] = voteHash;
          confirmedVoters[roundNumber][v].push(msg.sender);
          popularity[roundNumber][v]++;
          
          allVoters[voteCount[roundNumber]] = msg.sender;
          voteCount[roundNumber]++;
          hasVoted[roundNumber][msg.sender] = true; 
         
         //Removed: voting does not extend round by 10 seconds. (Rounds now last 6 minutes each)
         
         emit voteCast(roundNumber,msg.sender,v);
      }
     
      function endRound() private { 
           if (voteCount[roundNumber] == 0) {
               emit roundEnded(roundNumber,0);
               roundNumber++;
               inRound = true;
              emit roundStarted(roundNumber, roundEnd); 
               return;
           }
           
           bool tie = true; 
           uint firstNonZero = 0;
           uint256 splitPot = 0;
           uint256 i =0;
           uint256 winningIndex = 0;
           address winner;
           ERC20 theToken = ERC20(uDai); 
           Jackpot jc = Jackpot(jackpotContract);
           
           for (i= 0; i < 9; i++) {
               if (popularity[roundNumber][i] == 0)
                 continue;
                
               if (firstNonZero == 0)
                  firstNonZero = popularity[roundNumber][i]; 
                  
               if (popularity[roundNumber][i] != firstNonZero) {
                   tie = false;
                   break;
               }
           }
           
           if (tie) {
               jc.jackpotFor(voteCount[roundNumber]);
               splitPot = theToken.balanceOf(address(this)).wdiv(voteCount[roundNumber]*1e18);
               
               for (i = 0; i < voteCount[roundNumber]; i++) {
                   winner = allVoters[i];
                   theToken.transfer(winner,splitPot);
                emit win(roundNumber,winner,splitPot);
               }
               
           } else {
                 firstNonZero = MAX_UINT;
               
                 
                //This time get the number with the least votes (skipping non-zero)
                for (i= 0; i < 9; i++) {
                    if (popularity[roundNumber][i] == 0)
                    continue;
                    
                    if (firstNonZero > popularity[roundNumber][i]) {
                       firstNonZero = popularity[roundNumber][i];
                       winningIndex =  i;
                    }
                }
                
                    jc.jackpotFor(confirmedVoters[roundNumber][winningIndex].length);
                    splitPot = theToken.balanceOf(address(this)).wdiv(confirmedVoters[roundNumber][winningIndex].length*1e18);
                    
                    for (i = 0; i < confirmedVoters[roundNumber][winningIndex].length; i++) {
                        winner = confirmedVoters[roundNumber][winningIndex][i];
                        theToken.transfer(winner,splitPot);
                        emit win(roundNumber,winner,splitPot);
                    }
           }
           
           emit roundEnded(roundNumber,winningIndex);
           roundPool = 0;
           inRound = true;
           roundNumber++;
           emit roundStarted(roundNumber, roundEnd);  
  }
  
  function fulfill(bytes32 _requestId) public recordChainlinkFulfillment(_requestId) {
      
     /* additional computation here */
     uint256 time = now; 
     inRound = false;
     roundStart = time;
     roundEnd = roundStart+maxRound; 
     
     if (enable_chainlink) {
       Chainlink.Request memory req = buildChainlinkRequest(ALARM_CLOCK_ID, this, this.fulfill.selector);
       req.addUint("until", now + 6 minutes);
       sendChainlinkRequestTo(0x7AFe1118Ea78C1eae84ca8feE5C65Bc76CcF879e, req, 1 ether);
     }
     
              
     endRound();
     
  }
  
  function fulfill2() public { 
      require(now >= roundEnd);
      require(!enable_chainlink);
      
      uint256 time = now; 
      inRound = false;
      roundStart = time;
      roundEnd = roundStart+maxRound; 
      
      endRound();
  }
  
  function enableChainlink(bool enbl) public onlyOwner {
      enable_chainlink = enbl;
  }

       
  function getTimeLeft() view public returns (uint256) {
          uint256 time = now; 
          return (time > roundEnd) ? 0 : roundEnd - time; 
          
   }
   
   function setJackpotContract(address jc) public onlyOwner {
       jackpotContract = jc; 
   }
      
      event roundStarted(uint roundNumber, uint roundEnd);
      event roundEnded(uint roundNumber, uint winningNum);
      event win(uint roundNumber, address winner, uint amount);
      event voteCast(uint roundNumber, address voter, uint vote);
    
    }
      
 
