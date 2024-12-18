\m5_TLV_version 1d: tl-x.org
\m5
   use(m5-1.0)
   
   
   // ########################################################
   // #                                                      #
   // #  Empty template for Tiny Tapeout Makerchip Projects  #
   // #                                                      #
   // ########################################################
   
   // ========
   // Settings
   // ========
   
   //-------------------------------------------------------
   // Build Target Configuration
   //
   var(my_design, tt_um_example)   /// The name of your top-level TT module, to match your info.yml.
   var(target, ASIC)   /// Note, the FPGA CI flow will set this to FPGA.
   //-------------------------------------------------------
   
   va…
\m5_TLV_version 1d: tl-x.org
\m5
   use(m5-1.0)
   
   
   // ########################################################
   // #                                                      #
   // #  Empty template for Tiny Tapeout Makerchip Projects  #
   // #                                                      #
   // ########################################################
   
   // ========
   // Settings
   // ========
   
   //-------------------------------------------------------
   // Build Target Configuration
   //
   var(my_design, tt_um_example)   /// The name of your top-level TT module, to match your info.yml.
   var(target, ASIC)   /// Note, the FPGA CI flow will set this to FPGA.
   //-------------------------------------------------------
   
   var(in_fpga, 1)   /// 1 to include the demo board. (Note: Logic will be under /fpga_pins/fpga.)
   var(debounce_inputs, 0)         /// 1: Provide synchronization and debouncing on all input signals.
                                   /// 0: Don't provide synchronization and debouncing.
                                   /// m5_if_defined_as(MAKERCHIP, 1, 0, 1): Debounce unless in Makerchip.
   
   // ======================
   // Computed From Settings
   // ======================
   
   // If debouncing, a user's module is within a wrapper, so it has a different name.
   var(user_module_name, m5_if(m5_debounce_inputs, my_design, m5_my_design))
   var(debounce_cnt, m5_if_defined_as(MAKERCHIP, 1, 8'h03, 8'hff))

\SV
   // Include Tiny Tapeout Lab.
   m4_include_lib(['https:/']['/raw.githubusercontent.com/os-fpga/Virtual-FPGA-Lab/5744600215af09224b7235479be84c30c6e50cb7/tlv_lib/tiny_tapeout_lib.tlv'])

module spi_tft_controller (
    input wire clk,           // System clock
    input wire rst,           // Reset signal
    input wire start,         // Start signal
    input wire [7:0] data_in, // 8-bit data input
    input wire dc_select,     // DC pin: 0=Command, 1=Data
    output reg cs,            // Chip Select
    output reg sclk,          // SPI Clock
    output reg mosi,          // Master Out Slave In
    output reg dc,            // Data/Command pin
    output reg reset,         // Reset pin (active low)
    output reg led            // Backlight (always on)
);

// Parameters
parameter CLK_DIV = 4; // SPI clock divider

// Internal Registers
reg [7:0] shift_reg;  // Shift register
reg [3:0] clk_cnt;    // Clock divider counter
reg [2:0] bit_cnt;    // Bit counter
reg [1:0] state;      // State register

// State Encoding
parameter IDLE = 2'b00, LOAD = 2'b01, TRANSFER = 2'b10, DONE = 2'b11;

// Reset and LED initialization
initial begin
    reset = 1'b0; // Active reset
    led = 1'b1;   // Backlight ON
end

