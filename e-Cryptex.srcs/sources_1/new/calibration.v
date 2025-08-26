`timescale 1ns / 1ps

module e_Cryptex_FSM (
    input wire clk,
    input wire reset,
    input wire adc_clk,
    input wire adc_on,
    input wire mode_switch,
    input wire continuous_switch,
    input wire sda1,
    input wire sda2,
    input wire busy1,
    input wire busy2,
    output reg convst1,
    output reg convst2,
    output reg [23:0] key
);

    parameter IDLE              = 3'b000;
    parameter WAIT_AFTER_RESET  = 3'b101;
    parameter READ_ADC          = 3'b001;
    parameter UPDATE_MIN_MAX    = 3'b010;
    parameter CALCULATE_CALIBRATION = 3'b011;
    parameter CALCULATE_MASK        = 3'b111;
    parameter WAIT_MASK         = 3'b110;
    parameter PROCESS_KEY       = 3'b100;
    
    reg [2:0] current_state, next_state;
    reg [15:0] adc_shift_reg1, adc_shift_reg2;
    
    reg [11:0] calibration_value1, calibration_value2;
    reg [11:0] min_adc1, max_adc1, min_adc2, max_adc2;
    reg [3:0] stable_bits1, stable_bits2;
    
//    wire [11:0] final_adc1;
//    wire [11:0] final_adc2;
    
    reg [11:0] final_adc1;
    reg [11:0] final_adc2;
    reg [11:0] masking1;
    reg [11:0] masking2;
    reg [11:0] mask1;
    reg [11:0] mask2;
    
    reg [7:0] debounce_cnt;
    reg adc_on_sync_0;
    reg adc_on_sync_1;
    reg adc_on_stable;
    reg adc_on_prev;
    wire adc_on_posedge = (adc_on_prev == 1'b0) && (adc_on_stable == 1'b1);
   
    reg [31:0] wait_counter;
    parameter WAIT_TIME_CYCLES = 32'd31_250_000;
    wire wait_done;
    
    reg sampling_enabled;
    reg [4:0] bit_count;
    
    assign wait_done = (wait_counter >= WAIT_TIME_CYCLES);

//    assign final_adc1 = (((adc_shift_reg1[11:0] & masking1) - calibration_value1) & mask1);
//    assign final_adc2 = (((adc_shift_reg2[11:0] & masking2) - calibration_value2) & mask2);

    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            debounce_cnt     <= 8'b0;
            adc_on_sync_0 <= 1'b1;
            adc_on_sync_1 <= 1'b1;
            adc_on_stable <= 1'b1;
            adc_on_prev   <= 1'b1;
        end else begin
            adc_on_sync_0 <= adc_on;
            adc_on_sync_1 <= adc_on_sync_0;
            
            if (adc_on_sync_1 != adc_on_stable) begin
                debounce_cnt <= debounce_cnt + 1;
                if (debounce_cnt >= 8'd100) begin
                    adc_on_stable <= adc_on_sync_1;
                    debounce_cnt <= 8'b0;
                end
            end else begin
                debounce_cnt <= 8'b0;
            end
            adc_on_prev <= adc_on_stable;
        end
    end
    
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        case (current_state)
            IDLE: begin
                next_state = (adc_on_posedge) ? WAIT_AFTER_RESET : IDLE;
            end

            WAIT_AFTER_RESET: begin
                next_state = wait_done ? READ_ADC : WAIT_AFTER_RESET;
            end

            READ_ADC: begin
                if (bit_count >= 16)
                    next_state = (mode_switch) ? UPDATE_MIN_MAX : WAIT_MASK;
                else
                    next_state = READ_ADC;
            end

            UPDATE_MIN_MAX: begin
                next_state = (continuous_switch) ? IDLE : CALCULATE_CALIBRATION;
            end

            CALCULATE_CALIBRATION: begin
                next_state = CALCULATE_MASK;
            end
            
            CALCULATE_MASK: begin
                next_state = WAIT_MASK;
            end
            
            WAIT_MASK: begin
                next_state = PROCESS_KEY;
            end

            PROCESS_KEY: begin
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            convst1           <= 1'b0;
            convst2           <= 1'b0;
            key               <= 24'b0;
            calibration_value1 <= 12'b0;
            calibration_value2 <= 12'b0;
            stable_bits1      <= 4;
            stable_bits2      <= 4;
            min_adc1          <= 12'hFFF;
            max_adc1          <= 12'h000;
            min_adc2          <= 12'hFFF;
            max_adc2          <= 12'h000;
            masking1          <= 12'h000;
            masking2          <= 12'h000;
            mask1             <= 12'h000;
            mask2             <= 12'h000;
            adc_shift_reg1    <= 16'b0;
            adc_shift_reg2    <= 16'b0;
            wait_counter      <= 32'b0;
            bit_count         <= 4'b0;
            sampling_enabled  <= 1'b0;
        end else begin
            if (adc_on_prev == 1'b1 && adc_on_stable == 1'b0)
                key <= 24'b0;
            case (current_state)
                IDLE: begin
                    convst1           <= 1'b0;
                    convst2           <= 1'b0;
                    adc_shift_reg1    <= 16'b0;
                    adc_shift_reg2    <= 16'b0;
                    wait_counter      <= 32'b0;
                    bit_count         <= 4'b0;
                    sampling_enabled  <= 1'b0;
                end

                WAIT_AFTER_RESET: begin
                    if (!wait_done)
                        wait_counter <= wait_counter + 1;
                end

                READ_ADC: begin
                    convst1 <= 1'b1;
                    convst2 <= 1'b1;

                    if (!busy1 && !busy2) begin
                        convst1 <= 1'b0;
                        convst2 <= 1'b0;
                        sampling_enabled <= 1'b1;
                    end
                    
                    if (bit_count >= 16) begin
                        sampling_enabled <= 1'b0;
                    end

                    if (sampling_enabled && bit_count < 16) begin
                        adc_shift_reg1 <= {adc_shift_reg1[14:0], sda1};
                        adc_shift_reg2 <= {adc_shift_reg2[14:0], sda2};
                        bit_count      <= bit_count + 1;
                    end
                end

                UPDATE_MIN_MAX: begin
                    if (adc_shift_reg1[11:0] < min_adc1) min_adc1 <= adc_shift_reg1[11:0];
                    if (adc_shift_reg1[11:0] > max_adc1) max_adc1 <= adc_shift_reg1[11:0];

                    if (adc_shift_reg2[11:0] < min_adc2) min_adc2 <= adc_shift_reg2[11:0];
                    if (adc_shift_reg2[11:0] > max_adc2) max_adc2 <= adc_shift_reg2[11:0];
                end

                CALCULATE_CALIBRATION: begin
                    calibration_value1 <= (max_adc1 - min_adc1);
                    calibration_value2 <= (max_adc2 - min_adc2);
                    
                    masking1 <= ~(max_adc1 ^ min_adc1);
                    masking2 <= ~(max_adc2 ^ min_adc2);

                    if (max_adc1 == min_adc1) stable_bits1 <= 0;
                    else if (max_adc1 - min_adc1 + 1 <= 2) stable_bits1 <= 1;
                    else if (max_adc1 - min_adc1 + 1 <= 4) stable_bits1 <= 2;
                    else if (max_adc1 - min_adc1 + 1 <= 8) stable_bits1 <= 3;
                    else if (max_adc1 - min_adc1 + 1 <= 16) stable_bits1 <= 4;
                    else if (max_adc1 - min_adc1 + 1 <= 32) stable_bits1 <= 5;
                    else if (max_adc1 - min_adc1 + 1 <= 64) stable_bits1 <= 6;
                    else if (max_adc1 - min_adc1 + 1 <= 128) stable_bits1 <= 7;
                    else if (max_adc1 - min_adc1 + 1 <= 256) stable_bits1 <= 8;
                    else if (max_adc1 - min_adc1 + 1 <= 512) stable_bits1 <= 9;
                    else if (max_adc1 - min_adc1 + 1 <= 1024) stable_bits1 <= 10;
                    else stable_bits1 <= 11;

                    if (max_adc2 == min_adc2) stable_bits2 <= 0;
                    else if (max_adc2 - min_adc2 + 1 <= 2) stable_bits2 <= 1;
                    else if (max_adc2 - min_adc2 + 1 <= 4) stable_bits2 <= 2;
                    else if (max_adc2 - min_adc2 + 1 <= 8) stable_bits2 <= 3;
                    else if (max_adc2 - min_adc2 + 1 <= 16) stable_bits2 <= 4;
                    else if (max_adc2 - min_adc2 + 1 <= 32) stable_bits2 <= 5;
                    else if (max_adc2 - min_adc2 + 1 <= 64) stable_bits2 <= 6;
                    else if (max_adc2 - min_adc2 + 1 <= 128) stable_bits2 <= 7;
                    else if (max_adc2 - min_adc2 + 1 <= 256) stable_bits2 <= 8;
                    else if (max_adc2 - min_adc2 + 1 <= 512) stable_bits2 <= 9;
                    else if (max_adc2 - min_adc2 + 1 <= 1024) stable_bits2 <= 10;
                    else stable_bits2 <= 11;
                end
                
                CALCULATE_MASK: begin
                    mask1 <= (12'hFFF << (12 - stable_bits1));
                    mask2 <= (12'hFFF << (12 - stable_bits2));
                end
                
                WAIT_MASK: begin
                    final_adc1 <= (((adc_shift_reg1[11:0] & masking1) - calibration_value1) & mask1);
                    final_adc2 <= (((adc_shift_reg2[11:0] & masking2) - calibration_value2) & mask2);
                end
                
                PROCESS_KEY: begin
                    key <= {final_adc1[11:6], final_adc2[5:0], final_adc2[11:6], final_adc1[5:0]};
                end
            endcase
        end
    end

endmodule

