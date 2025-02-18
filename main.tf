module "resourceGroup" {
  source   = "./modules/resourceGroup"
  for_each = var.resourceGroup
  rgName   = each.value["rgName"]
  location = each.value["location"]
}

module "vnet" {
  source                   = "./modules/vnet"
  depends_on               = [module.resourceGroup]
  for_each                 = var.vnet
  namePrefix               = each.value["namePrefix"]
  rgName                   = each.value["rgName"]
  vnetAddressPrefix        = each.value["vnetAddressPrefix"]
  vnetName                 = each.value["name"]
  vnetLocation             = each.value["vnetLocation"]
  gatewayAvailabilityZones = each.value["gatewayAvailabilityZones"]
  subnets                  = each.value["subnets"]
  privateDnsName           = each.value.privateDns.name
  offering                 = each.value.privateDns.offering
  appGwFrontendIpName      = each.value.publicIp.name
  location                 = each.value.publicIp.location
}

module "aksCluster" {
  source                = "./modules/aksCluster"
  depends_on            = [module.resourceGroup, module.vnet]
  subnet_id             = lookup(lookup(lookup(lookup(module.vnet, each.value["vnet_ref"], null), "subnets", null), each.value["subnet_ref"], null), "subnetId", null)
  resourceGroupId       = lookup(lookup(module.resourceGroup, each.value["resourceGroup_ref"], null), "resourceGroupId", null)
  for_each              = var.aksCluster
  clientId              = var.clientId
  CLIENT_SECRET         = var.CLIENT_SECRET
  rgName                = each.value["rgName"]
  location              = each.value["location"]
  nodePools             = each.value["nodePools"]
  kubernetesVersion     = each.value["kubernetesVersion"]
  namePrefix            = each.value["namePrefix"]
  defaultNodePool       = each.value["defaultNodePool"]
  aksAuthorizedIpRanges = each.value.aksAuthorizedIpRanges
  additionalAksIpRanges = each.value.additionalAksIpRanges
  localAccountDisable   = each.value.localAccountDisable
}

module "waf" {
  source          = "./modules/waf"
  depends_on      = [module.resourceGroup]
  for_each        = var.waf
  namePrefix      = each.value["namePrefix"]
  rgName          = each.value["rgName"]
  location        = each.value["location"]
  clientIp        = each.value["clientIp"]
  customWafDomain = each.value["customWafDomain"]
  policyName      = each.value["name"]
}

module "logAnalyticsWorkspace" {
  source          = "./modules/logAnalyticsWorkspace"
  depends_on      = [module.resourceGroup]
  for_each        = var.logAnalyticsWorkspace
  namePrefix      = each.value["namePrefix"]
  rgName          = each.value["rgName"]
  location        = each.value["location"]
  sku             = each.value["sku"]
  retentionInDays = each.value["retentionInDays"]
}

module "webGateway" {
  source                   = "./modules/webGateway"
  depends_on               = [module.resourceGroup, module.vnet, module.waf]
  subnet_id                = lookup(lookup(lookup(lookup(module.vnet, each.value["vnet_ref"], null), "subnets", null), each.value["subnet_ref"], null), "subnetId", null)
  wafPolicyId              = lookup(lookup(module.waf, each.value["wafPolicy_ref"], null), "wafPolicyId", null)
  appGwFrontendIpId        = lookup(lookup(module.vnet, each.value["vnet_ref"], null), "appGwFrontendIpId", null)
  storageAccountId         = lookup(lookup(module.storageAccount, each.value["storageAccount_ref"], null), "storageAccountId", null)
  logAnalyticsWorkspaceId  = lookup(lookup(module.logAnalyticsWorkspace, each.value["logAnalyticsWorkspace_ref"], null), "logWorkspaceId", null)
  for_each                 = var.webGateway
  namePrefix               = each.value["namePrefix"]
  rgName                   = each.value["rgName"]
  location                 = each.value["location"]
  appG_autoScale           = each.value["appG_autoScale"]
  upperLimit               = each.value["upperLimit"]
  lowerLimit               = each.value["lowerLimit"]
  size                     = each.value["size"]
  sku                      = each.value["sku"]
  sslPfxCertFile           = each.value["sslPfxCertFile"]
  sslPfxCertFileMtls       = each.value["sslPfxCertFileMtls"]
  gatewayAvailabilityZones = each.value["gatewayAvailabilityZones"]
  mtlsEnabled              = each.value["mtlsEnabled"]
  clientIp                 = each.value["clientIp"]
  disabledRuleGroups       = each.value["disabledRuleGroups"]
  waf                      = each.value["waf"]
}

module "storageAccount" {
  source              = "./modules/storageAccount"
  depends_on          = [module.resourceGroup, module.vnet]
  for_each            = var.storageAccount
  namePrefix          = each.value["namePrefix"]
  rgName              = each.value["rgName"]
  location            = each.value["location"]
  nodeSubnetIds       = lookup(lookup(lookup(lookup(module.vnet, each.value["vnet_ref"], null), "subnets", null), each.value["subnet_ref"], null), "subnetId", null)
  logsSARetentionTime = each.value["logsSARetentionTime"]
  storageAccountName  = each.value["name"]
  access_tier         = each.value["access_tier"]
  rule                = each.value.rule.name
}

module "securityGroup" {
  source     = "./modules/securityGroup"
  depends_on = [module.resourceGroup, module.vnet]
  for_each   = var.securityGroup
  namePrefix = each.value["namePrefix"]
  rgName     = each.value["rgName"]
  location   = each.value["location"]
  name       = each.value["name"]
}
