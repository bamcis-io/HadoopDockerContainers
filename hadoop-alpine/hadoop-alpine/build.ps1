Param(
	[Parameter(Position = 0, ValueFromPipeline = $true)]
	[ValidateNotNullOrEmpty()]
	[System.String]$Version = "2.7.6"
)

& docker build ../hadoop-alpine -t "bamcis/hadoop-alpine:$Version" -t "bamcis/hadoop-alpine:latest" --build-arg "SOURCE=bamcis/hadoop-alpine-hdfs:$Version"