#!/bin/bash	

if ! [[ "${MASTER_NODE}" =~ ^[-a-zA-Z0-9]+$ ]]; then
	echo "The master node host name must only contain letters, numbers, and dashes."
	exit 1
fi

# Adjust the heap size
if [ "${HEAPSIZE}" -gt 0 ]; then 
	
	if grep -q -e "^.*export\s\+HADOOP_HEAPSIZE\s*=" "${HADOOP_HOME}/etc/hadoop/hadoop-env.sh"; then
		su-exec "${HADOOP_USER}" sed -i "s|^.*export\s\+HADOOP_HEAPSIZE.*|export HADOOP_HEAPSIZE=${HEAPSIZE}|g" "${HADOOP_HOME}/etc/hadoop/hadoop-env.sh"
	else 	
		su-exec "${HADOOP_USER}" echo "export HADOOP_HEAPSIZE=${HEAPSIZE}" >> "${HADOOP_HOME}/etc/hadoop/hadoop-env.sh"		
	fi
		
	if grep -q -e "^.*export\s\+HADOOP_NAMENODE_INIT_HEAPSIZE\s*=" "${HADOOP_HOME}/etc/hadoop/hadoop-env.sh"; then 
		su-exec "${HADOOP_USER}" sed -i "s|^.*export\s\+HADOOP_NAMENODE_INIT_HEAPSIZE.*|export HADOOP_NAMENODE_INIT_HEAPSIZE=${HEAPSIZE}|g" "${HADOOP_HOME}/etc/hadoop/hadoop-env.sh"
	else 
		su-exec "${HADOOP_USER}" echo "export HADOOP_NAMENODE_INIT_HEAPSIZE=${HEAPSIZE}" >> "${HADOOP_HOME}/etc/hadoop/hadoop-env.sh"
	fi
		
	su-exec "${HADOOP_USER}" sed -i "s|^.*export\s\+HADOOP_JOB_HISTORYSERVER_HEAPSIZE.*|export HADOOP_JOB_HISTORYSERVER_HEAPSIZE=${HEAPSIZE}|g" "${HADOOP_HOME}/etc/hadoop/mapred-env.sh"
		
	# No else here since the mapred-env.sh uses logic to export the value and if we didn't find it, then
	# that value is missing, i.e.
	# if [ "$HADOOP_JOB_HISTORYSERVER_HEAPSIZE" = "" ]; then
	#   export HADOOP_JOB_HISTORYSERVER_HEAPSIZE=1000
	# fi
	# Don't do this one globally since the script assigns to JAVA_HEAP_MAX later
	su-exec "${HADOOP_USER}" sed -i "s/^#\?\s*JAVA_HEAP_MAX=.*/JAVA_HEAP_MAX=-Xmx${HEAPSIZE}m/" "${HADOOP_HOME}/etc/hadoop/yarn-env.sh"
	su-exec "${HADOOP_USER}" sed -i "s/^#\?\s*YARN_HEAPSIZE=.*/YARN_HEAPSIZE=${HEAPSIZE}/" "${HADOOP_HOME}/etc/hadoop/yarn-env.sh"

	cat "${HADOOP_HOME}/etc/hadoop/hadoop-env.sh"
	cat "${HADOOP_HOME}/etc/hadoop/mapred-env.sh"
	cat "${HADOOP_HOME}/etc/hadoop/yarn-env.sh"
fi

# Start the ssh server
/usr/sbin/sshd

