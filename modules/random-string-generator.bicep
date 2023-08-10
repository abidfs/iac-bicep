// param Location string = resourceGroup().location
// param UtcNow string = utcNow()
// param DeploymentScriptName string = newGuid()

// var scriptContent = '''
//   function Shuffle-String([string]$inputString) {
//     $charArray = $inputString.ToCharArray()
//     $rng = New-Object System.Random
//     $remainingChars = $charArray.length
//     while ($remainingChars -gt 1) {
//         $remainingChars--
//         $charIndex = $rng.Next($remainingChars + 1)
//         $value = $charArray[$charIndex]
//         $charArray[$charIndex] = $charArray[$remainingChars]
//         $charArray[$remainingChars] = $value
//     }
//     return -join $charArray
//   }

//   function Create-Password() {
//     $TokenSet = @{
//           U = [Char[]]'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
//           L = [Char[]]'abcdefghijklmnopqrstuvwxyz'
//           N = [Char[]]'0123456789'
//           S = [Char[]]'!"#$%&''()*+,-./:;<=>?@[\]^_`{|}~'
//     }

//     $Upper = Get-Random -Count 5 -InputObject $TokenSet.U
//     $Lower = Get-Random -Count 5 -InputObject $TokenSet.L
//     $Number = Get-Random -Count 5 -InputObject $TokenSet.N
//     $Special = Get-Random -Count 5 -InputObject $TokenSet.S
//     $Combined = ($Upper + $Lower + $Number + $Special) -join ''

//     return Shuffle-String $Combined
//   }

//   $DeploymentScriptOutputs = @{}
//   $DeploymentScriptOutputs['password'] = Create-Password
// '''

// resource DeploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
//   name: 'module-random-string-generator'
//   kind: 'AzurePowerShell'
//   location: location
//   identity: {}
//   properties: {
//     forceUpdateTag: UtcNow
//     azPowerShellVersion: '6.4'
//     scriptContent: scriptContent
//     timeout: 'PT15M'
//     cleanupPreference: 'Always'
//     retentionInterval: 'PT1H'
//     arguments: ''
//   }
// }
