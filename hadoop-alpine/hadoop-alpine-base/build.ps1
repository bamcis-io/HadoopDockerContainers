Param(
	[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
	[ValidateNotNullOrEmpty()]
	[System.String]$Version
)

$Cleanup = "$($Version.Remove($Version.Length - 1))x"

docker build ../hadoop-alpine-base -t "bamcis/hadoop-alpine-base:$Version" -t "bamcis/hadoop-alpine-base:latest" --build-arg HADOOP_VERSION=$Version --build-arg CLEANUP_FOLDER=$Cleanup