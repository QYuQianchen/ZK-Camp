// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import { BilinearPairing, ECLib, PairingFailure } from "../src/BilinearPairing.sol";

contract BilinearPairingTest is Test {
    using ECLib for *;

    BilinearPairing public bp;

    function setUp() public {
        bp = new BilinearPairing();
    }

    function test_pairing() public {
        // Prover gives
        // A1 = multiply(G1, 53)
        // B2 = multiply(G2, 3)
        // C1 = multiply(G1, 3)
        // x1 = 4
        // x2 = 5
        // x3 = 6

        // A1 is (19228364643017302119251615170851391070072208144197170544602581999723466520744, 2361433017139987680898212037938357914740274453545239885456064358182999787307)
        // B2 is ((2725019753478801796453339367788033689375851816420509565303521482350756874229, 7273165102799931111715871471550377909735733521218303035754523677688038059653), (2512659008974376214222774206987427162027254181373325676825515531566330959255, 957874124722006818841961785324909313781880061366718538693995380805373202866))
        // C1 is (3353031288059533942658390886683067124040920775575537747144343083137631628272, 19321533766552368860946552437480515441416830039777911637913418824951667761761)
        ECLib.G1Point memory a1G1Point = ECLib.G1Point(19228364643017302119251615170851391070072208144197170544602581999723466520744, 2361433017139987680898212037938357914740274453545239885456064358182999787307);
        BilinearPairing.G2Point memory b2G2Point = BilinearPairing.G2Point(7273165102799931111715871471550377909735733521218303035754523677688038059653, 2725019753478801796453339367788033689375851816420509565303521482350756874229, 957874124722006818841961785324909313781880061366718538693995380805373202866, 2512659008974376214222774206987427162027254181373325676825515531566330959255);
        ECLib.G1Point memory c1G1Point = ECLib.G1Point(3353031288059533942658390886683067124040920775575537747144343083137631628272, 19321533766552368860946552437480515441416830039777911637913418824951667761761);
        uint256 x1 = 4;
        uint256 x2 = 5;
        uint256 x3 = 6;

        // Verifier checks
        bool result = bp.pairing(a1G1Point, b2G2Point, c1G1Point, x1, x2, x3);
        assert(result);
    }

    function test_pairing_for_two() public {
        uint256 xA1 = 30;
        bool result = bp.pairingForTwo(xA1);
        assert(result);

    }

    function test_pairing_example() public {
        // replicate the example in the contract https://www.evm.codes/precompiled for 0x08
        ECLib.G1Point memory a1G1Point = ECLib.G1Point(
            //(G1)x
            uint256(0x2cf44499d5d27bb186308b7af7af02ac5bc9eeb6a3d147c186b21fb1b76e18da),
            //(G1)y
            uint256(0x2c0f001f52110ccfe69108924926e45f0b0c868df0e7bde1fe16d3242dc715f6)
        );

        BilinearPairing.G2Point memory b2G2Point = BilinearPairing.G2Point(
            //(G2)x_1
            uint256(0x1fb19bb476f6b9e44e2a32234da8212f61cd63919354bc06aef31e3cfaff3ebc),
            //(G2)x_0
            uint256(0x22606845ff186793914e03e21df544c34ffe2f2f3504de8a79d9159eca2d98d9),
            //(G2)y_1
            uint256(0x2bd368e28381e8eccb5fa81fc26cf3f048eea9abfdd85d7ed3ab3698d63e4f90),
            //(G2)y_0
            uint256(0x2fe02e47887507adf0ff1743cbac6ba291e66f59be6bd763950bb16041a0a85e)
        );

        // -G1
        ECLib.G1Point memory c1G1Point = ECLib.G1Point(
            //(G1)x
            uint256(0x0000000000000000000000000000000000000000000000000000000000000001),
            //(G1)y
            uint256(0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd45)
        );

        BilinearPairing.G2Point memory d2G2Point = BilinearPairing.G2Point(
            //(G2)x_1
            uint256(0x1971ff0471b09fa93caaf13cbf443c1aede09cc4328f5a62aad45f40ec133eb4),
            //(G2)x_0
            uint256(0x091058a3141822985733cbdddfed0fd8d6c104e9e9eff40bf5abfef9ab163bc7),
            //(G2)y_1
            uint256(0x2a23af9a5ce2ba2796c1f4e453a370eb0af8c212d9dc9acd8fc02c2e907baea2),
            //(G2)y_0
            uint256(0x23a8eb0b0996252cb548a4487da97b02422ebc0e834613f954de6c7e0afdc1fc)
        );

        // Test A1, B2, C1, D2
        (bool ok, bytes memory result) = address(8).staticcall(
            abi.encode(
                a1G1Point, b2G2Point, c1G1Point, d2G2Point
            )
        );
        if (!ok) revert PairingFailure();
        assert(abi.decode(result, (bool)));

        // Test A1, B2, C1, D2, A1, B2, C1, D2
        (bool ok_2, bytes memory result_2) = address(8).staticcall(
            abi.encode(
                a1G1Point, b2G2Point, c1G1Point, d2G2Point, a1G1Point, b2G2Point, c1G1Point, d2G2Point
            )
        );
        if (!ok_2) revert PairingFailure();
        assert(abi.decode(result_2, (bool)));
    }
}
