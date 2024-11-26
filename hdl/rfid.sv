
//PICC to PCD
module rfid 
  (
    input wire clk_in, // (main clock is 135.6 MHz)
    input wire clk_in_picc, // pass in 0.026484 MHz ( 13.56 MHz/(128*4) )
    input wire rst_in, // clock and reset 
    input wire btn_in,
    output logic signed [31:0] amp_out
  );

  logic [39:0] picc_data_in;
  logic [2:0] picc_num_bytes_in;
  logic picc_trigger_in;
  logic picc_busy_out;
  logic picc_amp_out;

  logic [15:0] sine_out;

  assign amp_out = $signed($signed(picc_amp_out) * sine_out); // FIX THIS, should amp_amt be larger? sine goes into negatives, right?

  picc_to_pcd picc
    (
      .sys_clk(clk_in),
      .clk_in(clk_in_picc),
      .rst_in(rst_in),
      .data_in(picc_data_in),
      .num_bytes_in(picc_num_bytes_in),
      .trigger_in(picc_trigger_in),
      .busy_out(picc_busy_out),
      .amp_out(picc_amp_out)
    );
  
  sine_generator sine_gen
    (
      .clk_in(clk_in),
      .rst_in(rst_in),
      .step_in(1),
      .amp_out(sine_out)
    );

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      picc_trigger_in <= 0;
    end else begin
      if (btn_in) begin
        picc_data_in <= 32'h24_90_67_35;
        picc_num_bytes_in <= 4;
        picc_trigger_in <= 1;
      end else begin
        picc_trigger_in <= 0;
      end
    end
  end
  

endmodule
