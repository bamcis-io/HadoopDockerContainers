#!/bin/bash

# Adjust the heap size
if [ "${HEAPSIZE}" -gt 0 ]; then 
	
	if grep -q -e "^.*export\s\+HADOOP_HEAPSIZE\s*=" "${HADOOP_HOME}/etc/hadoop/hadoop-env.sh"; then
		sed -i "s|^.*export\s\+HADOOP_HEAPSIZE.*|export HADOOP_HEAPSIZE=${HEAPSIZE}|g" "${HADOOP_HOME}/etc/hadoop/hadoop-env.sh"
	else 	
		echo "export HADOOP_HEAPSIZE=${HEAPSIZE}" >> "${HADOOP_HOME}/etc/hadoop/hadoop-env.sh"		
	fi
		
	if grep -q -e "^.*export\s\+HADOOP_NAMENODE_INIT_HEAPSIZE\s*=" "${HADOOP_HOME}/etc/hadoop/hadoop-env.sh"; then 
		sed -i "s|^.*export\s\+HADOOP_NAMENODE_INIT_HEAPSIZE.*|export HADOOP_NAMENODE_INIT_HEAPSIZE=${HEAPSIZE}|g" "${HADOOP_HOME}/etc/hadoop/hadoop-env.sh"
	else 
		echo "export HADOOP_NAMENODE_INIT_HEAPSIZE=${HEAPSIZE}" >> "${HADOOP_HOME}/etc/hadoop/hadoop-env.sh"
	fi
		
	sed -i "s|^.*export\s\+HADOOP_JOB_HISTORYSERVER_HEAPSIZE.*|export HADOOP_JOB_HISTORYSERVER_HEAPSIZE=${HEAPSIZE}|g" "${HADOOP_HOME}/etc/hadoop/mapred-env.sh"
		
	# No else here since the mapred-env.sh uses logic to export the value and if we didn't find it, then
	# that value is missing, i.e.
	# if [ "$HADOOP_JOB_HISTORYSERVER_HEAPSIZE" = "" ]; then
	#   export HADOOP_JOB_HISTORYSERVER_HEAPSIZE=1000
	# fi
	# Don't do this one globally since the script assigns to JAVA_HEAP_MAX later
	sed -i "s/^#\?\s*JAVA_HEAP_MAX=.*/JAVA_HEAP_MAX=-Xmx${HEAPSIZE}m/" "${HADOOP_HOME}/etc/hadoop/yarn-env.sh"
	sed -i "s/^#\?\s*YARN_HEAPSIZE=.*/YARN_HEAPSIZE=${HEAPSIZE}/" "${HADOOP_HOME}/etc/hadoop/yarn-env.sh"

	cat "${HADOOP_HOME}/etc/hadoop/hadoop-env.sh"
	cat "${HADOOP_HOME}/etc/hadoop/mapred-env.sh"
	cat "${HADOOP_HOME}/etc/hadoop/yarn-env.sh"
fi

# Start the ssh server
/usr/sbin/sshd

# Start dfs and then execute jps to see what processes are running
su --login "${HADOOP_USER}" --command "start-dfs.sh"
su --login "${HADOOP_USER}" --command "start-yarn.sh"
su --login "${HADOOP_USER}" --command "mr-jobhistory-daemon.sh start historyserver"
su --login "${HADOOP_USER}" --command "jps"

# Do something in the foreground to keep the container running
# Trap any TERM INT and execute "true"
trap true TERM INT
tail -f /dev/null