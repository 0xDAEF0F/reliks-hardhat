import { ethers } from 'hardhat'

async function main() {
  const Box = await ethers.getContractFactory('Box')
  console.log('Deploying Box...')
  const box = await Box.deploy()

  await box.deployed()

  console.log(box.address, ' box(proxy) address')
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
