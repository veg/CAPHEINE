from Bio import SeqIO
import argparse
from pathlib import Path

arguments = argparse.ArgumentParser(description = 'Remove sequences with high number of gaps')
arguments.add_argument('-i', '--input_alignment', help='Full path to input alignment in fasta format', required=True, type=str)
arguments.add_argument('-o', '--output_prefix', help='Prefix for output alignment in fasta format', required=True, type=str)
arguments.add_argument('-t', '--threshold', help='Exclude sequences with equal to or more than THRESHOLD fraction of gaps', default=0.5, type=float)
settings = arguments.parse_args()

def filter_sequences(input_fasta, output_fasta, threshold):
    ambig_and_gap = set("NRYSWKMBDHVX-.")
    with open(output_fasta, "w") as out:
        for record in SeqIO.parse(input_fasta, "fasta"):
            seq = str(record.seq)
            gap_count = sum(1 for char in seq.upper() if char in ambig_and_gap)
            if gap_count / len(seq) < threshold:
                SeqIO.write(record, out, "fasta")

file_path = Path(settings.input_alignment)  # "path/to/my_alignment.fasta"
base_path = file_path.with_suffix('')  # "path/to/my_alignment", removes suffix
filter_sequences(settings.input_alignment, settings.output_prefix + "-clean.fasta", settings.threshold)

