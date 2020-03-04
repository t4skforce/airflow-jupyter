#!/bin/bash
export CONFIG_PATH={{env.CONFIG_PATH|default('/config',true)}}
export CONDA_DIR={{env.CONDA_DIR|default('/opt/conda',true)}}
export PATH=$CONDA_DIR/bin:/dotnet/tools/:$PATH
