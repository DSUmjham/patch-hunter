# patch-hunter
The **patch-hunter** Docker container ingests two subject firmware files (.bins) and performs automated patch analysis on them. This suite of tools generates extracted firmware images and allows analysts to quickly identify file modifications, additions, and deletions between two versions. 

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
![Running patch-hunter in Terinal](https://github.com/DSUmjham/patch-hunter/blob/main/images/docker-run.png?raw=true)

4. All output files are stored in the **/patch-hunter/outputs** directory.
   * **extractions/file01.bin/** - directory containin the file01 extracted firmware
   * **extractions/file02.bin/** - directory containin the file02 extracted firmware
   * **firmware_diff_flat.json** - JSON containing full file paths
   * **firmware_diff_tree.json** - JSON containing a tree structure of file paths

## Example Output
In addition to providing the extracted firmware samples, patch-hunter produces easily parsable JSON files to show any file modifications, additions, and deletions. You can find sample .json files in the [examples](https://github.com/DSUmjham/patch-hunter/tree/main/examples) directory of this repo.

* [Flat JSON](https://github.com/DSUmjham/patch-hunter/blob/main/examples/firmware_diff_flat.json) representation of the firmware diff between old and new firmware.

![Flat JSON output](https://github.com/DSUmjham/patch-hunter/blob/main/images/json_flat.png?raw=true)

* [Tree JSON](https://github.com/DSUmjham/patch-hunter/blob/main/examples/firmware_diff_tree.json) representation of the firmware diff between old and new firmware.

![Tree JSON output](https://github.com/DSUmjham/patch-hunter/blob/main/images/json_tree.png?raw=true)