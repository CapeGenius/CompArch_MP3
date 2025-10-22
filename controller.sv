
module controller (
    input logic clk, 
    output logic load_sreg, 
    output logic transmit_pixel, 
    output logic [5:0] pixel, 
    output logic [4:0] frame
);

    localparam TRANSMIT_FRAME       = 1'b0;
    localparam IDLE                 = 1'b1;

    localparam [2:0] READ_CH_VALS   = 3'b001; // state to read channels
    localparam [2:0] LOAD_SREG      = 3'b010; // state to load the register
    localparam [2:0] TRANSMIT_PIXEL = 3'b100; // state to transmit pixel

    localparam [8:0] TRANSMIT_CYCLES    = 9'd360;       // = 24 bits / pixel x 15 cycles / bit
    localparam [19:0] IDLE_CYCLES       = 20'd3051832;   // = 375000 - 64 x (360 + 2) for 32 frames / second

    logic state = TRANSMIT_FRAME;
    logic next_state;

    logic [2:0] transmit_phase = READ_CH_VALS; // current phase is to read channel values
    logic [2:0] next_transmit_phase;

    logic [5:0] pixel_counter = 6'd0; // 2^6 = 64 pixels per frame
    logic [2:0] frame_counter = 4'b0; // 2^5 = 32 frames per second
    logic [8:0] transmit_counter = 9'd0; // 2^9 --> number of cycles to transmit a frame --> until (360 + 2) x 64 max cycles 
    logic [19:0] idle_counter = 20'd0; // number of cycles between frames

    logic transmit_pixel_done;
    logic idle_done;

    assign transmit_pixel_done = (transmit_counter == TRANSMIT_CYCLES - 1); //logic to define when transmit cycles are done
    assign idle_done = (idle_counter == IDLE_CYCLES - 1); // logic to define when idle cycles are done

    always_ff @(negedge clk) begin
        state <= next_state;
        transmit_phase <= next_transmit_phase;
    end

    always_comb begin //logic that defines the next state logic and transmit state logic
        next_state = 1'bx;
        unique case (state)
            TRANSMIT_FRAME:
                if ((pixel_counter == 6'd63) && (transmit_pixel_done)) // if all pixels are tansmitted --> become idle
                    next_state = IDLE;
                else
                    next_state = TRANSMIT_FRAME;
            IDLE: //if the idle cycles are done --> start transmitting frames
                if (idle_done)
                    next_state = TRANSMIT_FRAME;
                else
                    next_state = IDLE;
        endcase
    end

    always_comb begin
        next_transmit_phase = READ_CH_VALS;
        if (state == TRANSMIT_FRAME) begin //only starts this block if the phase is in transmit mode
            case (transmit_phase)
                READ_CH_VALS: // read pixel data from memory
                    next_transmit_phase = LOAD_SREG; //load pixels onto shift register
                LOAD_SREG:
                    next_transmit_phase = TRANSMIT_PIXEL; // transmit pixels into data
                TRANSMIT_PIXEL:
                    next_transmit_phase = transmit_pixel_done ? READ_CH_VALS : TRANSMIT_PIXEL; // if transmit pixel is done --> either read channel values or transmit pixels
            endcase
        end
    end

    always_ff @(negedge clk) begin
        if ((state == TRANSMIT_FRAME) && transmit_pixel_done) begin // counter to measure if pixel is done
            pixel_counter <= pixel_counter + 1;
        end
    end

    always_ff @(negedge clk) begin
        if (idle_done) begin // counter to increment frame counter
            frame_counter <= frame_counter + 1;
        end
    end

    always_ff @(negedge clk) begin
        if (transmit_phase == TRANSMIT_PIXEL) begin // counter for transmitting pixels in transmit phase
            transmit_counter <= transmit_counter + 1;
        end
        else begin // otherwise it will remain 0
            transmit_counter <= 9'd0;
        end
    end

    always_ff @(negedge clk) begin
        if (state == IDLE) begin // if the state is in idle
            idle_counter <= idle_counter + 1;
        end
        else begin // if the state is not in idle
            idle_counter <= 20'd0;
        end
    end

    assign pixel = pixel_counter; // defines which pixel
    assign frame = frame_counter; // defines which frame

    assign load_sreg = (transmit_phase == LOAD_SREG); //load register assignment
    assign transmit_pixel = (transmit_phase == TRANSMIT_PIXEL); //transmit pixel assignment

endmodule
