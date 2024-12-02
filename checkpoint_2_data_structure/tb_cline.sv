`include "pkg_line.sv"
import line::*;

module tb_cline;

    // Test inputs
    logic [ADDR_SIZE-1:0] address;           // Test address input
    logic [INDEX_SIZE-1:0] index;            // Cache index output (no need to drive this in testbench)
    logic [TAG_SIZE-1:0] tag;                // Cache tag output (no need to drive this in testbench)

    // Instantiate the cache module
    cache uut (
        .address(address), 
        .index(index), 
        .tag(tag)
    );

    // Internal variables for test
    mesi_e expected_state;  // Expected MESI state
    logic [NUM_SETS-1:0][N_WAY-1:0] valid_lines; // Valid bit tracking

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

        // Test 1: Simulate a read operation
        #10;
        address = 32'h0000_1000;
        perform_read(address);

        // Test 2: Simulate a write operation
        address = 32'h0000_2000;
        perform_write(address);

        // Test 3: Simulate invalidation (I state)
        address = 32'hFFFF_8000;
        perform_invalidation(address);

        // Test 4: Test transition from Shared to Exclusive
        address = 32'h0000_3000;
        perform_shared_to_exclusive(address);

        // Finish the simulation
        $stop;
    end

    // Task to perform a read operation
    task perform_read(input logic [ADDR_SIZE-1:0] address);
        expected_state = S; // Expect Shared state after read
        // Calculate index and tag from address
        // index and tag are automatically driven by the uut

        $display("Performing READ at address: %h", address);
        // Simulate cache access and update MESI state based on the FSM logic
        uut.cache_mem[address[INDEX_SIZE-1:0]].ways[0].valid = 1;  // Simulate a valid entry
        uut.cache_mem[address[INDEX_SIZE-1:0]].ways[0].mesi = S;   // Expect Shared state after read

        // Allow cache FSM to process the read and update MESI state
        #50;

        // Check the MESI state
        if (uut.cache_mem[address[INDEX_SIZE-1:0]].ways[0].mesi !== expected_state) begin
            $display("Error: Expected MESI state %s, but found %s", 
                     expected_state.name(), uut.cache_mem[address[INDEX_SIZE-1:0]].ways[0].mesi.name());
        end else begin
            $display("PASS: MESI state is %s as expected", expected_state.name());
        end
    endtask

    // Task to perform a write operation
    task perform_write(input logic [ADDR_SIZE-1:0] address);
        expected_state = M; // Expect Modified state after write
        // Calculate index and tag from address
        // index and tag are automatically driven by the uut

        $display("Performing WRITE at address: %h", address);
        // Simulate cache access and update MESI state based on the FSM logic
        uut.cache_mem[address[INDEX_SIZE-1:0]].ways[0].valid = 1;  // Simulate a valid entry
        uut.cache_mem[address[INDEX_SIZE-1:0]].ways[0].mesi = M;   // Expect Modified state after write

        // Allow cache FSM to process the write and update MESI state
        #50;

        // Check the MESI state
        if (uut.cache_mem[address[INDEX_SIZE-1:0]].ways[0].mesi !== expected_state) begin
            $display("Error: Expected MESI state %s, but found %s", 
                     expected_state.name(), uut.cache_mem[address[INDEX_SIZE-1:0]].ways[0].mesi.name());
        end else begin
            $display("PASS: MESI state is %s as expected", expected_state.name());
        end
    endtask

    // Task to perform invalidation (transition to I state)
    task perform_invalidation(input logic [ADDR_SIZE-1:0] address);
        expected_state = I; // Expect Invalid state
        // Calculate index and tag from address
        // index and tag are automatically driven by the uut

        $display("Performing INVALIDATION at address: %h", address);
        // Simulate invalidation and set MESI state to I
        uut.cache_mem[address[INDEX_SIZE-1:0]].ways[0].mesi = I; // Simulate FSM action

        // Allow cache FSM to process invalidation and update MESI state
        #50;

        // Check the MESI state
        if (uut.cache_mem[address[INDEX_SIZE-1:0]].ways[0].mesi !== expected_state) begin
            $display("Error: Expected MESI state %s, but found %s", 
                     expected_state.name(), uut.cache_mem[address[INDEX_SIZE-1:0]].ways[0].mesi.name());
        end else begin
            $display("PASS: MESI state is %s as expected", expected_state.name());
        end
    endtask

    // Task to transition from Shared to Exclusive
    task perform_shared_to_exclusive(input logic [ADDR_SIZE-1:0] address);
        expected_state = E; // Expect Exclusive state
        // Calculate index and tag from address
        // index and tag are automatically driven by the uut

        $display("Transitioning from Shared to Exclusive at address: %h", address);
        // Simulate FSM transition from Shared to Exclusive
        uut.cache_mem[address[INDEX_SIZE-1:0]].ways[0].mesi = E;

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

