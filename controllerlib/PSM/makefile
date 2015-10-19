all: IO_controller_program.vhd | channel_program.vhd

IO_controller_program.vhd: IO_controller_program.psm route_command.psm \
		SPI_IO.psm ADC_SPI.psm global_registers.psm definitions.psm \
		uart_interface_routines.psm command_IO.psm utility.psm ROM_form.vhd \
 		AD9510_SPI.psm
	kcpsm6 IO_controller_program.psm               
	
channel_program.vhd: channel_program.psm channel_command_handler.psm\
		definitions.psm uart_interface_routines.psm \
  	command_IO.psm utility.psm rom_form.vhd 
	kcpsm6 channel_program.psm