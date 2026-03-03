#!/usr/bin/env python3

import re

from argparse import ArgumentParser
from os import path
from sys import exit


def parse_args():
    parser = ArgumentParser(description="Print information about target architectures and profiles")

    parser.add_argument(
        "-a",
        "--all",
        action="count",
        default=0,
        help="Print not the first one but all profiles. Specifying more than once prints model-specific targets as well (e.g. TRB1401). Does not have any effect when --target is used",
    )
    parser.add_argument(
        "-f",
        "--format",
        choices=["ci", "table"],
        default="table",
        help="Print in YAML format for pipelines (ci) or a plaintext table (default)",
    )
    parser.add_argument(
        "-t",
        "--target",
        help="Print information only for specified target",
    )
    parser.add_argument(
        "-x",
        "--exclude",
        action="append",
        help="Exclude target from list",
    )

    parser.add_argument(
        "targetinfo_file",
        nargs="?",
        default=path.dirname(path.realpath(__file__)) + "/../tmp/.targetinfo",
        help="File to parse the target information from",
    )

    return parser.parse_args()


args = parse_args()

try:
    with open(args.targetinfo_file, "r") as file:
        content = file.read()
except FileNotFoundError as e:
    print(
        f"Target info file is required and default {args.targetinfo_file} was not found. Please specify; or run 'make defconfig' to generate a default one."
    )
    exit(e.errno)
except Exception as e:
    print(f"Error reading the file: {e}")
    exit(getattr(e, "errno", 1))


class Value:
    def __init__(self, pattern, default=None):
        self.pattern = pattern
        self.value = default


default_libc = "musl"
profiles = []
unique_combinations = {}

arch = Value(re.compile(r"Target-Arch: (\S+)"))
cpu = Value(re.compile(r"CPU-Type: (\S+)"))
libc_pattern = re.compile(r"Target-Profile-Libc: (\S+)")
profile_pattern = re.compile(r"Target-Profile:\s+DEVICE_teltonika_(\S+)")

lines = content.splitlines()
for i, line in enumerate(lines):
    for v in [arch, cpu]:
        match = v.pattern.search(line)
        if match:
            v.value = match.group(1)
            break

    profile_match = profile_pattern.search(line)
    if profile_match and arch.value and cpu.value:
        profile_name = profile_match.group(1)

        profile_libc = default_libc
        for l in lines[i + 1 :]:
            if l.startswith("Target-Profile:"):
                break
            match = libc_pattern.search(l)
            if match:
                profile_libc = match.group(1)
                break

        profiles.append({"name": profile_name, "arch": arch.value, "cpu": cpu.value, "libc": profile_libc})

for profile in profiles:
    target_name = re.sub(r"x{2,}$", "", profile["name"], flags=re.MULTILINE)

    if (args.exclude and profile["arch"] in args.exclude) or (args.all < 2 and len(profile["name"]) > 6):
        continue

    key = (profile["arch"], profile["cpu"])
    if key not in unique_combinations:
        unique_combinations[key] = {}
    if profile["libc"] not in unique_combinations[key]:
        unique_combinations[key][profile["libc"]] = []

    unique_combinations[key][profile["libc"]].append(target_name)

if args.format == "ci":
    indent = "\n" + " " * 6
    env_var_prefix = "DOCKER_BUILD_ARG_"

    def print_line(arch: str, cpu: str, libc: tuple, profile: str) -> None:  # pyright: ignore[reportRedeclaration]
        print(
            f"{indent}- {env_var_prefix}ARCH: {arch}{indent}  {env_var_prefix}CPU_TYPE: {cpu}{indent}  {env_var_prefix}LIBC: {libc}{indent}  {env_var_prefix}SELECT_TARGET: [ {profile} ]"
        )

elif args.format == "table":

    def print_line(arch: str, cpu: str, libc: str, profile: str) -> None:
        print(f"{arch: <15}{cpu: <30}{libc: <10}{profile}")

    if not args.target:
        print_line("Arch", "CPU type", "Libc", "Targets" if args.all else "First target")

for (arch, cpu), targets in unique_combinations.items():
    for libc, target_list in targets.items():
        target_list = list(dict.fromkeys(target_list))

        if args.target:
            if args.target not in target_list:
                continue
            target_list = [args.target]

        print_line(
            arch,
            cpu,
            libc,
            ", ".join(target_list) if args.all else target_list[0],
        )
