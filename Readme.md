# BAMCIS Hadoop Docker Containers

This repo contains Hadoop Docker Containers running both Alpine Linux and
Debian Linux using OpenJDK 8.

## Source
The `hadoop-*-base` images all use the `bamcis/ca-*:latest` for their source which includes a CA certificate that can
be used to generate SSL certificates.

## Alpine Linux
The Alpine Linux flavors of these containers requires Hadoop to be compiled from source code in order to correctly
compile the Hadoop native libraries. There are some minor changes required to the source code to get it to compile
correctly and these changes only support the `2.7.x` versions of Hadoop, the `2.8.x+` versions will not compile 
successfully.

## Container Types

There are serveral different versions of the `hadoop-*` containers.

* **hadoop-*-base** - This container has just the Hadoop binaries installed, no configurations to the hadoop environment
  have been performed. This is useful if you are installing another application that just requires the Hadoop jar files.
* **haddoop-*-hdfs** - This container has HDFS setup but does not contain any configurations for MapReduce or YARN. 
* **hadoop-*-pseudo-distributed** - A fully operational pseudo distributed Hadoop setup.
* **hadoop-*** - A container that can run a distributed hadoop cluster.

## Notes

** Do not use anything but characters, numbers, and the hyphen when naming your containers in docker-compose. The master node
name is supplied to the slaves and itself as an environment variable. Hadoop will fail to start if that name contains something
like an underscore `_` or a special character like `&`.

** The distributed and pseudo distributed versions accept a runtime environment variable `HEAPSIZE`. This determines the specific
maximum heap size for each node in the cluster when it starts.