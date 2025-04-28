import React, { useState, useEffect } from "react";
import { ethers } from "ethers";

// ABI dan Alamat Kontrak
const TokenFactoryABI = [
  "function createToken(string name, string symbol, address tokenOwner) public returns (address)",
  "function getTokensByUser(address user) public view returns (address[])",
  "function addToAVSTokens(address token) public",
  "function removeFromAVSTokens(address token) public",
  "function getUserTokenCount(address user) public view returns (uint256)",
];

const TokenABI = [
  "function mint(address to, uint256 amount) public",
  "function burn(uint256 amount) public",
  "function balanceOf(address account) public view returns (uint256)",
  "function symbol() public view returns (string)",
];

const ReserveABI = [
  "function setReserveBalance(address tokenAddress, uint256 newBalance) external",
  "function getReserveBalance(address tokenAddress) external view returns (uint256)",
  "function getLastUpdateTimestamp() external view returns (uint256)",
];

const VeristableAVSABI = [
  "function underwrite(address token, uint128 amount) external",
  "function withdraw(address token, uint128 amount) external",
  "function claimRewards(address token) external",
  "function depositRewards(address token, uint128 amount) public",
  "function pause() public",
  "function unpause() public",
  "function transferOwnership(address newOwner) public",
  "function paused() public view returns (bool)",
  "function owner() public view returns (address)",
  "function underwritingAmounts(address token, address underwriter) public view returns (uint128)",
  "function totalUnderwriting(address token) public view returns (uint128)",
  "function totalRewards(address token) public view returns (uint128)",
  "function unclaimedRewards(address token, address underwriter) public view returns (uint128)",
];

// Alamat Kontrak di Pharos Network
const factoryAddress = "0x5418fc891317C20f923ccB431d9B040D14987bD8";
const reserveAddress = "0x32e26c6880e652599A20CF8eb672FDd9179114FC";
const veristableAVSAddress = "0x7F3AC11808D1ADd56Abe48603D7ee16cAB970060";

