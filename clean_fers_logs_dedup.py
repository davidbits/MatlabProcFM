#!/usr/bin/env python3
import os
import hashlib
import difflib
import time
import re

# --- Configuration ---
INPUT_PATH = "run.log"
OUTPUT_PATH = INPUT_PATH + ".cleaned"

# Maximum fraction length difference to consider for 99% similarity candidates.
LENGTH_DIFF_FRACTION = 0.01  # 1%

# How many characters of the prefix to use for bucketing
PREFIX_CHARS = 8

# Bucket size cap: keep at most this many representative lines per bucket to bound memory
MAX_REPRS_PER_BUCKET = 200

# Progress reporting interval
REPORT_EVERY = 1000  # report every N processed lines

# Similarity threshold (0.0 - 1.0)
SIMILARITY_THRESHOLD = 0.99

# Regexes used for normalization
_RE_ISO_TS = re.compile(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?")
_RE_TIME = re.compile(r"\d{1,2}:\d{2}:\d{2}(?:\.\d+)?")
_RE_NUMBER = re.compile(r"\d+([.,]\d+)?")
_RE_HEX = re.compile(r"0x[0-9a-fA-F]+")
_RE_WS = re.compile(r"\s+")


def sha256_text(s: str) -> str:
    h = hashlib.sha256()
    h.update(s.encode('utf-8', errors='replace'))
    return h.hexdigest()


def normalize_line(s: str) -> str:
    """Normalize a line by replacing timestamps, hex, and numbers with placeholders, and collapsing whitespace.
    This helps treat lines that differ only by numeric values as identical for fast filtering.
    """
    if not s:
        return s
    s = _RE_ISO_TS.sub('<TS>', s)
    s = _RE_TIME.sub('<TS>', s)
    s = _RE_HEX.sub('<HEX>', s)
    s = _RE_NUMBER.sub('<NUM>', s)
    s = _RE_WS.sub(' ', s)
    return s.strip()


def tokens_of(s: str):
    # simple word tokens from normalized string
    return frozenset(re.findall(r"\w+", s))


def likely_similar_by_length(a: str, b: str) -> bool:
    la = len(a)
    lb = len(b)
    if la == 0 and lb == 0:
        return True
    maxl = max(la, lb)
    return abs(la - lb) / maxl <= LENGTH_DIFF_FRACTION


def jaccard(tokens_a: frozenset, tokens_b: frozenset) -> float:
    if not tokens_a and not tokens_b:
        return 1.0
    inter = tokens_a.intersection(tokens_b)
    union = tokens_a.union(tokens_b)
    return len(inter) / len(union)


def is_similar(a: str, b: str, tokens_a: frozenset = None, tokens_b: frozenset = None) -> bool:
    """Return True if strings a and b are >= SIMILARITY_THRESHOLD similar.
    Uses fast token-set Jaccard first, then falls back to difflib.SequenceMatcher only when needed.
    """
    if a == b:
        return True
    if not likely_similar_by_length(a, b):
        return False

    if tokens_a is None:
        tokens_a = tokens_of(a)
    if tokens_b is None:
        tokens_b = tokens_of(b)

    # Fast check: if token sets are almost identical, treat as duplicate
    j = jaccard(tokens_a, tokens_b)
    if j >= SIMILARITY_THRESHOLD:
        return True
    # If token sets are very different, skip expensive ratio
    if j < 0.5:
        return False
    # Fallback to difflib for borderline cases
    ratio = difflib.SequenceMatcher(None, a, b).ratio()
    return ratio >= SIMILARITY_THRESHOLD


def bucket_key_for_line(line: str):
    """Return a bucket key (length bucket, short prefix) for a given line (use normalized prefix)."""
    length_bucket = len(line) // max(1, int(1 / LENGTH_DIFF_FRACTION))
    prefix = line[:PREFIX_CHARS]
    return (length_bucket, prefix)


def clean_file(input_path: str, output_path: str):
    seen_exact = set()  # store sha256 of lines seen exactly
    seen_normal = set()  # store sha256 of normalized lines
    # mapping bucket_key -> list of representative dicts {content, normalized, tokens}
    buckets = {}

    total = 0
    kept = 0
    skipped_exact = 0
    skipped_similar = 0

    start = time.time()
    with open(input_path, 'r', encoding='utf-8', errors='replace') as inf, open(output_path, 'w', encoding='utf-8') as outf:
        for line in inf:
            total += 1
            has_newline = line.endswith('\n')
            content = line[:-1] if has_newline else line

            # Quick exact duplicate check
            h = sha256_text(content)
            if h in seen_exact:
                skipped_exact += 1
                if total % REPORT_EVERY == 0:
                    elapsed = time.time() - start
                    print(f"Processed {total:,} lines in {elapsed:.1f}s - kept {kept:,}, skipped_exact {skipped_exact:,}, skipped_similar {skipped_similar:,}")
                continue

            # Fast normalized-hash check: catches lines that only differ by numbers/timestamps
            normalized = normalize_line(content)
            nh = sha256_text(normalized)
            if nh in seen_normal:
                skipped_similar += 1
                if total % REPORT_EVERY == 0:
                    elapsed = time.time() - start
                    print(f"Processed {total:,} lines in {elapsed:.1f}s - kept {kept:,}, skipped_exact {skipped_exact:,}, skipped_similar {skipped_similar:,}")
                continue

            key = bucket_key_for_line(normalized)
            reps = buckets.get(key)
            is_dup = False

            tok_a = tokens_of(normalized)
            if reps:
                # Compare against representatives in this bucket only using token jaccard then difflib fallback
                for rep in reps:
                    # rep has keys: 'content','normalized','tokens'
                    if is_similar(normalized, rep['normalized'], tok_a, rep['tokens']):
                        is_dup = True
                        skipped_similar += 1
                        break

            if not is_dup:
                # Write line to output (preserve newline behavior)
                outf.write(content + ('\n' if has_newline else ''))
                kept += 1
                seen_exact.add(h)
                seen_normal.add(nh)
                # Add to bucket representatives (limit size)
                if reps is None:
                    buckets[key] = [{'content': content, 'normalized': normalized, 'tokens': tok_a}]
                else:
                    if len(reps) < MAX_REPRS_PER_BUCKET:
                        reps.append({'content': content, 'normalized': normalized, 'tokens': tok_a})
                    # else: bucket is full, don't add more representatives to bound memory

            if total % REPORT_EVERY == 0:
                elapsed = time.time() - start
                print(f"Processed {total:,} lines in {elapsed:.1f}s - kept {kept:,}, skipped_exact {skipped_exact:,}, skipped_similar {skipped_similar:,}")

    elapsed = time.time() - start
    print("--- Done ---")
    print(f"Input: {input_path}")
    print(f"Output: {output_path}")
    print(f"Total lines: {total:,}")
    print(f"Kept lines: {kept:,}")
    print(f"Skipped exact duplicates: {skipped_exact:,}")
    print(f"Skipped similar lines: {skipped_similar:,}")
    print(f"Elapsed time: {elapsed:.1f}s")


if __name__ == '__main__':
    if not os.path.exists(INPUT_PATH):
        print(f"Input path does not exist: {INPUT_PATH}")
        print("Edit the INPUT_PATH constant at the top of this script to point to your log file.")
    else:
        print(f"Cleaning file: {INPUT_PATH}")
        clean_file(INPUT_PATH, OUTPUT_PATH)
