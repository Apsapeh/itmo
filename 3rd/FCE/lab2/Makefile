IVERILOG       := iverilog -g2012
VVP            := vvp
OPENFGPALOADER := openFPGALoader -b tangprimer20k
BUILD_DIR      := impl

BITSTREAM      := impl/pnr/lab2.fs

mul:
	$(call run_test,mul,src/mul.sv)

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

.PHONY: mul uart_tx uart_rx uart_tx_rx

upload:
	$(OPENFGPALOADER) $(BITSTREAM) 

.PHONY: upload
