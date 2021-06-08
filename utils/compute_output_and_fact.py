import os
import sys

DIR = os.path.dirname(__file__)

from starkware.cairo.bootloader.generate_fact import get_cairo_pie_fact_info
from starkware.cairo.bootloader.hash_program import compute_program_hash_chain
from starkware.cairo.sharp.client_lib import CairoPie

def main():
    file_path = os.path.join(DIR, "../fill_order_pie")
    cairo_pie = CairoPie.from_file(file_path)

    program_hash = compute_program_hash_chain(cairo_pie.program)
    print(f'program hash: {hex(program_hash)}')
    fact_info = get_cairo_pie_fact_info(cairo_pie, program_hash)
    print(f'program output: {fact_info.program_output}')
    print(f'fact: {fact_info.fact}')

if __name__ == "__main__":
    sys.exit(main())