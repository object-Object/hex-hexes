import argparse
import sys

instructions: dict[str, int] = {
    "or": 64,
    "nand": 65,
    "nor": 66,
    "and": 67,
    "add": 68,
    "sub": 69,

    "cp": 128,

    "s0": 0,
    "s1": 8,
    "s2": 16,
    "s3": 24,
    "s4": 32,
    "s5": 40,
    "in": 48,
    "cdr": 56,

    "d0": 0,
    "d1": 1,
    "d2": 2,
    "d3": 3,
    "d4": 4,
    "d5": 5,
    "out": 6,

    "never": 192,
    "eq": 193,
    "less": 194,
    "less_eq": 195,
    "always": 196,
    "not_eq": 197,
    "greater_eq": 198,
    "greater": 199,
}

def convert_instruction(inst: str) -> int:
    if inst.isdigit():
        assert 0 <= (num := int(inst)) < 64, f"Expected 0 <= n < 64, got {num}"
        return num
    elif inst.startswith("cp|"):
        _, src, dest = inst.split("|")
        return instructions["cp"] | instructions[src] | instructions[dest]
    else:
        return instructions[inst]


def prepare_instuction(line: str) -> str:
    return "".join(line.split(";")[0].split())

def assemble(lines: list[str], pad: bool) -> list[int]:
    assembly = [convert_instruction(s.lower()) for line in lines if (s := prepare_instuction(line))]
    if len(assembly) > 256:
        raise ValueError(f"File too long (max 256 lines, got {len(lines)})")

    return assembly + ([0 for _ in range(256 - len(assembly))] if pad else [])

def generate_give_command(data: list[int]) -> str:
    list_contents = ",".join(f"""{{"hexcasting:type":"hexcasting:double","hexcasting:data":{x}d}}""" for x in data)
    return f"""/give @p hexcasting:focus{{data: {{"hexcasting:type":"hexcasting:list","hexcasting:data":[{list_contents}]}}}}"""

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("file", nargs="?", type=argparse.FileType("r"), default=sys.stdin)
    parser.add_argument("-p", "--pad", action="store_true")
    args = parser.parse_args()

    assembly = assemble(args.file.readlines(), args.pad)
    print(assembly)
    print(generate_give_command(assembly))
