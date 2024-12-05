
//PICC to PCD
module rfid #
  (
    parameter integer C_S00_AXIS_TDATA_WIDTH	= 32,
    parameter integer C_M00_AXIS_TDATA_WIDTH	= 32
  )
  (
    // Ports of Axi Slave Bus Interface S00_AXIS
    input wire  s00_axis_aclk, s00_axis_aresetn,
    input wire  s00_axis_tlast, s00_axis_tvalid,
    input wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata,
    input wire [(C_S00_AXIS_TDATA_WIDTH/8)-1: 0] s00_axis_tstrb,
    output logic  s00_axis_tready,

    // Ports of Axi Master Bus Interface M00_AXIS
    input wire  m00_axis_aclk, m00_axis_aresetn,
    input wire  m00_axis_tready,
    output logic  m00_axis_tvalid, m00_axis_tlast,
    output logic [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata,
    output logic [(C_M00_AXIS_TDATA_WIDTH/8)-1: 0] m00_axis_tstrb,

    input wire clk_in, // (main clock is 135.6 MHz)
    input wire clk_in_picc, // pass in 0.026484 MHz ( 13.56 MHz/(128*4) )
    input wire rst_in, // clock and reset 
    input wire btn_in,
    output logic signed [31:0] amp_out
  );

  logic m00_axis_tvalid_reg, m00_axis_tlast_reg;
  logic [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata_reg;
  logic [(C_M00_AXIS_TDATA_WIDTH/8)-1: 0] m00_axis_tstrb_reg;
 
  assign m00_axis_tvalid = m00_axis_tvalid_reg;
  assign m00_axis_tlast = m00_axis_tlast_reg;
  assign m00_axis_tdata = m00_axis_tdata_reg;
  assign m00_axis_tstrb = m00_axis_tstrb_reg;
  //change...only if there is a slot for new data to go into:
  //this should avoid deadlock.
  assign s00_axis_tready = m00_axis_tready || ~m00_axis_tvalid;

  rst_in = s00_axis_aresetn == 0;

  logic [39:0] picc_data_in;
  logic [2:0] picc_num_bytes_in;
  logic picc_trigger_in;
  logic picc_busy_out;
  logic picc_amp_out;

  logic [15:0] sine_out;

  assign amp_out = $signed($signed(picc_amp_out) * sine_out); // FIX THIS, should amp_amt be larger? sine goes into negatives, right?
  logic done_out;

  picc_to_pcd picc
    (
      .sys_clk(clk_in),
      .clk_in(clk_in_picc),
      .rst_in(rst_in),
      .data_in(picc_data_in),
      .num_bytes_in(picc_num_bytes_in),
      .trigger_in(picc_trigger_in),
      .busy_out(picc_busy_out),
      .amp_out(picc_amp_out),
      .done_out(done_out)
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

  always_ff @(posedge s00_axis_aclk)begin
    if (s00_axis_aresetn==0)begin
      m00_axis_tvalid_reg <= 0;
      m00_axis_tlast_reg <= 0;
      m00_axis_tdata_reg <= 0;
      m00_axis_tstrb_reg <= 0;
    end else begin
      //only if there is room in either our registers...
      //or downstream consumer/slave do we update.
      if (s00_axis_tready & busy_out)begin
        m00_axis_tvalid_reg <= s00_axis_tvalid;
        m00_axis_tlast_reg <= done_out;
        m00_axis_tdata_reg <=picc_amp_out;
        m00_axis_tstrb_reg <= s00_axis_tstrb;
      end
    end
  end
  

endmodule
