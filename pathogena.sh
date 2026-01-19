#!/bin/bash

set -euo pipefail

LOGFILE="gpas.log"
exec > >(tee -a "$LOGFILE") 2>&1

timestamp() { date +"%Y-%m-%d %H:%M:%S"; }

echo " GPAS Myco Pipeline Run Started $(timestamp)"

START_TIME=$(date +%s)
WORKDIR="$(pwd)"
FASTQ_DIR="$WORKDIR/fastq"
BACKUP_DIR="$WORKDIR/original_fastq_backup_$(date +%Y%m%d_%H%M%S)"

# Prepare directories
# --------------------------------------------------------------------
mkdir -p "$FASTQ_DIR"
mkdir -p "$BACKUP_DIR"

# Collect FASTQs into fastq/
# --------------------------------------------------------------------
echo "[INFO] Collecting FASTQ files"

find "$WORKDIR" -maxdepth 1 -name "*.fastq.gz" -exec mv {} "$FASTQ_DIR/" \;

cd "$FASTQ_DIR"

FASTQ_COUNT=$(ls *.fastq.gz 2>/dev/null | wc -l)
echo "[INFO] FASTQ files found: $FASTQ_COUNT"

if [ "$FASTQ_COUNT" -eq 0 ]; then
    echo "[ERROR] No FASTQ files found"
    exit 1
fi

# Rename FASTQs to GPAS format (_1/_2)
# --------------------------------------------------------------------
echo "[INFO] Renaming FASTQ files to GPAS format"

RENAMED=0

for f in *_R1_*.fastq.gz *_R1.fastq.gz; do
    [ -e "$f" ] || continue
    if [[ $f =~ ^(.+)_S[0-9]+_L[0-9]+_R1_001\.fastq\.gz$ || \
          $f =~ ^(.+)_R1\.fastq\.gz$ ]]; then
        SAMPLE="${BASH_REMATCH[1]}"
        cp "$f" "$BACKUP_DIR/"
        mv "$f" "${SAMPLE}_1.fastq.gz"
        ((RENAMED++))
    fi
done

for f in *_R2_*.fastq.gz *_R2.fastq.gz; do
    [ -e "$f" ] || continue
    if [[ $f =~ ^(.+)_S[0-9]+_L[0-9]+_R2_001\.fastq\.gz$ || \
          $f =~ ^(.+)_R2\.fastq\.gz$ ]]; then
        SAMPLE="${BASH_REMATCH[1]}"
        cp "$f" "$BACKUP_DIR/"
        mv "$f" "${SAMPLE}_2.fastq.gz"
        ((RENAMED++))
    fi
done

echo "[INFO] FASTQ files renamed: $RENAMED"

# Validate pairing
# --------------------------------------------------------------------
echo "[INFO] Validating R1/R2 pairing"

R1=$(ls *_1.fastq.gz | sed 's/_1.fastq.gz//' | sort)
R2=$(ls *_2.fastq.gz | sed 's/_2.fastq.gz//' | sort)

if ! diff <(echo "$R1") <(echo "$R2") >/dev/null; then
    echo "[ERROR] R1/R2 mismatch detected"
    echo "[ERROR] R1 samples:"
    echo "$R1"
    echo "[ERROR] R2 samples:"
    echo "$R2"
    exit 1
fi

SAMPLE_COUNT=$(echo "$R1" | wc -l)
echo "[INFO] Paired samples detected: $SAMPLE_COUNT"

# Build GPAS CSV
# --------------------------------------------------------------------
cd "$WORKDIR"
rm -f tb_upload.csv

COLLECTION_DATE="2025-01-01"   # CHANGE if needed

echo "[INFO] Building GPAS CSV"

gpas build-csv "$FASTQ_DIR" \
    --output-csv tb_upload.csv \
    --batch-name Batch4 \
    --collection-date "$COLLECTION_DATE" \
    --country IND \
    --instrument-platform illumina \
    --specimen-organism mycobacteria

if [ ! -s tb_upload.csv ]; then
    echo "[ERROR] CSV creation failed or empty"
    exit 1
fi

echo "[INFO] CSV preview:"
head -5 tb_upload.csv
echo "[INFO] Total samples in CSV: $(( $(wc -l < tb_upload.csv) - 1 ))"

# Validate CSV
# --------------------------------------------------------------------
echo "[INFO] Validating CSV"
gpas validate tb_upload.csv

# Upload
# --------------------------------------------------------------------
UPLOAD_START=$(date +%s)
echo "[INFO] Upload started"

gpas upload tb_upload.csv

UPLOAD_END=$(date +%s)
echo "[INFO] Upload finished in $((UPLOAD_END - UPLOAD_START)) seconds"
END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))

echo "====================================="
echo " GPAS Myco Pipeline Completed"
echo " Samples uploaded: $SAMPLE_COUNT"
echo " Runtime: ${TOTAL_TIME}s (~$((TOTAL_TIME/60)) min)"
echo " Backup directory: $BACKUP_DIR"
echo " Log file: $LOGFILE"
echo "====================================="
