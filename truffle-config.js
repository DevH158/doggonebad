const HDWalletProvider = require("truffle-hdwallet-provider-klaytn");

require('dotenv').config();

const privateKey = process.env.PRIVATE_KEY1;

module.exports = {
  compilers: {
    solc: {
      version: "^0.8.0"
    }
  },
  networks: {
    development: {
      host: "localhost",
      port: 8551,
      network_id: "*", // Match any network id
    },
    klaytn: {
      provider: () => {
        const pks = JSON.parse(
          fs.readFileSync(path.resolve(__dirname) + "/privateKeys.js")
        );

        return new HDWalletProvider(
          pks,
          "https://api.baobab.klaytn.net:8651",
          0,
          pks.length
        );
      },
      network_id: "1001", //Klaytn baobab testnet's network id
      gas: "8500000",
      gasPrice: null,
    },
    kasBaobab: {
      provider: () => {
        const option = {
          headers: [
            {
              name: "Authorization",
              value:
                "Basic " +
                Buffer.from(accessKeyId + ":" + secretAccessKey).toString(
                  "base64"
                ),
            },
            { name: "x-chain-id", value: "1001" },
          ],
          keepAlive: false,
        };
        return new HDWalletProvider(
          privateKey,
          new Caver.providers.HttpProvider(
            "https://node-api.klaytnapi.com/v1/klaytn",
            option
          )
        );
      },
      network_id: "1001", //Klaytn baobab testnet's network id
      gas: "50000000",
      gasPrice: "750000000000",
    },
    kasCypress: {
      provider: () => {
        const option = {
          headers: [
            {
              name: "Authorization",
              value:
                "Basic " +
                Buffer.from(accessKeyId + ":" + secretAccessKey).toString(
                  "base64"
                ),
            },
            { name: "x-chain-id", value: "8217" },
          ],
          keepAlive: false,
        };
        return new HDWalletProvider(
          cypressPrivateKey,
          new Caver.providers.HttpProvider(
            "https://node-api.klaytnapi.com/v1/klaytn",
            option
          )
        );
      },
      network_id: "8217", //Klaytn baobab testnet's network id
      gas: "8500000",
      gasPrice: "25000000000",
    },
    baobab: {
      provider: () => {
        return new HDWalletProvider(privateKey, "https://api.baobab.klaytn.net:8651");
      },
      network_id: "1001", //Klaytn baobab testnet's network id
      gas: "9000000",
      gasPrice: '750000000000',
    },
    cypress: {
      provider: () => {
        return new HDWalletProvider(privateKey, "https://public-node-api.klaytnapi.com/v1/cypress");
      },
      network_id: "8217", //Klaytn mainnet's network id
      gas: "5000000",
      gasPrice: '750000000000',
    },
  },
};