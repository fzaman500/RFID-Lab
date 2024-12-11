
//PICC to PCD
module pcd_in 
  (
    input wire sys_clk, // (main clock is 135.6 MHz)
    input wire clk_in, // 1/2 of the fourth frame clk
    input wire rst_in, //clock and reset
    input wire data_in, // from adc
    output logic data_out, // bits out
    output logic valid_out
  );

  logic [3:0] eighth_frame_count;
  logic [39:0] curr_index;
  logic prev_num;
  logic parity_bit;

  logic [3:0] last_four;
  logic valid_data;

  enum {IDLE, RECEIVING_DATA, RECEIVING_PARITY } state;

  always_ff @(posedge sys_clk) begin
    if (rst_in) begin
      state <= IDLE;
      data_out <= 0;
      eighth_frame_count <= 0;
      prev_num <= 0;
      curr_index <= 0;
      parity_bit <= 0;
      last_four <= 4'b0000;
      valid_out <= 0;
    end
  end

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
    end else begin
      case (state)
        IDLE: begin
          if (eighth_frame_count%4 == 1) begin
            last_four[0] <= data_in;
            last_four[1] <= last_four[0];
            last_four[2] <= last_four[1];
            last_four[3] <= last_four[2];
          end

          if (last_four == 4'b1101) begin
            data_out <= 1;
            valid_out <= 1;
            state <= RECEIVING_DATA;
            eighth_frame_count <= 0;
          end else begin
            valid_out <= 0;
          end

          eighth_frame_count <= eighth_frame_count + 1;
        end
        RECEIVING_DATA: begin
          if (eighth_frame_count%4 == 1) begin
            last_four[0] <= data_in;
            last_four[1] <= last_four[0];
            last_four[2] <= last_four[1];
            last_four[3] <= last_four[2];
          end

          if (eighth_frame_count == 15) begin
            if (last_four == 4'b1101) begin
              data_out <= 1;
              valid_out <= 1;
            end else if (last_four == 4'b1111 || last_four == 4'b0111) begin
              data_out <= 0;
              valid_out <= 1;
            end
          end
          else begin
            valid_out <= 0;
          end

          eighth_frame_count <= eighth_frame_count + 1;
        end
      endcase
    end
  end
endmodule
