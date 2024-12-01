`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
<<<<<<< HEAD
// Company: 
// Engineer: Aakash Siddharth | Satyajit Deokar | Siddesh Patil | Rajani Kallur
=======
// 
>>>>>>> ba8d507d55913c9a2131c8e2e0f8c3ba5f733e23
// 
// Create Date: 02.11.2024 12:03:05
// Design Name: 
// Module Name: MSD_Cache_parser
// Project Name: MSD_Last Level Cache using MESI Protocol
// Target Devices: 
// Tool Versions: 
// Description: Working code to read and parse an input trace file including Conditional Compilation
// (the name of which is specified by the user) with correct default if none specified
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: l26: changed path
// 
//////////////////////////////////////////////////////////////////////////////////

module MSD_Cache_parser;
  // Define the default trace file name
  string trace_filename = "rwims.din"; 	// changed path
  int file;
  string line;


  initial begin
    `ifdef DEBUG
      $display("Working code to read and parse an input trace file (the name of which is specified by the user) with correct default if none specified");
    `endif

    // Check if a custom filename was provided
    if (!$value$plusargs("trace_file=%s", trace_filename)) begin
      `ifdef DEBUG
        $display("No input trace file specified. Using default: %s", trace_filename);
      `endif
    end else begin
      `ifdef DEBUG
        $display("Using input trace file: %s", trace_filename);
      `endif
    end

    // Open the trace file
    `ifdef FILE_IO
      file = $fopen(trace_filename, "r");    	// Added else condition 
      if (file) begin
        `ifdef DEBUG
          $display("File opened successfully: %s \n", trace_filename);
        `endif
      end else begin
        $fatal("Error opening file: %s \n", trace_filename);
      end 

      // Read and parse the file line-by-line
      while (!$feof(file)) begin
        int n;
        bit [31:0] address;
      

        // Read a line from the file
        if ($fgets(line, file)) begin
          // Parse the line format "n address" where n is a number and address is a hex
          if ($sscanf(line, "%d %h", n, address) == 2) begin
          //  address1 = decode_address(address);
            `ifdef DEBUG
              $display("Parsed: n = %0d, \nAddress: Tag[31:20] = %h, Index[19:6] = %h , Offset[5:0] = %h",
                        n, address[31:20], address[19:6], address[5:0] );
            `endif

            // Process each trace event based on `n` value
            case (n)
              0: $display("Read request from L1 data cache, Address: %h \n", address);
              1: $display("Write request from L1 data cache, Address: %h\n", address);
              2: $display("Read request from L1 instruction cache, Address: %h\n", address);
              3: $display("Snooped read request, Address: %h\n", address);
              4: $display("Snooped write request, Address: %h\n", address);
              5: $display("Snooped read with intent to modify request, Address: %h\n", address);
              6: $display("Snooped invalidate command, Address: %h\n", address);
              8: $display("Clear the cache and reset all state\n");
              9: $display("Print contents and state of each valid cache line (doesn't end simulation!)\n");
              default: $display("Unknown trace event: %d\n", n);
            endcase
          end else begin
            $display("Invalid line format: %s", line);
          end
        end
      end

      // Close the file after reading
      $fclose(file);
      `ifdef DEBUG
        $display("Finished reading from %s.", trace_filename);
      `endif
    `else
      $display("File I/O functionality disabled. Define FILE_IO to enable.");
    `endif
  end

endmodule

