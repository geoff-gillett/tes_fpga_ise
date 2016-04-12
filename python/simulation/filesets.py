import numpy as np
from .data import File

measurement_subsystem_TB = dict()
# dict containing tuples (filename, dtype, is_array, is_sliceable) representing a set of testbench output files
# to be read to create a simulation.data Data class
#
# The dict key is the name to give the resulting attribute in the Data class instance
# The file is read using numpy.fromfile() with the given dtype
# If is array is True then all files of the form filenmameX are read, where X is a digit indicating the channel
# the created attribute is an array.
# is_slicable boolean indicates that the attribute should be included when creating a Data.Slice object.
# When the dtype includes a field labeled index, the slice will contain the values where the index field is
# in the slice bounds rather than the traditional start:stop range

measurement_subsystem_TB['trace'] = File(
    'traces',
    np.dtype([('input', np.int16), ('raw', np.int16), ('filtered', np.int16), ('slope', np.int16)]),
    True,
    True,
)

meas_dt=np.dtype([('index', np.int32), ('area', np.int32), ('extrema', np.int32)])

measurement_subsystem_TB['raw'] = File(
    'raw',
    meas_dt,
    True,
    True
)

measurement_subsystem_TB['filtered'] = File(
    'filtered',
    meas_dt,
    True,
    True
)

measurement_subsystem_TB['slope'] = File(
    'slope',
    meas_dt,
    True,
    True
)

measurement_subsystem_TB['pulse'] = File(
    'pulse',
    meas_dt,
    True,
    True
)

index_dt = np.dtype([('index', np.uint32)])

measurement_subsystem_TB['pulse_start'] = File(
    'pulsestart',
    index_dt,
    True,
    True
)

measurement_subsystem_TB['slope_thresh_xing'] = File(
    'slopethreshxing',
    index_dt,
    True,
    True
)

measurement_subsystem_TB['peak'] = File(
    'peak',
    index_dt,
    True,
    True
)

measurement_subsystem_TB['peak_start'] = File(
    'peakstart',
    index_dt,
    True,
    True
)

measurement_subsystem_TB['heights'] = File(
    'height',
    index_dt,
    True,
    True
)

measurement_subsystem_TB['cfd_low'] = File(
    'cfdlow',
    index_dt,
    True,
    True
)

measurement_subsystem_TB['cfd_high'] = File(
    'cfdhigh',
    index_dt,
    True,
    True
)

measurement_subsystem_TB['trigger'] = File(
    'trigger',
    index_dt,
    True,
    True
)

stream_dt = np.dtype([('data', np.uint64), ('last', np.bool)])

measurement_subsystem_TB['event_stream'] = File(
    'muxstream',
    stream_dt,
    False,
    False
)

measurement_subsystem_TB['mca_stream'] = File(
    'mcastream',
    stream_dt,
    False,
    False
)

measurement_subsystem_TB['ethernet_stream'] = File(
    'ethernetstream',
    stream_dt,
    False,
    False
)

error_dt = np.dtype([('index', np.uint32), ('flags', np.uint8)])

measurement_subsystem_TB['cfd_error'] = File(
    'cfderror',
    error_dt,
    False,
    True
)

measurement_subsystem_TB['time_overflow'] = File(
    'timeoverflow',
    error_dt,
    False,
    True
)

measurement_subsystem_TB['peak_overflow'] = File(
    'peakoverflow',
    error_dt,
    False,
    True
)


measurement_subsystem_TB['mux_full'] = File(
    'muxfull',
    error_dt,
    False,
    True
)

measurement_subsystem_TB['mux_overflow'] = File(
    'muxoverflow',
    error_dt,
    False,
    True
)

measurement_subsystem_TB['framer_overflow'] = File(
    'frameroverflow',
    error_dt,
    False,
    True
)

measurement_subsystem_TB['baseline_error'] = File(
    'baselineerror',
    error_dt,
    False,
    True
)

measurement_subsystem_TB['time_overflow'] = File(
    'timeoverflow',
    np.int32,
    False,
    True
)

measurement_subsystem_TB['settings'] = File(
    'setting',
    np.int32,
    True,
    False
)

measurement_subsystem_TB['mca_settings'] = File(
    'mcasetting',
    np.int32,
    False,
    False
)

measurement_subsystem_TB['byte_stream'] = File(
    'bytestream',
    np.dtype([('index', np.uint32), ('data', np.uint8), ('last', np.bool)]),
    False,
    False
)
