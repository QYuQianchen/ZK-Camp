// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import { EllipticCurveCalculation } from "../src/ECCalculation.sol";

contract EllipticCurveCalculationTest is Test {
    EllipticCurveCalculation public ecCalculation;

    function setUp() public {
        ecCalculation = new EllipticCurveCalculation();
    }

    function test_ec_addition_1_2() public {
        EllipticCurveCalculation.ECPoint memory p1 = EllipticCurveCalculation.ECPoint(1, 2);
        EllipticCurveCalculation.ECPoint memory p2 = ecCalculation.add(p1, p1);
        assertEq(p2.x, 1368015179489954701390400359078579693043519447331113978918064868415326638035);
        assertEq(p2.y, 9918110051302171585080402603319702774565515993150576347155970296011118125764);
    }

    function test_ec_addition_with_multiplication() public {
        // ensure that there's y on the curve
        EllipticCurveCalculation.ECPoint memory p1 = EllipticCurveCalculation.ECPoint(1, 2);
        EllipticCurveCalculation.ECPoint memory p2 = ecCalculation.add(p1, p1);
        EllipticCurveCalculation.ECPoint memory p3 = ecCalculation.multiply(p1, 2);
        assertEq(p2.x, p3.x);
        assertEq(p2.y, p3.y);
    }

    function test_zk_num_div_den() public {
        // prover wants to prove that 1/3 + 8/21 = 5/7
        // they turn the private values (1/3 and 8/21) into points on the curve with public ECPoint(1,2)
        EllipticCurveCalculation.ECPoint memory p1 = ecCalculation.rationalNumberOnCurve(1, 3);
        EllipticCurveCalculation.ECPoint memory p2 = ecCalculation.rationalNumberOnCurve(8, 21);

        // verifier takes p1 and p2 and checks if they add up to 5/7
        uint256 num = 5;
        uint256 den = 7;
        bool result = ecCalculation.rationalAdd(p1, p2, num, den);
        assert(result);
    }

    function test_matmul() public {
        // [1 2 3][1] = [14]
        // [4 5 6][2] = [32]
        // [7 8 9][3] = [50]

        uint256[] memory matrix = new uint256[](9);
        for (uint256 i = 0; i < 9; i++) {
            matrix[i] = i + 1;
        }
        EllipticCurveCalculation.ECPoint[] memory s = new EllipticCurveCalculation.ECPoint[](3);
        s[0] = EllipticCurveCalculation.ECPoint(1, 2);
        s[1] = ecCalculation.multiply(s[0], 2);
        s[2] = ecCalculation.multiply(s[0], 3);
        uint256[] memory o = new uint256[](3);
        o[0] = 14;
        o[1] = 32;
        o[2] = 50;
        bool result = ecCalculation.matmul(matrix, 3, s, o);
        assert(result);
    }

    function test_generate_constants() public {
        EllipticCurveCalculation.ECPoint memory alpha = ecCalculation.multiply(ecCalculation.publicECPoint(), 5);
        emit log_named_uint("alpha.x", alpha.x);
        emit log_named_uint("alpha.y", alpha.y);
    }
}
