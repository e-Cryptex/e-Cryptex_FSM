`timescale 1 ns / 1 ps

module top (
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
    output wire convst1,
    output wire convst2,
    output wire adc_clk_out,
    output wire [23:0] key
);

    wire clk_fsm;
    wire clk_adc;

    // Clocking Wizard 인스턴스
    clk_wiz_0 clk_wiz_inst (
        .clk_in1(clk), 
        .clk_out1(clk_fsm),
        .clk_out2(clk_adc),
        .resetn(reset),
        .locked()
    );
    
    ODDR #(
        .DDR_CLK_EDGE("SAME_EDGE"),
        .INIT(1'b0),
        .SRTYPE("SYNC")
    ) oddr_adc_clk_out (
        .Q(adc_clk_out),
        .C(clk_adc),   // 내부 클럭 입력
        .CE(1'b1),
        .D1(1'b1),
        .D2(1'b0),
        .R(1'b0),
        .S(1'b0)
    );
    
    // FSM 인스턴스
    e_Cryptex_FSM fsm_inst (
        .clk(clk_fsm),
        .reset(reset),
        .adc_clk(clk_adc),
        .adc_on(adc_on),
        .mode_switch(mode_switch),
        .continuous_switch(continuous_switch),
        .sda1(sda1),
        .sda2(sda2),
        .busy1(busy1),
        .busy2(busy2),
        .convst1(convst1),
        .convst2(convst2),
//        .adc_clk_out(),
        .key(key)
    );

endmodule