# If slave nodes were defined, then update for distributed mode
# Otherwise, everything should work for pseudo distributed mode
if [ ! -z "${SLAVE_NODES// }" ] || [ ${ROLE,,} = "slave" ]; then

	###########################

	# Update the hdfs-site.xml
	if [ -e "${HADOOP_HOME}/etc/hadoop/hdfs-site.xml.template" ]; then
		su-exec "${HADOOP_USER}" /bin/cp -f "${HADOOP_HOME}/etc/hadoop/hdfs-site.xml.template" "${HADOOP_HOME}/etc/hadoop/hdfs-site.xml"
	else
		su-exec "${HADOOP_USER}" /bin/cp -f "${HADOOP_HOME}/etc/hadoop/hdfs-site.xml" "${HADOOP_HOME}/etc/hadoop/hdfs-site.xml.template"
	fi

	su-exec "${HADOOP_USER}" sed -i "s|<value>1</value>|<value>${REPLICATION_FACTOR}</value>|" "${HADOOP_HOME}/etc/hadoop/hdfs-site.xml"
	# sed -i "s/{{REPLICATION_FACTOR}}/${REPLICATION_FACTOR}/g" "${HADOOP_HOME}/etc/hadoop/hdfs-site.xml"

	##########################

	# Update the core-site.xml with the master node info
	if [ -e "${HADOOP_HOME}/etc/hadoop/core-site.xml.template" ]; then
		su-exec "${HADOOP_USER}" /bin/cp -f "${HADOOP_HOME}/etc/hadoop/core-site.xml.template" "${HADOOP_HOME}/etc/hadoop/core-site.xml"
	else
		su-exec "${HADOOP_USER}" /bin/cp -f "${HADOOP_HOME}/etc/hadoop/core-site.xml" "${HADOOP_HOME}/etc/hadoop/core-site.xml.template"
	fi

	su-exec "${HADOOP_USER}" sed -i "s/localhost/${MASTER_NODE}/g" "${HADOOP_HOME}/etc/hadoop/core-site.xml"

	###########################

	# Update the yarn-site.xml with the master node info
	if [ -e "${HADOOP_HOME}/etc/hadoop/core-site.xml.template" ]; then
		su-exec "${HADOOP_USER}" /bin/cp -f "${HADOOP_HOME}/etc/hadoop/core-site.xml.template" "${HADOOP_HOME}/etc/hadoop/yarn-site.xml"
	else
		su-exec "${HADOOP_USER}" /bin/cp -f "${HADOOP_HOME}/etc/hadoop/core-site.xml" "${HADOOP_HOME}/etc/hadoop/yarn-site.xml.template"
	fi

	su-exec "${HADOOP_USER}" sed -i "s/localhost/${MASTER_NODE}/g" "${HADOOP_HOME}/etc/hadoop/yarn-site.xml"

	###########################

	# ,, makes it lowercase
	case ${ROLE,,} in
		"master")
			FILE="slaves"

			if [ "${HADOOP_VERSION:0:1}" -ge 3 ]; then
				FILE="workers"
			fi

			# Delete the slaves file
			su-exec "${HADOOP_USER}" rm -f "${HADOOP_HOME}/etc/hadoop/${FILE}"

			# Create the slaves file
			su-exec "${HADOOP_USER}" touch "${HADOOP_HOME}/etc/hadoop/${FILE}"

			# Split the slave nodes string on the ',' and add each one
			# to the workers file and wait on each node to be accessible over ssh
			while IFS=',' read -ra NODES; do
				for NODE in "${NODES[@]}"; do
					su-exec "${HADOOP_USER}" echo "${NODE}" >> "${HADOOP_HOME}/etc/hadoop/${FILE}"

					if ! grep -q -e "^${NODE}" "/home/${HADOOP_USER}/.ssh/known_hosts"; then
						KEY=$(cat /etc/ssh/ssh_host_rsa_key.pub)
						echo -e "Adding:\n${NODE} ${KEY}"
						echo "${NODE} ${KEY}" >> /home/"${HADOOP_USER}"/.ssh/known_hosts
					fi

					# Make sure each slave node is online before we try and configure them
					until nc -z -v -w60 "${NODE}" 22
					do	
						echo "Waiting for slave node ${NODE} to be available on port 22..."
						# Wait 5 seconds before checking again
						sleep 5
					done
				done
			done <<< "${SLAVE_NODES}"

			# Start dfs, yarn, and job history server and then execute jps to see what processes are running
			su-exec "${HADOOP_USER}" start-dfs.sh
			su-exec "${HADOOP_USER}" start-yarn.sh
			su-exec "${HADOOP_USER}" mr-jobhistory-daemon.sh start historyserver
			su-exec "${HADOOP_USER}" jps
		;;
		"slave" | *)
			echo "Slave node ${HOSTNAME} online."
		;;
	esac
fi

###########################

# Do something in the foreground to keep the container running
# Trap any TERM INT and execute "true"
trap true TERM INT
tail -f /dev/null