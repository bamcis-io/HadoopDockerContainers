#!/bin/bash	

if ! [[ "${MASTER_NODE}" =~ ^[-a-zA-Z0-9]+$ ]]; then
	echo "The master node host name must only contain letters, numbers, and dashes."
	exit 1
fi

# Start the ssh server
/usr/sbin/sshd

# If slave nodes were defined, then update for distributed mode
# Otherwise, everything should work for pseudo distributed mode
if [ ! -z "${SLAVE_NODES// }" ] || [ ${ROLE,,} = "slave" ]; then

	###########################

	# Update the hdfs-site.xml
	if [ -e "${HADOOP_HOME}/etc/hadoop/hdfs-site.xml.template" ]; then
		su --login "${HADOOP_USER}" --command "/bin/cp -f ${HADOOP_HOME}/etc/hadoop/hdfs-site.xml.template ${HADOOP_HOME}/etc/hadoop/hdfs-site.xml"
	else
		su --login "${HADOOP_USER}" --command "/bin/cp -f ${HADOOP_HOME}/etc/hadoop/hdfs-site.xml ${HADOOP_HOME}/etc/hadoop/hdfs-site.xml.template"
	fi

	sed -i "s|<value>1</value>|<value>${REPLICATION_FACTOR}</value>|" "${HADOOP_HOME}/etc/hadoop/hdfs-site.xml"
	# sed -i "s/{{REPLICATION_FACTOR}}/${REPLICATION_FACTOR}/g" "${HADOOP_HOME}/etc/hadoop/hdfs-site.xml"

	##########################

	# Update the core-site.xml with the master node info
	if [ -e "${HADOOP_HOME}/etc/hadoop/core-site.xml.template" ]; then
		su --login "${HADOOP_USER}" --command "/bin/cp -f ${HADOOP_HOME}/etc/hadoop/core-site.xml.template ${HADOOP_HOME}/etc/hadoop/core-site.xml"
	else
		su --login "${HADOOP_USER}" --command "/bin/cp -f ${HADOOP_HOME}/etc/hadoop/core-site.xml ${HADOOP_HOME}/etc/hadoop/core-site.xml.template"
	fi

	sed -i "s/localhost/${MASTER_NODE}/g" "${HADOOP_HOME}/etc/hadoop/core-site.xml"

	###########################

	# ,, makes it lowercase
	case ${ROLE,,} in
		"master")
			FILE="slaves"

			if [ "${HADOOP_VERSION:0:1}" -ge 3 ]; then
				FILE="workers"
			fi

			# Delete the slaves file
			rm -f "${HADOOP_HOME}/etc/hadoop/${FILE}"

			# Create the slaves file
			su --login "${HADOOP_USER}" --command "touch ${HADOOP_HOME}/etc/hadoop/${FILE}"

			# Split the slave nodes string on the ',' and add each one
			# to the workers file and wait on each node to be accessible over ssh
			while IFS=',' read -ra NODES; do
				for NODE in "${NODES[@]}"; do
					echo "${NODE}" >> "${HADOOP_HOME}/etc/hadoop/${FILE}"

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

			# Start dfs and then execute jps to see what processes are running
			su --login "${HADOOP_USER}" --command "start-dfs.sh"
			su --login "${HADOOP_USER}" --command "jps"
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