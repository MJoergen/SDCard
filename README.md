# SDCard

This repository contains a portable OpenSource SDCard controller for FPGAs written in VHDL.
I'm writing my own implementation because I've looked at several other implementations, and
they all seemed lacking in various regards (features, stability, portability, simplicity, etc.).

The SDCard controller in this repository is a complete rewrite from scratch,
and is provided with a [MIT license](LICENSE).

## Resources
The [doc](doc) folder contains useful resources, including
* [Part1_Physical_Layer_Simplified_Specification_Ver8.00.pdf](doc/Part1_Physical_Layer_Simplified_Specification_Ver8.00.pdf)
  downloaded from [sdcard.org/downloads/pls](https://www.sdcard.org/downloads/pls).
* [sdcard_mass_storage_controller_latest.tar.gz](doc/sdcard_mass_storage_controller_latest.tar.gz)
  downloaded from [opencores.org/projects/sdcard_mass_storage_controller](https://opencores.org/projects/sdcard_mass_storage_controller).
* [SDFlashControllerUsingSDBus-Documentation.pdf](doc/SDFlashControllerUsingSDBus-Documentation.pdf)
  downloaded from [www.latticesemi.com](https://www.latticesemi.com/-/media/LatticeSemi/Documents/ReferenceDesigns/SZ/SDFlashControllerUsingSDBus-Documentation.ashx?document_id=36706).

The [sim](sim) folder contains the files needed for testing in simulation
* [sdModel.v](sim/sdModel.v). This is an SDCard simulation model copied from
  [opencores.org/projects/sdcard_mass_storage_controller](https://opencores.org/projects/sdcard_mass_storage_controller).
