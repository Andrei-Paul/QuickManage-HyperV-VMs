# QuickManage-HyperV-VMs
Easily -Create / -Update / -Destroy HyperV VMs for tests that require multiple such cycles done easy and fast.

# $default
$default contains all the fields that will be taken into account when processing the VMs.
  $null can be used for fields that do not have a default value ( Name, MACAddress )

# $Nodes
$Nodes contains the actual VMs description.
  Any ammount of VMs can be added.
  Only fields that differ in value from the defaults need to be added.
  
# Calling
  ## Create VMs as described by $Nodes and $defaults:
  ```powershell
  ManageVMs.ps1 -Create
  ```

  ## Updates VMs as described by $Nodes and $defaults, after values in $Nodes and $defaults have been manually changed in ManageVMs.ps1
  ```powershell
  ManageVMs.ps1 -Update
  ```

  ## Destroy VMs as described by $Nodes and $defaults. Does not remove all empty directories.
  ```powershell
  ManageVMs.ps1 -Destroy
  ```
  
  ## Destroy VMs as described by $Nodes and $defaults. Does not remove disks described by $Nodes and $defaults. Does not remove all empty directories.
  ```powershell
  ManageVMs.ps1 -Destroy -KeepDisks
  ```
