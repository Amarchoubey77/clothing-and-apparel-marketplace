# Clothing Marketplace Smart Contract

This smart contract defines the functionality for a clothing marketplace on the Sui blockchain framework.

## Overview

The Clothing Marketplace smart contract allows users to manage a clothing store, including adding new apparel items, updating stock and details, managing orders, and handling customer accounts.

## Features

- **Add Apparel:** Add a new apparel item to the store with details such as name, description, price, stock, size, and color.
- **Get Apparel:** Retrieve details of all apparel items available in the store.
- **Delete Apparel:** Remove an apparel item from the store.
- **Update Stock:** Update the stock of an apparel item.
- **Update Details:** Modify details such as name, description, price, size, and color of an apparel item.
- **Create Order:** Allow users to create a new order for purchasing apparel items.
- **Get Order:** Retrieve information about a specific order by its ID.
- **Manage Customer Accounts:** Enable users to create and manage customer accounts for tracking orders and managing shopping carts.

## Note

- Ensure to handle errors such as apparel not found and insufficient stock.
- Transactions such as adding, updating, and purchasing apparel items require sufficient gas for execution.
- Access control mechanisms can be implemented to restrict certain operations to authorized users only.
- Consider implementing events to emit notifications for important actions like order placements or stock updates.

## Dependency

- This DApp relies on the Sui blockchain framework for its smart contract functionality.
- Ensure you have the Move compiler installed and configured to the appropriate framework (e.g., `framework/devnet` for Devnet or `framework/testnet` for Testnet).

```bash
Sui = { git = "https://github.com/MystenLabs/sui.git", subdir = "crates/sui-framework/packages/sui-framework", rev = "framework/devnet" }
```

## Installation

Follow these steps to deploy and use the Clothing Marketplace:

1. **Move Compiler Installation:**
   Ensure you have the Move compiler installed. Refer to the [Sui documentation](https://docs.sui.io/) for installation instructions.

2. **Compile the Smart Contract:**
   Switch the dependencies in the `Sui` configuration to match your chosen framework (`framework/devnet` or `framework/testnet`), then build the contract.

   ```bash
   sui move build
   ```

3. **Deployment:**
   Deploy the compiled smart contract to your chosen blockchain platform using the Sui command-line interface.

   ```bash
   sui client publish --gas-budget 100000000 --json
   ```

