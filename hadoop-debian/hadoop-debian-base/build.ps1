Param(
	[Parameter(Position = 0, ValueFromPipeline = $true)]
	[ValidateNotNullOrEmpty()]
	[System.String]$Version = "3.0.0"
)

docker build ../hadoop-debian-base -t bamcis/hadoop-debian-base:$Version --build-arg HADOOP_VERSION=$Version