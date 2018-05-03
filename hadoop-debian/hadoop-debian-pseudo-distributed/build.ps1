Param(
	[Parameter(Position = 0, ValueFromPipeline = $true)]
	[ValidateNotNullOrEmpty()]
	[System.String]$Version = "2.9.0"
)

& docker build ../hadoop-debian-pseudo-distributed -t "bamcis/hadoop-debian-pseudo-distributed:$Version" -t "bamcis/hadoop-debian-pseudo-distributed:latest" --build-arg "SOURCE=bamcis/hadoop-debian-hdfs:$Version"