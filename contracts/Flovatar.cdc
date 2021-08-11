import NonFungibleToken from "./NonFungibleToken.cdc"
import FlovatarComponentTemplate from "./FlovatarComponentTemplate.cdc"
import FlovatarComponent from "./FlovatarComponent.cdc"
import FlovatarPack from "./FlovatarPack.cdc"

/*

 The contract that defines the Flovatar NFT and a Collection to manage them

Base components that will be used to generate the unique combination of the Flovatar
'body', 'hair', 'facialhair', 'eyes', 'nose', 'mouth', 'clothing'

Extra components that can be added in a second moment
'accessory', 'hat', eyeglass'

 */

pub contract Flovatar: NonFungibleToken {

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let AdminStoragePath: StoragePath

    pub var totalSupply: UInt64
    access(contract) let mintedCombinations: [String]
    access(contract) let mintedNames: [String]

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Created(id: UInt64, metadata: Metadata)


    pub struct Metadata {
        pub let name: String
        pub let mint: UInt64
        pub let svg: String
        pub let combination: String
        pub let creatorAddress: Address
        pub let components: {String: UInt64}


        init(
            name: String,
            mint: UInt64
            svg: String,
            combination: String,
            creatorAddress: Address,
            components: {String: UInt64}
        ) {
                self.name = name
                self.mint = mint
                self.svg = svg
                self.combination = combination
                self.creatorAddress = creatorAddress
                self.components = components
        }
    }

    //The public interface can show metadata and the content for the Flovatar
    pub resource interface Public {
        pub let id: UInt64
        pub let metadata: Metadata

        //these three are added because I think they will be in the standard. At least Dieter thinks it will be needed
        pub let name: String
        pub let description: String
        pub let schema: String?

        pub fun getAccessory(): UInt64?
        pub fun getHat(): UInt64?
        pub fun getEyeglasses(): UInt64?

        pub fun getSvg(): String
    }

    //The private interface can update the Accessory, Hat and Eyeglasses for the Flovatar
    pub resource interface Private {
        pub fun setAccessory(component: @FlovatarComponent.NFT): UInt64?
        pub fun setHat(component: @FlovatarComponent.NFT): UInt64?
        pub fun setEyeglasses(component: @FlovatarComponent.NFT): UInt64?
    }

    pub resource NFT: NonFungibleToken.INFT, Public, Private {
        pub let id: UInt64
        pub let metadata: Metadata
        access(contract) var accessory: UInt64?
        access(contract) var hat: UInt64?
        access(contract) var eyeglasses: UInt64?

        pub let name: String
        pub let description: String
        pub let schema: String?

        init(metadata: Metadata) {

            Flovatar.totalSupply = Flovatar.totalSupply + UInt64(1)

            self.id = Flovatar.totalSupply
            self.metadata = metadata
            self.accessory = nil
            self.hat = nil
            self.eyeglasses = nil

            self.schema = nil
            self.name = metadata.name
            self.description = metadata.name
        }

        pub fun getID(): UInt64 {
            return self.id
        }

        pub fun getMetadata(): Metadata {
            return self.metadata
        }

        pub fun getAccessory(): UInt64? {
            return self.accessory
        }
        
        pub fun setAccessory(component: @FlovatarComponent.NFT): UInt64? {
            pre {
                component.getCategory() == "accessory" : "The component needs to be an accessory"
            }

            self.accessory = component.templateId

            destroy component
            return self.accessory
        }

        pub fun getHat(): UInt64? {
            return self.hat
        }
        
        pub fun setHat(component: @FlovatarComponent.NFT): UInt64? {
            pre {
                component.getCategory() == "hat" : "The component needs to be a hat"
            }

            self.hat = component.templateId

            destroy component
            return self.hat
        }

        pub fun getEyeglasses(): UInt64? {
            return self.eyeglasses
        }
        
        pub fun setEyeglasses(component: @FlovatarComponent.NFT): UInt64? {
            pre {
                component.getCategory() == "eyeglasses" : "The component needs to be a pair of eyeglasses"
            }

            self.eyeglasses = component.templateId

            destroy component
            return self.eyeglasses
        }

        pub fun getSvg(): String {
            let svg: String = "<svg viewBox='0 0 100 100' xmlns='http://www.w3.org/2000/svg'>"

            svg.concat(self.metadata.svg)

            if let eyeglasses = self.getEyeglasses() {
                if let template = FlovatarComponentTemplate.getComponentTemplate(id: eyeglasses) {
                    svg.concat(template.svg!)
                }
            }

            if let hat = self.getHat() {
                if let template = FlovatarComponentTemplate.getComponentTemplate(id: hat) {
                    svg.concat(template.svg!)
                }
            }

            if let accessory = self.getAccessory() {
                if let template = FlovatarComponentTemplate.getComponentTemplate(id: accessory) {
                    svg.concat(template.svg!)
                }
            }

            svg.concat("</svg>")

            return svg

        }
    }

    //Standard NFT collectionPublic interface that can also borrowFlovatar as the correct type
    pub resource interface CollectionPublic {

        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowFlovatar(id: UInt64): &{Flovatar.Public}?
    }

    pub resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        // withdraw removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <- token
        }

        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @Flovatar.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return &self.ownedNFTs[id] as &NonFungibleToken.NFT
        }

        // borrowFlovatar returns a borrowed reference to a Flovatar
        // so that the caller can read data and call methods from it.
        //
        // Parameters: id: The ID of the NFT to get the reference for
        //
        // Returns: A reference to the NFT
        pub fun borrowFlovatar(id: UInt64): &{Flovatar.Public}? {
            if self.ownedNFTs[id] != nil {
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                return ref as! &Flovatar.NFT
            } else {
                return nil
            }
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    pub struct FlovatarData {
        pub let id: UInt64
        pub let metadata: Flovatar.Metadata
        init(id: UInt64, metadata: Flovatar.Metadata) {
            self.id = id
            self.metadata = metadata
        }
    }


    pub fun getFlovatar(address: Address, flovatarId: UInt64) : FlovatarData? {

        let account = getAccount(address)

        if let flovatarCollection = account.getCapability(self.CollectionPublicPath).borrow<&{Flovatar.CollectionPublic}>()  {
            if let flovatar = flovatarCollection.borrowFlovatar(id: flovatarId) {
                return FlovatarData(
                    id: flovatarId,
                    metadata: flovatar!.metadata
                )
            }
        }
        return nil
    }

    pub fun getFlovatars(address: Address) : [FlovatarData] {

        var flovatarData: [FlovatarData] = []
        let account = getAccount(address)

        if let flovatarCollection = account.getCapability(self.CollectionPublicPath).borrow<&{Flovatar.CollectionPublic}>()  {
            for id in flovatarCollection.getIDs() {
                var Flovatar = flovatarCollection.borrowFlovatar(id: id)
                flovatarData.append(FlovatarData(
                    id: id,
                    metadata: Flovatar!.metadata
                    ))
            }
        }
        return flovatarData
    }


    pub fun getMintedCombinations() : [String] {
        return Flovatar.mintedCombinations
    }
    pub fun getMintedNames() : [String] {
        return Flovatar.mintedNames
    }

    access(account) fun addMintedCombination(combination: String) {
        Flovatar.mintedCombinations.append(combination)
    }
    access(account) fun addMintedName(name: String) {
        Flovatar.mintedNames.append(name)
    }

    pub fun getCombinationString(
        body: UInt64,
        hair: UInt64,
        facialHair: UInt64?,
        eyes: UInt64,
        nose: UInt64,
        mouth: UInt64,
        clothing: UInt64
    ) : String {
        let facialHairString = (facialHair != nil) ? facialHair!.toString() : "x"
        return "B".concat(body.toString()).concat("H").concat(hair.toString()).concat("F").concat(facialHairString).concat("E").concat(eyes.toString()).concat("N").concat(nose.toString()).concat("M").concat(mouth.toString()).concat("C").concat(clothing.toString())
    }

    pub fun checkCombinationAvailable(
        body: UInt64,
        hair: UInt64,
        facialHair: UInt64?,
        eyes: UInt64,
        nose: UInt64,
        mouth: UInt64,
        clothing: UInt64
    ) : Bool {
        let combinationString = Flovatar.getCombinationString(
            body: body,
            hair: hair,
            facialHair: facialHair,
            eyes: eyes,
            nose: nose,
            mouth: mouth,
            clothing: clothing
        )
        return ! Flovatar.mintedCombinations.contains(combinationString)
    }

    pub fun checkNameAvailable(name: String) : Bool {
        return ! Flovatar.mintedNames.contains(name)
    }

    pub fun createFlovatar(
        name: String,
        body: @FlovatarComponent.NFT,
        hair: @FlovatarComponent.NFT,
        facialHair: @FlovatarComponent.NFT?,
        eyes: @FlovatarComponent.NFT,
        nose: @FlovatarComponent.NFT,
        mouth: @FlovatarComponent.NFT,
        clothing: @FlovatarComponent.NFT,
        address: Address
    ) : @Flovatar.NFT {


        pre {

            name.length > 2 : "The name is too short"
            name.length < 20 : "The name is too long" 

            body.getCategory() == "body" : "The body component belongs to the wrong category"
            hair.getCategory() == "hair" : "The hair component belongs to the wrong category"
            eyes.getCategory() == "eyes" : "The eyes component belongs to the wrong category"
            nose.getCategory() == "nose" : "The nose component belongs to the wrong category"
            mouth.getCategory() == "mouth" : "The mouth component belongs to the wrong category"
            clothing.getCategory() == "clothing" : "The clothing component belongs to the wrong category"

        }
        if(facialHair != nil){
            if(facialHair?.getCategory() != "facialHair"){
                panic("The facial hair component belongs to the wrong category")
            }
        }


        let combinationString = Flovatar.getCombinationString(
            body: body.templateId, 
            hair: hair.templateId, 
            facialHair: facialHair != nil ? facialHair?.templateId : nil, 
            eyes: eyes.templateId, 
            nose: nose.templateId, 
            mouth: mouth.templateId, 
            clothing: clothing.templateId)


        if(Flovatar.checkNameAvailable(name: name) == false){
            panic("This name has already been taken")
        }

        if(Flovatar.mintedCombinations.contains(combinationString) == true) {
            panic("This combination has already been taken")
        }

        let facialHairSvg:String  = facialHair != nil ? facialHair?.getSvg()! : ""
        let svg = (body.getSvg()!).concat(facialHairSvg).concat(eyes.getSvg()!).concat(nose.getSvg()!).concat(mouth.getSvg()!).concat(clothing.getSvg()!).concat(hair.getSvg()!)

        //TODO fix this with optional. No idea why it's expecting UInt64 instead of UInt64? even if it's defined in Metadata struct
        let facialHairId: UInt64 = facialHair != nil ? facialHair?.templateId! : 0

        let metadata = Metadata(
            name: name,
            mint: Flovatar.totalSupply + UInt64(1),
            svg: svg,
            combination: combinationString,
            creatorAddress: address,
            components: {
                "body": body.templateId, 
                "hair": hair.templateId, 
                "facialHair": facialHairId, 
                "eyes": eyes.templateId, 
                "nose": nose.templateId, 
                "mouth": mouth.templateId, 
                "clothing": clothing.templateId
            }
        )

        var newNFT <- create NFT(metadata: metadata)
        emit Created(id: Flovatar.totalSupply, metadata: metadata)

        destroy body
        destroy hair
        destroy facialHair
        destroy eyes
        destroy nose
        destroy mouth
        destroy clothing

        return <- newNFT
    }


    pub resource Admin {

        pub fun createComponentTemplate(
            name: String,
            category: String,
            color: String,
            description: String,
            svg: String,
            maxMintableComponents: UInt64
        ) : @FlovatarComponentTemplate.ComponentTemplate {
            return <- FlovatarComponentTemplate.createComponentTemplate(
                name: name,
                category: category,
                color: color,
                description: description,
                svg: svg,
                maxMintableComponents: maxMintableComponents
            )
        }

        pub fun createComponent(templateId: UInt64) : @FlovatarComponent.NFT {
            return <- FlovatarComponent.createComponent(templateId: templateId)
        }

        pub fun createPack(
            body: @FlovatarComponent.NFT,
            hair: @FlovatarComponent.NFT,
            facialHair: @FlovatarComponent.NFT?,
            eyes: @FlovatarComponent.NFT,
            nose: @FlovatarComponent.NFT,
            mouth: @FlovatarComponent.NFT,
            clothing: @FlovatarComponent.NFT,
            hat: @FlovatarComponent.NFT?,
            eyeglasses: @FlovatarComponent.NFT?,
            accessory: @FlovatarComponent.NFT?
        ) : @FlovatarPack.Pack {

        return <- FlovatarPack.createPack(
            body: <-body,
            hair: <-hair,
            facialHair: <-facialHair,
            eyes: <-eyes,
            nose: <-nose,
            mouth: <-mouth,
            clothing: <-clothing,
            hat: <-hat,
            eyeglasses: <-eyeglasses,
            accessory: <-accessory
        )
    }

        pub fun createNewAdmin(): @Admin {
            return <-create Admin()
        }
    }





	init() {
        //TODO: remove suffix before deploying to mainnet!!!
        self.CollectionPublicPath = /public/FlovatarCollection001
        self.CollectionStoragePath = /storage/FlovatarCollection001
        self.AdminStoragePath = /storage/FlovatarAdmin001

        // Initialize the total supply
        self.totalSupply = UInt64(0)
        self.mintedCombinations = []
        self.mintedNames = []
        self.account.save<@NonFungibleToken.Collection>(<- Flovatar.createEmptyCollection(), to: Flovatar.CollectionStoragePath)
        self.account.link<&{Flovatar.CollectionPublic}>(Flovatar.CollectionPublicPath, target: Flovatar.CollectionStoragePath)

        // Put the Minter in storage
        self.account.save<@Admin>(<- create Admin(), to: self.AdminStoragePath)

        emit ContractInitialized()
	}
}

