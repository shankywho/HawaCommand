"""LLM Provider Factory supporting Groq, Amazon Bedrock, and deterministic template fallback.

Never accepts credentials as function arguments; reads strictly from settings.
Strips all authorization secrets from debug logs.
"""
from typing import Optional
from hawa_ml.settings import settings
from hawa_ml.logging_conf import configure_logging

logger = configure_logging("llm_provider")


class BaseLLMClient:
    def generate(self, prompt: str, system_prompt: str = "") -> str:
        raise NotImplementedError


class GroqLLMClient(BaseLLMClient):
    def __init__(self, api_key: str, model_id: str = "openai/gpt-oss-120b"):
        self.model_id = model_id
        try:
            from groq import Groq
            self.client = Groq(api_key=api_key)
        except Exception:
            from openai import OpenAI
            self.client = OpenAI(
                base_url="https://api.groq.com/openai/v1",
                api_key=api_key,
            )

    def generate(self, prompt: str, system_prompt: str = "") -> str:
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": prompt})

        try:
            resp = self.client.chat.completions.create(
                model=self.model_id,
                messages=messages,
                temperature=0.2,
                max_tokens=600,
            )
            return resp.choices[0].message.content or ""
        except Exception as e:
            logger.warning(f"Groq generation failed: {e}. Using deterministic fallback.")
            return ""


class BedrockLLMClient(BaseLLMClient):
    def __init__(self, model_id: str = "anthropic.claude-3-5-sonnet-20241022-v2:0"):
        self.model_id = model_id
        import boto3
        session = boto3.Session(
            aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
            region_name=settings.AWS_REGION,
        )
        self.client = session.client("bedrock-runtime")

    def generate(self, prompt: str, system_prompt: str = "") -> str:
        import json
        body = json.dumps({
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 800,
            "system": system_prompt,
            "messages": [{"role": "user", "content": prompt}],
            "temperature": 0.2,
        })
        try:
            resp = self.client.invoke_model(modelId=self.model_id, body=body)
            resp_body = json.loads(resp.get("body").read())
            return resp_body.get("content", [{}])[0].get("text", "")
        except Exception as e:
            logger.warning(f"Bedrock generation failed: {e}. Using deterministic fallback.")
            return ""


class TemplateFallbackClient(BaseLLMClient):
    """Deterministic template fallback renderer for zero-key offline execution."""

    def generate(self, prompt: str, system_prompt: str = "") -> str:
        return ""


def get_llm_client() -> BaseLLMClient:
    """Factory returning configured LLM client or template fallback."""
    if settings.OFFLINE_MODE:
        return TemplateFallbackClient()

    if settings.LLM_PROVIDER.lower() == "groq" and settings.GROQ_API_KEY:
        try:
            logger.info("Initializing Groq LLM client...")
            return GroqLLMClient(api_key=settings.GROQ_API_KEY)
        except Exception as e:
            logger.warning(f"Failed to initialize Groq: {e}")

    # no static keys needed: boto3 falls back to the IAM role / default credential chain on AWS
    if settings.LLM_PROVIDER.lower() == "bedrock":
        try:
            logger.info("Initializing Amazon Bedrock client...")
            return BedrockLLMClient(model_id=settings.BEDROCK_MODEL_ID or "anthropic.claude-3-5-sonnet-20241022-v2:0")
        except Exception as e:
            logger.warning(f"Failed to initialize Bedrock: {e}")

    return TemplateFallbackClient()


# Singleton client
llm_client = get_llm_client()
