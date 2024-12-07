`include "pkg_line.sv"
import pkg_line::*;
import pkg_bus::*; // Importing bus operations

module tb_cline;

    // Test inputs
    logic [ADDR_SIZE-1:0] address;           // Test address input
    logic [INDEX_SIZE-1:0] index;            // Cache index output (no need to drive this in testbench)
    logic [TAG_SIZE-1:0] tag;                // Cache tag output (no need to drive this in testbench)
    bus_operation_e operation;               // Enum for bus operations

    // Instantiate the cache module
    cache uut (
        .clk(clk),
        .rst(rst),
        .address(address),
        .index(index),
        .tag(tag)
    );

    // Internal variables for test
    mesi_e expected_state;  // Expected MESI state

    // Initial block to run the test
    initial begin
        // Display constants
        $display("NUM_SETS: %d", NUM_SETS);      // Display number of sets
        $display("INDEX_SIZE: %d", INDEX_SIZE);  // Display index size

        // Initialize cache
        uut.initialize_cache();

        // Check cache structure
        check_cache_structure();  // Verify that the cache structure is correct
        $display("Cache initialized and structure verified successfully.");

        // Check if the MESI protocol is initialized correctly
        check_mesi_initialization();

        // Test 1: Simulate a read operation (C signal logic will be checked)
        #10;
        address = 32'h0000_1000;
        operation = READ;
        perform_operation(address);
#10;
        // Test 2: Simulate a write operation (Write transition to M state)
        address = 32'h0000_2000;
        operation = WRITE;
        perform_operation(address);
#10;
        // Test 3: Simulate invalidation (I state)
        address = 32'hFFFF_8000;
        operation = INVALIDATE;
        perform_operation(address);
#10;
        // Test 4: Test transition from Shared to Exclusive (with snooping)
        address = 32'h0000_3000;
        operation = READ;
        perform_operation(address);
#10;
        // Finish the simulation
        $stop;
    end

    // Task to perform a bus operation based on the given address and operation type
    task perform_operation(input logic [ADDR_SIZE-1:0] address);
        $display("Performing operation %s at address: %h", operation.name(), address);

        // Set MESI state based on bus operation and snooping result
        case (operation)
            READ: begin
                // Perform read and check snooping for copy
                expected_state = (BusOperation(operation, address, 1) == HIT) ? S : E;
                // Trigger read
                uut.cache_mem[address[INDEX_SIZE-1:0]].ways[0].valid = 1;
                uut.cache_mem[address[INDEX_SIZE-1:0]].ways[0].mesi = expected_state;
            end

            WRITE: begin
                expected_state = M; // Expect Modified state after write
                // Trigger write
                uut.cache_mem[address[INDEX_SIZE-1:0]].ways[0].valid = 1;
                uut.cache_mem[address[INDEX_SIZE-1:0]].ways[0].mesi = expected_state;
            end

            INVALIDATE: begin
                expected_state = I; // Expect Invalid state after invalidate
                // Trigger invalidate
                uut.cache_mem[address[INDEX_SIZE-1:0]].ways[0].mesi = I;
            end

            default: begin
                expected_state = I; // Default invalidation state
            end
        endcase

        // Allow cache FSM to process and update MESI state
        #50;

        // Check the MESI state
        if (uut.cache_mem[address[INDEX_SIZE-1:0]].ways[0].mesi !== expected_state) begin
            $display("Error: Expected MESI state %s, but found %s", 
                     expected_state.name(), uut.cache_mem[address[INDEX_SIZE-1:0]].ways[0].mesi.name());
        end else begin
            $display("PASS: MESI state is %s as expected", expected_state.name());
        end
    endtask

    // Task to check MESI initialization
    task check_mesi_initialization();
        $display("Checking MESI protocol initialization...");
        for (int i = 0; i < NUM_SETS; i++) begin
            for (int j = 0; j < N_WAY; j++) begin
                if (uut.cache_mem[i].ways[j].mesi !== I) begin
                    $display("Error: MESI state not initialized to Invalid in set %d, way %d", i, j);
                end
            end
        end
        $display("PASS: MESI protocol initialized correctly.");
    endtask

    // Function to check cache structure
    task check_cache_structure();
        $display("Checking cache structure...");

        // Check if cache_mem is initialized properly
        for (int i = 0; i < NUM_SETS; i++) begin
            if (uut.cache_mem[i].plru_bits !== '0) begin
                $display("Error: PLRU bits are not zero in set %d", i);
            end

            for (int j = 0; j < N_WAY; j++) begin
                if (uut.cache_mem[i].ways[j].valid !== 0) begin
                    $display("Error: Line %d in set %d has invalid 'valid' bit", j, i);
                end
                if (uut.cache_mem[i].ways[j].tag !== 0) begin
                    $display("Error: Line %d in set %d has invalid 'tag' value", j, i);
                end
            end
        end
        $display("PASS: Cache structure is valid.");
    endtask

endmodule   
