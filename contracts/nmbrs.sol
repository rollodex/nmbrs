/*
     NMBRS - An Ethereum lottery game

     Deployed at: 0xacc36F1BD84a1b3A6b7886db1f3CFFE20342809a (Rinkeby)

*/

pragma solidity ^0.4.22;

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
    function add(uint x, uint y) internal pure returns (uint z) {
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
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
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

 contract NmbrsCore is Owned {
      uint256 public roundPool;
      uint256 public devPool;
      uint256 public divPool;
      uint256 public roundNumber;

      uint256 public roundGap = 1 hours;
      uint256 public votingPeriod = 32 hours;
      uint256 public maxRound = 72 hours;
      uint256 public roundStart;
      uint256 public roundEnd;
      uint256 public votingEnd;

      bool public inRound = false;
      bool public isVoting = false;
      bool public gameStarted = false;

      mapping (uint256 => mapping(address => bool)) public hasVoted;
      mapping (uint256 => mapping(address => bytes32)) public voteHashes;
      mapping (uint256 => uint256) public voteCount;
      mapping (uint256 => uint256) public votesCounted;
      mapping (uint256 => uint8[9]) public popularity;
      mapping (uint256 => mapping (uint8 => address[])) public confirmedVoters;
      mapping (address => uint256) public winnings;

       constructor() public  {


       }

     function startGame() public onlyOwner {
         uint256 time = now;
         roundStart = time + roundGap;
         roundEnd = roundStart+maxRound;
         gameStarted = true;
     }

      function vote(bytes32 voteHash) public payable {
          require(!hasVoted[roundNumber][msg.sender]);
          require(msg.value > 0);
          require(!isVoting);
          require(gameStarted);

          uint256 time = now;
          if (time >= roundStart && time < roundEnd)
             inRound = true;

          if (time >= roundEnd) {
              inRound = false;
              isVoting = true;
              votingEnd = time + votingPeriod;
          }

          uint256 split = msg.value;

          //Calculate pools:
          uint256 contribution = split * 100;
          contribution = contribution / 10000;
          devPool += contribution;
          divPool += contribution;
          split -= contribution;
          split -= contribution;

          roundPool += split;

          voteHashes[roundNumber][msg.sender] = voteHash;
          voteCount[roundNumber]++;
          hasVoted[roundNumber][msg.sender] = true;
          if (inRound)
             roundEnd += 10 seconds;

      }

      function revealVote(uint256 secretNum,uint256 seed) public {
          require(hasVoted[roundNumber][msg.sender]);
          require(isVoting);

          uint256 time = now;

          uint256 v = secretNum + seed;
          bytes32 h = keccak256(v);

          bytes32 roundHash = voteHashes[roundNumber][msg.sender];

          if (h == roundHash) {
              if (secretNum >= 1 && secretNum <= 9) {
                 votesCounted[roundNumber]++;

              }
              if (secretNum == 1) {
                  confirmedVoters[roundNumber][0].push(msg.sender);
                  popularity[roundNumber][0]++;
              }

               if (secretNum == 2) {
                  confirmedVoters[roundNumber][1].push(msg.sender);
                  popularity[roundNumber][1]++;
              }

               if (secretNum == 3) {
                  confirmedVoters[roundNumber][2].push(msg.sender);
                  popularity[roundNumber][2]++;
              }

               if (secretNum == 4) {
                  confirmedVoters[roundNumber][3].push(msg.sender);
                  popularity[roundNumber][3]++;
              }

               if (secretNum == 5) {
                  confirmedVoters[roundNumber][4].push(msg.sender);
                  popularity[roundNumber][4]++;
              }

               if (secretNum == 6) {
                  confirmedVoters[roundNumber][5].push(msg.sender);
                  popularity[roundNumber][5]++;
              }

               if (secretNum == 7) {
                  confirmedVoters[roundNumber][6].push(msg.sender);
                  popularity[roundNumber][6]++;
              }

               if (secretNum == 8) {
                  confirmedVoters[roundNumber][7].push(msg.sender);
                  popularity[roundNumber][7]++;
              }

               if (secretNum == 9) {
                  confirmedVoters[roundNumber][8].push(msg.sender);
                  popularity[roundNumber][8]++;
              }
          }

          if (votesCounted[roundNumber] == voteCount[roundNumber] || time >= votingEnd ) {
              isVoting = false;
              inRound  = false;
              roundStart = time + roundGap;
              roundEnd = roundStart+maxRound;
              endRound();
          }
      }

      function endRound() private {
          uint8 small = popularity[roundNumber][0];
          uint8 winningIndex = 0;
          uint256 rN = roundNumber;
          roundNumber++;

          for(uint8 i = 1; i < 9; i++) {
              uint8 p = popularity[roundNumber][i];
              if (p == 0) continue;

              if (small < p || small == 0) {
                small = p;
                winningIndex = i;
              }
          }

          //Payout to the winning index:
          uint256 winnersLen = confirmedVoters[rN][winningIndex].length;
          if (winnersLen != 0) {
              uint256 splitPot = roundPool / winnersLen;

              for (uint256 j = 0; j <winnersLen; j++) {
                 address winner  = confirmedVoters[rN][winningIndex][i];
                 winnings[winner] += splitPot;
              }
          }
      }

      function wdDev(address sendTo) public onlyOwner {
         require (devPool < address(this).balance);
         uint256 amtToSend = devPool;
         devPool = 0;
         sendTo.transfer(amtToSend);
      }

      function wdWin() public {
          require(winnings[msg.sender] > 0 && winnings[msg.sender] < address(this).balance);

          msg.sender.transfer(winnings[msg.sender]);
      }
    }

 
