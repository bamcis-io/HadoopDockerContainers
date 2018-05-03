Param(
	[Parameter(Position = 0, ValueFromPipeline = $true)]
	[ValidateNotNullOrEmpty()]
	[System.String]$Version = "2.9.0"
)

& docker build ../hadoop-debian-hdfs -t "bamcis/hadoop-debian-hdfs:$Version" -t "bamcis/hadoop-debian-hdfs:latest" --build-arg "SOURCE=bamcis/hadoop-debian-base:$Version"