import { expect } from 'chai'
import { ethers } from 'hardhat'
import { Contract } from 'ethers'

describe('Whale', () => {
  let lair: Contract

  beforeEach(async () => {
    const [, appAcct] = await ethers.getSigners()
    const Lair = await ethers.getContractFactory('Lair')
    lair = await Lair.deploy(appAcct.address, 3, ethers.utils.parseEther('1'))
    await lair.deployed()
  })

  it('lair fullness should be false after deploy', async () => {
    expect(await lair.lairFull()).to.eq(false)
  })
  it('should revert when depositing less than the initial entry', async () => {
    const [, acct2] = await ethers.getSigners()
    expect(
      lair.connect(acct2).enterLair({ value: ethers.utils.parseEther('0.9') })
    ).to.be.revertedWith('Not enough money.')
  })
  it('should create a whale when entering lair initially', async () => {
    const [, acct2] = await ethers.getSigners()
    await lair.connect(acct2).enterLair({ value: ethers.utils.parseEther('1') })
    expect(await lair.isWhale(acct2.address)).to.eq(true)
    const newWhale = await lair.whaleArr(0)
    expect(newWhale.addr).to.equal(acct2.address)
  })
  it('lair should be filled when max whales enter', async () => {
    const [, acct2, acct3, acct4] = await ethers.getSigners()
    await lair.connect(acct2).enterLair({ value: ethers.utils.parseEther('1') })
    await lair.connect(acct3).enterLair({ value: ethers.utils.parseEther('2') })
    await lair.connect(acct4).enterLair({ value: ethers.utils.parseEther('3') })
    expect(await lair.lairFull()).to.be.true
  })
  it('lair should get sorted after lair gets full', async () => {
    const [, acct2, acct3, acct4] = await ethers.getSigners()
    await lair.connect(acct2).enterLair({ value: ethers.utils.parseEther('1') })
    await lair.connect(acct3).enterLair({ value: ethers.utils.parseEther('2') })
    await lair.connect(acct4).enterLair({ value: ethers.utils.parseEther('3') })
    const biggestWhale = await lair.whaleArr(0)
    const smallestWhale = await lair.whaleArr(2)
    expect(biggestWhale.addr).to.equal(acct4.address)
    expect(smallestWhale.addr).to.equal(acct2.address)
  })
  it('lowest whale should be replaced by new whale when lair is full', async () => {
    const [, acct2, acct3, acct4, acct5] = await ethers.getSigners()
    await lair.connect(acct2).enterLair({ value: ethers.utils.parseEther('1') })
    await lair.connect(acct3).enterLair({ value: ethers.utils.parseEther('2') })
    await lair.connect(acct4).enterLair({ value: ethers.utils.parseEther('3') })
    await lair.connect(acct5).enterLair({ value: ethers.utils.parseEther('4') })
    expect((await lair.whaleArr(2)).addr).to.equal(acct3.address)
    expect(await lair.isWhale(acct2.address)).to.be.false
    expect(await lair.isWhale(acct5.address)).to.be.true
    expect(await lair.refundWhaleAmount(acct2.address)).to.equal(ethers.utils.parseEther('1'))
  })
  it('should revert when depositing less than lowest whale', async () => {
    const [, acct2, acct3, acct4, acct5] = await ethers.getSigners()
    await lair.connect(acct2).enterLair({ value: ethers.utils.parseEther('2') })
    await lair.connect(acct3).enterLair({ value: ethers.utils.parseEther('3') })
    await lair.connect(acct4).enterLair({ value: ethers.utils.parseEther('4') })
    expect(
      lair.connect(acct5).enterLair({ value: ethers.utils.parseEther('1.5') })
    ).to.be.revertedWith('Not enough to dethrone whale.')
  })
  it('should transfer ether correctly to creator when lair not full', async () => {
    const [acct1, acct2, acct3, acct4] = await ethers.getSigners()
    const oldBalance = await acct1.getBalance()
    await lair.connect(acct2).enterLair({ value: ethers.utils.parseEther('1') })
    await lair.connect(acct3).enterLair({ value: ethers.utils.parseEther('2') })
    await lair.connect(acct4).enterLair({ value: ethers.utils.parseEther('3') })
    const newBalance = await acct1.getBalance()
    expect(newBalance.sub(oldBalance)).to.equal(ethers.utils.parseEther('5.40'))
  })
  it('should transfer correctly when dethrone occurs', async () => {
    const [creatorAcct, appAcct, acct3, acct4, acct5, acct6] = await ethers.getSigners()
    const creatorOldBalance = await creatorAcct.getBalance()
    const appOldBalance = await appAcct.getBalance()
    await lair.connect(acct3).enterLair({ value: ethers.utils.parseEther('4') })
    await lair.connect(acct4).enterLair({ value: ethers.utils.parseEther('3') })
    await lair.connect(acct5).enterLair({ value: ethers.utils.parseEther('3') })
    await lair.connect(acct6).enterLair({ value: ethers.utils.parseEther('13') })
    const creatorNewBalance = await creatorAcct.getBalance()
    const appNewBalance = await appAcct.getBalance()
    expect(appNewBalance.sub(appOldBalance)).to.equal(ethers.utils.parseEther('2'))
    expect(creatorNewBalance.sub(creatorOldBalance)).to.equal(ethers.utils.parseEther('18'))
  })
  it('events should be emitted properly', async () => {
    const [, acct2, acct3, acct4, acct5] = await ethers.getSigners()
    await expect(await lair.connect(acct2).enterLair({ value: ethers.utils.parseEther('1') }))
      .to.emit(lair, 'LogNewWhale')
      .withArgs(
        ethers.utils.parseEther('1'),
        acct2.address,
        '0x0000000000000000000000000000000000000000'
      )
    await expect(await lair.connect(acct3).enterLair({ value: ethers.utils.parseEther('2') }))
      .to.emit(lair, 'LogNewWhale')
      .withArgs(
        ethers.utils.parseEther('2'),
        acct3.address,
        '0x0000000000000000000000000000000000000000'
      )
    await expect(await lair.connect(acct4).enterLair({ value: ethers.utils.parseEther('3') }))
      .to.emit(lair, 'LogNewWhale')
      .withArgs(
        ethers.utils.parseEther('3'),
        acct4.address,
        '0x0000000000000000000000000000000000000000'
      )
    await expect(await lair.connect(acct5).enterLair({ value: ethers.utils.parseEther('4') }))
      .to.emit(lair, 'LogNewWhale')
      .withArgs(ethers.utils.parseEther('4'), acct5.address, acct2.address)
  })
})
