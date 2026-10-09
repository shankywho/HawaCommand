"""HawaCommand CLI tool."""
import argparse
import sys
from . import __version__
from .core.config import get_settings


def main() -> None:
    parser = argparse.ArgumentParser(prog="hawa", description="HawaCommand Backend Management CLI")
    subparsers = parser.add_subparsers(dest="command", help="Available subcommands")

    # version
    subparsers.add_parser("version", help="Print HawaCommand backend version")

    # config
    subparsers.add_parser("config", help="Print current active configuration")

    # check
    subparsers.add_parser("check", help="Verify configuration sanity")

    args = parser.parse_args()

    if args.command == "version":
        print(f"HawaCommand Backend v{__version__}")
    elif args.command == "config":
        settings = get_settings()
        print(f"Environment: {settings.env}")
        print(f"Debug:       {settings.debug}")
        print(f"Database:    {settings.database_url}")
        print(f"Redis:       {settings.redis_url}")
        print(f"Kafka:       {settings.kafka_bootstrap_servers}")
    elif args.command == "check":
        settings = get_settings()
        print("[OK] Configuration validated successfully.")
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
