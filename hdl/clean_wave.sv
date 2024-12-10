
module clean_wave #
  (
    parameter integer BIT_THRESHOLD = 5000
  )
  (
    input wire clk_in,
    input wire rst_in,
    input logic signed [31:0] data_in,
    input wire period_trigger_in,
    output logic bit_out
  );

  logic period_trigger_in_prev;

  logic [31:0] rectified_data;
  assign rectified_data = data_in[31] ? -data_in : data_in;

  logic [63:0] sum;
  logic [31:0] count;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      sum <= 0;
      count <= 0;
      bit_out <= 0;
      period_trigger_in_prev <= 0;
    end else begin
      if (period_trigger_in == 1 && period_trigger_in_prev == 0) begin
        bit_out <= (sum / count) > BIT_THRESHOLD;
        sum <= 0;
        count <= 0;
        period_trigger_in_prev <= period_trigger_in;
      end else begin
        sum <= sum + rectified_data;
        count <= count + 1;
        period_trigger_in_prev <= period_trigger_in;
      end
    end
  end
  

endmodule
