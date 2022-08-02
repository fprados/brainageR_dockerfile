# brainageR_dockerfile

Dockerfile creates a base docker container that can execute the new version 2.1 of brainageR (author James Cole) which can be found on https://github.com/james-cole/brainageR. Brainage R is a software for generating a brain-predicted age value from a raw T1-weighted MRI scan.

To build the docker you can use the following command, where 'brainimage' is the name of the docker, you can change this variable. Ensure that brainageR script and neurodebian.gpg are in the same directory as Dockerfile.

       docker build . -f Dockerfile -t brainimage

Once the docker is built, you can analyze a raw T1-weighted MRI scan with the following command:

       docker run --rm -it -v ${PWD}/your_data:/data -w /data docker.io/library/brainimage:latest brainageR -f sub-01_T1w_defaced.nii -o subj01_brain_predicted.age.csv

'sub-01_T1w_defaced.nii' is the name of the raw T1-weighted MRI scan decompressed in nii format placed in your_data folder, and 'subj01_brain_predicted.age.csv' is the .csv file where the age predictions are saved. 

In this dockerfile, brainageR relies in Octave instead of Matlab. In brainageR we reset the header realigning the input image to MNI to ensure all values are in the proper range. This procedure overwrites the old file. 

Links for required softwares:

·BrainageR: https://github.com/james-cole/brainageR

·SPM12(r7219): https://github.com/spm/spm12/archive/refs/tags/r7219.tar.gz

·OCTAVE patch (also works for SPM12 r7219): https://raw.githubusercontent.com/spm/spm-docker/main/octave/spm12_r7771.patch

·Neurodebian.gpg file for FSL installation: https://github.com/PennBBL/fiberfox-wrapper/blob/master/neurodebian.gpg

