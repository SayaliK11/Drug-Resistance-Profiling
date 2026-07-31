### 1. Install Mykrobe
```
conda create -n mykrobe -c bioconda -c conda-forge python=3.11 mykrobe
```


### 2. Activate conda environment
```
conda activate mykrobe

# Check installation
mykrobe --help
```

### 3. Move to the directory that has samples and this script

### 4. Make a sample IDs list file (optional)
```
ls -1 *_R1_001.fastq.gz 2>/dev/null | sed 's/_R1_001.fastq.gz//' > sample_ids.txt
```

### 5. Create bash script for Mykrobe
```
cat > mykrobe.sh << 'EOF'
#!/bin/bash
# Mykrobe batch script for Multiple Samples
# ------------------------------------------

RESULTS_DIR="mykrobe_results"
mkdir -p "$RESULTS_DIR"

LOGFILE="${RESULTS_DIR}/mykrobe_run.log"
exec > >(tee -a "$LOGFILE") 2>&1

timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

echo "===== Mykrobe batch run started at $(timestamp) ====="

# Activate conda environment
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate mykrobe_env || {
  echo "Failed to activate mykrobe_env"
  exit 1
}

# Run Mykrobe on all paired-end samples
for sample_r1 in *_R1_001.fastq.gz; do

  sample="${sample_r1%%_R1_001.fastq.gz}"
  sample_r2="${sample}_R2_001.fastq.gz"

  if [[ ! -f "$sample_r2" ]]; then
    echo "[$(timestamp)] WARNING: Missing R2 file for $sample, skipping..."
    continue
  fi

  echo "[$(timestamp)] Processing sample: $sample"

  mkdir -p "${RESULTS_DIR}/${sample}"
  cd "${RESULTS_DIR}/${sample}" || {
    echo "Failed to enter ${RESULTS_DIR}/${sample}"
    exit 1
  }

  start_time=$(date +%s)

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
EOF
```

### 6. Save it as executable
```
chmod +x mykrobe.sh
```

### 7. Execute
```
./mykrobe.sh
```

---

### If you want to run it in the background (recommended for long analyses)
```
nohup ./mykrobe.sh > mykrobe.out 2>&1 &
```

### Monitor the progress with
```
tail -f mykrobe_results/mykrobe_run.log
```
or
```
tail -f mykrobe.out
```
