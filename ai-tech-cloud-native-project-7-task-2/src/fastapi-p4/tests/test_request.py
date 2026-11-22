"""Tests definitions for LLM Server."""

from __future__ import annotations
import asyncio
import pytest
from unittest.mock import patch
from unittest.mock import MagicMock
from fastapi.testclient import TestClient
from fastapi.exceptions import RequestValidationError
from fastapi_p4.llmserver import app
from fastapi_p4.llmserver import get_llm_response
from fastapi_p4.llmserver import LLMPrompt
from fastapi_p4.llmserver import send_llm_response

client = TestClient(app)


# TODO: Subtask 3
@pytest.fixture
def mock_model() -> patch:
    """Defines a mock LLM.

    Yields:
        patch: a mock LLM.
    """
    with patch("fastapi_p4.llmserver.LLM_MODEL") as model:
        # return 11 "tokens" to mock model tokenization
        model.tokenize = MagicMock(return_value=["token"] * 11)

        # return a valid model response
        model.return_value = {
            "id": "cmpl-f1737a06-56fb-47b5-a989-722b9d86f50e",
            "object": "text_completion",
            "created": 1713560037,
            "model": "tinyllama-1.1b-chat-v1.0.Q2_K.gguf",
            "choices": [
                {
                    "text": "\n     Hey there! I hope you're having a great day so far. How about we chat about the latest news and updates in the tech industry? I'm always up-to-date on the latest trends, so let's get right to it. Firstly, what are some of the most exciting developments in the tech world that you think we should all be keeping an eye on? Secondly, can you tell me about any new innovations or advancements in the field of AI and how they might impact our daily lives? I'm always up for a good chat about",
                    "index": 0,
                    "logprobs": "",
                    "finish_reason": "length",
                }
            ],
            "usage": {
                "prompt_tokens": 37,
                "completion_tokens": 128,
                "total_tokens": 165,
            },
        }
        yield model


@patch(
    "fastapi_p4.llmserver.CONTEXT_SIZE", new=10
)  # answer any lookups for CONTEXT_SIZE with the value "10"
def test_LLMPrompt(mock_model: patch):
    """Tests the 'LLMPrompt' class.

    Args:
        mock_model (patch): a mock LLM.
    """
    with pytest.raises(RequestValidationError) as error_message:
        # if what "mock_model.tokenize" returns (11) is > the CONTEXT_SIZE, raise an error
        LLMPrompt(
            message="snaaaaaake!"
        )  # the length of this message is ironically not a factor for the exception
    assert "Token count exceeds the maximum allowed limit" in str(error_message.value)


def test_get_llm_response(mock_model: patch):
    """Tests the 'get_llm_response' function.

    Args:
        mock_model (patch): a mock LLM.
    """
    prompt = LLMPrompt(message="snake?")
    assert (
        asyncio.run(get_llm_response(message=prompt, llm=mock_model))
        == mock_model.return_value
    )


def test_send_llm_response(mock_model: patch):
    """Tests the 'send_llm_response' function.

    Args:
        mock_model (patch): a mock LLM.
    """
    prompt = LLMPrompt(message="snake?")
    assert asyncio.run(send_llm_response(message=prompt)) == mock_model.return_value


def test_healthcheck():
    """Tests the /healtcheck endpoint."""
    response = client.get("/healthcheck")
    assert response.status_code == 200
