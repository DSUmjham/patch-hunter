# patch-hunter
The **patch-hunter** docker container ingests two subject firmware files (.bins) and performs automated patch analysis on them. This suite of tools generates extracted firmware images and allows analysts to quickly identify file modificaitons, additions, and deletions between two versions. 

## Running patch-hunter
1. Build the Docker image after cloning it from this repo:
```shell
cd patch-hunter
docker build -t patch-hunter .
```
2. Place the target binaries into the **patch-hunter/bins/** folder. 

3. Run the container, which will automatically analyze the diff files:
```shell
docker run -it \
  -v $(pwd)/bins:/bins \
  -v $(pwd)/outputs:/outputs \
  -e OLD_FW=file01.bin \
  -e NEW_FW=file02.bin \
  patch-hunter
```

4. All output files are stored in the **/patch-hunter/outputs** directory.
   * **extractions/file01.bin/** - directory containin the file01 extracted firmware
   * **extractions/file02.bin/** - directory containin the file02 extracted firmware
   * **firmware_diff_flat.json** - JSON containing full file paths
   * **firmware_diff_tree.json** - JSON containing a tree structure of file paths

## Example Output