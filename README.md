# brainageR_dockerfile

Creates a base docker container that can execute the new version 2.1 of brainageR (author James Cole), can be found on https://github.com/james-cole/brainageR

To build the docker you can use the following command, where 'brainimage' is the name of the docker, you can change this variable.

       docker build . -f Dockerfile -t brainimage

Once the docker is built, you can analyze an image with the following command:

       docker run --rm -it -v ${PWD}/your_data:/data -w /data docker.io/library/brainimage:latest brainageR -f sub-01_T1w_defaced.nii -o subj01_brain_predicted.age.csv

'sub-01_T1w_defaced.nii' is the name of the MRI image decompressed in nii format and 'subj01_brain_predicted.age.csv' the .csv file where the age predictions are saved.
For linux, you must replace ${PWD} by ´pwd´. In this dockerfile, brainageR relies in Octave instead of Matlab.

Links for required softwares:

·BrainageR: https://github.com/james-cole/brainageR

·SPM12(r7219): https://github.com/spm/spm12/archive/refs/tags/r7219.tar.gz

·OCTAVE patch (also works for SPM12 r7219): https://raw.githubusercontent.com/spm/spm-docker/main/octave/spm12_r7771.patch

·Nuerodebian.gpg file for FSL installation: https://github.com/PennBBL/fiberfox-wrapper/blob/master/neurodebian.gpg

