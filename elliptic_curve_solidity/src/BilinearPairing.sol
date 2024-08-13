// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

error ECAdditionFailure();
error ECMultiplicationFailure();
error PairingFailure();

library ECLib {
    uint256 constant BN_128_PRIME_MODULUS = 0x30644E72E131A029B85045B68181585D97816A916871CA8D3C208C16D87CFD47;

    struct G1Point {
        uint256 x;
        uint256 y;
    }

    /**
     * @dev Add two points on the elliptic curve with precompiled contract 0x06
     * @param p1 G1Point p1
     * @param p2 G1Point p2
     * @return G1Point
     */
    function add(G1Point memory p1, G1Point memory p2) public view returns (G1Point memory) {
        // Address 6 is the address of the precompiled contract for elliptic curve addition
        (bool ok, bytes memory result) = address(6).staticcall(abi.encode(p1.x, p1.y, p2.x, p2.y));
        if (!ok) revert ECAdditionFailure();
        (uint256 x, uint256 y) = abi.decode(result, (uint256, uint256));
        return G1Point(x, y);
    }

    /**
     * @dev Multiply a point on the elliptic curve with a scalar with precompiled contract 0x07
     * @param p1 G1Point p1
     * @param s scalar
     * @return G1Point
     */
    function multiply(G1Point memory p1, uint256 s) public view returns (G1Point memory) {
        // Address 7 is the address of the precompiled contract for elliptic curve multiplication
        (bool ok, bytes memory result) = address(7).staticcall(abi.encode(p1.x, p1.y, s));
        if (!ok) revert ECMultiplicationFailure();
        (uint256 x, uint256 y) = abi.decode(result, (uint256, uint256));
        return G1Point(x, y);
    }

    /**
     * @dev The negation of p.
     * p.plus(p.negate()) should be zero.
     * @param p G1Point
     * @return G1Point
     */
    function negate(G1Point memory p) public pure returns (G1Point memory) {
        if (p.x == 0 && p.y == 0) {
            return G1Point(0, 0);
        } else {
            return G1Point(p.x, BN_128_PRIME_MODULUS - (p.y % BN_128_PRIME_MODULUS));
        }
    }
}

contract BilinearPairing {
    using ECLib for *;

    // @notice: Pay attention to the order of x1, x0, y1, y0!!!
    struct G2Point {
        uint256 x1;
        uint256 x0;
        uint256 y1;
        uint256 y0;
    }

    ECLib.G1Point public g1 = ECLib.G1Point(1, 2);

    // # Generator for twisted curve over FQ2
    // G2 = (FQ2([10857046999023057135944570762232829481370756359578518086990519993285655852781, 11559732032986387107991004021392285783925812861821192530917403151452391805634]),
    //       FQ2([8495653923123431417604973247489272438418190587263600148770280649306958101930, 4082367875863433681332203403145435568316851327593401208105741076214120093531]))
    G2Point public g2 = G2Point(
        11559732032986387107991004021392285783925812861821192530917403151452391805634,
        10857046999023057135944570762232829481370756359578518086990519993285655852781,
        4082367875863433681332203403145435568316851327593401208105741076214120093531,
        8495653923123431417604973247489272438418190587263600148770280649306958101930
    );

    ECLib.G1Point public alpha1 = ECLib.G1Point(10744596414106452074759370245733544594153395043370666422502510773307029471145, 848677436511517736191562425154572367705380862894644942948681172815252343932);
    G2Point public beta2 = G2Point(12345624066896925082600651626583520268054356403303305150512393106955803260718, 10191129150170504690859455063377241352678147020731325090942140630855943625622, 13790151551682513054696583104432356791070435696840691503641536676885931241944, 16727484375212017249697795760885267597317766655549468217180521378213906474374);
    G2Point public gamma2 = G2Point(18551411094430470096460536606940536822990217226529861227533666875800903099477, 15512671280233143720612069991584289591749188907863576513414377951116606878472, 1711576522631428957817575436337311654689480489843856945284031697403898093784, 13376798835316611669264291046140500151806347092962367781523498857425536295743);
    G2Point public delta2 = G2Point(1513450333913810775282357068930057790874607011341873340507105465411024430745, 11166086885672626473267565287145132336823242144708474818695443831501089511977, 20245151454212206884108313452940569906396451322269011731680309881579291004202, 10576778712883087908382530888778326306865681986179249638025895353796469496812);

    /**
     * @dev Pairing check for two points
     * It takes two pairs of G1 and G2 and check if 0 = - A1 * B2 + alpha1 * beta2
     * @param xA1 uint256
     * @return bool
     */
    function pairingForTwo(
        uint256 xA1
    ) public view returns (bool) {
        ECLib.G1Point memory a1Neg = g1.multiply(xA1).negate();

        // Address 8 is the address of the precompiled contract for ec pairing
        (bool ok, bytes memory result) = address(8).staticcall(
            abi.encode(a1Neg, g2, alpha1, beta2)
        );
        if (!ok) revert PairingFailure();
        return abi.decode(result, (bool));
    } 

    /**
     * @dev Pairing check for three points
     * It takes three pairs of G1 and G2 and check if 0 = - A1 * B2 + alpha1 * beta2 + (x1 + x2 + x3) * G1 * gamma2 + c1 * delta2
     */
    function pairing(
        ECLib.G1Point memory a1,
        G2Point memory b2,
        ECLib.G1Point memory c1,
        uint256 x1,
        uint256 x2,
        uint256 x3
    ) public view returns (bool) {
        ECLib.G1Point memory a1Neg = a1.negate();
        ECLib.G1Point memory x1G1Point = g1.multiply(x1).add(g1.multiply(x2)).add(g1.multiply(x3));

        // Address 8 is the address of the precompiled contract for ec pairing
        (bool ok, bytes memory result) = address(8).staticcall(
            abi.encode(a1Neg, b2, alpha1, beta2, x1G1Point, gamma2, c1, delta2)
        );
        if (!ok) revert PairingFailure();
        return abi.decode(result, (bool));
    }
}