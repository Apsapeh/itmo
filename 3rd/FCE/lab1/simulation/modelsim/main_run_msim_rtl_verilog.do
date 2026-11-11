transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+/home/ghost/Desktop/itmo/3rd/FCE/lab1 {/home/ghost/Desktop/itmo/3rd/FCE/lab1/main.v}
vlog -vlog01compat -work work +incdir+/home/ghost/Desktop/itmo/3rd/FCE/lab1 {/home/ghost/Desktop/itmo/3rd/FCE/lab1/mux2_assign.v}
vlog -vlog01compat -work work +incdir+/home/ghost/Desktop/itmo/3rd/FCE/lab1 {/home/ghost/Desktop/itmo/3rd/FCE/lab1/mux2_n.v}

vlog -vlog01compat -work work +incdir+/home/ghost/Desktop/itmo/3rd/FCE/lab1 {/home/ghost/Desktop/itmo/3rd/FCE/lab1/tb.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -voptargs="+acc"  tb

add wave *
view structure
view signals
run -all
