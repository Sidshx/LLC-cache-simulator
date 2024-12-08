`include "pkg_line.sv"

package pkg_bus;

    // Import definitions from other packages
    import pkg_line::*; // Assumes set_st, NUM_SETS, INDEX_SIZE, TAG_SIZE are in pkg_cache

    logic NormalMode = 1;


    // Enumerations
    typedef enum logic [2:0] {
        READ      = 3'b001, // Read operation
        WRITE     = 3'b010, // Write operation
        INVALIDATE = 3'b011, // Invalidate operation
        RWIM      = 3'b100  // Read With Intent to Modify
    } bus_operation_e;

    typedef struct packed {
        bus_operation_e operation;   // Bus operation type
        logic [31:0] address;        // Address for the operation
        logic [3:0] cache_id;        // ID of the cache initiating the operation
    } bus_msg_st;

    typedef enum logic [1:0] {
        NOHIT = 2'b00,  // No hit
        HIT   = 2'b01,  // Hit
        HITM  = 2'b10   // Hit to Modified
    } snoop_result_e;

    typedef enum logic [2:0] {
        GETLINE       = 3'b001, // Request data for modified line in L1
        SENDLINE      = 3'b010, // Send requested cache line to L1
        INVALIDATELINE = 3'b011, // Invalidate a line in L1
        EVICTLINE     = 3'b100  // Evict a line from L1
    } l2_l1_msg_e;

    // Functions
    function automatic void BusOperation(
        input bus_operation_e busop,      // Type of bus operation (READ, WRITE, etc.)
        input logic [31:0] addr,          // Memory address involved in the operation
        input bit NormalMode              // Flag to enable or disable debug printing
    );

        snoop_result_e SnoopResult;

        // Call GetSnoopResult with Address and cache memory
        SnoopResult = GetSnoopResult(addr);

        // Print debug information if NormalMode is enabled
        if (NormalMode) begin
            $display("Busop: %0d, Address: %h, Snoop Result: %0d", busop.name(), addr, SnoopResult.name());
        end
	
	if (busop == READ || RWIM) begin
	increment_read();
	end else if (busop == WRITE) begin
        $display("Calling increment_write()");	
	increment_write();
	end

//        return SnoopResult;

    endfunction

    function void PutSnoopResult(
        input logic [31:0] addr,          // Address to report
        input snoop_result_e SnoopResult  // Snoop result to report
    );
        if (NormalMode) begin
            $display("SnoopResult: Address %h, SnoopResult: %0d", addr, SnoopResult.name());
        end
    endfunction

    function void MessageToCache(
        input l2_l1_msg_e msg,            // Bus operation type (e.g., READ, WRITE)
        input logic [31:0] addr          // Memory address associated with the operation
    );
        if (NormalMode) begin
            $display("L2: %0d %h", msg.name(), addr);
        end
    endfunction

    function automatic snoop_result_e GetSnoopResult(
        input logic [31:0] addr          // Address to check
    );
        // Extract the two least significant bits (LSBs) of the address
        logic [1:0] lsb = addr[1:0];
        
        // Declare the result
        snoop_result_e result;

        // Determine the snoop result based on the LSBs
        case (lsb)
            2'b00: result = HIT;
            2'b01: result = HITM;
            default: result = NOHIT; // Covers 2'b10 and 2'b11
        endcase

        return result; // Return the determined snoop result
    endfunction

endpackage : pkg_bus

