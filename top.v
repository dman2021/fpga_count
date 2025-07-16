module top (
    input wire clk_25mhz,
    output wire [7:0] led,
    output wire wifi_gpio0,    // Reset ESP32
    output wire ftdi_rxd       // TX from FPGA to USB (seen as COM port)
);

    // Hold ESP32 in reset for ~12 seconds
    reg [27:0] reset_counter = 0;
    wire reset_done = reset_counter[27];

    always @(posedge clk_25mhz) begin
        if (!reset_done)
            reset_counter <= reset_counter + 1;
    end

    assign wifi_gpio0 = reset_done ? 1'b1 : 1'b0;

    // UART Transmit Module (send "Hello\r\n" one byte at a time)
    reg [3:0] state = 0;
    reg [9:0] baud_counter = 0;
    reg [7:0] byte_to_send;
    reg uart_tx = 1;
    reg [3:0] bit_index = 0;
    reg [7:0] hello_msg [0:5];

    initial begin
        hello_msg[0] = "H";
        hello_msg[1] = "e";
        hello_msg[2] = "l";
        hello_msg[3] = "l";
        hello_msg[4] = "o";
        hello_msg[5] = "\n";
    end

    always @(posedge clk_25mhz) begin
        if (reset_done) begin
            baud_counter <= baud_counter + 1;

            if (baud_counter == 434) begin  // 25MHz / 57600 baud
                baud_counter <= 0;

                case (state)
                    0: begin  // Start bit
                        uart_tx <= 0;
                        bit_index <= 0;
                        byte_to_send <= hello_msg[0];
                        state <= 1;
                    end
                    1: begin  // Data bits
                        uart_tx <= byte_to_send[bit_index];
                        bit_index <= bit_index + 1;
                        if (bit_index == 7) state <= 2;
                    end
                    2: begin  // Stop bit
                        uart_tx <= 1;
                        state <= 3;
                    end
                    3: begin
                        hello_msg[0] <= hello_msg[1];
                        hello_msg[1] <= hello_msg[2];
                        hello_msg[2] <= hello_msg[3];
                        hello_msg[3] <= hello_msg[4];
                        hello_msg[4] <= hello_msg[5];
                        hello_msg[5] <= 8'h00;
                        if (hello_msg[0] == 8'h00) state <= 4;
                        else state <= 0;
                    end
                    4: begin
                        // done
                    end
                endcase
            end
        end
    end

    assign ftdi_rxd = uart_tx;
    assign led = 8'b00000001;  // Simple visual debug

endmodule
