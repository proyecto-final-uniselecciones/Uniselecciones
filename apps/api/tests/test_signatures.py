"""Pruebas de firma digital y verificación Ed25519."""

import pytest
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey

from uniselecciones_api.core.signatures import sign_message, verify_message


@pytest.fixture
def keypair():
    """Genera un par Ed25519 temporal para las pruebas."""
    private_key = Ed25519PrivateKey.generate()

    private_pem = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.BestAvailableEncryption(
            b"unit-test-only-password"
        ),
    )

    public_pem = private_key.public_key().public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo,
    )

    return private_pem, public_pem


def test_valid_signature_is_verified(keypair):
    """Una firma del mensaje original debe ser válida."""
    private_pem, public_pem = keypair
    message = b"UniSelecciones: documento de prueba 2026"

    signature = sign_message(
        message,
        private_pem,
        b"unit-test-only-password",
    )

    assert verify_message(message, signature, public_pem) is True


def test_modified_message_is_rejected(keypair):
    """Un mensaje modificado debe invalidar la firma."""
    private_pem, public_pem = keypair
    message = b"Documento original"

    signature = sign_message(
        message,
        private_pem,
        b"unit-test-only-password",
    )

    assert verify_message(b"Documento modificado", signature, public_pem) is False


def test_signature_from_another_key_is_rejected(keypair):
    """Una llave pública diferente no debe validar la firma."""
    private_pem, _ = keypair
    another_key = Ed25519PrivateKey.generate()

    another_public_pem = another_key.public_key().public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo,
    )

    message = b"Documento de prueba"

    signature = sign_message(
        message,
        private_pem,
        b"unit-test-only-password",
    )

    assert verify_message(message, signature, another_public_pem) is False
