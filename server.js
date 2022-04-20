const fs = require('fs');
const express = require('express');
const keccak256 = require('keccak256');
const { MerkleTree } = require('merkletreejs');

const buf2hex = x => '0x' + x.toString('hex');

const app = express();
const port = process.env.PORT || 3000;

app.get('/whitelist/:id', (req, res) => {
    fs.readFile(`./whitelists/${req.params.id}.txt`, 'utf8', (err, data) => {
        res.json({
            data: data.split('\n')
        });
    });
});

app.get('/root/:id', (req, res) => {
    fs.readFile(`./whitelists/${req.params.id}.txt`, 'utf8', (err, data) => {
        const addresses = data.split('\n');
        const leaves = addresses.map(x => keccak256(x));
        const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });
        const root = buf2hex(tree.getRoot());
        res.json({ root });
    });
});

app.listen(port, () => {
    console.log(`Whitelist server is listening at localhost:${process.env.PORT}`);
});