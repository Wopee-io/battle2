from functools import lru_cache

from pydantic import model_validator
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str
    secret_key: str
    cors_origins: str = "http://localhost:3002"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 30

    # GitHub OAuth (placeholder)
    github_client_id: str = ""
    github_client_secret: str = ""

    # Environment and logging
    app_env: str = "production"  # "development" or "production"
    log_level: str = "info"  # Derived from app_env if not explicitly set

    model_config = {"env_file": ".env", "extra": "ignore"}

    @model_validator(mode="after")
    def derive_log_level(self) -> "Settings":
        """Set log_level based on app_env if using default."""
        if self.log_level == "info" and self.app_env == "development":
            object.__setattr__(self, "log_level", "debug")
        return self


@lru_cache
def get_settings() -> Settings:
    return Settings()
