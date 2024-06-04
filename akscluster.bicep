@description('Name of the AKS Cluster')
param aksClusterName string

@description('DNS Zone name')
param dnsZoneName string

@description('DNS Zone Resource Group')
param dnsZoneResourceGroup string

@description('Location for the resources')
param location string = resourceGroup().location

@description('AKS node count')
param nodeCount int = 1

@description('AKS node VM size')
param vmSize string = 'Standard_DS2_v2'

@description('AKS DNS name prefix')
param dnsNamePrefix string

@description('Client ID of the Service Principal')
param clientId string

@description('Client Secret of the Service Principal')
param clientSecret string

@description('SSH RSA public key for the Linux VM')
param sshRSAPublicKey string

resource dnsZone 'Microsoft.Network/dnsZones@2018-05-01' = {
  name: dnsZoneName
  scope: resourceGroup(dnsZoneResourceGroup)
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: '${aksClusterName}-publicIP'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: dnsNamePrefix
    }
  }
}

resource aksCluster 'Microsoft.ContainerService/managedClusters@2021-03-01' = {
  name: aksClusterName
  location: location
  properties: {
    dnsPrefix: dnsNamePrefix
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: nodeCount
        vmSize: vmSize
        osType: 'Linux'
      }
    ]
    linuxProfile: {
      adminUsername: 'azureuser'
      ssh: {
        publicKeys: [
          {
            keyData: sshRSAPublicKey
          }
        ]
      }
    }
    servicePrincipalProfile: {
      clientId: clientId
      secret: clientSecret
    }
    networkProfile: {
      networkPlugin: 'azure'
    }
  }
  dependsOn: [
    publicIP
  ]
}

resource dnsARecord 'Microsoft.Network/dnsZones/A@2018-05-01' = {
  name: '${dnsZone.name}/www'
  scope: resourceGroup(dnsZoneResourceGroup)
  properties: {
    TTL: 3600
    ARecords: [
      {
        ipv4Address: publicIP.properties.ipAddress
      }
    ]
  }
  dependsOn: [
    dnsZone
    publicIP
  ]
}

output aksClusterFqdn string = aksCluster.properties.fqdn
output publicIpAddress string = publicIP.properties.ipAddress
output dnsZoneName string = dnsZone.name
