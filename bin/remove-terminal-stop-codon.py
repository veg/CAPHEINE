#!/usr/bin/env python3
"""
remove_terminal_stops.py

Trim all terminal stop codons from sequences in a FASTA file, using a chosen
NCBI genetic code (translation table). Leave non-stop terminal codons alone.
If any INTERNAL, in-frame stop codon is found, exit with:
    "hyphy does not permit internal stop codons"

Requires: Biopython
    pip install biopython

Usage:
    python remove_terminal_stops.py -i input.fasta -o output.fasta -t 1
    # You can also use table names, e.g. -t "Vertebrate Mitochondrial"
"""

import argparse
import sys
from Bio import SeqIO
from Bio.Seq import Seq
from Bio.Data import CodonTable

def load_table(table_arg: str):
    """Return a DNA codon table from an NCBI table id (int) or name (str)."""
    if table_arg is None:
        return CodonTable.unambiguous_dna_by_id[1]  # Standard
    # try as integer id
    try:
        tid = int(table_arg)
        return CodonTable.unambiguous_dna_by_id[tid]
    except (ValueError, KeyError):
        pass
    # try as name
    try:
        return CodonTable.unambiguous_dna_by_name[table_arg]
    except KeyError:
        # Build a helpful hint list
        valid_ids = sorted(CodonTable.unambiguous_dna_by_id.keys())
        valid_names = sorted(CodonTable.unambiguous_dna_by_name.keys())
        sys.stderr.write(
            f"ERROR: Unknown genetic code '{table_arg}'.\n"
            f"Try an NCBI table id (e.g., 1) or one of these names:\n"
            f"  {', '.join(valid_names)}\n"
            f"(Valid ids include: {', '.join(map(str, valid_ids))})\n"
        )
        sys.exit(2)

def trim_terminal_stops_and_validate(record, stop_codons):
    """
    - Remove ALL trailing stop codons (0+ at the end).
    - If any internal in-frame stop codon exists (excluding the trailing block),
      exit with the required message.
    - Ignore a terminal codon that is not a stop codon.
    """
    # Work with DNA letters; treat any RNA U as T
    seq_str = str(record.seq).upper().replace("U", "T")

    # Count how many full codons sit at the end that are stops
    idx = len(seq_str)
    trailing_stops = 0
    while idx >= 3:
        codon = seq_str[idx-3:idx]
        if codon in stop_codons:
            trailing_stops += 1
            idx -= 3
        else:
            break

    # Scan for INTERNAL stops: all complete codons up to (but not including)
    # the trailing stop block (and ignoring any trailing partial codon).
    scan_end = (idx // 3) * 3  # only complete codons
    for pos in range(0, scan_end, 3):
        codon = seq_str[pos:pos+3]
        if codon in stop_codons:
            " "
            sys.stderr.write(
            f"ERROR: Found an internal stop codon in sequence '{record.id}' at position {str(pos)}.\n"
            f"Hyphy does not permit internal stop codons. Please review your input sequences.\n"
            )
            sys.exit(2)

    # Finally, remove the trailing stop codons (if any)
    if trailing_stops > 0:
        seq_str = seq_str[:idx]

    # Leave sequences with non-stop terminal codons unchanged by design
    return Seq(seq_str)

def main():
    ap = argparse.ArgumentParser(
        description="Remove all terminal stop codons from a FASTA, using a chosen genetic code. "
                    "Fail if any internal in-frame stop codon is present."
    )
    ap.add_argument("-i", "--input", required=True, help="Input FASTA file")
    ap.add_argument("-o", "--output", required=True, help="Output FASTA file")
    ap.add_argument(
        "-t", "--table",
        help="NCBI translation table id (e.g., 1) or name (e.g., 'Vertebrate Mitochondrial'). "
             "Default: 1 (Standard)."
    )
    args = ap.parse_args()

    table = load_table(args.table)
    stop_codons = set(table.stop_codons)  # e.g., {'TAA','TAG','TGA'} for Standard

    records_out = []
    for rec in SeqIO.parse(args.input, "fasta"):
        new_seq = trim_terminal_stops_and_validate(rec, stop_codons)
        rec.seq = new_seq
        records_out.append(rec)

    SeqIO.write(records_out, args.output, "fasta")

if __name__ == "__main__":
    main()
