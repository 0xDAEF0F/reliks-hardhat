import { expect } from 'chai'
import { ethers } from 'hardhat'
import { Contract, BigNumber } from 'ethers'

describe('Whale', () => {
  let whale: Contract

  beforeEach(async () => {
    const [acct1] = await ethers.getSigners()
    const Whale = await ethers.getContractFactory('WhaleStrategy')
    whale = await Whale.deploy(acct1.address, 3, ethers.utils.parseEther('1'))
    await whale.deployed()
  })

  it('lair fullness should be false after deploy', async () => {
    expect(await whale.lairFull()).to.eq(false)
  })
  it('should revert when depositing less than the initial entry', async () => {
    const [, acct2] = await ethers.getSigners()
    expect(
      whale.connect(acct2).enterLair({ value: ethers.utils.parseEther('0.9') })
    ).to.be.revertedWith('Not enough money.')
  })
  it('should create a whale when entering lair initially', async () => {
    const [, acct2] = await ethers.getSigners()
    await whale.connect(acct2).enterLair({ value: ethers.utils.parseEther('1') })
    expect(await whale.isWhale(acct2.address)).to.eq(true)
    const newWhale = await whale.whaleArr(0)
    expect(newWhale.addr).to.equal(acct2.address)
  })
  it('lair should be filled when max whales enter', async () => {
    const [, acct2, acct3, acct4] = await ethers.getSigners()
    await whale.connect(acct2).enterLair({ value: ethers.utils.parseEther('1') })
    await whale.connect(acct3).enterLair({ value: ethers.utils.parseEther('2') })
    await whale.connect(acct4).enterLair({ value: ethers.utils.parseEther('3') })
    expect(await whale.lairFull()).to.be.true
  })
  it('lair should get sorted after lair gets full', async () => {
    const [, acct2, acct3, acct4] = await ethers.getSigners()
    await whale.connect(acct2).enterLair({ value: ethers.utils.parseEther('1') })
    await whale.connect(acct3).enterLair({ value: ethers.utils.parseEther('2') })
    await whale.connect(acct4).enterLair({ value: ethers.utils.parseEther('3') })
    const biggestWhale = await whale.whaleArr(0)
    const smallestWhale = await whale.whaleArr(2)
    expect(biggestWhale.addr).to.equal(acct4.address)
    expect(smallestWhale.addr).to.equal(acct2.address)
  })
  it('lowest whale should be replaced by new whale when lair is full', async () => {
    const [, acct2, acct3, acct4, acct5] = await ethers.getSigners()
    await whale.connect(acct2).enterLair({ value: ethers.utils.parseEther('1') })
    await whale.connect(acct3).enterLair({ value: ethers.utils.parseEther('2') })
    await whale.connect(acct4).enterLair({ value: ethers.utils.parseEther('3') })
    await whale.connect(acct5).enterLair({ value: ethers.utils.parseEther('4') })
    expect((await whale.whaleArr(2)).addr).to.equal(acct3.address)
    expect(await whale.isWhale(acct2.address)).to.be.false
    expect(await whale.isWhale(acct5.address)).to.be.true
  })
  it('should revert when depositing less than lowest whale', async () => {
    const [, acct2, acct3, acct4, acct5] = await ethers.getSigners()
    await whale.connect(acct2).enterLair({ value: ethers.utils.parseEther('2') })
    await whale.connect(acct3).enterLair({ value: ethers.utils.parseEther('3') })
    await whale.connect(acct4).enterLair({ value: ethers.utils.parseEther('4') })
    expect(
      whale.connect(acct5).enterLair({ value: ethers.utils.parseEther('1.5') })
    ).to.be.revertedWith('Not enough to dethrone whale.')
  })
  it('should transfer ether correctly to creator when lair not full', async () => {
    const [acct1, acct2, acct3, acct4] = await ethers.getSigners()
    const oldBalance = await acct1.getBalance()
    await whale.connect(acct2).enterLair({ value: ethers.utils.parseEther('1') })
    await whale.connect(acct3).enterLair({ value: ethers.utils.parseEther('2') })
    await whale.connect(acct4).enterLair({ value: ethers.utils.parseEther('3') })
    const newBalance = await acct1.getBalance()
    expect(newBalance.sub(oldBalance)).to.equal(ethers.utils.parseEther('5.40'))
  })
  it('should transfer correctly when dethrone occurs', async () => {})
})
