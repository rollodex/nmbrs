var State = {
  user: { value: "", watchers: [] },  //web3.eth.addresses[0]
  id: { value: 0, watchers: [] }, //metamask change
  daiBal: { value: 0, watchers: [] }, //erc20 dai. getBalance
  time: {value: 0, watchers:[]},
  target: {value: '', watchers:[]}
};

var maxUINT = '115792089237316195423570985008687907853269984665640564039457584007913129639935';

var WC = {
 dai: {mainnet:"",rinkeby:"0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa",instance:undefined},
 game: {mainnet:"",rinkeby:"0xacc36F1BD84a1b3A6b7886db1f3CFFE20342809a",instance:undefined}
}

function On(key, watcher) {
  State[key].watchers.push(watcher);
}

function Transition(route) {
  if (location.hash == "")
    route = 'play'
  console.log("Route: " + route)

  TransitionTable[route].updater();
  TransitionTable[route].loader();
}

function UpdateState(key, value) {
  if (State[key].value === value) return;
  if (!(State[key].value instanceof Array)) {
    console.log("Not array");
    State[key].value = value;
    for (w in State[key].watchers) {
      State[key].watchers[w](value);
    }
  } else {
      console.log("Array");
      State[key].value.push(value);
      for (w in State[key].watchers) {
        State[key].watchers[w](value);
      }

  }
}

var TransitionTable = {
  play: {
    loader: function () {

      $("#current").html(document.getElementById("play").innerHTML);
    },
    updater: function() {}
  },

  monitor: {
    loader: function () {

     $("#current").html(document.getElementById("monitor").innerHTML);
    },
    updater: function() {}
  }
}

$(window).on("hashchange", function() {
  doNav()
});

function doNav() {
  
  if (location.hash == "") {
    Transition("play");
  } else {
    console.log('hash: ' + location.hash)
    let route = location.hash.slice(1);
    let subroute = route.split('/');
    route = subroute[0];
    path = subroute[1];
    UpdateState('path',path)
    Transition(route)
  }

}

function makeContract(name,abi) {
  var id = State["id"].value;
  var network = ''

  switch (id) {
    case 1:
      network = 'mainnet';
      break;

    case 4:
      network = 'rinkeby';
      break;

  }

  var entry = WC[name];
  var address = entry[network];
  var instance = new web3.eth.Contract(abi,address);
  WC[name].instance = instance;

}

window.addEventListener("load", async () => {
  doNav();
  //feather.replace();

  if (window.ethereum) {
    await ethereum.enable();
    window.web3 = new Web3(ethereum);
  } else if (window.web3) {
    // Then backup the good old injected Web3, sometimes it's usefull:
    window.web3old = window.web3;
    // And replace the old injected version by the latest build of Web3.js version 1.0.0
    window.web3 = new Web3(window.web3.currentProvider);
  }

  startApp();
});

function startApp() {
  var netId = web3.eth.net.getId().then( (id) =>  {
      console.log("Network Id: " + id);
      if (id == 1 ) {
        //$('#network-alert').removeAttr("hidden");
      }
      UpdateState("id", id);
      window.web3.eth.getAccounts((error, accounts) => {
         UpdateState("user", accounts[0]);
         web3.currentProvider.publicConfigStore.on("update", updateMetamask);

         makeContract('dai',window.ercABI);
         makeContract('game',window.gameABI);

     })
   })

}

function updateMetamask(data) {
  console.log("Update User: " + data.selectedAddress);
  console.log("Update Network: "  + data.networkVersion)
  UpdateState("user", data.selectedAddress);

}

function getTime() {
  return parseInt(Date.now() / 1000)
}

function getTimeLeft(timestamp) {
  return (getTime() >= parseInt(timestamp)) ? 'Round Ended' : parseInt(timestamp) - getTime()
}

function updateTimer() {

  var time = getTimeLeft(State.time.value);
  if (time != 'Round Ended')
    time = new Date(time * 1000).toISOString().substr(11, 8)
  $('#time').text(time);

}
