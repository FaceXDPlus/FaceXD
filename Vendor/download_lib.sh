#!/bin/bash
curl --refer ${REFER} https://facexd-dlib-1253814426.cos.ap-chengdu.myqcloud.com/depend.zip -o depend.zip
curl --refer ${REFER} https://facexd-dlib-1253814426.cos.ap-chengdu.myqcloud.com/shape_predictor_68_face_landmarks.dat -o shape_predictor_68_face_landmarks.dat
unzip depend.zip
rm depend.zip
rm -rf __MACOSX

