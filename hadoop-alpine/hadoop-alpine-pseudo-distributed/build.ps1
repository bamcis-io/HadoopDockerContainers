Param(
	[Parameter(Position = 0, ValueFromPipeline = $true)]
	[ValidateNotNullOrEmpty()]
	[System.String]$Version = "2.7.6"
)

& docker build ../hadoop-alpine-pseudo-distributed -t "bamcis/hadoop-alpine-pseudo-distributed:$Version" -t "bamcis/hadoop-alpine-pseudo-distributed:latest" --build-arg "SOURCE=bamcis/hadoop-alpine-hdfs:$Version"