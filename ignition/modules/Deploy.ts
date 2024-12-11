import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

// Replace the VRF public key with a real one, if you have it.
// For demonstration, we'll use a placeholder value.
const DEFAULT_VRF_PUBLIC_KEY = "0x0582fB623317d4B711Da3D7658cd6f834b508417";

const OracleAndConsumerModule = buildModule("OracleAndConsumerModule", (m) => {
  // Parameters (these can be set via ignition CLI or hardhat.config.ts)
  const vrfPublicKey = m.getParameter("vrfPublicKey", DEFAULT_VRF_PUBLIC_KEY);

  // Deploy the VRF Oracle with the public key
  const oracle = m.contract("VRFOracleWithCallback", [vrfPublicKey]);

  // Deploy the improved random consumer with the oracle's address
  const consumer = m.contract("ImprovedRandomConsumer", [oracle]);

  // Return the deployed contracts
  return { oracle, consumer };
});

export default OracleAndConsumerModule;
