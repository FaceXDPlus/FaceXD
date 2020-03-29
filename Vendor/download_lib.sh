#!/bin/bash
curl --refer ${REFER} https://facexd-dlib-1253814426.cos.ap-chengdu.myqcloud.com/depend.zip -o depend.zip
unzip depend.zip
rm depend.zip
rm -rf __MACOSX

