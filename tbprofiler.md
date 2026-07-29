
### Install TBProfiler
# Set up the channels
```
conda config --add channels defaults
conda config --add channels bioconda
conda config --add channels conda-forge

conda config --show channels #Check channels available
```

### Make yaml file and add the dependencies
conda env create -f tbprofiler_env.yaml
conda activate tbprofiler_env
tb-profiler --help

#Check installation 
tb-profiler version
tb-profiler --help

### Activate conda environment
conda activate tbprofiler_en

### Move to the directory which has samples and this script

### Make a sample ids list file
ls -1 *_R1_001.fastq.gz 2>/dev/null | sed 's/_R1_001.fastq.gz//' > sample_ids.txt


```
#!/bin/bash
# TBProfiler batch script 
# ------------------------------------------

LOGFILE="tbprofiler_run.log"
RESULT_DIR="tbp_results"
timestamp() 
{
  date +"%Y-%m-%d %H:%M:%S"
}
mkdir -p "$RESULT_DIR"
echo "===== tb-profiler batch run started at $(timestamp) =====" | tee -a "$LOGFILE"

conda activate tbprofiler_env || { echo "Failed to activate tbprofiler_env" | tee -a "$LOGFILE"; exit 1; }

# run tbprofiler
for sample_r1 in *_R1_001.fastq.gz; do
  sample="${sample_r1%%_R1_001.fastq.gz}"  

  echo "[$(timestamp)] Processing sample: $sample" | tee -a "$LOGFILE"

  mkdir -p "$RESULT_DIR/$sample"
  cd "$RESULT_DIR/$sample" || { echo "Failed to enter $sample" | tee -a "../../$LOGFILE"; exit 1; }

  start_time=$(date +%s)

  tb-profiler profile \
    -1 "../../${sample}_R1_001.fastq.gz" \
    -2 "../../${sample}_R2_001.fastq.gz" \
    -t 4 \
    -p "$sample" \
    --txt

  end_time=$(date +%s)
```
  duration=$((end_time - start_time))

  echo "[$(timestamp)] Finished sample: $sample in ${duration}s" | tee -a "../../$LOGFILE"
  cd ../..
done
echo "===== tb-profiler batch run finished at $(timestamp) =====" | tee -a "$LOGFILE"
