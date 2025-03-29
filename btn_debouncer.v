`timescale 1ns / 1ps

module btn_debounce(
    input clk,
    input reset,
    input i_btn,
    output o_btn
    );

    // state
    reg [7:0] q_reg, q_next; // shift register
    reg edge_detect;

    wire btn_debounce;

    // 1khz
    reg [$clog2(100_000)-1:0] counter;
    reg r_1khz;

    // 1khz clk state
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter <= 0;
            r_1khz <= 0;
        end
        else begin
            if (counter == 100_000) begin
                counter <= 0;
                r_1khz <= 1'b1;
            end
            else begin
                counter <= counter + 1'b1;
                r_1khz <= 1'b0;
            end
        end
    end

    // state logic
    always @(posedge r_1khz, posedge reset) begin
        if (reset) begin
            q_reg <= 0;
        end
        else begin
            q_reg <= q_next;
        end
    end

    // next
    always @(i_btn, r_1khz) begin // event i_btn, r_1khz
        q_next = {i_btn, q_next[7:1]};

    end

    // 8input AND gate
    assign btn_debounce = &q_reg;

    // edge detector
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            edge_detect <= 0;
        end
        else begin
            edge_detect <= btn_debounce;
        end
    end

    // final output
    assign o_btn = btn_debounce & (~edge_detect);
endmodule
