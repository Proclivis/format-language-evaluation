-- device-ltc3887.dhall

{- This file is an example of a LTC3887 programming file.
-}

let recoverDevices = \(args: {channel : Text}) ->
    { 
        description = "Recover devices.",
        operation_type = "smbus_operation",
        operation_error_handling = "break_on_error",
        channel = args.channel,
        smbus_address = 0x5B,
        smbus_operation_structure = [
            "command_code", "transaction_type", "write_data", "use_pec"
            ],
        smbus_operation_steps = [
            ["0xE6", "write_byte" , "0x4F"  , "true"], -- MFR_ADDRESS
            ["0x15", "send_byte"  , "0x06"  , "true"], -- MFR_CONFIG-ALL disable PEC
            ["0x10", "send_byte"  , "0x00"  , "false"] -- WRITE_PROTECT disable WP
        ]
    }

let checkIfDisabled = \(args: {channel : Text, address : Natural}) ->
    { 
        description = "Configure device.",
        operation_type = "smbus_operation",
        operation_error_handling = "break_on_error",
        channel = args.channel,
        smbus_address = args.address,
        smbus_operation_structure = [
            "command_code", "transaction_type", "write_data", "expect_data", "and_mask", "use_pec"],
        smbus_operation_steps = [
            ["0x01", "read_byte" , "null"   , "0x00", "0x80" , "false"] -- OPERATION, evaluate bit 7
        ]
    }

let writeConfiguration = \(args: {channel : Text, address : Natural}) ->
    { 
        description = "Configure device.",
        operation_type = "smbus_operation",
        operation_error_handling = "break_on_error",
        channel = args.channel,
        smbus_address = args.address,
        smbus_operation_structure = [
            "command_code", "transaction_type", "write_data", "use_pec"
            ],
        smbus_operation_steps = [
            ["0x01", "write_byte"  , "0x80", "false"], -- OPERATION
            ["0x02", "write_byte"  , "00"  , "false"], -- ON_OFF_CONFIG
            ["null", "delay_in_ms" , "10"  , "false"] -- A hack to deal with IC's requiring txn delays / fit within mapping
--            within mapping
        ]
    }

let makeConfiguration = \(args: {description : Text, channel : Text, address : Natural}) ->
    let description = args.description
    let recover = recoverDevices {
        channel = args.channel
    }
    let disableCheck = checkIfDisabled { 
        channel = args.channel, 
        address = args.address 
    }
    let writeConfig = writeConfiguration { 
        channel = args.channel, 
        address = args.address 
    }
    in  { description,
          operation_type = "composition",
          composition_operation_steps_order = [
            "recover",
            "disableCheck",
            "writeConfig"
          ],
          composition_operation_steps = {
            recover,
            disableCheck,
            writeConfig
          }
        }


-- TODO let writeVerify = \(args: {description: Text}) ->

-- TODO
let makeVerify = \(args: {description : Text, channel : Text, address : Natural}) ->
    let description = args.description
    let channel = args.channel
    in  { description,
          channel
        }

-- TODO
let makePresence = \(args: {description : Text, channel : Text, address : Natural}) ->
    let description = args.description
    let channel = args.channel
    in  { description,
          channel
        }

-- EXPORT FUNCTIONS FOR USE IN SYSTEM FILE
-- Note how I only expose the make-related functions

in {makeConfiguration, makeVerify, makePresence}