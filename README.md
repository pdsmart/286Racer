## Overview

The 286 Racer ([repo](https://github.com/pdsmart/286Racer)) was my final year University degree project which attained an 85% score.

In 1988, the main personal computers came from IBM, specifically the [IBM PC XT](https://en.wikipedia.org/wiki/IBM_Personal_Computer_XT)'s based on the [Intel 8088](https://en.wikipedia.org/wiki/Intel_8088)
CPU and the [IBM PC AT](https://en.wikipedia.org/wiki/IBM_Personal_Computer/AT)'s based on the [Intel 80286](https://en.wikipedia.org/wiki/Intel_80286). The IBM PC AT carried quite a premium and was a much faster machine.

This project was to devise a plug in card which would convert an IBM PC XT into an AT equivalent at less cost than buying an IBM PC AT. It also provided the ability to run
detached jobs as a co-processor, so software compilations, databases etc would run much more quickly, in the background, and thus provided value added features above that of an IBM AT.

It was designed in Orcad Schematic and built using wire-wrapping techniques and used relatively advanced technologies such as PLD's and methodologies such as interprocessor communications. The
design required the writing of an IBM PC BIOS from scratch, for both the host PC and the 286 Racer Card along with supporting programs to allow the 286 Racer to take over the host or sit in the
background as a co-processor and accepts spawned jobs.

Unfortunately, I cannot find any of the documentation (it was well documented at the time, the electronic design, the BIOS, software etc), only the schematics, C programs, Assembly Programs and
associated scripts exist now and are stored in the repository.

The schematics were designed under ORCAD v1-2 and are not readable by a modern version of Orcad (they dropped support for older formats years ago). If I can find an old copy of Orcad and run it
I will convert the schematics to PDF and store in the repository.


## Credits

Where I have used or based any component on a 3rd parties design I have included the original authors copyright notice within the headers or given due credit. All 3rd party software, to my knowledge and research, is open source and freely useable, if there is found to be any component with licensing restrictions, it will be removed from this repository and a suitable link/config provided.


## Licenses

This design, hardware and software, is licensed under the GNU Public Licence v3.

### The Gnu Public License v3
 The source and binary files in this project marked as GPL v3 are free software: you can redistribute it and-or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

 The source files are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

 You should have received a copy of the GNU General Public License along with this program.  If not, see http://www.gnu.org/licenses/.


