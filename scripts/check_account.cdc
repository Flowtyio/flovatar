
//import FungibleToken from 0xee82856bf20e2aa6
//import FungibleToken from "../contracts/FungibleToken.cdc"
//import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
//import FUSD from "../contracts/FUSD.cdc"
import Flovatar from "../contracts/Flovatar.cdc"
import FlovatarComponent from "../contracts/FlovatarComponent.cdc"
import FlovatarComponentTemplate from "../contracts/FlovatarComponentTemplate.cdc"
import FlovatarPack from "../contracts/FlovatarPack.cdc"


pub fun main(address: Address): Bool {

  let account = getAccount(address)

  let flovatarCap = account.getCapability<&{Flovatar.CollectionPublic}>(Flovatar.CollectionPublicPath)
  let flovatarComponentCap = account.getCapability<&{FlovatarComponent.CollectionPublic}>(FlovatarComponent.CollectionPublicPath)
  let marketplaceCap = account.getCapability<&{Marketplace.SalePublic}>(Marketplace.CollectionPublicPath)
  let flovatarPackCap = account.getCapability<&{FlovatarPack.CollectionPublic}>(FlovatarPack.CollectionPublicPath)

  var hasFusd = false
  if let fusdVault = account.getCapability(/public/fusdBalance).borrow<&FUSD.Vault{FungibleToken.Balance}>(){
    hasFusd = true
  }

  return (flovatarCap.check() && flovatarComponentCap.check() && marketplaceCap.check() && flovatarPackCap.check() && hasFusd)
}
