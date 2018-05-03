Param(
	[Parameter(Position = 0, ValueFromPipeline = $true)]
	[ValidateNotNullOrEmpty()]
	[System.String]$Version = "2.9.0"
)

& docker build ../hadoop-debian -t "bamcis/hadoop-debian:$Version" -t "bamcis/hadoop-debian:latest" --build-arg "SOURCE=bamcis/hadoop-debian-hdfs:$Version"