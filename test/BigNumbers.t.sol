// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/BigNumbers.sol";
import "../src/utils/Crypto.sol";

contract BigNumbersTest is Test {
    using BigNumbers for *;
    using Crypto for *;

    function testRSA() public {
        bytes memory Msg = hex'68656c6c6f20776f726c64'; // "hello world" in hex

        BigNumber memory S = hex"079bed733b48d69bdb03076cb17d9809072a5a765460bc72072d687dba492afe951d75b814f561f253ee5cc0f3d703b6eab5b5df635b03a5437c0a5c179309812f5b5c97650361c645bc99f806054de21eb187bc0a704ed38d3d4c2871a117c19b6da7e9a3d808481c46b22652d15b899ad3792da5419e50ee38759560002388".init(false);

        BigNumber memory e = hex"010001".init(false);

        BigNumber memory nn = hex"df3edde009b96bc5b03b48bd73fe70a3ad20eaf624d0dc1ba121a45cc739893741b7cf82acf1c91573ec8266538997c6699760148de57e54983191eca0176f518e547b85fe0bb7d9e150df19eee734cf5338219c7f8f7b13b39f5384179f62c135e544cb70be7505751f34568e06981095aeec4f3a887639718a3e11d48c240d".init(false);

        assertEq(Crypto.pkcs1Sha256VerifyRaw(Msg, S, e, nn), 0);
    }

    function testInit() public {
        bytes memory val;
        BigNumber memory bn;

        val = hex"ffffffff";
        bn = BigNumbers.init(val, false, 36);
        assertEq(bn.val.length,  0x20);
        assertEq(bn.val,  hex"00000000000000000000000000000000000000000000000000000000ffffffff");
        assertEq(bn.neg,  false);
        assertEq(bn.bitlen,  36);

        val = hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
        bn = BigNumbers.init(val, true);
        assertEq(bn.val.length,  0x20);
        assertEq(bn.val,  hex"00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
        assertEq(bn.neg,  true);
        assertEq(bn.bitlen,  248);

        val = hex"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
        bn = BigNumbers.init(val, false);
        assertEq(bn.val.length,  0x20);
        assertEq(bn.val,  hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
        assertEq(bn.neg,  false);
        assertEq(bn.bitlen,  256);
    }

    function testVerify() public pure {
        BigNumber memory bn = BigNumber({
            val: hex"00000000000000000000000000000000000000000000bccc69e47d98498430b725f7ff5af5be936fb1ccde3fdcda3b0882a9082eab761e75b34da18d8923d70b481d89e2e936eecec248b3d456b580900a18bcd39b3948bc956139367b89dde7",
            neg: false,
            bitlen: 592
        });
        bn.verify();
    }

    function testFailVerifyBitlen() public pure {
        BigNumber memory bn = BigNumber({
            val: hex"00000000000000000000000000000000000000000000bccc69e47d98498430b725f7ff5af5be936fb1ccde3fdcda3b0882a9082eab761e75b34da18d8923d70b481d89e2e936eecec248b3d456b580900a18bcd39b3948bc956139367b89dde7",
            neg: false,
            bitlen: 1
        });
        bn.verify();
    }

    function testFailVerifyLength() public pure {
        BigNumber memory bn = BigNumber({
            val: hex"000000000000000000000000000000000000000000bccc69e47d98498430b725f7ff5af5be936fb1ccde3fdcda3b0882a9082eab761e75b34da18d8923d70b481d89e2e936eecec248b3d456b580900a18bcd39b3948bc956139367b89dde7",
            neg: false,
            bitlen: 592
        });
        bn.verify();
    }

    function testLengths() public {
        BigNumber memory val = hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff".init(false);
        assertEq(BigNumbers.bitLength(val), 256);
        val = hex"0000000000000000000000000000000000000000000000000000000000000000".init(false);
        assertEq(BigNumbers.bitLength(val), 0);
        val = hex"0000000000000000000000000000000000000000000000000000000000000001".init(false);
        assertEq(BigNumbers.bitLength(val), 1);
        val = hex"f000000000000000000000000000000000000000000000000000000000000000".init(false);
        assertEq(BigNumbers.bitLength(val), 256);

        assertEq(BigNumbers.bitLength(0), 0);
        assertEq(BigNumbers.bitLength(1), 1);
        assertEq(BigNumbers.bitLength(1 << 200), 201);
        assertEq(BigNumbers.bitLength((1 << 200)+1), 201);
        assertEq(BigNumbers.bitLength(1 << 255), 256);
    }

    function testShiftRight() public {
        // shift by value greater than word length
        BigNumber memory r;
        BigNumber memory bn = BigNumber({
            val: hex"1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111",
            neg: false,
            bitlen: 1024
        });
        r = bn.shr(500);
        
        assertEq(r.val, hex"000000000000000000000000000000000000000000000000000000000000011111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111");
        assertEq(r.val.length, 0x60);
        assertEq(r.bitlen, 524); 
        assertEq(r.neg, false); 

        // shift by value greater than word length and multiple of 8
        bn = BigNumber({
            val: hex"11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111",
            neg: false,
            bitlen: 512
        });
        r = bn.shr(264); // shift right by 33 bytes

        assertEq(r.val, hex"0011111111111111111111111111111111111111111111111111111111111111");
        assertEq(r.val.length, 0x20);
        assertEq(r.bitlen, 248); 
        assertEq(r.neg, false); 

        // shift by value >= bit length
        bn = BigNumber({
            val: hex"11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111",
            neg: false,
            bitlen: 512
        });
        r = bn.shr(512);

        assertEq(r.val, hex"0000000000000000000000000000000000000000000000000000000000000000");
        assertEq(r.val.length, 0x20);
        assertEq(r.bitlen, 0); 
        assertEq(r.neg, false); 

        // shift by value with a remaining leading zero word
        bn = BigNumber({
            val: hex"00000000000000000000000000000000000000000000000000000000000011111111111111111111111111111111111111111111111111111111111111111111",
            neg: false,
            bitlen: 272
        });
        r = bn.shr(17);

        assertEq(r.val, hex"0888888888888888888888888888888888888888888888888888888888888888");
        assertEq(r.val.length, 0x20);
        assertEq(r.bitlen, 255); 
        assertEq(r.neg, false); 

        r = ((hex'ffff').init(false)).shr(192);
        assertEq(r.val.length, 0x20);
        assertEq(r.bitlen, 0); 
        assertEq(r.neg, false); 
    }

    function testShiftLeft() public {

        // fails: [0x8000000000000000000000000000000000000000000000000000000000000000, 0]
        BigNumber memory r;
        BigNumber memory bn;
        // shift by value within this word length
        bn = BigNumber({
            val: hex"00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111",
            neg: false,
            bitlen: 496
        });
        r = bn.shl(12);

        assertEq(r.val, hex"01111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111000");
        assertEq(r.val.length, 0x40);
        assertEq(r.bitlen, 508);
        assertEq(r.neg, false);

        // shift by value within this word length and multiple of 8
        bn = BigNumber({
            val: hex"00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111",
            neg: false,
            bitlen: 496
        });
        r = bn.shl(8);

        assertEq(r.val, hex"00111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100");
        assertEq(r.val.length, 0x40);
        assertEq(r.bitlen, 504);
        assertEq(r.neg, false); 

        // shift creating extra trailing word
        bn = BigNumber({
            val: hex"00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111",
            neg: false,
            bitlen: 496
        });
        r = bn.shl(268);

        assertEq(r.val, hex"011111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000");
        assertEq(r.val.length, 0x60);
        assertEq(r.bitlen, 764);
        assertEq(r.neg, false);


        // shift creating extra trailing word and multiple of 8
        bn = BigNumber({
            val: hex"00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111",
            neg: false,
            bitlen: 496
        });
        r = bn.shl(264);

        assertEq(r.val, hex"001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000");
        assertEq(r.val.length, 0x60);
        assertEq(r.bitlen, 760);
        assertEq(r.neg, false); 

        // shift creating extra leading word
        bn = BigNumber({
            val: hex"00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111",
            neg: false,
            bitlen: 496
        });
        r = bn.shl(20);

        assertEq(r.val, hex"000000000000000000000000000000000000000000000000000000000000000111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000");
        assertEq(r.val.length, 0x60);
        assertEq(r.bitlen, 516);
        assertEq(r.neg, false); 

        // shift creating extra leading word and multiple of 8
        bn = BigNumber({
            val: hex"00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111",
            neg: false,
            bitlen: 496
        });
        r = bn.shl(24);

        assertEq(r.val, hex"000000000000000000000000000000000000000000000000000000000000001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111000000");
        assertEq(r.val.length, 0x60);
        assertEq(r.bitlen, 520);
        assertEq(r.neg, false); 
    }

    function testDiv() public view {
        bytes memory _a = hex"c44185bd565bf73657762992dd9825b34c44c95f3845fa188bf98d3f36db0b38cdad5a8be77f36baf8467826c4574b2e3cbdc1a4d4b0fc4ff667434a6ac644e7d8349833f80b82e901";
        bytes memory _b = hex"4807722751c4327f377e03";
        bytes memory _res = hex"02b98463de4a24865849566e8398b60d2596843283dbff493f37f0efb8f738cd9f06dedf61a7b6177f41732cfb722c585edab0e6bfcdaf7a0f7df79756732a";
        BigNumber memory a = _a.init(true);
        BigNumber memory b = _b.init(false);
        BigNumber memory res = _res.init(true); 

        a.divVerify(b, res);
    }

    function testModMul() public view {
        bytes memory _a = hex"1f78";
        bytes memory _b = hex"0309";
        bytes memory _m = hex"3178";
        BigNumber memory a = _a.init(false);
        BigNumber memory b = _b.init(false);
        BigNumber memory m = _m.init(false);
    
        BigNumber memory res = a.modmul(b, m);

        console.log('res out:');
        console.logBytes(res.val);
        console.logBool(res.neg);
    }
}
