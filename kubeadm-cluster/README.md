Check available vm-sizes per region:
```bash
az vm list-sizes --location "southcentralus" -o table |less
```

Check available skus and policies:
```bash
az vm list-skus --location "southcentralus" -o table |grep -Ei "Standard" |grep -Ei "None" |grep -Ei "D2" |less
```

or check the available vms directly on Azure Portal.

Check cloud-init logs:
```bash
sudo cloud-init status --long
sudo cat /var/log/cloud-init-output.log
```