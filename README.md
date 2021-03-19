# CaptureNetworkTraceByPowerShell
Network trace capturing script by PowerShell with netsh command.

## Usage

```
Get-NetworkTrace.ps1 [[-SaveFolderPath] <string>] [[-FilePrefix] <string>] [[-FileSwitchInterval] <uint32>] [<CommonParameters>]
```

- __SaveFolderPath__: The trace files (*.etl) are stored in this folder. The default folder path is the current folder path.
- __FilePrefix__: The trace file name prefix. The default prefix is "netcap". The trace file name is like "Prefix-ComputerName-yyyyMMdd-HHmmss-SequenceNumber.etl". e.g. "netcap-WIN10HOST-20180501-233251-000.etl"
- __FileSwitchInterval__: The interval to switch the trace file. The default interval is 24 hours (86,400 seconds).

Example:

```
PS > .\Get-NetworkTrace.ps1 -SaveFolderPath C:\Temp -Verbose

Ctrl+C to finish capture manually.

VERBOSE: Current trace file: C:\Temp\netcap-WIN10HOST-20180501-001049-000.etl
VERBOSE:
Trace configuration:
-------------------------------------------------------------------
Status:             Running
Trace File:         C:\Temp\netcap-WIN10HOST-20180501-001049-000.etl
Append:             Off
Circular:           On
Max Size:           500 MB
Report:             Disabled

VERBOSE: Wait for passed the file switch interval (86400 seconds).

VERBOSE: Merging traces ... done
File location = C:\Temp\netcap-WIN10HOST-20180501-001049-000.etl
Tracing session was successfully stopped.
```

## Related

- [NdisEtl2Pcap](https://github.com/tksh164/NdisEtl2Pcap): Convert from the network trace file (*.etl) to the pcap file.

## License

Copyright (c) 2018-present Takeshi Katano. All rights reserved. This software is released under the [MIT License](https://github.com/tksh164/CaptureNetworkTraceByPowerShell/blob/master/LICENSE).

Disclaimer: The codes stored herein are my own personal codes and do not related my employer's any way.
