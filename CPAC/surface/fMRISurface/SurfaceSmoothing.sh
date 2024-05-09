#!/bin/bash

# Human Connectome Project [Pipelines][Pipelines] = THIS SOFTWARE

# Copyright (c) 2011-2014 [The Human Connectome Project][HCP]

# Redistribution and use in source and binary forms, with or without modification,
# is permitted provided that the following conditions are met:

# * Redistributions of source code must retain the above copyright notice,
#   this list of conditions, and the following disclaimer.

# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions, and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.

# * The names of Washington University in St. Louis, the University of Minnesota,
#   Oxford University, the Human Connectome Project, or any contributors
#   to this software may *not* be used to endorse or promote products derived
#   from this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
# OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
# EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# <!-- References -->

# [HCP]: http://www.humanconnectome.org
# [Pipelines]: https://github.com/Washington-University/Pipelines

# Source: https://github.com/DCAN-Labs/DCAN-HCP/blob/32254dc/fMRISurface/scripts/SurfaceSmoothing.sh

# Modifications copyright (C) 2021 - 2024  C-PAC Developers
# This file is part of C-PAC.

set -e
echo -e "\n START: SurfaceSmoothing"

NameOffMRI="$1"
Subject="$2"
DownSampleFolder="$3"
LowResMesh="$4"
SmoothingFWHM="$5"

Sigma=`echo "$SmoothingFWHM / ( 2 * ( sqrt ( 2 * l ( 2 ) ) ) )" | bc -l`


for Hemisphere in L R ; do
  wb_command -metric-smoothing "$DownSampleFolder"/"$Subject"."$Hemisphere".midthickness."$LowResMesh"k_fs_LR.surf.gii "$NameOffMRI"."$Hemisphere".atlasroi."$LowResMesh"k_fs_LR.func.gii "$Sigma" "$NameOffMRI"_s"$SmoothingFWHM".atlasroi."$Hemisphere"."$LowResMesh"k_fs_LR.func.gii -roi "$DownSampleFolder"/"$Subject"."$Hemisphere".atlasroi."$LowResMesh"k_fs_LR.shape.gii
done

echo " END: SurfaceSmoothing"
