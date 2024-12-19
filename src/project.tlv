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

// SPI-based TFT Display Example: Displaying Number 7

module tft_display (
    input wire clk,
    input wire reset,
    output wire tft_sck,
    output wire tft_mosi,
    output wire tft_dc,  // Data/Command pin
    output wire tft_cs,  // Chip Select
    output wire tft_rst, // Reset pin
    output reg busy      // Busy signal
);

    // Parameters for screen dimensions
    parameter WIDTH = 128;
    parameter HEIGHT = 128;

    // State machine states
    typedef enum reg [1:0] {
        INIT = 2'b00,
        SEND_COMMAND = 2'b01,
        SEND_DATA = 2'b10,
        DONE = 2'b11
    } state_t;

    state_t current_state, next_state;

    // SPI signals
    reg [7:0] spi_data;
    reg spi_start;
    wire spi_done;

    // SPI Module Instantiation
    spi_controller spi (
        .clk(clk),
        .reset(reset),
        .data_in(spi_data),
        .start(spi_start),
        .sck(tft_sck),
        .mosi(tft_mosi),
        .done(spi_done)
    );

    // TFT Control Pins
    assign tft_cs = 1'b0;  // Always selected (active low)
    assign tft_rst = ~reset;  // Active low reset

    // Data for displaying number 7 (example bitmap)
    reg [15:0] frame_buffer [0:WIDTH * HEIGHT - 1];

    integer x, y;

    // Load a simple bitmap of the number "7"
    initial begin
        for (y = 0; y < HEIGHT; y = y + 1) begin
            for (x = 0; x < WIDTH; x = x + 1) begin
                if ((x > WIDTH / 4 && x < 3 * WIDTH / 4 && y < HEIGHT / 4) ||
                    (x > 3 * WIDTH / 4 - y / 4)) begin
                    frame_buffer[y * WIDTH + x] = 16'hFFFF; // White
                end else begin
                    frame_buffer[y * WIDTH + x] = 16'h0000; // Black
                end
            end
        end
    end

    // State Machine Logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= INIT;
        end else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        case (current_state)
            INIT: begin
                // Initialization commands
                spi_start = 1'b1;
                spi_data = 8'h01; // Reset command (example)
                if (spi_done) begin
                    next_state = SEND_COMMAND;
                end else begin
                    next_state = INIT;
                end
            end
            SEND_COMMAND: begin
                // Example command to set column address
                spi_start = 1'b1;
                spi_data = 8'h2A; // Set Column Address command
                if (spi_done) begin
                    next_state = SEND_DATA;
                end else begin
                    next_state = SEND_COMMAND;
                end
            end
            SEND_DATA: begin
                // Send pixel data for the frame buffer
                spi_start = 1'b1;
                spi_data = frame_buffer[y * WIDTH + x][15:8]; // Upper byte
                if (spi_done) begin
                    if (x < WIDTH && y < HEIGHT) begin
                        x = x + 1;
                        if (x == WIDTH) begin
                            x = 0;
                            y = y + 1;
                        end
                    end else begin
                        next_state = DONE;
                    end
                end else begin
                    next_state = SEND_DATA;
                end
            end
            DONE: begin
                // Finished displaying
                busy = 1'b0;
                next_state = DONE;
            end
            default: next_state = INIT;
        endcase
    end

endmodule

// Simple SPI Controller Module
module spi_controller (
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    input wire start,
    output reg sck,
    output reg mosi,
    output reg done
);

    reg [2:0] bit_counter;
    reg [7:0] shift_reg;
    reg active;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            bit_counter <= 3'd0;
            shift_reg <= 8'd0;
            active <= 1'b0;
            done <= 1'b0;
            sck <= 1'b0;
            mosi <= 1'b0;
        end else if (start && !active) begin
            active <= 1'b1;
            shift_reg <= data_in;
            bit_counter <= 3'd0;
            done <= 1'b0;
        end else if (active) begin
            sck <= ~sck;
            if (sck) begin
                mosi <= shift_reg[7];
                shift_reg <= {shift_reg[6:0], 1'b0};
                bit_counter <= bit_counter + 1;
                if (bit_counter == 3'd7) begin
                    active <= 1'b0;
                    done <= 1'b1;
                end
            end
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
      
       
       wire busy;
       
       // Instantiate the tft_display module
       tft_display uut (
           .clk(*clk),
           .reset(*reset),
           .tft_sck(*uo_out[4]),
           .tft_mosi(*uo_out[0]),
           .tft_dc(*uo_out[1]),
           .tft_cs(*uo_out[3]),
           .tft_rst(*uo_out[2]),
           .busy(busy)
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
   
   /*
   // Or, to provide specific inputs at specific times (as for lab C-TB) ...
   // BE SURE TO COMMENT THE ASSIGNMENT OF INPUTS ABOVE.
   // BE SURE TO DRIVE THESE ON THE B-PHASE OF THE CLOCK (ODD STEPS).
   // Driving on the rising clock edge creates a race with the clock that has unpredictable simulation behavior.
   initial begin
      #1  // Drive inputs on the B-phase.
         ui_in = 8'h0;
      #10 // Step 5 cycles, past reset.
         ui_in = 8'hFF;
      // ...etc.
   end
   */

   // Instantiate the Tiny Tapeout module.
   m5_user_module_name tt(.*);
   
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
