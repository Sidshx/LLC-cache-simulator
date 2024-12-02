`include "pkg_line.sv"
import line::*;

// Testbench module
module tb_cline;

    // Test inputs
    logic [ADDR_SIZE-1:0] address;           // Test address input
    logic [INDEX_SIZE-1:0] index;            // Cache index output
    logic [TAG_SIZE-1:0] tag;                // Cache tag output

    // Instantiate the cache module
    cache uut (
        .address(address), 
        .index(index), 
        .tag(tag)
    );

    // Initial block to run the test
    initial begin
        // Display constants
        $display("NUM_SETS: %d", NUM_SETS);      // Display number of sets
        $display("INDEX_SIZE: %d", INDEX_SIZE);  // Display index size

        // Initialize cache in the testbench by calling the task
        uut.initialize_cache();  // Call the initialization task
        $display("Cache initialized successfully.");

        // Check if cache structure is formed correctly
        check_cache_structure();

        // Test 1: Load a test address and display outputs
        address = 32'h0000_1000;  // Example address
        #10;  // Wait for 10 time units
        $display("Address: %h, Index: %h, Tag: %h", address, index, tag);

        // Check cache access
        check_cache_access(address);

        // Test 2: Test with another address
        address = 32'h0001_2000;  // Another address
        #10;  // Wait for 10 time units
        $display("Address: %h, Index: %h, Tag: %h", address, index, tag);

        // Check cache access
        check_cache_access(address);

        // Test 3: Test with another address
        address = 32'hFFFF_8000;  // Another address
        #10;  // Wait for 10 time units
        $display("Address: %h, Index: %h, Tag: %h", address, index, tag);

        // Check cache access
        check_cache_access(address);

        // Finish the simulation
        $stop;
    end

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
    endtask

    // Function to check cache access
    task check_cache_access(input logic [ADDR_SIZE-1:0] address);
        logic [INDEX_SIZE-1:0] temp_index;
        logic [TAG_SIZE-1:0] temp_tag;

        // Calculate the index and tag
        temp_index = address[OFFSET_SIZE + INDEX_SIZE - 1 : OFFSET_SIZE];
        temp_tag = address[ADDR_SIZE - 1 : OFFSET_SIZE + INDEX_SIZE];

        // Check if the calculated index and tag match the expected values
        if (temp_index !== index) begin
            $display("Error: Calculated index %h does not match the expected index %h", temp_index, index);
        end
        if (temp_tag !== tag) begin
            $display("Error: Calculated tag %h does not match the expected tag %h", temp_tag, tag);
        end
    endtask

endmodule

