\m5_TLV_version 1d: tl-x.org
\m5
   use(m5-1.0)
   
   // ########################################################
   // #                                                      #
   // #  Tiny Tapeout Project for SPI TFT Controller         #
   // #                                                      #
   // ########################################################
   
   // ========
   // Settings
   // ========
   
   //-------------------------------------------------------
   // Build Target Configuration
   //
   var(my_design, spi_tft_controller_project)   /// The name of your top-level TT module, matching info.yml.
   var(target, ASIC)   /// Note, the FPGA CI flow will set this to FPGA.
   //-------------------------------------------------------
   
   var(in_fpga, 1)   /// 1 to include the demo board logic under /fpga_pins/fpga.
   var(debounce_inputs, 0)  /// Set to 0: No debouncing provided.
   
   // ======================
   // Computed From Settings
   // ======================
   var(user_module_name, m5_if(m5_debounce_inputs, my_design, m5_my_design))
   var(debounce_cnt, m5_if_defined_as(MAKERCHIP, 1, 8'h03, 8'hff))

\SV
   // Include Tiny Tapeout Lab.
   m4_include_lib(['https:/']['/raw.githubusercontent.com/os-fpga/Virtual-FPGA-Lab/5744600215af09224b7235479be84c30c6e50cb7/tlv_lib/tiny_tapeout_lib.tlv'])

\TLV my_design()
   // ==================
   // |  SPI TFT Controller |
   // ==================
   // Inputs
   |spi_tft_controller(
      *clk,
      *rst,
      $start,            // Start signal
      $data_in[7:0],     // 8-bit data input
      $dc_select,        // DC pin: Command/Data select
      // Outputs
      *uo_out[3],        // Chip Select
      *uo_out[4],        // SPI Clock
      *uo_out[0],        // Master Out Slave In (MOSI)
      *uo_out[1],        // DC pin
      *uo_out[2],        // Reset pin
      *uo_out[5]         // LED Backlight
   );

\SV_plus
   // Verilog Code for SPI TFT Controller
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
