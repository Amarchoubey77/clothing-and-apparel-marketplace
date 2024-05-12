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

    use clothing_marketplace::store::{Self, Apparel, ApparelPublisher};
    use clothing_marketplace::floor_price::{Self};
    use clothing_marketplace::royalty_rule::{Self};
    use clothing_marketplace::helpers::{init_test_helper};

    const TEST_ADDRESS1: address = @0xB;
    const TEST_ADDRESS2: address = @0xC;

    #[test]
    public fun test_create_kiosk() {
        let scenario_test = init_test_helper();
        let scenario = &mut scenario_test;
        // Create a kiosk for the marketplace
        next_tx(scenario, TEST_ADDRESS1);
        {
            let cap = store::new(ts::ctx(scenario));
            transfer::public_transfer(cap, TEST_ADDRESS1);
        };

        // Create a policy for apparel
        next_tx(scenario, TEST_ADDRESS1);
        {
            let publisher = ts::take_shared<ApparelPublisher>(scenario);
            store::new_policy(&publisher, ts::ctx(scenario));

            ts::return_shared(publisher);
        };
        
        // Add a royalty rule
        next_tx(scenario, TEST_ADDRESS1);
        {
            let policy = ts::take_shared<TransferPolicy<Apparel>>(scenario);
            let cap = ts::take_from_sender<TransferPolicyCap<Apparel>>(scenario);
            let amount_bp: u16 = 100;
            let min_amount: u64 = 0;

            royalty_rule::add(&mut policy, &cap, amount_bp, min_amount);
           
            ts::return_to_sender(scenario, cap);
            ts::return_shared(policy);
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

            let apparel_store = store::new_apparel(name, description, price, stock, size, color, ts::ctx(scenario));
 
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
            let royalty_price  = mint_for_testing(20, ts::ctx(scenario));
            // Get item ID from effects
            let id_ = ts::created(&nft_data);
            let item_id = id_[0];
        
            let (item, request) = kiosk::purchase<Apparel>(&mut kiosk, item_id, price);

            royalty_rule::pay(&mut policy, &mut request, royalty_price);
            // Confirm the request. Destroy the hot potato
            let (item_id, paid, from ) = tp::confirm_request(&policy, request);

            assert_eq(kiosk::item_count(&kiosk), 0);
            assert_eq(kiosk::has_item(&kiosk, item_id), false);

            transfer::public_transfer(item, TEST_ADDRESS2);
         
            ts::return_shared(kiosk);
            ts::return_shared(policy);
        };

        // Withdraw royalty amount from TP
        next_tx(scenario, TEST_ADDRESS1);
        {
            let cap = ts::take_from_sender<TransferPolicyCap<Apparel>>(scenario);
            let policy = ts::take_shared<TransferPolicy<Apparel>>(scenario);
            let amount = option::none();
            option::fill(&mut amount, 20);

            let coin_ = tp::withdraw(&mut policy, &cap, amount, ts::ctx(scenario));

            transfer::public_transfer(coin_, TEST_ADDRESS1);
        
            ts::return_to_sender(scenario, cap);
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

        ts::end(scenario_test);
    }
}
