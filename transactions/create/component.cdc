
//import FungibleToken from 0xee82856bf20e2aa6
//import FungibleToken from "../../contracts/FungibleToken.cdc"
//import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
//import FUSD from "../../contracts/FUSD.cdc"
import Flovatar from "../../contracts/Flovatar.cdc"
import FlovatarComponent from "../../contracts/FlovatarComponent.cdc"
import FlovatarComponentTemplate from "../../contracts/FlovatarComponentTemplate.cdc"
import FlovatarPack from "../../contracts/FlovatarPack.cdc"


//this transaction will create a new Webshot and create and auction for it
transaction(templateId: UInt64) {

    let flovatarComponentCollection: &FlovatarComponent.Collection
    let flovatarAdmin: &Flovatar.Admin

    prepare(account: AuthAccount) {
        self.flovatarComponentCollection = account.borrow<&FlovatarComponent.Collection>(from: FlovatarComponent.CollectionStoragePath)!

        self.flovatarAdmin = account.borrow<&Flovatar.Admin>(from: Flovatar.AdminStoragePath)!
    }

    execute {
        let flovatarComponent <- self.flovatarAdmin.createComponent(templateId: templateId) as! @FlovatarComponent.NFT

        self.flovatarComponentCollection.deposit(token: <-flovatarComponent)

    }
}