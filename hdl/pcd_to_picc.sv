
//PICC to PCD
module pcd_to_picc 
  (
    input wire sys_clk, // (main clock is 135.6 MHz)
    input wire clk_in, //pass in 3.39MHz (13.56 MHz/4) 
    input wire rst_in, //clock and reset
    input logic [39:0] data_in, // I believe I transmit LSB first
    input logic [2:0] num_bytes_in,
    input wire is_short_frame_in,
    input wire trigger_in,
    output logic busy_out,
    output logic signed [31:0] amp_out
  );

  logic [15:0] sine_out;
  logic [1:0] fourth_frame_count;
  logic [39:0] real_data;
  logic [39:0] curr_index;
  logic prev_num;
  logic parity_bit;
  logic [39:0] max_index;
  logic is_short_frame_real;

  enum {IDLE, STARTING, ENDING, SENDING_PARITY, SENDING_1, SENDING_0} state;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      amp_out <= 0;
      busy_out <= 0;
      state <= IDLE;
      fourth_frame_count <= 0;
      prev_num <= 0;
      curr_index <= 0;
      parity_bit <= 0;
    end else begin
      case (state)
        IDLE: begin
          busy_out <= 0;
          if (trigger_in) begin
            state <= STARTING; //end bit is 0
            real_data <= data_in;
            max_index <= 8 * num_bytes_in - 1;
            curr_index <= 0;
            prev_num <= 0;
            amp_out <= 0;
            busy_out <= 1;
            parity_bit <= 0;
            fourth_frame_count <= 0;
            is_short_frame_real <= is_short_frame_in;
          end
        end
        STARTING: begin //start bit is 0
          fourth_frame_count <= fourth_frame_count + 1;

          if (fourth_frame_count == 0) begin //send 0
            amp_out <= 0;
          end else begin
            amp_out <= 1;
          end
          
          if (fourth_frame_count == 3) begin
            if (real_data[curr_index] == 0) begin
              state <= SENDING_0;
            end else begin
              state <= SENDING_1;
            end
          end

        end
        SENDING_1: begin //SENDING 1
          fourth_frame_count <= fourth_frame_count + 1;

          if (fourth_frame_count == 2) begin //off between 1/2 - 3/4
            amp_out <= 0;
          end else begin
            amp_out <= 1;
          end

          if (fourth_frame_count == 3) begin
            fourth_frame_count <= 0;
            prev_num <= 1;
            parity_bit <= parity_bit ^ 1;
            if ((curr_index == 7) | (curr_index == 15) | (curr_index == 23) | (curr_index == 31) | (curr_index == 39)) begin
              state <= SENDING_PARITY;
            end else begin
              curr_index <= curr_index + 1;
              if (real_data[curr_index + 1] == 1) begin
                state <= SENDING_1;
              end else begin 
                state <=  SENDING_0;
              end
            end
          end

        end        
        SENDING_0: begin //SENDING 0
          fourth_frame_count <= fourth_frame_count + 1;

          if (prev_num == 1) begin //stay on
            amp_out <= 1;
          end else begin //off for first fourth, on for rest
            if (fourth_frame_count == 0) begin
              amp_out <= 0;
            end else begin
              amp_out <= 1;
            end
          end

          if (fourth_frame_count == 3) begin
            fourth_frame_count <= 0;
            prev_num <= 0;
            parity_bit <= parity_bit ^ 0;
            if ((curr_index == 7) & is_short_frame_real) begin
              state <= ENDING;
            end else if ((curr_index == 7) | (curr_index == 15) | (curr_index == 23) | (curr_index == 31) | (curr_index == 39)) begin
              state <= SENDING_PARITY;
            end else begin
              curr_index <= curr_index + 1;
              if (real_data[curr_index + 1] == 1) begin
                state <= SENDING_1;
              end else begin 
                state <=  SENDING_0;
              end
            end
          end
          
        end
        SENDING_PARITY: begin //sending parity_bit bit logic and next steps
          if (is_short_frame_real) begin
            fourth_frame_count <= fourth_frame_count + 1;
            state <= ENDING;
          end else begin
            fourth_frame_count <= fourth_frame_count + 1;

            if (parity_bit == 1) begin //send 1
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

            if (fourth_frame_count == 3) begin
              prev_num <= parity_bit;
              if (curr_index == max_index) begin //end it
                fourth_frame_count <= fourth_frame_count + 1;
                state <= ENDING;
              end else begin // go to next num
                curr_index <= curr_index + 1;
                fourth_frame_count <= 0;
                if (real_data[curr_index + 1] == 1) begin
                    state <= SENDING_1;
                end else begin 
                    state <=  SENDING_0;
                end
              end
            end

          end
        end
        ENDING: begin //cease after last parity_bit bit
          fourth_frame_count <= fourth_frame_count + 1;
          if (fourth_frame_count == 3) begin
            state <= IDLE;
          end

          //send 0
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
      endcase
    end
  end
endmodule
