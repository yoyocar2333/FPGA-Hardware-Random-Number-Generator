module Top (
    input        i_clk,
    input        i_rst_n,
    input        i_start,
    input        i_in2,
    input        i_in3,
    output [3:0] o_random_out
);

// please check out the working example in lab1 README (or Top_exmaple.sv) first

    localparam
        CLOCK_FREQUENCY = 50_000_000,
        MIN_DELAY = CLOCK_FREQUENCY / 50,
        MAX_DELAY = CLOCK_FREQUENCY / 2,
        DELAY_STEP = CLOCK_FREQUENCY / 50;

    localparam
        S_IDLE = 0,
        S_WORK = 1,
		S_IMME = 2,
		S_STORE= 3;
    reg [1:0] state, next_state;

    reg [31:0] counter, next_counter;
    wire[31:0] counter_inc = counter+1;
    reg [31:0] delay, next_delay;

    reg [3:0] random_reg, random;
    assign o_random_out = random_reg;

    reg [31:0] lfsr_reg;
    wire new_bit = lfsr_reg[31] ^ lfsr_reg[21] ^ lfsr_reg[1] ^ lfsr_reg[0];
    wire[31:0] lfsr = {lfsr_reg[30:0], new_bit};

	reg [15:0] history, next_history;
	reg [1:0] history_count, next_history_count;

	genvar k;
	wire [3:0] history_seg [0:3];
	generate
		for (k=0; k<4; k=k+1) begin : HISTORY_SEGMENTATION
			assign history_seg[k] = history[4*k+3:4*k];
		end
	endgenerate

    always_comb begin
        next_state = state;
        next_counter = counter_inc;
        next_delay = delay;
        random = random_reg;
		next_history = history;
		next_history_count = history_count;
        case (state)
            S_IDLE: begin
				random = history_seg[history_count];
                if (i_start) begin
                    next_state = S_WORK;
                    next_delay = MIN_DELAY;
				end else if (i_in2) begin
					next_history_count = history_count + 1;
				end else if (i_in3) begin
					next_state = S_IMME;
				end
            end
            S_WORK: begin
                if (counter >= delay) begin
                    next_counter = 32'b0;
                    next_delay = delay + DELAY_STEP;
                    random = lfsr_reg[3:0];
                end
                if ((delay > MAX_DELAY) || (i_start)) begin
                    next_state = S_STORE;
                end
            end
			S_IMME: begin
				random = lfsr_reg[3:0];
				next_state = S_STORE;
			end
			S_STORE: begin
				next_state = S_IDLE;
				next_history = {history[11:0], o_random_out};
				next_history_count = 0;
			end
        endcase
    end

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state <= S_IDLE;
            counter <= 32'b0;
            delay <= MIN_DELAY;
            random_reg <= 4'b0;
            lfsr_reg <= 32'h368B_4F78;
			history <= 0;
			history_count <= 0;
        end else begin
            state <= next_state;
            counter <= next_counter;
            delay <= next_delay;
            random_reg <= random;
            lfsr_reg <= lfsr;
			history <= next_history;
			history_count <= next_history_count;
        end    
    end

endmodule
