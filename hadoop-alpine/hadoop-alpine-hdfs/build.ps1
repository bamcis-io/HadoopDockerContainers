Param(
	[Parameter(Position = 0, ValueFromPipeline = $true)]
	[ValidateNotNullOrEmpty()]
	[System.String]$Version = "2.7.6"
)

& docker build ../hadoop-alpine-hdfs -t "bamcis/hadoop-alpine-hdfs:$Version" -t "bamcis/hadoop-alpine-hdfs:latest" --build-arg "SOURCE=bamcis/hadoop-alpine-base:$Version"