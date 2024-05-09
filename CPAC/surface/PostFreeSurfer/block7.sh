
#!/bin/bash

echo "START"

StudyFolder="$1"
echo "StudyFolder: ${StudyFolder}"

FreeSurferFolder="$2"
echo "FreeSurferFolder: ${FreeSurferFolder}"

Subject="$3"
echo "Subject: ${Subject}"

T1wRestoreImageCPAC="$4"
echo "T1wRestoreImageCPAC: ${T1wRestoreImageCPAC}"

AtlasSpaceT1wImageCPAC="$5"
echo "AtlasSpaceT1wImageCPAC: ${AtlasSpaceT1wImageCPAC}"

AtlasTransformCPAC="$6"
echo "AtlasTransformCPAC ${AtlasTransformCPAC}"

InverseAtlasTransformCPAC="$7"
echo "InverseAtlasTransformCPAC: ${InverseAtlasTransformCPAC}"

SurfaceAtlasDIR="$8"
echo "SurfaceAtlasDIR: ${SurfaceAtlasDIR}"

GrayordinatesSpaceDIR="$9"
echo "GrayordinatesSpaceDIR: ${GrayordinatesSpaceDIR}"

GrayordinatesResolutions="${10}"
echo "GrayordinatesResolutions: ${GrayordinatesResolutions}"

HighResMesh="${11}"
echo "HighResMesh: ${HighResMesh}"

LowResMeshes="${12}"
echo "LowResMeshes: ${LowResMeshes}"

SubcorticalGrayLabels="${13}"
echo "SubcorticalGrayLabels: ${SubcorticalGrayLabels}"

FreeSurferLabels="${14}"
echo "FreeSurferLabels: ${FreeSurferLabels}"

RegName=MSMSulc
# RegName=FS
useT2=false

# default parameters
CorrectionSigma=$(echo "sqrt ( 200 )" | bc -l)
InflateExtraScale=1

#Naming Conventions
T1wImage="T1w_acpc_dc"
T1wFolder="T1w" #Location of T1w images
T2wFolder="T2w" #Location of T1w images
T2wImage="T2w_acpc_dc"
AtlasSpaceFolder="MNINonLinear"
NativeFolder="Native"
FreeSurferInput="T1w_acpc_dc_restore_1mm"
AtlasTransform="acpc_dc2standard"
InverseAtlasTransform="standard2acpc_dc"
AtlasSpaceT1wImage="T1w_restore"
AtlasSpaceT2wImage="T2w_restore"
T1wRestoreImage="T1w_acpc_dc_restore"
T2wRestoreImage="T2w_acpc_dc_restore"
OrginalT1wImage="T1w"
OrginalT2wImage="T2w"
T1wImageBrainMask="brainmask_fs"
InitialT1wTransform="acpc.mat"
dcT1wTransform="T1w_dc.nii.gz"
InitialT2wTransform="acpc.mat"
dcT2wTransform="T2w_reg_dc.nii.gz"
FinalT2wTransform="${Subject}/mri/transforms/T2wtoT1w.mat"
BiasField="BiasField_acpc_dc"
OutputT1wImage="T1w_acpc_dc"
OutputT1wImageRestore="T1w_acpc_dc_restore"
OutputT1wImageRestoreBrain="T1w_acpc_dc_restore_brain"
OutputMNIT1wImage="T1w"
OutputMNIT1wImageRestore="T1w_restore"
OutputMNIT1wImageRestoreBrain="T1w_restore_brain"
OutputT2wImage="T2w_acpc_dc"
OutputT2wImageRestore="T2w_acpc_dc_restore"
OutputT2wImageRestoreBrain="T2w_acpc_dc_restore_brain"
OutputMNIT2wImage="T2w"
OutputMNIT2wImageRestore="T2w_restore"
OutputMNIT2wImageRestoreBrain="T2w_restore_brain"
OutputOrigT1wToT1w="OrigT1w2T1w.nii.gz"
OutputOrigT1wToStandard="OrigT1w2standard.nii.gz" #File was OrigT2w2standard.nii.gz, regnerate and apply matrix
OutputOrigT2wToT1w="OrigT2w2T1w.nii.gz" #mv OrigT1w2T2w.nii.gz OrigT2w2T1w.nii.gz
OutputOrigT2wToStandard="OrigT2w2standard.nii.gz"
BiasFieldOutput="BiasField"
Jacobian="NonlinearRegJacobians.nii.gz"


