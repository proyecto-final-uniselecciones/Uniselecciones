"""Firma y verificación de integridad mediante Ed25519."""

from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import (
    Ed25519PrivateKey,
    Ed25519PublicKey,
)


def sign_message(
    message: bytes,
    private_key_pem: bytes,
    password: bytes,
) -> bytes:
    """Firma un mensaje utilizando una llave privada Ed25519 protegida."""
    if not isinstance(message, bytes):
        raise TypeError("El mensaje debe proporcionarse como bytes.")

    private_key = serialization.load_pem_private_key(
        private_key_pem,
        password=password,
    )

    if not isinstance(private_key, Ed25519PrivateKey):
        raise TypeError("La llave privada debe ser Ed25519.")

    return private_key.sign(message)


def verify_message(
    message: bytes,
    signature: bytes,
    public_key_pem: bytes,
) -> bool:
    """Verifica una firma Ed25519 y devuelve False si no es válida."""
    if not isinstance(message, bytes):
        raise TypeError("El mensaje debe proporcionarse como bytes.")

    public_key = serialization.load_pem_public_key(public_key_pem)

    if not isinstance(public_key, Ed25519PublicKey):
        raise TypeError("La llave pública debe ser Ed25519.")

    try:
        public_key.verify(signature, message)
        return True
    except InvalidSignature:
        return False
