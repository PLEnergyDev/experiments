import argparse
from logging import error, info
import logging
import os

from utils import Compiler

logging.basicConfig(level=logging.DEBUG, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)

logging.getLogger("matplotlib").setLevel(logging.WARNING)
logging.getLogger("seaborn").setLevel(logging.WARNING)
logging.getLogger().setLevel(logging.WARNING)


def comma_separated_list(value):
    return value.split(",")


def comma_separated_configs(value):
    allowed_values = {"no-warmup", "warmup"}
    configs = comma_separated_list(value)
    invalid_values = set(configs) - allowed_values
    if invalid_values:
        raise argparse.ArgumentTypeError(
            f"Invalid config values: {','.join(invalid_values)}. "
            f"Allowed values: {','.join(allowed_values)}."
        )
    return configs


def parse_args():
    parser = argparse.ArgumentParser(
        description="Script for processing benchmark results."
    )

    parser.add_argument("base_dir", help="The base path for all benchmark results.")
    parser.add_argument(
        "-c",
        "--configs",
        type=comma_separated_configs,
        help="Comma-separated list of configs. Allowed values: 'no-warmup', 'warmup' (or both).",
    )
    parser.add_argument(
        "-l",
        "--languages",
        type=comma_separated_list,
        help="Comma-separated list of languages. If omitted, all languages found in the base directory are used.",
    )
    parser.add_argument(
        "-b",
        "--benchmarks",
        type=comma_separated_list,
        help="Comma-separated list of benchmarks. If omitted, all benchmarks found in the language directories are used.",
    )
    parser.add_argument(
        "-a",
        "--average",
        action="store_true",
        help="Specifies whether it should average out the results after compiling.",
    )
    parser.add_argument(
        "-n",
        "--normalize",
        action="store_true",
        help="Specifies whether it should normalize the results after compiling.",
    )
    parser.add_argument(
        "-v",
        "--violin",
        action="store_true",
        help="Specifies whether it should build violin plots after compiling.",
    )
    parser.add_argument(
        "-i",
        "--interactive",
        action="store_true",
        help="Specifies whether it should build interactive cache plots after compiling.",
    )

    return parser.parse_args()


def get_files(args):
    configs = args.configs if args.configs else {"no-warmup", "warmup"}
    languages = set()
    benchmarks = set()

    if not args.languages:
        for config in configs:
            config_path = os.path.join(args.base_dir, config)
            if os.path.exists(config_path):
                languages.update(os.listdir(config_path))
    else:
        languages = set(args.languages)

    if "average" in languages:
        languages.remove("average")
    if "normalized.csv" in languages:
        languages.remove("normalized.csv")

    if not args.benchmarks:
        for config in configs:
            for language in languages:
                language_path = os.path.join(args.base_dir, config, language)
                if os.path.exists(language_path):
                    benchmarks.update(os.listdir(language_path))
    else:
        benchmarks = set(args.benchmarks)

    if "rapl.csv" in benchmarks:
        benchmarks.remove("rapl.csv")
    if "plots" in benchmarks:
        benchmarks.remove("plots")

    return configs, languages, benchmarks


def handle_commands(args):
    if not os.path.exists(args.base_dir):
        error(f"The specified base directory does not exist: {args.base_dir}")
        exit(1)

    configs, languages, benchmarks = get_files(args)
    compiler = Compiler(args.base_dir, configs, languages, benchmarks)

    info("Compiling benchmark results.")
    compiler.compile()

    if args.average:
        info("Averaging benchmark results.")
        compiler.average()

    if args.normalize:
        info("Normalizing benchmark results.")
        compiler.normalize()

    if args.violin:
        info("Building violin plots.")
        compiler.violins()

    if args.interactive:
        info("Building interactive cache plots.")
        compiler.interactive()

    info("Done!")


def main():
    args = parse_args()
    handle_commands(args)


if __name__ == "__main__":
    main()
