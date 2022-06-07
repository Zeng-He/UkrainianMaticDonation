const chai = require("./chaisetup.js");
const expect = chai.expect;
const BN = web3.utils.BN;

const MultiSigMaxCap = artifacts.require("MultiSigMaxCap");

// Traditional Truffle test
contract("MultiSigMaxCap", (accounts) => {

    const [ initialHolder, recipient, anotherAccount ] = accounts;
    // const TOTAL_AMOUNT_OF_GUINESS = process.env.INITIAL_TOKENS; will require dotenv dependency
    const numConfirmationsRequired = 3;
    const initialValue = 0;
    const VALUE_NOT_CONFIRMED = new BN(0);
    const VALUE_CONFIRMED = new BN(1);

    var multiSigMaxCap; //The contract
    beforeEach(async () => {
      // we use new instead of deploy/deployed
      multiSigMaxCap = await MultiSigMaxCap.new([initialHolder, recipient, anotherAccount], numConfirmationsRequired, initialValue);
    });

    describe("Deployment", () => {
      it("MultiSigMaxCap must be deployed", async () => {
        return expect(multiSigMaxCap).to.not.be.undefined;
      });
    
      it("maxCap should be set to suplied value on construction", async () => {
          return expect(await multiSigMaxCap.maxCap()).to.be.a.bignumber.equal(new BN(initialValue));
      });
  
      it("numConfirmationsRequired should be set to suplied value on construction", async () => {
          return expect(await multiSigMaxCap.numConfirmationsRequired()).to.be.a.bignumber.equal(new BN(numConfirmationsRequired));
      });
    });

    describe("Signers", () => {
      it("provided addresses at construction should be set as signers", async () => {
        expect(await multiSigMaxCap.isSigner(initialHolder)).to.be.true;
        expect(await multiSigMaxCap.isSigner(recipient)).to.be.true;
        return expect(await multiSigMaxCap.isSigner(anotherAccount)).to.be.true;
      });
   
      it("other but provided addresses at construction should not be set as signers", async () => {
        const wallet = ethers.Wallet.createRandom().connect(ethers.provider);
        return expect(await multiSigMaxCap.isSigner(wallet.address)).to.be.false;
      });
    });

    describe("Status", () => {
      it("should be set as VALUE_NOT_CONFIRMED when maxCap not changed from deployment", async () => {
        return expect(await multiSigMaxCap.getStatus()).to.be.a.bignumber.equal(VALUE_NOT_CONFIRMED);
      });

      it("should be set as VALUE_NOT_CONFIRMED when maxCap not changed from deployment", async () => {
        await multiSigMaxCap.signValue(100 , {from: initialHolder});
        await multiSigMaxCap.signValue(100 , {from: recipient});
        await multiSigMaxCap.signValue(100 , {from: anotherAccount});
        return expect(await multiSigMaxCap.getStatus()).to.be.a.bignumber.equal(VALUE_CONFIRMED);
      });
    });

    describe("Sign", () => {
      it("Signer can sign and signs are updated", async () => {
        await expect(multiSigMaxCap.signValue(100 , {from: initialHolder})).to.eventually.be.fulfilled;
        await expect(multiSigMaxCap.signs(100, initialHolder)).to.eventually.be.true;
        return await expect(multiSigMaxCap.signCount(100)).to.eventually.be.a.bignumber.equal(new BN(1));
      });

      it("sign should not change for signer who not signed", async () => {
        await expect(multiSigMaxCap.signValue(100 , {from: initialHolder})).to.eventually.be.fulfilled;
        await expect(multiSigMaxCap.signs(100, recipient)).to.eventually.be.false;
        await expect(multiSigMaxCap.signCount(100)).to.eventually.be.a.bignumber.equal(new BN(1));
      });

      it("non-signer cannot sign", async () => {
        const wallet = ethers.Wallet.createRandom().connect(ethers.provider);
        await expect(multiSigMaxCap.signValue(100 , {from: wallet.address})).to.eventually.be.rejected;
        await expect(multiSigMaxCap.signs(100, wallet.address)).to.eventually.be.false;
        await expect(multiSigMaxCap.signCount(100)).to.eventually.be.a.bignumber.equal(new BN(0));
      });

      it("multiple signers can sign and increase sign count", async () => {
        await expect(multiSigMaxCap.signValue(100 , {from: initialHolder})).to.eventually.be.fulfilled;
        await expect(multiSigMaxCap.signValue(100 , {from: recipient})).to.eventually.be.fulfilled;
        await expect(multiSigMaxCap.signs(100, initialHolder)).to.eventually.be.true;
        await expect(multiSigMaxCap.signs(100, recipient)).to.eventually.be.true;
        await expect(multiSigMaxCap.signCount(100)).to.eventually.be.a.bignumber.equal(new BN(2));
      });

      it("Signer cannot sign twice the same proposal", async () => {
        await expect(multiSigMaxCap.signValue(100 , {from: initialHolder})).to.eventually.be.fulfilled;
        await expect(multiSigMaxCap.signValue(100 , {from: initialHolder})).to.eventually.be.rejected;
        await expect(multiSigMaxCap.signs(100, initialHolder)).to.eventually.be.true;
        await expect(multiSigMaxCap.signCount(100)).to.eventually.be.a.bignumber.equal(new BN(1));
      });

      it("getting all the signs should change max cap", async () => {
        await expect(multiSigMaxCap.signValue(100 , {from: initialHolder})).to.eventually.be.fulfilled;
        await expect(multiSigMaxCap.signValue(100 , {from: recipient})).to.eventually.be.fulfilled;
        await expect(multiSigMaxCap.signValue(100 , {from: anotherAccount})).to.eventually.be.fulfilled;
        await expect(multiSigMaxCap.signs(100, initialHolder)).to.eventually.be.true;
        await expect(multiSigMaxCap.signs(100, recipient)).to.eventually.be.true;
        await expect(multiSigMaxCap.signs(100, anotherAccount)).to.eventually.be.true;
        await expect(multiSigMaxCap.signCount(100)).to.eventually.be.a.bignumber.equal(new BN(3));
        await expect(multiSigMaxCap.maxCap()).to.eventually.be.a.bignumber.equal(new BN(100));
      });
    });
      
    describe("Revoke", () => {
      it("Signer can revoke sign", async () => {
        await expect(multiSigMaxCap.signValue(100 , {from: initialHolder})).to.eventually.be.fulfilled;
        await expect(multiSigMaxCap.revokeSign(100 , {from: initialHolder})).to.eventually.be.fulfilled;

        await expect(multiSigMaxCap.signs(100, initialHolder)).to.eventually.be.false;
        await expect(multiSigMaxCap.signCount(100)).to.eventually.be.a.bignumber.equal(new BN(0));
      });

      it("non-signer cannot revoke", async () => {
        const wallet = ethers.Wallet.createRandom().connect(ethers.provider);
        await expect(multiSigMaxCap.revokeSign(100 , {from: wallet.address})).to.eventually.be.rejected;
      });

      it("Signer cannot revoke sign twice", async () => {
        await expect(multiSigMaxCap.signValue(100 , {from: initialHolder})).to.eventually.be.fulfilled;
        await expect(multiSigMaxCap.revokeSign(100 , {from: initialHolder})).to.eventually.be.fulfilled;
        await expect(multiSigMaxCap.revokeSign(100 , {from: initialHolder})).to.eventually.be.rejected;

        await expect(multiSigMaxCap.signs(100, initialHolder)).to.eventually.be.false;
        await expect(multiSigMaxCap.signCount(100)).to.eventually.be.a.bignumber.equal(new BN(0));
      });

      it("Signer cannot revoke sign if not signed already", async () => {
        await expect(multiSigMaxCap.revokeSign(100 , {from: initialHolder})).to.eventually.be.rejected;
        await expect(multiSigMaxCap.signs(100, initialHolder)).to.eventually.be.false;
        await expect(multiSigMaxCap.signCount(100)).to.eventually.be.a.bignumber.equal(new BN(0));
      });

      it("Signer cannot revoke other's sign", async () => {
        await expect(multiSigMaxCap.signValue(100 , {from: initialHolder})).to.eventually.be.fulfilled;
        await expect(multiSigMaxCap.revokeSign(100 , {from: recipient})).to.eventually.be.rejected;
        await expect(multiSigMaxCap.signs(100, initialHolder)).to.eventually.be.true;
        await expect(multiSigMaxCap.signCount(100)).to.eventually.be.a.bignumber.equal(new BN(1));
      });

      it("revoking does not affect others sign", async () => {
        await expect(multiSigMaxCap.signValue(100 , {from: initialHolder})).to.eventually.be.fulfilled;
        await expect(multiSigMaxCap.signValue(100 , {from: recipient})).to.eventually.be.fulfilled;
        await expect(multiSigMaxCap.revokeSign(100 , {from: recipient})).to.eventually.be.fulfilled;

        await expect(multiSigMaxCap.signs(100, initialHolder)).to.eventually.be.true;
        await expect(multiSigMaxCap.signs(100, recipient)).to.eventually.be.false;
        await expect(multiSigMaxCap.signCount(100)).to.eventually.be.a.bignumber.equal(new BN(1));
      });

      it("revoking after value is confirmed does not change status nor max Cap", async () => {
        await expect(multiSigMaxCap.signValue(100 , {from: initialHolder})).to.eventually.be.fulfilled;
        await expect(multiSigMaxCap.signValue(100 , {from: recipient})).to.eventually.be.fulfilled;
        await expect(multiSigMaxCap.signValue(100 , {from: anotherAccount})).to.eventually.be.fulfilled;
        await expect(multiSigMaxCap.revokeSign(100 , {from: anotherAccount})).to.eventually.be.fulfilled;
        await expect(multiSigMaxCap.signs(100, initialHolder)).to.eventually.be.true;
        await expect(multiSigMaxCap.signs(100, recipient)).to.eventually.be.true;
        await expect(multiSigMaxCap.signs(100, anotherAccount)).to.eventually.be.false;
        await expect(multiSigMaxCap.signCount(100)).to.eventually.be.a.bignumber.equal(new BN(2));
        await expect(multiSigMaxCap.maxCap()).to.eventually.be.a.bignumber.equal(new BN(100));
        await expect(multiSigMaxCap.getStatus()).to.eventually.be.a.bignumber.equal(VALUE_CONFIRMED);
      });

    });
      
    describe("Recahed Max Cap", () => {
      it("should reject before value is confirmed", async () => {
        await expect(multiSigMaxCap.getStatus()).to.eventually.be.a.bignumber.equal(VALUE_NOT_CONFIRMED);
        await expect(multiSigMaxCap.isMaxCapReached(100 , {from: initialHolder})).to.eventually.be.rejected;
      });

      it("when max cap is not reached should return false", async () => {
        await multiSigMaxCap.signValue(100 , {from: initialHolder});
        await multiSigMaxCap.signValue(100 , {from: recipient});
        await multiSigMaxCap.signValue(100 , {from: anotherAccount});
        // The following line throws underflow..
        // await expect(multiSigMaxCap.isMaxCapReached(99.99 , {from: initialHolder})).to.eventually.be.false;
        await expect(multiSigMaxCap.isMaxCapReached(99 , {from: initialHolder})).to.eventually.be.false;
      });

      it("when max cap is reached or surpassed should return true", async () => {
        await multiSigMaxCap.signValue(100 , {from: initialHolder});
        await multiSigMaxCap.signValue(100 , {from: recipient});
        await multiSigMaxCap.signValue(100 , {from: anotherAccount});
        // The following line throws underflow..
        // await expect(multiSigMaxCap.isMaxCapReached(99.99 , {from: initialHolder})).to.eventually.be.false;
        await expect(multiSigMaxCap.isMaxCapReached(100 , {from: initialHolder})).to.eventually.be.true;
        await expect(multiSigMaxCap.isMaxCapReached(101 , {from: initialHolder})).to.eventually.be.true;
      });
    });
  });