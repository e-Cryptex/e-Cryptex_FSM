module tb_e_Cryptex_FSM;

    reg clk;
    reg reset;
    reg adc_reset;
    reg mode_switch;
    reg continuous_switch;
    reg sda1;
    reg sda2;
    reg busy1;
    reg busy2;

    wire convst1;
    wire convst2;
    wire adc_clk_out;
    wire [23:0] key;
    wire [2:0] state_debug;
    wire negative_detect_debug;

    // Instantiate the DUT (Device Under Test)
    e_Cryptex_FSM uut (
        .clk(clk),
        .reset(reset),
        .adc_reset(adc_reset),
        .mode_switch(mode_switch),
        .continuous_switch(continuous_switch),
        .sda1(sda1),
        .sda2(sda2),
        .busy1(busy1),
        .busy2(busy2),
        .convst1(convst1),
        .convst2(convst2),
        .adc_clk_out(adc_clk_out),
        .key(key),
        .state_debug(state_debug),
        .negative_detect_debug(negative_detect_debug)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Stimulus
    initial begin
        reset = 0;
        adc_reset = 1;
        mode_switch = 0;
        continuous_switch = 0;
        sda1 = 0;
        sda2 = 0;
        busy1 = 0;
        busy2 = 0;

        #20 reset = 1;
        #50 adc_reset = 0; // falling edge 발생
        #1000 $finish;
    end

endmodule
