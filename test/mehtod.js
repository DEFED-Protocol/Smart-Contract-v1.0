const Ext = require('./ext-dependency');

let i = 1;
let usdc = 1e6;
let asset = "0x0000000000000000000000000000000000000000";
let accountId = 111111;

describe("TokenController", function () {
  beforeEach("before", async function () {
    await Ext.deployDep();
    console.log(" ");
    console.log("---------------------------------------");
    console.log("> " + "case  " + i);
    i++;
  })


  it("test", async function () {
    console.log("lendingPool -------  "+lendingPool.address)
  }) 
})