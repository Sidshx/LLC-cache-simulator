// INCLUDE THE SNOOPONG BUS OPR. ALSO 

`include "pkg_line.sv"  // Import the package to use mesi_e
import line::*;
module mesi_fsm (
    input logic clk,
    input logic rst,
    input logic read_req,
    input logic write_req,
    input logic invalidate,
    output mesi_e current_state
);

    mesi_e state, next_state;

    // FSM: Sequential logic for state updates
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= I;  // Start in Invalid state
        end else begin
            state <= next_state; // Update to next state
        end
    end

    // FSM: Combinational logic for transitions
    always_comb begin
        // Default state
        next_state = state;

        case (state)
            I: begin
                if (read_req) begin
                    next_state = S; // Move to Shared on read also add a logic for copy and not of copy
                end else if (write_req) begin
                    next_state = M; // Move to Modified on write
                end
            end
            S: begin
                if (invalidate) begin
                    next_state = I; // Invalidate the line
                end else if (write_req) begin
                    next_state = M; // Move to Modified on write
                end
            end
            E: begin
                if (invalidate) begin
                    next_state = I; // Invalidate the line
                end else if (write_req) begin
                    next_state = M; // Move to Modified on write
                end
            end
            M: begin
                if (invalidate) begin
                    next_state = I; // Invalidate the line
                end
		else begin
                    next_state = M; // Stay in Modified on writes
                end
            end
        endcase
    end

    // Output the current state
    assign current_state = state;

endmodule


