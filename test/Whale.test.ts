
import { expect } from 'chai'
import { ethers } from 'hardhat'
import { Contract, BigNumber } from 'ethers'

describe('Whale',  () => {
  let whale: Contract

  beforeEach(async  () => {
    const [acct1] = await ethers.getSigners()
    const Whale = await ethers.getContractFactory('WhaleStrategy')
    whale = await Whale.deploy(acct1.address, 3, ethers.utils.parseEther("1"))
    await whale.deployed()
  })

  it('lair fullness should be false after deploy', async () => {
    expect(await whale.lairFull()).to.eq(false) 
  })

  it('should make a whale when entering lair with initial amount', async  () => {
    const [,acct2] = await ethers.getSigners()
    await whale.connect(acct2).enterLair({value: ethers.utils.parseEther("1")})
    expect(await whale.isWhale(acct2.address)).to.eq(true)
  })
})
