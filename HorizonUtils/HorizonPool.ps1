
# Released under MIT License

# Author: Narendran Jothiram

# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

function HorizonPool
{
  param
  (
    [string]$PoolName,
    [switch]$disable,
    [switch]$enable,
    [switch]$help,
    [switch]$verbose
  )
  $currentuser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
  $principals = New-Object System.Security.Principal.WindowsPrincipal($currentuser)
  if (-not($principals.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))) {
     Write-Host  -ForegroundColor Red "This script requires elevated privileges to run. Please check if current user has Administrator privilege."
     return
  }
  if($help) {
     Write-Host -ForegroundColor Green "Usage:"
     Write-Host -ForegroundColor Green "    HorizonPool -PoolName `"NotePadPlusPlus`" -enable "
     Write-Host -ForegroundColor Green "    HorizonPool -PoolName `"Windows10`" -disable "
     return
  }
  If(-not($PoolName) -OR $PoolName -like $Null){
    Write-Output "PoolName is mandatory!"
    Write-Output "Example Usage: HorizonPool -PoolName `"NotePadPlusPlus`" -enable "
    return
  }
  if(-not($disable) -AND -not($enable)) {
     Write-Output "Please use -enable or -disable to take an action on horizon pool!"
     Write-Output "Example Usage to Disable: HorizonPool -PoolName `"NotePadPlusPlus`" -disable "
     return
  }
  $dn = [System.String]::Concat("CN=",$PoolName,",OU=Applications,DC=vdi,DC=vmware,DC=int")
  $paeDisable = 0;
  $disableString = "Disabled";
  if ($disable) {
      $paeDisable = 1;
      $disableString = "Disabled";
  }
  if ($enable) {
      $paeDisable = 0;
      $disableString = "Enabled";
  }
  
  try {
      $adObject = Get-ADObject -Filter {distinguishedName -eq $dn} -Server localhost -SearchScope OneLevel -Properties 'pae-Disabled' -SearchBase "OU=Applications,DC=vdi,DC=vmware,DC=int"
      if($adObject.objectClass -eq "pae-DesktopApplication" -OR $adObject.objectClass -eq "pae-RDSApplication") {
        Set-ADObject -Identity $dn -Server localhost -Partition "DC=vdi,DC=vmware,DC=int" -Replace @{'pae-Disabled'=$paeDisable}
      } else {
          Write-Host -ForegroundColor Red "`"$PoolName`" is not an Horizon Desktop or Application Pool!"
          return
      }
  } catch [Exception] {
      
      if($verbose) {
          echo $_.Exception|format-list -force
      }
      Write-Host -ForegroundColor Red "Horizon Pool with name `"$PoolName`" not found!"
      return
  }
  try {
      Get-ADObject -Filter {distinguishedName -eq $dn -AND pae-Disabled -eq $paeDisable} -Server localhost -SearchScope OneLevel -Properties 'pae-Disabled' -SearchBase "OU=Applications,DC=vdi,DC=vmware,DC=int" | Select-Object -Property Name,pae-Disabled |  Format-Table -Property @{L=’Pool Name’;E={$_.'Name'}}, @{L=’Disabled’;E={$_.'pae-Disabled'}} -AutoSize
      Write-Host -ForegroundColor Green "Pool status updated as $disableString"
      return
  } catch [Exception] {
      if($verbose) {
          echo $_.Exception|format-list -force
      }
      Write-Host -ForegroundColor Red "Failed to update Horizon Pool $PoolName!"
      return
  }

}



