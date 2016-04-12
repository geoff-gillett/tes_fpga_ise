=================
Channel Registers
=================

capture
-------
13 registers

max_peaks 
  unsigned 4 bits
   
  The maximum numer of peaks stored in a peak or trace event is 
  max_peaks+1. This can be used to set the fixed transmittion size of a pulse 
  event.

cfd_rel2min
  boolean
   
  If false the constant fraction value of the *first* peak in a pulse is 
  calulated from baseline (0) to the peak height. Otherwise the calculation is 
  from the preceeding minima to peak height.
   
constant_fraction
  unsigned?? 0.18 bits 
  
  The 18 represent the reciprical of the constant fraction.
  
pulse_threshold
   unsigned?? 18.3?? bits
   
   Threshold on the filtered signal, must be exceeded for a event to be 
   transmitted. Pulse area is the sum of samples above pulse_threshold
   
slope_threshold
   unsigned?? 18.3?? bits
 
   Threshold on slope signal, arms the peak detector when exceeded
  
pulse_area_threshold
   signed 32 bits
   
   Threshold pulse area must exceed for event to be transmitted
   
height_type
   discrete type 2 bits
   
   how the height value is calculated.
   
      00:peak
      01:cfd_high
      10:slope_integral
      11:reserved
 
 threshold_rel2min
   boolean
   
   If true the pulse threshold is relative to the minima preceeding the peak.
   If false it is relative to the baseline.
   
 height_rel2min
   boolean
   
   The height value is relative to the preceeding minima.
   
 trigger_type
   discrete type 2 bits
   
   The point that is time-stamped
   
   00:pulse_threshold positive crossing
   01:slope_threshold positive crossing
   10:cfd_low
   11:rise_start the minima precceding the peak
 
 detection_type
   discrete type 2 bits
   
   Type of event sent
   
   00:peak  - individually timed peaks, 8 bytes 
   01:area  - the area of a pulse, 8 bytes
   10:pulse - peak and area information, fixed but selectable length
   11:trace - peak and area information and 1 or two signal traces.
   
 trace0_type, trace1_type (1 register)
   discrete type 2 bits
   
   Signal to trace
   
   00:none
   01:raw
   10:filtered
   11:slope
   
 captue.baseline
 ---------------
 6 registers
 
 offset
   unsigned 14 bit
   
   zero for adc
   
subtraction
   boolean
   
   enable baseline subtraction

timeconstant
   unsigned 32 bits
   
   time to accumlate distributions for baseline calculation
   
threshold
   unsigned 10 bits
   
   Values *above* threshold do not contribute to the baseline
   
count_threshold 
   unsigned 18 bits
   
   The value must be seen at least this many time before appearing in the 
   baseline average
   
 average_order
   integer 0 to 6 (3 bits)
   
   Order of the baseline averaging filter
   
32 bit registers
count_threshold
time_constant
 

 
   
      
   
 