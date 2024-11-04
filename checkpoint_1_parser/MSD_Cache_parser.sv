`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:  Satyajit Deokar
// 
// Create Date: 02.11.2024 12:03:05
// Design Name: 
// Module Name: MSD_Cache_parser
// Project Name: MSD_LAst Level Cache using MESI Protocol
// Target Devices: 
// Tool Versions: 
// Description: Working code to read and parse an input trace file 
//(the name of which is specified by the user) with correct default if none specified
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
  string trace_filename = "rwims.din"; 	//changed path
  int file;
  string line;

  typedef struct {
	logic [11:0] tag;
	logic [13:0] index;
	logic [5:0] offset;
} add_struct;

  function add_struct decode_address(logic[31:0] address);
	add_struct decode;
	decode.tag = address[31:20];
	decode.index = address[19:6];
	decode.offset = address[5:0];
	return decode;
  endfunction

  initial begin
    $display("Working code to read and parse an input trace file (the name of which is specified by the user) with correct default if none specified");

    // Check if a custom filename was provided
    if (!$value$plusargs("trace_file=%s", trace_filename)) begin
      $display("No input trace file specified. Using default: %s", trace_filename);
    end else begin
      $display("Using input trace file: %s", trace_filename);
    end

    // Open the trace file
    file = $fopen(trace_filename, "r");    	// Added else condition 
    if (file) begin
	 $display("File opened succesfully: %s", trace_filename);
    end else begin
     	 $fatal("Error opening file: %s", trace_filename);
    end 
    

    // Read and parse the file line-by-line
    while (!$feof(file)) begin
      int n;
      bit [31:0] address;
      add_struct address1;

      // Read a line from the file
      if ($fgets(line, file)) begin
        // Parse the line format "n address" where n is a number and address is a hex
        if ($sscanf(line, "%d %h", n, address) == 2) begin
          $display("\n %s - This is the instruction and the Addr. in the file", line); // Display each line
	  address1 = decode_address(address);
          $display("Parsed: n = %0d, address = %p", n, address1);

          // Process each trace event based on `n` value
          case (n)
            0: $display("Read request from L1 data cache %h", address);
            1: $display("Write request from L1 data cache %h", address);
            2: $display("Read request from L1 instruction cache %h", address);
            3: $display("Snooped read request %h", address);
            4: $display("Snooped write request %h", address);
            5: $display("Snooped read with intent to modify request %h", address);
            6: $display("Snooped invalidate command %h", address);
            8: $display("Clear the cache and reset all state");
            9: $display("Print contents and state of each valid cache line (doesn’t end 	       simulation!)");
            default: $display("Unknown trace event: %d", n);
          endcase
        end else begin
          $display("Invalid line format: %s", line);
        end
      end
    end

    // Close the file after reading
    $fclose(file);
    $display("Finished reading from %s.", trace_filename);
  end

endmodule

