function registers = interpret_settings( vector )

registers.dsp.baseline.subtraction=vector(1);
registers.dsp.baseline.offset=vector(2);
registers.dsp.constant_fraction=vector(3);
registers.dsp.pulse_threshold=vector(4);
registers.dsp.slope_threshold=vector(5);
registers.dsp.baseline.av_order=vector(6);
registers.dsp.baseline.AV_FRAC=vector(7);
registers.capture.rel_to_min=vector(8);
registers.capture.event_type=vector(9);
registers.capture.height_type=vector(10);
registers.capture.trigger_type=vector(11);


end

