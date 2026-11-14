IVERILOG    := iverilog -g2012
VVP         := vvp
BUILD_DIR   := impl

uart_tx:
	$(call run_test,uart_tx,src/uart_tx.sv)

uart_rx:
	$(call run_test,uart_rx,src/uart_rx.sv)

uart_tx_rx:
	$(call run_test,uart_tx_rx,src/uart_rx.sv src/uart_tx.sv)

define run_test
	@mkdir -p $(BUILD_DIR)
	@echo "=== Building $(1) ==="
	$(IVERILOG) -o $(BUILD_DIR)/$(1) $(2) tb/$(1)_tb.sv
	@echo "\n=== Running $(1) ==="
	@cd $(BUILD_DIR) && $(VVP) $(1)
endef
