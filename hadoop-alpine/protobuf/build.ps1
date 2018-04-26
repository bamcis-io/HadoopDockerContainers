Param(
	[Parameter(Position = 0, ValueFromPipeline = $true)]
	[ValidateNotNullOrEmpty()]
	[System.String]$Version = "2.5.0"
)

docker build ../protobuf -t "bamcis/alpine-protobuf:$Version" --build-arg "PROTOBUF_VERSION=$Version"