T1wFolder="$StudyFolder"/"$T1wFolder"
T2wFolder="$StudyFolder"/"$T2wFolder"
AtlasSpaceFolder="$StudyFolder"/"$AtlasSpaceFolder"
AtlasTransform="$AtlasSpaceFolder"/xfms/"$AtlasTransform"
InverseAtlasTransform="$AtlasSpaceFolder"/xfms/"$InverseAtlasTransform"

LowResMeshes=${LowResMeshes//@/ }
echo "LowResMeshes: ${LowResMeshes}"

GrayordinatesResolutions=${GrayordinatesResolutions//@/ }
echo "GrayordinatesResolutions: ${GrayordinatesResolutions}"

HCPPIPEDIR=/code/CPAC/resources
source ${HCPPIPEDIR}/global/scripts/log.shlib # Logging related functions
echo "HCPPIPEDIR: ${HCPPIPEDIR}"
MSMCONFIGDIR=${HCPPIPEDIR}/MSMConfig

# Create midthickness Vertex Area (VA) maps
echo "Create midthickness Vertex Area (VA) maps"

for Hemisphere in L R ; do
	#Set a bunch of different ways of saying left and right
	if [ $Hemisphere = "L" ] ; then
		hemisphere="l"
		Structure="CORTEX_LEFT"
	elif [ $Hemisphere = "R" ] ; then
		hemisphere="r"
		Structure="CORTEX_RIGHT"
	fi
cd ${StudyFolder}

for LowResMesh in ${LowResMeshes} ; do

	echo "Creating midthickness Vertex Area (VA) maps for LowResMesh: ${LowResMesh}"

	# DownSampleT1wFolder             - path to folder containing downsampled T1w files
	# midthickness_va_file            - path to non-normalized midthickness vertex area file
	# normalized_midthickness_va_file - path ot normalized midthickness vertex area file
	# surface_to_measure              - path to surface file on which to measure surface areas
	# output_metric                   - path to metric file generated by -surface-vertex-areas subcommand

	DownSampleT1wFolder=${T1wFolder}/fsaverage_LR${LowResMesh}k
	DownSampleFolder=${AtlasSpaceFolder}/fsaverage_LR${LowResMesh}k
	midthickness_va_file=${DownSampleT1wFolder}/${Subject}.midthickness_va.${LowResMesh}k_fs_LR.dscalar.nii
	normalized_midthickness_va_file=${DownSampleT1wFolder}/${Subject}.midthickness_va_norm.${LowResMesh}k_fs_LR.dscalar.nii

	for Hemisphere in L R ; do
		surface_to_measure=${DownSampleT1wFolder}/${Subject}.${Hemisphere}.midthickness.${LowResMesh}k_fs_LR.surf.gii
		output_metric=${DownSampleT1wFolder}/${Subject}.${Hemisphere}.midthickness_va.${LowResMesh}k_fs_LR.shape.gii
		wb_command -surface-vertex-areas ${surface_to_measure} ${output_metric}
	done

	# left_metric  - path to left hemisphere VA metric file
	# roi_left     - path to file of ROI vertices to use from left surface
	# right_metric - path to right hemisphere VA metric file
	# roi_right    - path to file of ROI vertices to use from right surface

	left_metric=${DownSampleT1wFolder}/${Subject}.L.midthickness_va.${LowResMesh}k_fs_LR.shape.gii
	roi_left=${DownSampleFolder}/${Subject}.L.atlasroi.${LowResMesh}k_fs_LR.shape.gii
	right_metric=${DownSampleT1wFolder}/${Subject}.R.midthickness_va.${LowResMesh}k_fs_LR.shape.gii
	roi_right=${DownSampleFolder}/${Subject}.R.atlasroi.${LowResMesh}k_fs_LR.shape.gii

	wb_command -cifti-create-dense-scalar ${midthickness_va_file} \
				-left-metric  ${left_metric} \
				-roi-left     ${roi_left} \
				-right-metric ${right_metric} \
				-roi-right    ${roi_right}

	# VAMean - mean of surface area accounted for for each vertex - used for normalization
	VAMean=$(wb_command -cifti-stats ${midthickness_va_file} -reduce MEAN)
	echo "VAMean: ${VAMean}"

	wb_command -cifti-math "VA / ${VAMean}" ${normalized_midthickness_va_file} -var VA ${midthickness_va_file}

	echo "Done creating midthickness Vertex Area (VA) maps for LowResMesh: ${LowResMesh}"

done
done
echo "Done creating midthickness Vertex Area (VA) maps"
