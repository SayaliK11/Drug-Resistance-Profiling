#!/bin/bash

RESULTS_DIR="mykrobe_results"
mkdir -p "$RESULTS_DIR"

LOGFILE="${RESULTS_DIR}/mykrobe_run.log"

# Capture ALL stdout + stderr into log (and show on terminal)
exec > >(tee -a "$LOGFILE") 2>&1

timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

echo "===== Mykrobe batch run started at $(timestamp) ====="

# Make a sample ids list file
# ls -1 *_R1_001.fastq.gz 2>/dev/null | sed 's/_R1_001.fastq.gz//' > sample_ids.txt

# Activate conda environment
#conda activate mykrobe || { echo "Failed to activate mykrobe env"; exit 1; }

# Loop through all R1 FASTQ files
for sample_r1 in *_R1_001.fastq.gz; do
  sample="${sample_r1%%_R1_001.fastq.gz}"
  sample_r2="${sample}_R2_001.fastq.gz"

  if [[ ! -f "$sample_r2" ]]; then
    echo "[$(timestamp)] WARNING: Missing R2 file for $sample, skipping..."
    continue
  fi

  echo "[$(timestamp)] Processing sample: $sample"

  # Create per-sample directory INSIDE mykrobe_results
  mkdir -p "${RESULTS_DIR}/${sample}"
  cd "${RESULTS_DIR}/${sample}" || { echo "Failed to enter ${RESULTS_DIR}/${sample}"; exit 1; }

  start_time=$(date +%s)

  # Run Mykrobe on paired reads
  mykrobe predict \
    --sample "$sample" \
    --species tb \
    --output "${sample}_mykrobe.json" \
    --format json \
    --seq "../../${sample}_R1_001.fastq.gz" "../../${sample}_R2_001.fastq.gz"

  if [[ $? -ne 0 ]]; then
    echo "[$(timestamp)] ERROR: Mykrobe failed for $sample"
  else
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    echo "[$(timestamp)] Finished sample: $sample in ${duration}s"
  fi

  cd ../..
done

echo "===== Mykrobe batch run finished at $(timestamp) ====="

### Visualize results as:
# cd sample_id
# jq . sample_id.mykrobe.json | less
