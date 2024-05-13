#[test_only]
module clothing_marketplace::test_store {
    use sui::test_scenario::{Self as ts, next_tx, Scenario};
    use sui::transfer;
    use sui::test_utils::{assert_eq};
    use sui::kiosk::{Self, Kiosk, KioskOwnerCap};
    use sui::transfer_policy::{Self as tp, TransferPolicy, TransferPolicyCap};
    use sui::object;
    use sui::coin::{mint_for_testing};
    use std::string::{Self};
    use std::collections::HashMap;
    use std::option::{Self, Option};

    use clothing_marketplace::clothing_marketplace::{Self, Apparel, ApparelPublisher, new_order, Order, new_shopping_cart, ShoppingCart, new_customer_account, CustomerAccount, add_item_to_cart, remove_item_from_cart, checkout, update_order_status};

    const TEST_ADDRESS1: address = @0xB;
    const TEST_ADDRESS2: address = @0xC;

    #[test]
    public fun test_create_kiosk() {
        let scenario_test = init_test_helper();
        let scenario = &mut scenario_test;
        // Create a kiosk for the marketplace
        next_tx(scenario, TEST_ADDRESS1);
        {
            let cap = clothing_marketplace::new(ts::ctx(scenario));
            transfer::public_transfer(cap, TEST_ADDRESS1);
        };

        // Create a policy for apparel
        next_tx(scenario, TEST_ADDRESS1);
        {
            let publisher = ts::take_shared<ApparelPublisher>(scenario);
            clothing_marketplace::new_policy(&publisher, ts::ctx(scenario));

            ts::return_shared(publisher);
        };

        // Create an apparel item
        next_tx(scenario, TEST_ADDRESS1);
        {
            let name = String::from("T-shirt");
            let description = String::from("Comfortable cotton T-shirt");
            let color = String::from("Red");
            let price: u64 = 2000;
            let stock: u64 = 100;
            let size = String::from("M");

            let apparel_store = clothing_marketplace::new_apparel(name, description, price, stock, size, color, ts::ctx(scenario));

            transfer::public_transfer(apparel_store, TEST_ADDRESS1);
        };

        let nft_data = next_tx(scenario, TEST_ADDRESS1);

        // Place the apparel item to the kiosk
        next_tx(scenario, TEST_ADDRESS1);
        {
            let apparel = ts::take_from_sender<Apparel>(scenario);
            let kiosk_cap = ts::take_from_sender<KioskOwnerCap>(scenario);
            let kiosk =  ts::take_shared<Kiosk>(scenario);
            // Get item ID from effects
            let id_ = ts::created(&nft_data);
            let item_id = id_[0];

            kiosk::place(&mut kiosk, &kiosk_cap, apparel);

            assert_eq(kiosk::item_count(&kiosk), 1);

            assert_eq(kiosk::has_item(&kiosk, item_id), true);
            assert_eq(kiosk::is_locked(&kiosk, item_id), false);
            assert_eq(kiosk::is_listed(&kiosk, item_id), false);

            ts::return_shared(kiosk);
            ts::return_to_sender(scenario, kiosk_cap);
        };

        // List the apparel item to the kiosk
        next_tx(scenario, TEST_ADDRESS1);
        {
            let kiosk_cap = ts::take_from_sender<KioskOwnerCap>(scenario);
            let kiosk =  ts::take_shared<Kiosk>(scenario);
            let price : u64 = 2000;
            // Get item ID from effects
            let id_ = ts::created(&nft_data);
            let item_id = id_[0];

            kiosk::list<Apparel>(&mut kiosk, &kiosk_cap, item_id, price);

            assert_eq(kiosk::item_count(&kiosk), 1);

            assert_eq(kiosk::has_item(&kiosk, item_id), true);
            assert_eq(kiosk::is_locked(&kiosk, item_id), false);
            assert_eq(kiosk::is_listed(&kiosk, item_id), true);

            ts::return_shared(kiosk);
            ts::return_to_sender(scenario, kiosk_cap);
        };

        // Purchase the item
        next_tx(scenario, TEST_ADDRESS2);
        {
            let kiosk =  ts::take_shared<Kiosk>(scenario);
            let policy = ts::take_shared<TransferPolicy<Apparel>>(scenario);
            let price  = mint_for_testing(2000, ts::ctx(scenario));
            // Get item ID from effects
            let id_ = ts::created(&nft_data);
            let item_id = id_[0];

            let (item, request) = kiosk::purchase<Apparel>(&mut kiosk, item_id, price);

            // Confirm the request. Destroy the hot potato
            let (item_id, paid, from ) = tp::confirm_request(&policy, request);

            assert_eq(kiosk::item_count(&kiosk), 0);
            assert_eq(kiosk::has_item(&kiosk, item_id), false);

            transfer::public_transfer(item, TEST_ADDRESS2);

            ts::return_shared(kiosk);
            ts::return_shared(policy);
        };

        // Withdraw from kiosk
        next_tx(scenario, TEST_ADDRESS1);
        {
            let kiosk =  ts::take_shared<Kiosk>(scenario);
            let cap = ts::take_from_sender<KioskOwnerCap>(scenario);
            let amount = option::none();
            option::fill(&mut amount, 2000);

            let coin_ = kiosk::withdraw(&mut kiosk, &cap, amount, ts::ctx(scenario));

            transfer::public_transfer(coin_, TEST_ADDRESS1);

            ts::return_shared(kiosk);
            ts::return_to_sender(scenario, cap);
        };

        // Test shopping cart and order functionality
        // Test shopping cart and order functionality
    next_tx(scenario, TEST_ADDRESS{
        let username = String::from("customer1");
        let email = String::from("customer1@example.com");
        let password = String::from("password1");

        // Create a new customer account with an empty shopping cart
        let account = new_customer_account(username, email, password, ts::ctx(scenario));

        // Creat    let name = String::from("Jeans");
        let description = String::from("Denim jeans");
        let color = String::from("Blue");
        let price: u64 = 5000;
        let stock: u64 = 50;
        let size = String::from("L");
        let apparel = clothing_marketplace::new_apparel(name, description, price, stock, size, color, ts::ctx(scenario));
        let apparel_id = object::uid_to_inner(&object::uid_to_bytes(&object::id(&apparel)));

        // Add the apparel item to the shopping cart
        let cart = object::borrow_mut<ShoppingCart>(&mut account.shopping_cart);
        add_item_to_cart(cart, apparel_id, 2);

        // Remove one item from the shopping cart
        remove_item_from_cart(cart, apparel_id, 1);

        // Place an order
        let order = checkout(&mut account, ts::ctx(scenario));

        // Update the order status
        let mut order_ref = object::borrow_mut<Order>(&mut order);
        update_order_status(&mut order_ref, String::from("Shipped"));

        // Verify the order details
        assert_eq(order_ref.items.get(&apparel_id), Some(&1));
        assert_eq(order_ref.total_amount, price);
        assert_eq(order_ref.status, String::from("Shipped"));

        // Verify the shopping cart is reset
        let cart = object::borrow<ShoppingCart>(&account.shopping_cart);
        assert_eq(cart.items.is_empty(), true);
        assert_eq(cart.total_amount, 0);

        transfer::public_transfer(account, TEST_ADDRESS2);
    }

    ts::end(scenario_test);
}