// SPI State Machine
always @(posedge clk or posedge rst) begin
    if (rst) begin
        cs <= 1; sclk <= 0; mosi <= 0; dc <= 0;
        reset <= 0; state <= IDLE;
        clk_cnt <= 0; bit_cnt <= 0; shift_reg <= 8'b0;
    end else begin
        case (state)
            IDLE: begin
                reset <= 1;       // Release reset
                cs <= 1;          // Deactivate chip select
                if (start) begin
                    shift_reg <= data_in;
                    dc <= dc_select;
                    cs <= 0;      // Activate chip select
                    state <= LOAD;
                end
            end
            LOAD: begin
                clk_cnt <= 0; bit_cnt <= 0;
                state <= TRANSFER;
            end
            TRANSFER: begin
                if (clk_cnt == CLK_DIV - 1) begin
                    clk_cnt <= 0;
                    sclk <= ~sclk; // Toggle SPI clock
                    if (!sclk) begin
                        mosi <= shift_reg[7]; // Send MSB first
                        shift_reg <= {shift_reg[6:0], 1'b0}; // Shift left
                        bit_cnt <= bit_cnt + 1;
                        if (bit_cnt == 7) state <= DONE;
                    end
                end else clk_cnt <= clk_cnt + 1;
            end
            DONE: begin
                cs <= 1; // Deactivate chip select
                state <= IDLE;
            end
        endcase
    end
end

endmodule








\TLV my_design()
   
   
   
   // ==================
   // |                |
   // | YOUR CODE HERE |
   // |                |
   // ==================
   
   // Note that pipesignals assigned here can be found under /fpga_pins/fpga.
   
   
   
   
   \SV_plus
      spi_tft_controller spi(*clk, *reset,
         $start,         // Start signal to begin transmission
         $data_in[7:0],  // 8-bit data input
         $dc_select,     // DC pin (0=Command, 1=Data)
         //output
         *uo_out[3] ,            // Chip Select
         *uo_out[4],       // SPI Clock
         *uo_out[0],          // SDA
         *uo_out[1],           // A0
         *uo_out[2],       //reset
         *uo_out[5]       //led
         
         );
      
   
   
   
   // Connect Tiny Tapeout outputs. Note that uio_ outputs are not available in the Tiny-Tapeout-3-based FPGA boards.
   //*uo_out = 8'b0;
   m5_if_neq(m5_target, FPGA, ['*uio_out = 8'b0;'])
   m5_if_neq(m5_target, FPGA, ['*uio_oe = 8'b0;'])

// Set up the Tiny Tapeout lab environment.
\TLV tt_lab()
   // Connect Tiny Tapeout I/Os to Virtual FPGA Lab.
   m5+tt_connections()
   // Instantiate the Virtual FPGA Lab.
   m5+board(/top, /fpga, 7, $, , my_design)
   // Label the switch inputs [0..7] (1..8 on the physical switch panel) (top-to-bottom).
   m5+tt_input_labels_viz(['"UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED"'])

\SV

// ================================================
// A simple Makerchip Verilog test bench driving random stimulus.
// Modify the module contents to your needs.
// ================================================

module top(input logic clk, input logic reset, input logic [31:0] cyc_cnt, output logic passed, output logic failed);
   // Tiny tapeout I/O signals.
   logic [7:0] ui_in, uo_out;
   m5_if_neq(m5_target, FPGA, ['logic [7:0] uio_in, uio_out, uio_oe;'])
   logic [31:0] r;  // a random value
   always @(posedge clk) r <= m5_if_defined_as(MAKERCHIP, 1, ['$urandom()'], ['0']);
   assign ui_in = r[7:0];
   m5_if_neq(m5_target, FPGA, ['assign uio_in = 8'b0;'])
   logic ena = 1'b0;
   logic rst_n = ! reset;
   logic start,dc_select;
   logic [7:0]data_in;
   m5_user_module_name tt(.*);
   
   logic cs = uo_out[3];
   /*
   // Or, to provide specific inputs at specific times (as for lab C-TB) ...
   // BE SURE TO COMMENT THE ASSIGNMENT OF INPUTS ABOVE.
   // BE SURE TO DRIVE THESE ON THE B-PHASE OF THE CLOCK (ODD STEPS).
   // Driving on the rising clock edge creates a race with the clock that has unpredictable simulation behavior.
   */
   // Stimulus generation
    initial begin
        // Initialize inputs
         start = 0; data_in = 0; dc_select = 0;
        #100; // Hold reset for 100 ns

        
        // Send commands sequentially
        send_command(8'h2A, 0); // Column address set (Command)
        send_command(8'h00, 1); // Start column = 0 (Data)
        send_command(8'h7F, 1); // End column = 127 (Data)

        send_command(8'h2B, 0); // Row address set (Command)
        send_command(8'h00, 1); // Start row = 0 (Data)
        send_command(8'h7F, 1); // End row = 127 (Data)

        send_command(8'h2C, 0); // Memory write (Command)

        // Send pixel data (example: '7' row-by-row)
        send_command(8'hF8, 1); // Row 0
        send_command(8'h18, 1); // Row 1
        send_command(8'h30, 1); // Row 2
        send_command(8'h60, 1); // Row 3
        send_command(8'hC0, 1); // Row 4
        send_command(8'hC0, 1); // Row 5
        send_command(8'hC0, 1); // Row 6

        #500; // Wait and stop simulation
        $stop;
    end
   
    // Task to send a command or data
    task send_command(input [7:0] command, input dc_val);
        begin
            @(posedge clk); // Wait for clock edge
            data_in = command;   // Load data
            dc_select = dc_val;  // Set DC pin (0=Command, 1=Data)
            start = 1;           // Assert start
            @(posedge clk);
            start = 0;           // Deassert start
            // Wait for SPI transfer to complete
            wait (cs == 1);
        end
    endtask

   

   // Instantiate the Tiny Tapeout module.
   
   
   assign passed = top.cyc_cnt > 80;
   assign failed = 1'b0;
endmodule


// Provide a wrapper module to debounce input signals if requested.
m5_if(m5_debounce_inputs, ['m5_tt_top(m5_my_design)'])
\SV



// =======================
// The Tiny Tapeout module
// =======================

module m5_user_module_name (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    m5_if_eq(m5_target, FPGA, ['/']['*'])   // The FPGA is based on TinyTapeout 3 which has no bidirectional I/Os (vs. TT6 for the ASIC).
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    m5_if_eq(m5_target, FPGA, ['*']['/'])
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
   wire reset = ! rst_n;

   // List all potentially-unused inputs to prevent warnings
   wire _unused = &{ena, clk, rst_n, 1'b0};

\TLV
   /* verilator lint_off UNOPTFLAT */
   m5_if(m5_in_fpga, ['m5+tt_lab()'], ['m5+my_design()'])

\SV_plus
   
   // ==========================================
   // If you are using Verilog for your design,
   // your Verilog logic goes here.
   // Note, output assignments are in my_design.
   // ==========================================

\SV
endmodule
