#!/bin/bash

LOCATION="$1"

# There are still additional errors that prevent Hadoop from compiling that are not addressed here yet

# ERROR: 'sys_nerr' undeclared (first use in this function)
sed -ri 's/^#if defined\(__sun\)/#if 1/g' "${LOCATION}"/hadoop-common-project/hadoop-common/src/main/native/src/exception.c
	
# ERROR: undefined reference to fts_* 
sed -ri 's/^( *container)/\1\n    fts/g' "${LOCATION}"/hadoop-yarn-project/hadoop-yarn/hadoop-yarn-server/hadoop-yarn-server-nodemanager/src/CMakeLists.txt
    
# WARNING: implicit declaration of function 'setnetgrent'
sed -ri 's/^(.*JniBasedUnixGroupsNetgroupMapping.c)/#\1/g' "${LOCATION}"/hadoop-common-project/hadoop-common/src/CMakeLists.txt

 # FATAL ERROR: rpc/types.h: No such file or directory
sed -ri 's|^(include_directories.*)|\1\n    /usr/include/tirpc|' "${LOCATION}"/hadoop-tools/hadoop-pipes/src/CMakeLists.txt 
sed -ri 's/^( *pthread)/\1\n    tirpc/g' "${LOCATION}"/hadoop-tools/hadoop-pipes/src/CMakeLists.txt