Param(
	[Parameter(Position = 0, ValueFromPipeline = $true)]
	[ValidateNotNullOrEmpty()]
	[System.String]$Version = "2.9.0"
)

docker build ../hadoop-debian-base -t bamcis/hadoop-debian-base:$Version -t bamcis/hadoop-debian-base:latest --build-arg HADOOP_VERSION=$Version