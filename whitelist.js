const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');

const buf2hex = x => '0x' + x.toString('hex');

// test addresses
const addresses = [
    '0x15D6F888c24C491A9b21f47627565E2330ff23c6',
    '0x58a23Dc1E076eBE2cBb926F5FdFEf10B3A6eBDF1',
    '0xd038d98C9f52bd6DE00B3A9d8f2Cf3bf9125F1d6',
];

const leaves = addresses.map(x => keccak256(x));
const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });
const root = buf2hex(tree.getRoot());
console.log(root);

const leaf = keccak256('0x15D6F888c24C491A9b21f47627565E2330ff23c6');
console.log(buf2hex(leaf));
const proof = tree.getProof(leaf).map(x => buf2hex(x.data));
console.log(proof);
console.log(tree.verify(proof, leaf, root)); // true


// proof to send to contract for verification
let p = [
    "0x990bde5561e9bc5767f70238a0c9a12b93cccab0efdbcc441500f2014d183624",
    "0xd28cff7104fb285ed0d7ae9af5b49946fde6430bdc3f9997827f399d69f2aaf6"
]