# The Numbers Game

The Numbers Game (aka NMBRS) is an Ethereum lottery experiment for #colotterygamejam. It is a voting game, with a unique twist. In the game, the goal is to cast one vote for a number during the 6 minute round, and a jackpot is paid out to the players who picked the number with the *least* amount of votes, or all players in the case of a tie.


# Features

 - It doesn't require a central server and all game logic is fully contained within a blockchain smart contract, so it can be served fully decentralized (like running a local server or hosting on IPFS) 
 - It uses ChainLink Alarm Clock to execute itself at a set interval. This decentralizes the task of managing rounds, so you don't need to fund or rely on your own daemon or cron job, or other external actor other than Chainlink to keep the game running. 
 - The ticket fee (disabled for demo) and prize use the decentralized stablecoin, DAI, which is pegged to $1. It could easily be modified to use a USD on-ramp or converted to an all cash lottery.

## Inspiration

I wanted to create something simple, fun, reasonably unpredictable and that could be adapted down to pen and paper or a lottery-ticket/keno slip style of delivery. The blockchain aspects were inspired by popular ethereum games such as FOMO3D where a timer is the crucial component and driver of the action. The color scheme was inspired by vaporwave aesthetics. I want to capture the neon feel of a nightclub, or the fuzziness of a cathode ray monitor.  

## Future

 - More graphics. I am fascinated with WebGL and it's potential to make cool visualizations of the game data for the monitor 
 - Scalability - Chainlink provides great autonomy, and I want the possibility to move the payout processing out of solidity so it can handle more players (potentially statewide) per round. Perhaps via a Layer 2 solution or new technology such as RenVM.

## Changelog

8/1 - Initial prototype 
8/2 - Code and backbone boilerplate
8/3 - Initial visual design
8/5 - Getting rid of commit/reveal (vote hashing), changing the vote counting algorithm and other solidity fixes
8/8 - Incorporation of DAI and Chainlink
8/9 - Creating a fixed jackpot pool (separate contract for modularity) instead of splitting the ticket purchases as prize (makes for bigger prizes), removing the DAI fee so tickets don't have to be purchased to play.

Thanks to all who made this event possible! 