const TokenFactory = () => {
  const [account, setAccount] = useState("");
  const [provider, setProvider] = useState(null);
  const [userTokens, setUserTokens] = useState([]);
  const [tokenName, setTokenName] = useState("");
  const [tokenSymbol, setTokenSymbol] = useState("");
  const [mintAmount, setMintAmount] = useState("");
  const [burnAmount, setBurnAmount] = useState("");
  const [selectedToken, setSelectedToken] = useState("");
  const [reserveBalance, setReserveBalance] = useState("0");
  const [newReserveBalance, setNewReserveBalance] = useState("");
  const [lastUpdateTimestamp, setLastUpdateTimestamp] = useState("0");
  const [underwriteAmount, setUnderwriteAmount] = useState("");
  const [withdrawAmount, setWithdrawAmount] = useState("");
  const [depositRewardAmount, setDepositRewardAmount] = useState("");
  const [avsTokenAddress, setAvsTokenAddress] = useState("");
  const [newOwnerAddress, setNewOwnerAddress] = useState("");
  const [contractPaused, setContractPaused] = useState(false);
  const [contractOwner, setContractOwner] = useState("");
  const [userTokenCount, setUserTokenCount] = useState("0");
  const [userBalance, setUserBalance] = useState("0");
  const [unclaimedRewards, setUnclaimedRewards] = useState("0");
  const [totalUnderwriting, setTotalUnderwriting] = useState("0");
  const [totalRewards, setTotalRewards] = useState("0");

  // Koneksi Wallet
  const connectWallet = async () => {
    try {
      if (window.ethereum) {
        await window.ethereum.request({ method: "eth_requestAccounts" });
        const provider = new ethers.providers.Web3Provider(window.ethereum);
        const signer = provider.getSigner();
        const address = await signer.getAddress();
        setAccount(address);
        setProvider(provider);
        await loadUserTokens(address, provider);
        await checkContractStatus(provider);
      }
    } catch (error) {
      console.error("Error connecting wallet:", error);
      alert("Failed to connect wallet: " + error.message);
    }
  };

  // Load User Tokens
  const loadUserTokens = async (address, provider) => {
    try {
      const factory = new ethers.Contract(
        factoryAddress,
        TokenFactoryABI,
        provider
      );
      const tokens = await factory.getTokensByUser(address);
      const tokenCount = await factory.getUserTokenCount(address);
      setUserTokens(tokens);
      setUserTokenCount(tokenCount.toString());
    } catch (error) {
      console.error("Error loading tokens:", error);
    }
  };

  // Check Contract Status (Paused/Owner)
  const checkContractStatus = async (provider) => {
    try {
      const avs = new ethers.Contract(
        veristableAVSAddress,
        VeristableAVSABI,
        provider
      );
      const isPaused = await avs.paused();
      const owner = await avs.owner();
      setContractPaused(isPaused);
      setContractOwner(owner);
    } catch (error) {
      console.error("Error checking contract status:", error);
    }
  };

  // Create Token
  const createToken = async () => {
    try {
      if (!provider) return;
      if (!tokenName || !tokenSymbol) {
        alert("Nama token dan symbol harus diisi!");
        return;
      }
      const signer = provider.getSigner();
      const factory = new ethers.Contract(
        factoryAddress,
        TokenFactoryABI,
        signer
      );
      const tx = await factory.createToken(tokenName, tokenSymbol, account, {
        gasLimit: 3000000,
      });
      await tx.wait();
      await loadUserTokens(account, provider);
      setTokenName("");
      setTokenSymbol("");
      alert("Token created successfully!");
    } catch (error) {
      console.error("Error creating token:", error);
      alert("Failed to create token: " + error.message);
    }
  };

  // Mint Token
  const mintToken = async () => {
    try {
      if (!provider || !selectedToken) return;
      const signer = provider.getSigner();
      const token = new ethers.Contract(selectedToken, TokenABI, signer);
      const tx = await token.mint(account, ethers.utils.parseEther(mintAmount));
      await tx.wait();
      await getTokenInfo(selectedToken);
      alert("Tokens minted successfully!");
    } catch (error) {
      console.error("Error minting token:", error);
      alert("Failed to mint token: " + error.message);
    }
  };

  // Burn Token
  const burnToken = async () => {
    try {
      if (!provider || !selectedToken) return;
      const signer = provider.getSigner();
      const token = new ethers.Contract(selectedToken, TokenABI, signer);
      const tx = await token.burn(ethers.utils.parseEther(burnAmount));
      await tx.wait();
      await getTokenInfo(selectedToken);
      alert("Tokens burned successfully!");
    } catch (error) {
      console.error("Error burning token:", error);
      alert("Failed to burn token: " + error.message);
    }
  };

  // Set Reserve Balance
  // const setReserveBalance = async () => {
  const updateReserveBalance = async () => {
    try {
      if (!provider || !selectedToken) return;
      const signer = provider.getSigner();
      const reserve = new ethers.Contract(reserveAddress, ReserveABI, signer);
      const tx = await reserve.setReserveBalance(
        selectedToken,
        ethers.utils.parseEther(newReserveBalance)
      );
      await tx.wait();
      await getReserveBalance(selectedToken);
      alert("Reserve balance updated!");
    } catch (error) {
      console.error("Error setting reserve balance:", error);
      alert("Failed to set reserve balance: " + error.message);
    }
  };

  // Get Reserve Balance dan Last Update Timestamp
  const getReserveBalance = async (tokenAddress) => {
    try {
      if (!provider) return;
      const reserve = new ethers.Contract(reserveAddress, ReserveABI, provider);
      const balance = await reserve.getReserveBalance(tokenAddress);
      const timestamp = await reserve.getLastUpdateTimestamp();
      setReserveBalance(ethers.utils.formatEther(balance));
      setLastUpdateTimestamp(new Date(timestamp * 1000).toLocaleString());
    } catch (error) {
      console.error("Error getting reserve balance:", error);
    }
  };

  // Underwrite Tokens
  const underwriteTokens = async () => {
    try {
      if (!provider || !selectedToken) return;
      const signer = provider.getSigner();
      const avs = new ethers.Contract(
        veristableAVSAddress,
        VeristableAVSABI,
        signer
      );
      const token = new ethers.Contract(selectedToken, TokenABI, signer);
      await token.approve(
        veristableAVSAddress,
        ethers.utils.parseEther(underwriteAmount)
      );
      const tx = await avs.underwrite(
        selectedToken,
        ethers.utils.parseEther(underwriteAmount)
      );
      await tx.wait();
      await getTokenInfo(selectedToken);
      alert("Tokens underwritten successfully!");
    } catch (error) {
      console.error("Error underwriting tokens:", error);
      alert("Failed to underwrite tokens: " + error.message);
    }
  };

  // Withdraw Tokens
  const withdrawTokens = async () => {
    try {
      if (!provider || !selectedToken) return;
      const signer = provider.getSigner();
      const avs = new ethers.Contract(
        veristableAVSAddress,
        VeristableAVSABI,
        signer
      );
      const tx = await avs.withdraw(
        selectedToken,
        ethers.utils.parseEther(withdrawAmount)
      );
      await tx.wait();
      await getTokenInfo(selectedToken);
      alert("Tokens withdrawn successfully!");
    } catch (error) {
      console.error("Error withdrawing tokens:", error);
      alert("Failed to withdraw tokens: " + error.message);
    }
  };

  // Claim Rewards
  const claimRewards = async () => {
    try {
      if (!provider || !selectedToken) return;
      const signer = provider.getSigner();
      const avs = new ethers.Contract(
        veristableAVSAddress,
        VeristableAVSABI,
        signer
      );
      const tx = await avs.claimRewards(selectedToken);
      await tx.wait();
      await getTokenInfo(selectedToken);
      alert("Rewards claimed successfully!");
    } catch (error) {
      console.error("Error claiming rewards:", error);
      alert("Failed to claim rewards: " + error.message);
    }
  };

  // Deposit Rewards
  const depositRewards = async () => {
    try {
      if (!provider || !selectedToken) return;
      const signer = provider.getSigner();
      const avs = new ethers.Contract(
        veristableAVSAddress,
        VeristableAVSABI,
        signer
      );
      const token = new ethers.Contract(selectedToken, TokenABI, signer);
      await token.approve(
        veristableAVSAddress,
        ethers.utils.parseEther(depositRewardAmount)
      );
      const tx = await avs.depositRewards(
        selectedToken,
        ethers.utils.parseEther(depositRewardAmount)
      );
      await tx.wait();
      await getTokenInfo(selectedToken);
      alert("Rewards deposited successfully!");
    } catch (error) {
      console.error("Error depositing rewards:", error);
      alert("Failed to deposit rewards: " + error.message);
    }
  };

  // Add to AVS Tokens
  const addToAVSTokens = async () => {
    try {
      if (!provider) return;
      const signer = provider.getSigner();
      const factory = new ethers.Contract(
        factoryAddress,
        TokenFactoryABI,
        signer
      );
      const tx = await factory.addToAVSTokens(avsTokenAddress);
      await tx.wait();
      alert("Token added to AVS!");
    } catch (error) {
      console.error("Error adding to AVS tokens:", error);
      alert("Failed to add to AVS tokens: " + error.message);
    }
  };

  // Remove from AVS Tokens
  const removeFromAVSTokens = async () => {
    try {
      if (!provider) return;
      const signer = provider.getSigner();
      const factory = new ethers.Contract(
        factoryAddress,
        TokenFactoryABI,
        signer
      );
      const tx = await factory.removeFromAVSTokens(avsTokenAddress);
      await tx.wait();
      alert("Token removed from AVS!");
    } catch (error) {
      console.error("Error removing from AVS tokens:", error);
      alert("Failed to remove from AVS tokens: " + error.message);
    }
  };

  // Pause Contract
  const pauseContract = async () => {
    try {
      if (!provider) return;
      const signer = provider.getSigner();
      const avs = new ethers.Contract(
        veristableAVSAddress,
        VeristableAVSABI,
        signer
      );
      const tx = await avs.pause();
      await tx.wait();
      setContractPaused(true);
      alert("Contract paused!");
    } catch (error) {
      console.error("Error pausing contract:", error);
      alert("Failed to pause contract: " + error.message);
    }
  };

  // Unpause Contract
  const unpauseContract = async () => {
    try {
      if (!provider) return;
      const signer = provider.getSigner();
      const avs = new ethers.Contract(
        veristableAVSAddress,
        VeristableAVSABI,
        signer
      );
      const tx = await avs.unpause();
      await tx.wait();
      setContractPaused(false);
      alert("Contract unpaused!");
    } catch (error) {
      console.error("Error unpausing contract:", error);
      alert("Failed to unpause contract: " + error.message);
    }
  };

  // Transfer Ownership
  const transferOwnership = async () => {
    try {
      if (!provider) return;
      const signer = provider.getSigner();
      const avs = new ethers.Contract(
        veristableAVSAddress,
        VeristableAVSABI,
        signer
      );
      const tx = await avs.transferOwnership(newOwnerAddress);
      await tx.wait();
      setContractOwner(newOwnerAddress);
      alert("Ownership transferred!");
    } catch (error) {
      console.error("Error transferring ownership:", error);
      alert("Failed to transfer ownership: " + error.message);
    }
  };

  // Get Token Info (Balance, Underwriting, Rewards)
  const getTokenInfo = async (tokenAddress) => {
    try {
      if (!provider || !tokenAddress) return;
      const token = new ethers.Contract(tokenAddress, TokenABI, provider);
      const avs = new ethers.Contract(
        veristableAVSAddress,
        VeristableAVSABI,
        provider
      );
      const balance = await token.balanceOf(account);
      const underwriting = await avs.underwritingAmounts(tokenAddress, account);
      const rewards = await avs.unclaimedRewards(tokenAddress, account);
      const totalUnder = await avs.totalUnderwriting(tokenAddress);
      const totalRew = await avs.totalRewards(tokenAddress);
      setUserBalance(ethers.utils.formatEther(balance));
      setUnclaimedRewards(ethers.utils.formatEther(rewards));
      setTotalUnderwriting(ethers.utils.formatEther(totalUnder));
      setTotalRewards(ethers.utils.formatEther(totalRew));
    } catch (error) {
      console.error("Error getting token info:", error);
    }
  };

  // Update info saat selectedToken berubah
  useEffect(() => {
    if (selectedToken) {
      getReserveBalance(selectedToken);
      getTokenInfo(selectedToken);
    }
  }, [selectedToken]);

  return (
    <div className="min-h-screen bg-gray-100 p-8">
      <div className="max-w-4xl mx-auto">
        <div className="flex justify-between items-center mb-8">
          <h1 className="text-3xl font-bold">Veristable Platform</h1>
          {!account ? (
            <button
              onClick={connectWallet}
              className="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
            >
              Connect Wallet
            </button>
          ) : (
            <p className="font-mono">{account}</p>
          )}
        </div>

        {account && (
          <div className="space-y-8">
            {/* Create Token Section */}
            <div className="bg-white p-6 rounded-lg shadow">
              <h2 className="text-xl font-semibold mb-4">Create New Token</h2>
              <div className="space-y-4">
                <input
                  type="text"
                  placeholder="Token Name"
                  className="w-full p-2 border rounded"
                  value={tokenName}
                  onChange={(e) => setTokenName(e.target.value)}
                />
                <input
                  type="text"
                  placeholder="Token Symbol"
                  className="w-full p-2 border rounded"
                  value={tokenSymbol}
                  onChange={(e) => setTokenSymbol(e.target.value)}
                />
                <button
                  onClick={createToken}
                  className="bg-green-500 text-white px-4 py-2 rounded hover:bg-green-600 w-full"
                >
                  Create Token
                </button>
              </div>
            </div>

            {/* Mint/Burn Token Section */}
            <div className="bg-white p-6 rounded-lg shadow">
              <h2 className="text-xl font-semibold mb-4">Mint/Burn Token</h2>
              <div className="space-y-4">
                <select
                  className="w-full p-2 border rounded"
                  value={selectedToken}
                  onChange={(e) => setSelectedToken(e.target.value)}
                >
                  <option value="">Select Token</option>
                  {userTokens.map((token) => (
                    <option key={token} value={token}>
                      {token}
                    </option>
                  ))}
                </select>
                <p>Your Balance: {userBalance} Tokens</p>
                <input
                  type="number"
                  placeholder="Mint Amount"
                  className="w-full p-2 border rounded"
                  value={mintAmount}
                  onChange={(e) => setMintAmount(e.target.value)}
                />
                <button
                  onClick={mintToken}
                  className="bg-purple-500 text-white px-4 py-2 rounded hover:bg-purple-600 w-full"
                >
                  Mint Token
                </button>
                <input
                  type="number"
                  placeholder="Burn Amount"
                  className="w-full p-2 border rounded"
                  value={burnAmount}
                  onChange={(e) => setBurnAmount(e.target.value)}
                />
                <button
                  onClick={burnToken}
                  className="bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600 w-full"
                >
                  Burn Token
                </button>
              </div>
            </div>

            {/* Reserve Management Section */}
            <div className="bg-white p-6 rounded-lg shadow">
              <h2 className="text-xl font-semibold mb-4">Reserve Management</h2>
              <div className="space-y-4">
                <select
                  className="w-full p-2 border rounded"
                  value={selectedToken}
                  onChange={(e) => setSelectedToken(e.target.value)}
                >
                  <option value="">Select Token</option>
                  {userTokens.map((token) => (
                    <option key={token} value={token}>
                      {token}
                    </option>
                  ))}
                </select>
                <p>Reserve Balance: {reserveBalance} ETH</p>
                <p>Last Update: {lastUpdateTimestamp}</p>
                <input
                  type="number"
                  placeholder="New Reserve Balance"
                  className="w-full p-2 border rounded"
                  value={newReserveBalance}
                  onChange={(e) => setNewReserveBalance(e.target.value)}
                />
                <button
                  onClick={setReserveBalance}
                  className="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600 w-full"
                >
                  Set Reserve Balance
                </button>
                <button onClick={updateReserveBalance}>
                  Set Reserve Balance
                </button>
              </div>
            </div>

            {/* Underwrite/Withdraw/Rewards Section */}
            <div className="bg-white p-6 rounded-lg shadow">
              <h2 className="text-xl font-semibold mb-4">
                Underwrite & Rewards
              </h2>
              <div className="space-y-4">
                <select
                  className="w-full p-2 border rounded"
                  value={selectedToken}
                  onChange={(e) => setSelectedToken(e.target.value)}
                >
                  <option value="">Select Token</option>
                  {userTokens.map((token) => (
                    <option key={token} value={token}>
                      {token}
                    </option>
                  ))}
                </select>
                <p>Unclaimed Rewards: {unclaimedRewards} Tokens</p>
                <p>Total Underwriting: {totalUnderwriting} Tokens</p>
                <p>Total Rewards: {totalRewards} Tokens</p>
                <input
                  type="number"
                  placeholder="Underwrite Amount"
                  className="w-full p-2 border rounded"
                  value={underwriteAmount}
                  onChange={(e) => setUnderwriteAmount(e.target.value)}
                />
                <button
                  onClick={underwriteTokens}
                  className="bg-teal-500 text-white px-4 py-2 rounded hover:bg-teal-600 w-full"
                >
                  Underwrite Tokens
                </button>
                <input
                  type="number"
                  placeholder="Withdraw Amount"
                  className="w-full p-2 border rounded"
                  value={withdrawAmount}
                  onChange={(e) => setWithdrawAmount(e.target.value)}
                />
                <button
                  onClick={withdrawTokens}
                  className="bg-orange-500 text-white px-4 py-2 rounded hover:bg-orange-600 w-full"
                >
                  Withdraw Tokens
                </button>
                <button
                  onClick={claimRewards}
                  className="bg-yellow-500 text-white px-4 py-2 rounded hover:bg-yellow-600 w-full"
                >
                  Claim Rewards
                </button>
                <input
                  type="number"
                  placeholder="Deposit Reward Amount"
                  className="w-full p-2 border rounded"
                  value={depositRewardAmount}
                  onChange={(e) => setDepositRewardAmount(e.target.value)}
                />
                <button
                  onClick={depositRewards}
                  className="bg-cyan-500 text-white px-4 py-2 rounded hover:bg-cyan-600 w-full"
                >
                  Deposit Rewards
                </button>
              </div>
            </div>

            {/* AVS Token Management Section */}
            <div className="bg-white p-6 rounded-lg shadow">
              <h2 className="text-xl font-semibold mb-4">
                AVS Token Management
              </h2>
              <div className="space-y-4">
                <input
                  type="text"
                  placeholder="Token Address"
                  className="w-full p-2 border rounded"
                  value={avsTokenAddress}
                  onChange={(e) => setAvsTokenAddress(e.target.value)}
                />
                <button
                  onClick={addToAVSTokens}
                  className="bg-indigo-500 text-white px-4 py-2 rounded hover:bg-indigo-600 w-full"
                >
                  Add to AVS Tokens
                </button>
                <button
                  onClick={removeFromAVSTokens}
                  className="bg-pink-500 text-white px-4 py-2 rounded hover:bg-pink-600 w-full"
                >
                  Remove from AVS Tokens
                </button>
              </div>
            </div>

            {/* Admin Controls Section */}
            <div className="bg-white p-6 rounded-lg shadow">
              <h2 className="text-xl font-semibold mb-4">Admin Controls</h2>
              <div className="space-y-4">
                <p>Total Tokens Owned: {userTokenCount}</p>
                <p>Contract Status: {contractPaused ? "Paused" : "Active"}</p>
                <p>Contract Owner: {contractOwner}</p>
                <button
                  onClick={pauseContract}
                  className="bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600 w-full"
                  disabled={contractPaused}
                >
                  Pause Contract
                </button>
                <button
                  onClick={unpauseContract}
                  className="bg-green-500 text-white px-4 py-2 rounded hover:bg-green-600 w-full"
                  disabled={!contractPaused}
                >
                  Unpause Contract
                </button>
                <input
                  type="text"
                  placeholder="New Owner Address"
                  className="w-full p-2 border rounded"
                  value={newOwnerAddress}
                  onChange={(e) => setNewOwnerAddress(e.target.value)}
                />
                <button
                  onClick={transferOwnership}
                  className="bg-gray-500 text-white px-4 py-2 rounded hover:bg-gray-600 w-full"
                >
                  Transfer Ownership
                </button>
              </div>
            </div>

            {/* User Tokens Section */}
            <div className="bg-white p-6 rounded-lg shadow">
              <h2 className="text-xl font-semibold mb-4">Your Tokens</h2>
              <div className="space-y-2">
                {userTokens.map((token) => (
                  <div key={token} className="p-4 border rounded">
                    <p className="font-mono">{token}</p>
                    <button
                      onClick={() => setSelectedToken(token)}
                      className="mt-2 bg-blue-500 text-white px-4 py-1 rounded text-sm"
                    >
                      Select Token
                    </button>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default TokenFactory;
