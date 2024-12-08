module clk_div4 (
    input wire clk_in,
    input wire rst_in,
    output logic clk_out
);

logic count;

always_ff @(posedge clk_in) begin
    if (rst_in) begin
        count <= 0;
        clk_out <= 0;
    end else begin
      if (count == 1) begin
         count <= 0;
         clk_out <= !clk_out;
      end else begin
        count <= count + 1;
      end
    end
end

endmodule
