// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

error ECAdditionFailure();
error ECMultiplicationFailure();
error ModExpFailure();
error MatrixDimensionMismatched();

contract EllipticCurveCalculation {
    uint256 constant PRIME_MODULUS = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f;
    uint256 constant CURVE_ORDER = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141;
    struct ECPoint {
        uint256 x;
        uint256 y;
    }

    /**
     * @dev Returns the public point of the secp1256 curve
     * @return ECPoint
     */
    function publicECPoint() pure public returns (ECPoint memory) {
        return ECPoint(1, 2);
    }

    /**
     * @dev Add two points on the elliptic curve with precompiled contract 0x06
     * @param p1 ECPoint p1
     * @param p2 ECPoint p2
     * @return ECPoint
     */
    function add(ECPoint memory p1, ECPoint memory p2) public view returns (ECPoint memory) {
        // Address 6 is the address of the precompiled contract for elliptic curve addition
        (bool ok, bytes memory result) = address(6).staticcall(abi.encode(p1.x, p1.y, p2.x, p2.y));
        if (!ok) revert ECAdditionFailure();
        (uint256 x, uint256 y) = abi.decode(result, (uint256, uint256));
        return ECPoint(x, y);
    }

    /**
     * @dev Multiply a point on the elliptic curve with a scalar with precompiled contract 0x07
     * @param p1 ECPoint p1
     * @param s scalar
     * @return ECPoint
     */
    function multiply(ECPoint memory p1, uint256 s) public view returns (ECPoint memory) {
        // Address 7 is the address of the precompiled contract for elliptic curve multiplication
        (bool ok, bytes memory result) = address(7).staticcall(abi.encode(p1.x, p1.y, s));
        if (!ok) revert ECMultiplicationFailure();
        (uint256 x, uint256 y) = abi.decode(result, (uint256, uint256));
        return ECPoint(x, y);
    }

    /**
     * @dev Modular exponentiation with precompiled contract 0x05
     * @param base base
     * @param exponent exponent
     * @param modulus modulus
     * @return uint256
     */
    function modExp(uint256 base, uint256 exponent, uint256 modulus) public view returns (uint256) {
        // Address 5 is the address of the precompiled contract for modular exponentiation
        (bool ok, bytes memory result) = address(5).staticcall(abi.encode(32, 32, 32, base, exponent, modulus));
        if (!ok) revert ModExpFailure();
        return abi.decode(result, (uint256));
    }

    /**
     * @dev Calculate the rational number num/den on the elliptic curve
     * @param numerator numerator
     * @param denominator denominator
     * @return ECPoint
     */
    function rationalNumberOnCurve(uint256 numerator, uint256 denominator) public view returns (ECPoint memory) {
        uint256 demoninatorOnPrimeField = modExp(denominator, CURVE_ORDER - 2, CURVE_ORDER);
        return multiply(multiply(publicECPoint(), numerator), demoninatorOnPrimeField);
    }

    /**
     * @dev Verify the claim that "I know two rational numbers that add up to num/den"
     * @notice This function multiplies the rational number num/den with the generator point
     * knowing that `pow(a, -1, curve_order) == pow(a, curve_order - 2, curve_order)`
     * @param p1 ECPoint p1
     * @param p2 ECPoint p2
     * @param num numerator
     * @param den denominator
     * @return verified true if the claim is verified
     */
    function rationalAdd(ECPoint calldata p1, ECPoint calldata p2, uint256 num, uint256 den) public view returns (bool verified) {
        // calculate num/den
        ECPoint memory p3 = rationalNumberOnCurve(num, den);
        // calculate p1 + p2
        ECPoint memory p4 = add(p1, p2);
        // check if p3 == p4
        return p3.x == p4.x && p3.y == p4.y;
    }

    function matmul(
        uint256[] calldata matrix,
        uint256 n, // n x n for the matrix
        ECPoint[] calldata s, // n elements
        uint256[] calldata o // n elements
    ) public view returns (bool verified) {
        // revert if dimensions don't make sense or the matrices are empty
        if (matrix.length != n * n || s.length != n || o.length != n) revert MatrixDimensionMismatched();

        // return true if Ms == o elementwise. You need to do n equality checks. 
        // If you're lazy, you can hardcode n to 3, but it is suggested that you do this with a for loop 
        for (uint256 i = 0; i < n; i++) {
            ECPoint memory sum;
            ECPoint memory target = multiply(publicECPoint(), o[i]);
            for (uint256 j = 0; j < n; j++) {
                ECPoint memory increment = multiply(s[j], matrix[i * n + j]);
                sum = add(sum, increment);
            }
            if (sum.x != target.x || sum.y != target.y) return false;
        }
        return true;
    }
}