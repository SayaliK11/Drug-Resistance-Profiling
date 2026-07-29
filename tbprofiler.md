
### 1. Install TBProfiler
```
# Set up the channels
conda config --add channels defaults
conda config --add channels bioconda
conda config --add channels conda-forge

conda config --show channels #Check channels available
```

### 1. Make yaml file and add the dependencies
```
cat > tbprofiler_env.yaml << 'EOF'
name: tbprofiler_env
channels:
  - bioconda
  - conda-forge
  - defaults

dependencies:
  - python=3.8
  - tb-profiler=4.2.0
  - bcftools=1.14
  - htslib=1.14
  - delly=0.8.7
  - samtools=1.14
EOF

conda env create -f tbprofiler_env.yaml
```

### 3. Activate conda environment
```
conda activate tbprofiler_en

#Check installation 
tb-profiler version
tb-profiler --help
```

### 4. Move to the directory that has samples and this script

### 5. Make a sample ids list file (optional)
```
ls -1 *_R1_001.fastq.gz 2>/dev/null | sed 's/_R1_001.fastq.gz//' > sample_ids.txt
```

### 6. Create bash script for TBProfiler
```
cat > tbprofiler.sh << 'EOF'
#!/bin/bash
# TBProfiler batch script
# ------------------------------------------

LOGFILE="tbprofiler_run.log"
RESULT_DIR="tbp_results"

timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

mkdir -p "$RESULT_DIR"

echo "===== tb-profiler batch run started at $(timestamp) =====" | tee -a "$LOGFILE"

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate tbprofiler_env || {
  echo "Failed to activate tbprofiler_env" | tee -a "$LOGFILE"
  exit 1
}

# Run TBProfiler on all paired-end samples
for sample_r1 in *_R1_001.fastq.gz; do
  sample="${sample_r1%%_R1_001.fastq.gz}"

  echo "[$(timestamp)] Processing sample: $sample" | tee -a "$LOGFILE"

  mkdir -p "$RESULT_DIR/$sample"
  cd "$RESULT_DIR/$sample" || {
    echo "Failed to enter $sample" | tee -a "../../$LOGFILE"
    exit 1
  }

  start_time=$(date +%s)

  tb-profiler profile \
    -1 "../../${sample}_R1_001.fastq.gz" \
    -2 "../../${sample}_R2_001.fastq.gz" \
    -t 4 \
    -p "$sample" \
    --txt

  end_time=$(date +%s)
  duration=$((end_time - start_time))

  echo "[$(timestamp)] Finished sample: $sample in ${duration}s" | tee -a "../../$LOGFILE"

  cd ../..
done

echo "===== tb-profiler batch run finished at $(timestamp) =====" | tee -a "$LOGFILE"
EOF
```

### 7. Save it as 
```
chmod +x tbprofiler.sh
```

### 8. Execute
```
./tbprofiler.sh
```

---

### If you want to run it in the background (recommended for long analyses):
```
nohup ./tbprofiler.sh > tbprofiler.out 2>&1 &
```

### Monitor the progress with
```
tail -f tbprofiler_run.log
```
or 
```
tail -f tbprofiler.out
```

