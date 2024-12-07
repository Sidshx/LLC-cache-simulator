package pkg_bus;

    // Import definitions from other packages
    import pkg_line::*; // Assumes set_st, NUM_SETS, INDEX_SIZE, TAG_SIZE are in pkg_cache

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

    // Functions
    function automatic snoop_result_e BusOperation(
        input bus_operation_e Busop,      // Type of bus operation (READ, WRITE, etc.)
        input logic [31:0] Address,       // Memory address involved in the operation
        input bit NormalMode              // Flag to enable or disable debug printing
    );

        snoop_result_e SnoopResult;

        // Call GetSnoopResult with Address and cache memory
        SnoopResult = GetSnoopResult(Address, cache_mem);

        // Print debug information if NormalMode is enabled
        if (NormalMode) begin
            $display("Busop: %0d, Address: %h, Snoop Result: %0d", Busop, Address, SnoopResult);
        end

        return SnoopResult;
    endfunction

    function automatic snoop_result_e GetSnoopResult(
        input logic [31:0] Address,        // Address to check
        input set_st cache_mem[NUM_SETS]  // Cache memory array
    );

        logic [INDEX_SIZE-1:0] index;       // Index derived from the address
        logic [TAG_SIZE-1:0] tag;           // Tag derived from the address
        snoop_result_e result = NOHIT;      // Default to NOHIT

        // Derive the index and tag from the address
        index = Address[OFFSET_SIZE + INDEX_SIZE - 1 : OFFSET_SIZE];
        tag = Address[31 : OFFSET_SIZE + INDEX_SIZE];

        // Check the cache lines in the indexed set
        for (int i = 0; i < N_WAY; i++) begin
            if (cache_mem[index].ways[i].valid && // Valid line
                cache_mem[index].ways[i].tag == tag) begin // Tag match
                if (cache_mem[index].ways[i].mesi == M) begin
                    result = HITM; // Modified line found
                    return result; // No need to continue
                end else begin
                    result = HIT; // Line found but not modified
                end
            end
        end

        return result; // Return HIT, HITM, or NOHIT
    endfunction



typedef enum logic [1:0] {
    GETLINE        = 2'b01,  // Request data for modified line in L1
    SENDLINE       = 2'b10,  // Send requested cache line to L1
    INVALIDATELINE = 2'b11,  // Invalidate a line in L1
    EVICTLINE      = 2'b00   // Evict a line from L1
} l2_l1_message_e;

function automatic void PutSnoopResult(
    input logic [31:0] Address,        // Address for the snoop result
    input snoop_result_e SnoopResult, // Snoop result value
    input bit NormalMode              // Debug mode flag
);
    if (NormalMode) begin
        $display("SnoopResult: Address = %h, SnoopResult = %0d", Address, SnoopResult);
    end
endfunction


function automatic void MessageToCache(
    input l2_l1_message_e Message,    // Message type (e.g., `GETLINE`, `SENDLINE`)
    input logic [31:0] Address,       // Address related to the message
    input bit NormalMode              // Debug mode flag
);
    if (NormalMode) begin
        $display("L2: Message = %0d, Address = %h", Message, Address);
    end
endfunction

















endpackage : pkg_bus






