module clk_div128 (
    input wire clk_in,
    input wire rst_in,
    output logic clk_out
);

logic [7:0] count;

always_ff @(posedge clk_in) begin
    if (rst_in) begin
        count <= 0;
        clk_out <= 0;
    end else begin
      if (count == 63) begin
         count <= 0;
         if (clk_out == 0) clk_out <= 1;
         else clk_out <= 0;
      end else begin
        count <= count + 1;
      end
    end
end

endmodule
