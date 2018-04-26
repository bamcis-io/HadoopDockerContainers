Param(
	[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
	[ValidateNotNullOrEmpty()]
	[System.String]$Version
)

docker build ../hadoop-alpine-base -t "bamcis/hadoop-alpine-base:$Version" --build-arg HADOOP_VERSION=$Version