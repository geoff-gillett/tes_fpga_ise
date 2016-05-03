# Geoff gillett
PROJECT=teslib
TB=measurement_unit_TB
ISE_DIR=C:/Xilinx/14.7/ISE_DS
REPO=C:/TES_project/fpga_ise
ISE_SIMDIR=../PlanAhead/$(project).sim
VIVADO_SIMDIR=../Vivado/$(project).sim/$(TB)/behav

VHDL=../../extensions/HDL/boolean_vector.vhd \
../HDL/types.vhd ../HDL/dsptypes.vhd ../../extensions/HDL/logic.vhd \
../HDL/functions.vhd ../HDL/adc.vhd ../../streamlib/HDL/types.vhd \
../HDL/registers.vhd ../../mcalib/HDL/mca_buffer.vhd
../HDL/events.vhd ../HDL/serialiser_logic.vhd ../../mcalib/HDL/mca.vhd \
../IP_cores/stage2_FIR_23/stage2_FIR_23.vhd \
../IP_cores/stage1_FIR_23/stage1_FIR_23.vhd \
../HDL/utility/select_1of12.vhd ../HDL/measurements.vhd \
../HDL/dsp/SREG_delay.vhd ../HDL/dsp/most_frequent.vhd \
../HDL/dsp/average_filter.vhd ../../streamlib/HDL/serialiser.vhd \
../HDL/mca/mca_value_selector.vhd ../HDL/dsp/two_stage_FIR.vhd \
../HDL/dsp/signal_measurement.vhd ../HDL/dsp/RAM_delay.vhd \
../HDL/dsp/closest_xing.vhd ../HDL/dsp/baseline_estimator.vhd \
../../streamlib/HDL/framer.vhd ../HDL/dsp/measurement_unit.vhd \
../simulation/$(TB)/$(TB).vhd \

#generates the simulation exe
$(TB).exe: $(VHDL)
	fuse -intstyle pa -incremental -L extensions -L work -L streamlib -L mcalib \
		-L secureip -o $(ISE_SIMDIR)/$(TB)/$(TB).exe \
		--prj $(TB).prj \
		-top work.$(TB)

vivado_simdir: 
	mkdir $(VIVADO_SIMDIR)

OBJDIR := objdir
OBJS := $(addprefix $(OBJDIR)/,foo.o bar.o baz.o)

$(OBJDIR)/%.o : %.c
    $(COMPILE.c) $(OUTPUT_OPTION) $<

all: $(OBJS)

$(OBJS): | $(OBJDIR)

$(OBJDIR):
    mkdir -p $(OBJDIR)