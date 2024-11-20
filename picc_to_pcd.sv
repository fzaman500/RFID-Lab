`default_nettype none // prevents system from inferring an undeclared logic (good practice)
 
//PICC to PCD
module picc_to_pcd #
(
  input wire sys_clk, // (main clock is 135.6 MHz)
  input wire clk_in, //pass in 3.39MHz (13.56 MHz/4) 
  input wire rst_in, //clock and reset
  input logic [39:0] data, // I believe I transmit LSB first
  input logic [2:0] num_bytes,
  input wire is_transmit,
  output wire transmit_done,
  output logic signed [31:0] amp_out
);

logic [15:0] sine_out;
logic [1:0] fourth_frame_count;
logic [39:0] real_data;
logic [39:0] curr_index;
logic prev_num;
logic parity_bit;
logic [39:0] max_index;

typedef enum  {IDLE, STARTING, ENDING, SENDING_PARITY, SENDING_1, SENDING_0} state;

state STATE;

always_ff @(posedge clk_in) begin
  if (rst_in) begin
    amp_out <= 0;
    transmit_done <= 0;
    state <= IDLE;
    fourth_frame_count <= 0;
    prev_num <= 0;
    curr_index <= 0;
    parity_bit <= 0;
  end else begin
    if (state == IDLE) begin
      transmit_done <= 0;
      if (is_transmit) begin
        state <= SENDING_1; //end bit is 0
        real_data <= data;
        max_index <= 8 * num_bytes - 1;
        curr_index <= 0;
        prev_num <= 0;
        amp_out <= 0;
        parity_bit <= 0;
      end
    end
    else if (state == STARTING) begin //start bit is 1
      fourth_frame_count <= fourth_frame_count + 1;
      if (fourth_frame_count) begin
        if (real_data[curr_index] == 0) begin
          state <= SENDING_0;
        end else begin
          state <= SENDING_1;
        end
      end
      if (fourth_frame_count == 2) begin //off between 1/2 - 3/4
        amp_out <= 0;
      end else begin
        amp_out <= 1;
      end

    end else if (state == SENDING_1) begin //SENDING 1
       fourth_frame_count <= fourth_frame_count + 1;
       if (fourth_frame_count == 3) begin
        fourth_frame_count <= 0;
        prev_num <= 1;
        parity <= parity ^ 1;
        if ((curr_index == 7) | (curr_index == 15) | (curr_index == 23) | (curr_index == 31) | (curr_index == 39)) begin
          state <= PARITY;
        end else begin
          curr_index <= curr_index + 1;
          if (data[curr_index + 1] == 1) begin
            state <= SENDING_1;
          end else begin 
            state <=  SENDING_0;
          end
        end
       end

      if (fourth_frame_count == 2) begin //off between 1/2 - 3/4
        amp_out <= 0;
      end else begin
        amp_out <= 1;
      end

    end else if (state == SENDING_0) begin //SENDING 0
      fourth_frame_count <= fourth_frame_count + 1;
      if (fourth_frame_count == 3) begin
        fourth_frame_count <= 0;
        prev_num <= 0;
        parity <= parity ^ 0;
        if ((curr_index == 7) | (curr_index == 15) | (curr_index == 23) | (curr_index == 31) | (curr_index == 39)) begin
          state <= PARITY;
        end else begin
          curr_index <= curr_index + 1;
          if (data[curr_index + 1] == 1) begin
            state <= SENDING_1;
          end else begin 
            state <=  SENDING_0;
          end
        end
      end
      if (prev_num == 1) begin //stay on
        amp_out <= 1;
      end else begin //off for first fourth, on for rest
        if (fourth_frame_count == 0) begin
          amp_out <= 0;
        end else begin
          amp_out <= 1;
        end
      end
    end else if (state == SENDING_PARITY) begin //sending parity bit logic and next steps
      fourth_frame_count <= fourth_frame_count + 1;

      if (fourth_frame_count == 3) begin
        if (curr_index == max_index) begin //end it
          state <= ENDING;
        end else begin // go to next num
          curr_index <= curr_index + 1;
          fourth_frame_count <= 0;
          if (data[curr_index + 1] == 1) begin
            state <= SENDING_1;
          end else begin 
            state <=  SENDING_0;
          end
        end
      end

      if (parity == 1) begin //send 1
        if (fourth_frame_count == 2) begin //off between 1/2 - 3/4
          amp_out <= 0;
        end else begin
          amp_out <= 1;
        end
      end else begin //send 0
        if (prev_num == 1) begin //stay on
          amp_out <= 1;
        end else begin //off for first fourth, on for rest
          if (fourth_frame_count == 0) begin
            amp_out <= 0;
          end else begin
            amp_out <= 1;
          end
        end
      end

    end else if (state == ENDING) begin //cease after last parity bit
      state <= IDLE;
      transmit_done <= 1;
    end
  end
end


endmodule