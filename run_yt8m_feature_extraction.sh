#!/bin/bash
# Example usage (absolute path)
#  ./run_yt8m_feature_extraction.sh /root/test.mp4 /tmp/
INPUT_FILE=$1
OUTPUT_DIR=$2

MEDIAPIPE_DIR="/home/ec2-user/mediapipe"
DOCKER_MEDIAPIPE_DIR="/mediapipe"
TEMP_NAME=$RANDOM

mkdir -p ${OUTPUT_DIR}

#############################################
# Outside docker call
#############################################
docker start mediapipe
docker ps
retVal=$?
if [ $retVal -eq 0 ]; then
  echo "======================================================="
  echo "Calling docker exec"
  echo "======================================================="
  docker cp ${MEDIAPIPE_DIR}/run_yt8m_feature_extraction.sh mediapipe:${DOCKER_MEDIAPIPE_DIR}
  docker cp $INPUT_FILE mediapipe:/root/${TEMP_NAME}.mp4
  docker exec mediapipe ${DOCKER_MEDIAPIPE_DIR}/run_yt8m_feature_extraction.sh /root/${TEMP_NAME}.mp4 /root/yt8m_feature_output_${TEMP_NAME}
  docker cp mediapipe:/root/yt8m_feature_output_${TEMP_NAME}/metadata.pb ${OUTPUT_DIR}/metadata.pb
  docker cp mediapipe:/root/yt8m_feature_output_${TEMP_NAME}/features.pb ${OUTPUT_DIR}/features.pb
  docker exec mediapipe rm -rf /root/${TEMP_NAME}.mp4
  docker exec mediapipe rm -rf /root/yt8m_feature_output_${TEMP_NAME}
  exit 0
fi



############################################
# Command run inside docker
############################################
echo "===================================================="
echo "Run mediapipe in docker"
echo "===================================================="

curDir=$(pwd)
cd $DOCKER_MEDIAPIPE_DIR

python -m mediapipe.examples.desktop.youtube8m.generate_input_sequence_example \
  --path_to_input_video=${INPUT_FILE} \
  --clip_end_time_sec=21

GLOG_logtostderr=1 /mediapipe/bazel-bin/mediapipe/examples/desktop/youtube8m/extract_yt8m_features \
  --calculator_graph_config_file=mediapipe/graphs/youtube8m/feature_extraction.pbtxt \
  --input_side_packets=input_sequence_example=/tmp/mediapipe/metadata.pb  \
  --output_side_packets=output_sequence_example=${OUTPUT_DIR}/features.pb

cd $curDIR

cp /tmp/mediapipe/metadata.pb ${OUTPUT_DIR}/metadata.pb
