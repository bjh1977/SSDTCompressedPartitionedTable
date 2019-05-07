
cls

#Install-Module PoshSSDTBuildDeploy -Force
#Import-Module PoshSSDTBuildDeploy -Force


$dacfxPath = 'C:\Program Files\Microsoft SQL Server\140\DAC\bin\Microsoft.SqlServer.Dac.dll'

$connectionString="Data Source=.;Integrated Security=True;"

$targetDatabaseName = 'PartitionPlay'

$DacDeployOptions = @{'IncludeCompositeObjects'=$False;
                        'IgnoreObjectPlacementOnPartitionScheme'=$false; 
                        'IgnorePartitionSchemes'=$false; 
                        #'ExcludePartitionSchemes'=$true;    !!!! cannot set - this breaks PoshSSDTBuildDeploy !!!
                        #'ExcludePartitionFunctions'=$true;  !!!! cannot set - this breaks PoshSSDTBuildDeploy !!!
                        #'IgnoreIndexOptions'=$true;
                        #'IgnoreTableOptions'=$true 
                        }


Write-Host "PUBLISH XML:`n-------------------------------" -ForegroundColor Green
Write-Host "$(Get-Content "$PSScriptRoot\PartitionPlay\bin\Debug\PartitionPlay.publish.xml" -raw)`n`n " -ForegroundColor Green

$result = Publish-DatabaseDeployment -dacpac "$PSScriptRoot\PartitionPlay\bin\Debug\PartitionPlay.dacpac" `
                                     -publishXml "$PSScriptRoot\PartitionPlay\bin\Debug\PartitionPlay.publish.xml" `
                                     -targetConnectionString $connectionString `
                                     -targetDatabaseName $targetDatabaseName `
                                     -dacfxPath $dacfxPath `
                                     -ScriptPath 'c:\temp\' `
                                     -GenerateDeploymentScript $true `
                                     -dacDeployOptions $DacDeployOptions #-ScriptOnly $true



#Open deploy script in code 
#code $result.DatabaseScriptPath



