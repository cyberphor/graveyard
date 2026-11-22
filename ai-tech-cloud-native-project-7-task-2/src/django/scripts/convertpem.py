"""Simple Django PEM Conversion Script."""

from jwcrypto import jwk


def pem_to_jwk(pem_key: str):
    """Convert PEM to JWK file.

    Args:
        pem_key (str): Path to PEM file.

    Returns:
        JSON: Initial JSON
    """
    # Convert to JWK format
    jwk_key = jwk.JWK.from_pem(pem_key.encode("utf-8"))

    # Need to add alg to JWK otherwise KrakenD fails
    jwk_key["alg"] = "RS256"
    jwk_key["kid"] = "yourcoolkid"

    # Return the JWK as a JSON string
    return jwk_key.export()
