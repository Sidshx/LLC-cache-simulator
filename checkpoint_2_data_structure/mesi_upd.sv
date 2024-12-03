`include "pkg_line.sv"
`include "pkg_bus.sv"  // Import for bus_operation_e
import pkg_line::*;
import pkg_bus::*;

module mesi_upd (
    input logic clk,
    input logic rst,
    input bus_operation_e operation, // Bus operation type
    input logic copy,                // Copy signal (C)
    input logic [31:0] address,      // Address for snooping
    input set_st cache_mem[NUM_SETS], // Cache memory for snooping
    output mesi_e current_state      // Current MESI state
);

    mesi_e state, next_state;
    snoop_result_e snoop_result;     // Snoop result from the bus operation

    // FSM: Sequential logic for state updates
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= I; // Start in Invalid state
        end else begin
            state <= next_state; // Update to next state
        end
    end

    // FSM: Combinational logic for transitions
    always_comb begin
        // Default state
        next_state = state;
        
        // Check the snooping result based on the address
        snoop_result = BusOperation(operation, address, 1);  // Call BusOperation with NormalMode = 1 for debugging

        case (state)
            I: begin
                if (operation == READ) begin
                    if (copy) begin
                        next_state = S; // Shared if a copy exists
                    end else if (snoop_result == HIT) begin
                        next_state = S; // If snooping results in a hit, move to Shared
                    end else begin
                        next_state = E; // Exclusive if no copy exists
                    end
                end else if (operation == WRITE) begin
                    next_state = M; // Move to Modified on write
                end
            end
            S: begin
                if (operation == INVALIDATE) begin
                    next_state = I; // Invalidate the line
                end else if (operation == WRITE) begin
                    next_state = M; // Move to Modified on write
                end else if (operation == RWIM) begin
                    next_state = M; // Move to Modified on Read With Intent to Modify
                end
            end
            E: begin
                if (operation == INVALIDATE) begin
                    next_state = I; // Invalidate the line
                end else if (operation == WRITE) begin
                    next_state = M; // Move to Modified on write
                end
            end
            M: begin
                if (operation == INVALIDATE) begin
                    next_state = I; // Invalidate the line
                end else begin
                    next_state = M; // Stay in Modified on writes
                end
            end
        endcase
    end

    // Output the current state
    assign current_state = state;

endmodule

