from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    db_host: str = "localhost"
    db_port: int = 3306
    db_user: str = "root"
    db_password: str = ""
    db_name: str = "medisync"

    jwt_secret: str = "change-me"
    jwt_algorithm: str = "HS256"
    jwt_expire_hours: int = 24

    intake_auto_omit_minutes: int = 30
    intake_postpone_minutes: int = 10
    scheduler_interval_minutes: int = 5

    vital_sign_min_quality: int = 50

    cors_origins: str = "*"


settings = Settings()
