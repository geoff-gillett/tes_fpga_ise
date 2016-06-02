import numpy as np
from enum import Enum
from os import path as ospath
from pickle import Pickler, Unpickler
from collections import namedtuple
from datetime import datetime

DEFAULT_REPO_PATH = 'c:\\TES_project\\fpga_ise\\'
File = namedtuple('File', ['filename', 'dtype', 'is_list', 'is_sliceable'])

tick_dt = np.dtype(
    [('period', np.uint32),
     ('flags', np.uint8, (2, 1)),
     ('time', np.uint16),
     ('timestamp', np.uint64),
     ('framer_ovf', np.uint8),
     ('mux_ovf', np.uint8),
     ('measurement_ovf', np.uint8),
     ('cfd_error', np.uint8),
     ('peak_ovf', np.uint8),
     ('time_ovf', np.uint8),
     ('baseline_unf', np.uint8),
     ('reserved', np.uint8)]
)

area_dt = np.dtype(
    [('area', np.uint32), ('flags', np.uint8, (2,)), ('time', np.uint16)]
)


# TODO import from tes_interface.registers
class HeightType(Enum):
    @staticmethod
    def from_int(value):
        if value == 0:
            return HeightType.peak_height
        elif value == 1:
            return HeightType.cfd_high
        elif value == 2:
            return HeightType.slope_integral
        else:
            raise AttributeError()

    peak_height = 0
    cfd_high = 1
    slope_integral = 2


class TriggerType(Enum):
    @staticmethod
    def from_int(value):
        if value == 0:
            return TriggerType.pulse_threshold
        elif value == 1:
            return TriggerType.slope_threshold
        elif value == 2:
            return TriggerType.cfd_low
        else:
            raise AttributeError()

    pulse_threshold = 0
    slope_threshold = 1
    cfd_low = 2


class PayloadType(Enum):
    @staticmethod
    def from_int(value):
        if value == 0:
            return PayloadType.peak
        elif value == 1:
            return PayloadType.area
        elif value == 2:
            return PayloadType.pulse
        elif value == 3:
            return PayloadType.trace
        elif value == 4:
            return PayloadType.tick
        elif value == 5:
            return PayloadType.mca
        else:
            print('{:d} cannot be converted to PayloadType'.format(value))
            # raise AttributeError()
            return None

    peak = 0
    area = 1
    pulse = 2
    trace = 3
    tick = 4
    mca = 5


class McaValueType(Enum):
    @staticmethod
    def from_int(value):
        if value == 0:
            return McaValueType.filtered_signal
        elif value == 1:
            return McaValueType.filtered_area
        elif value == 2:
            return McaValueType.filtered_extrema
        elif value == 3:
            return McaValueType.slope_signal
        elif value == 4:
            return McaValueType.slope_area
        elif value == 5:
            return McaValueType.slope_extrema
        elif value == 6:
            return McaValueType.pulse_area
        elif value == 7:
            return McaValueType.pulse_extrema
        elif value == 8:
            return McaValueType.pulse_time
        elif value == 9:
            return McaValueType.raw_signal
        elif value == 10:
            return McaValueType.raw_area
        elif value == 11:
            return McaValueType.raw_extrema
        else:
            raise AttributeError(
                '{:d} cannot be converted to McaValueType'.format(value))

    # @property
    # def trace(self):
    #     if self is McaValueType.filtered_signal:
    #         return 'filtered'
    #     elif self is McaValueType.filtered_area:
    #         return 'filtered'
    #     elif self is McaValueType.filtered_extrema:
    #         return 'filtered'
    #     elif self is McaValueType.slope_signal:
    #         return 'slope'
    #     elif self is McaValueType.slope_area:
    #         return 'slope'
    #     elif self is McaValueType.slope_extrema:
    #         return 'slope'
    #     elif self is McaValueType.raw_signal:
    #         return 'raw'
    #     elif self is McaValueType.raw_area:
    #         return 'raw'
    #     elif self is McaValueType.raw_extrema:
    #         return 'raw'
    #     else:
    #         return None

    filtered_signal = 0
    filtered_area = 1
    filtered_extrema = 2
    slope_signal = 3
    slope_area = 4
    slope_extrema = 5
    pulse_area = 6
    pulse_extrema = 7
    pulse_time = 8
    raw_signal = 9
    raw_area = 10
    raw_extrema = 11


class McaTriggerType(Enum):
    @staticmethod
    def from_int(value):
        if value == 0:
            return McaTriggerType.disabled
        elif value == 1:
            return McaTriggerType.clock
        elif value == 2:
            return McaTriggerType.filtered_xing
        elif value == 3:
            return McaTriggerType.filtered_0xing
        elif value == 4:
            return McaTriggerType.slope_0xing
        elif value == 5:
            return McaTriggerType.slope_xing
        elif value == 6:
            return McaTriggerType.cfd_high
        elif value == 7:
            return McaTriggerType.cfd_low
        elif value == 8:
            return McaTriggerType.maxima
        elif value == 9:
            return McaTriggerType.mimima
        elif value == 10:
            return McaTriggerType.raw_0xing
        else:
            raise AttributeError()

    disabled = 0
    clock = 1
    filtered_xing = 2
    filtered_0xing = 3
    slope_0xing = 4
    slope_xing = 5
    cfd_high = 6
    cfd_low = 7
    maxima = 8
    mimima = 9
    raw_0xing = 10


class EventStream:
    # NOTE copies stream64 to bytestream.
    # Expects stream64 to contain only one PayloadType
    def __init__(self, stream64):
        self.last = (stream64['last'].nonzero()[0] + 1) * 8
        self.bytestream = np.copy(stream64['data']).view(np.uint8)

        tick = np.bitwise_and(self.bytestream[5], 0x02) != 0
        payload = PayloadType.from_int(
            np.right_shift(np.bitwise_and(self.bytestream[5], 0x000C), 2))
        event_size = self.bytestream[0:2].view(np.uint16)

        if tick:
            self.type = PayloadType.tick
        else:
            self.type = payload

        if self.type == PayloadType.pulse:
            pulse_peak_dt = np.dtype(
                ([('height', np.uint16), ('minima', np.int16),
                  ('rise_time', np.uint16), ('time', np.uint16)])
            )
            pulse_dt = np.dtype(
                ([('size', np.uint16), ('length', np.uint16),
                  ('flags', np.uint8, (2,)), ('time', np.uint16),
                  ('area', np.int32), ('pulse_threshold', np.uint16),
                  ('slope_threshold', np.uint16),
                  ('peaks', pulse_peak_dt, (event_size - 2,))])
            )
            self._event_dt = pulse_dt

        else:
            self._event_dt = None
            NotImplementedError(
                '{:} needs implementation in EventStream'.format(self.type))

    @property
    def events(self):
        if self._event_dt is None:
            return None
        else:
            return self.bytestream.view(self._event_dt)

    class Flags:
        def __init__(self, flags):
            self.peak_count = np.right_shift(np.bitwise_and(flags[0], 0xF0), 4)
            self.height_rel2min = np.bitwise_and(flags[0], 0x08) != 0
            self.channel = np.bitwise_and(flags[0], 0x07)
            self.timing = TriggerType.from_int(
                np.right_shift(np.bitwise_and(flags[1], 0xC0), 6))
            self.height = HeightType.from_int(
                np.right_shift(np.bitwise_and(flags[1], 0x30), 4))
            self.type = PayloadType.from_int(
                np.right_shift(np.bitwise_and(flags[1], 0x000C), 2))
            self.tick = np.bitwise_and(flags[1], 0x02) != 0
            self.new_window = np.bitwise_and(flags[1], 0x01) != 0

        def __repr__(self):
            return 'peak count:{:d}\nheight_rel2min:{:}\n{:}\n{:}\nchannel:{:d}\n{:}\ntick:{:}\nnew_window:{:}'.format(
                self.peak_count, self.height_rel2min, self.height, self.timing,
                self.channel, self.type,
                self.tick, self.new_window
            )


class Data:
    def __init__(self, fileset, channels, project, testbench, tool='PlanAhead',
                 repo=DEFAULT_REPO_PATH):
        self._fileset = fileset
        self.channels = channels
        self.project = project
        self.testbench = testbench
        self.tool = tool
        self.creation_date = datetime.now()

        for file in fileset:
            fileinfo = fileset[file]
            if fileinfo.is_list:
                data = []
                for c in range(0, channels):
                    # print('{:s}{:d}'.format(simfile.filename, c))
                    data.append(
                        self.fromfile(
                            '{:s}{:d}'.format(fileinfo.filename, c),
                            fileinfo.dtype, project, testbench, tool, repo
                        )
                    )
            else:
                data = self.fromfile(fileinfo.filename, fileinfo.dtype, project,
                                     testbench, tool, repo)

            setattr(self, file, data)

    @staticmethod
    def fromfile(file, dt, project, testbench, tool='PlanAhead',
                 repo=DEFAULT_REPO_PATH):
        path = repo + project + '\\' + tool + '\\' + project + '.sim\\' + testbench + '\\'
        # print(path + file)
        if ospath.isfile(path + file):
            return np.fromfile(path + file, dt)
        else:
            print('{:s} does not exist'.format(path + file))
            return None

    # def _parse_settings(self):
    #     registers = dict()
    #     if not hasattr(self, 'settings') and not hasattr(self, 'mca_settings'):
    #         return None
    #
    #     if hasattr(self, 'settings'):
    #         registers['baseline'] = dict()
    #         registers['baseline']['offset'] = self.settings[0]
    #         registers['baseline']['subtraction'] = self.settings[1] != 0
    #         registers['baseline']['time_constant'] = self.settings[2]
    #         registers['baseline']['threshold'] = self.settings[3]
    #         registers['baseline']['count_threshold'] = self.settings[4]
    #         registers['generic'] = dict()
    #         registers['baseline']['average_order'] = self.settings[5]
    #         registers['capture'] = dict()
    #         registers['capture']['cfd_relative'] = self.settings[6] != 0
    #         registers['capture']['constant_fraction'] = self.settings[7]
    #         registers['capture']['pulse_threshold'] = self.settings[8]
    #         registers['capture']['slope_threshold'] = self.settings[9]
    #         registers['capture']['pulse_area_threshold'] = self.settings[10]
    #         registers['capture']['height_type'] = HeightType.from_int(self.settings[11])
    #         registers['capture']['threshold_rel2min'] = self.settings[12] != 0
    #         registers['capture']['trigger_type'] = TriggerType.from_int(self.settings[13])
    #         registers['capture']['event_type'] = PayloadType.from_int(self.settings[14])
    #         registers['capture']['height_rel2min'] = self.settings[15] != 0
    #
    #     if hasattr(self, 'mca_settings'):
    #         registers['mca'] = self._parse_mcasettings()
    #
    #     return registers

    # def _parse_mcasettings(self):
    #     if hasattr(self, 'mca_settings'):
    #         mca_registers = dict()
    #         mca_registers['channel'] = self.mca_settings[0]
    #         mca_registers['bin_n'] = self.mca_settings[1]
    #         mca_registers['last_bin'] = self.mca_settings[2]
    #         mca_registers['lowest_value'] = self.mca_settings[3]
    #         mca_registers['value'] = McaValueType.from_int(self.mca_settings[4])
    #         mca_registers['trigger'] = McaTriggerType.from_int(self.mca_settings[5])
    #         mca_registers['ticks'] = self.mca_settings[6]
    #         return mca_registers
    #     else:
    #         return None

    def save(self, filename=None):
        if filename is None:
            filename = '{:s}-{:}.pickle'.format(self.testbench,
                                                datetime.now().date())
        fp = open(filename, 'wb')
        pickler = Pickler(fp, protocol=-1)
        pickler.dump(self)

    @staticmethod
    def load(filename):
        fp = open(filename, 'rb')
        unpickler = Unpickler(fp)
        return unpickler.load()

    # time slice returns nested class Slice
    def slice(self, bounds):
        return self.Slice(self, bounds)

    def region(self, point, pre, length):
        return self.slice((point - pre, point - pre + length))

    # quick and dirty proxy to handle slices
    class Slice:

        def _slice(self, attr, array):
            if array is None:
                return None

            if 'index' in self._data._fileset[attr].dtype.fields:
                sliced = array[
                         np.searchsorted(array['index'], self.bounds[0]):
                         np.searchsorted(array['index'], self.bounds[1])
                         ]
            else:
                sliced = array[self.bounds[0]:self.bounds[1]]
            return sliced

        def _apply_bounds(self, attr):

            data = getattr(self._data, attr)  # get array from Data instance

            if self._bounds == 'all' or not self._data._fileset[
                attr].is_sliceable:
                return data
            else:
                if self._data._fileset[attr].is_list:
                    sliced = []
                    for array in data:
                        sliced.append(self._slice(attr, array))
                else:
                    sliced = self._slice(attr, data)

                self._sliced[attr] = sliced
                return sliced

        def __init__(self, data, bounds='all'):
            self._bounds = bounds  # slice bounds -- (a,b) yields a numpy [a:b] type slice
            self._data = data  # points to the Data instance
            self._sliced = dict()  # arrays that are already sliced

        def __getattr__(self, attr):

            if attr not in self._data._fileset:
                return getattr(self._data, attr)

            if attr in self._sliced:  # already sliced
                return self._sliced[attr]

            return self._apply_bounds(attr)

        @property
        def bounds(self):
            return self._bounds

        @bounds.setter
        def bounds(self, value):
            self._bounds = value
            # rest stored slices
            self._sliced = dict()


class Packet:
    def __init__(self, byte_stream):
        self.bytes = byte_stream
        self.ethertype = byte_stream[12:14].view(np.uint16).byteswap()[0]
        self.length = byte_stream[14:16].view(np.uint16)[0]
        self.payload = byte_stream[24:]

        if self.ethertype == 0x88B5:
            if np.bitwise_and(self.bytes[20], 0x02):
                self.payload_type = PayloadType.tick
            else:
                self.payload_type = PayloadType.from_int(
                    np.right_shift(np.bitwise_and(self.bytes[20], 0x0C), 2))
        elif self.ethertype == 0x88B6:
            self.payload_type = PayloadType.mca
        else:
            print('Unknown ethertype:{:X}'.format(self.ethertype))
            self.payload_type = None

        self.frame_sequence = byte_stream[16:18].view(np.int16)[0]
        self.protocol_sequence = byte_stream[18:20].view(np.int16)[0]

    def __repr__(self):
        if self.payload_type is None:
            pname = 'UNKNOWN'
        else:
            pname = self.payload_type.name
        return 'ethertype:{:04X} length:{:d} Payload:{:s} frame:{:d} protocol:{:d}'.format(
            self.ethertype, self.length, pname, self.frame_sequence,
            self.protocol_sequence)

    @property
    def events(self):
        if self.payload_type == PayloadType.tick:
            return self.payload.view(tick_dt)
        elif self.payload_type == PayloadType.area:
            return self.payload.view(area_dt)
        else:
            raise NotImplementedError()

    @staticmethod
    def channel(events):
        return np.bitwise_and(events['flags'][:, 0], 0x07)


# class Events:
#     def __init__(self, packet):
#         self.packet = packet
#         if packet.payload_type == PayloadType.tick:
#             self.data = packet.payload.view(tick_dt)
#         elif self.payload_type == PayloadType.area:
#             return self.payload.view(area_dt)
#         else:
#             raise NotImplementedError()


class PacketStream:
    # NOTE copies stream['data'] to bytestream
    def __init__(self, stream):

        lasts = stream['last'].nonzero()[0] + 1

        if not lasts.size:
            self.byte_stream = None
            self.packets = None
            return

        # TODO pre allocate byte_stream
        self.byte_stream = np.copy(stream['data'][0:lasts[0]]).view(np.uint8)
        prev = lasts[0]
        end = len(self.byte_stream)
        self.packets = [Packet(self.byte_stream[0:end])]

        for last in lasts[1:]:
            self.byte_stream = np.append(self.byte_stream, np.copy(
                stream['data'][prev:last]).view(np.uint8))
            prev = last
            start = end
            end = len(self.byte_stream)
            self.packets.append(Packet(self.byte_stream[start:end]))

    @property
    def distributions(self):
        distributions = []
        last_seq = None
        d = None
        if self.packets is None:
            return None
        for packet in self.packets:
            if packet.payload_type == PayloadType.mca:
                if last_seq is None:
                    if packet.protocol_sequence != 0:
                        print(
                            'Error first MCA frame does not have a 0 protocol sequence number')
                else:
                    if packet.protocol_sequence != 0 and packet.protocol_sequence != last_seq + 1:
                        print('MCA sequence number:{:d} missing'.format(
                            last_seq + 1))

                last_seq = packet.protocol_sequence
                if last_seq == 0:
                    if d is not None:
                        if d.last_bin + 1 == d._total_bins:
                            distributions.append(d)
                        else:
                            print(
                                "incomplete distribution dropped starting frame:{:d}".format(
                                    d._frame_sequence))
                    d = Distribution(packet)

                else:
                    d.add(packet)
        return distributions

    @property
    def event_packets(self):
        last_seq = None
        for packet in self.packets:
            if packet.ethertype == 0x88b5:
                if last_seq is None:
                    last_seq = packet.protocol_sequence
                else:
                    if packet.protocol_sequence != 0 and \
                                    packet.protocol_sequence != last_seq + 1:
                        print('Event sequence number:{:d} missing'.format(
                            last_seq + 1))


class Distribution:
    def __init__(self, header_packet):
        flags = header_packet.payload[8:10]
        self._frame_sequence = header_packet.frame_sequence
        self.value = McaValueType.from_int(
            np.right_shift(np.bitwise_and(flags[0], 0xF0), 4))
        self.trigger = McaTriggerType.from_int(np.bitwise_and(flags[0], 0x0F))
        self.bin_n = np.right_shift(np.bitwise_and(flags[1], 0xF0), 4)
        self.bin_width = np.power(2, self.bin_n)
        self.channel = np.bitwise_and(flags[1], 0x0F)
        # self.num_bins = header_packet.payload[0:2].view(np.uint16)[0]*2
        self.last_bin = header_packet.payload[2:4].view(np.uint16)[0]
        self.lowest_value = header_packet.payload[4:8].view(np.int32)[0]
        self.total = header_packet.payload[16:24].view(np.uint64)[0]
        self.start_time = header_packet.payload[24:32].view(np.uint64)[0]
        self.stop_time = header_packet.payload[32:40].view(np.uint64)[0]
        self.counts = np.zeros([self.last_bin + 1], dtype=np.dtype(np.uint32))

        packet_bins = np.uint32((header_packet.length - 40 - 24) / 4)
        # print(packet_bins)
        self.counts[0:packet_bins] = np.copy(
            header_packet.payload[40:].view(np.uint32))
        self._total_bins = packet_bins

    def add(self, packet):
        packet_bins = np.uint32((packet.length - 24) / 4)
        # print(packet_bins)
        self.counts[self._total_bins:self._total_bins + packet_bins] = np.copy(
            packet.payload.view(np.uint32))
        self._total_bins += packet_bins

    def data_counts(self, data):

        s = data.slice((self.start_time, self.start_time + np.uint64(1)))
        value = self.value.name.split('_')

        if value[1] == 'signal':
            values = s.trace[self.channel][value[0]]
        else:
            return NotImplementedError(
                '.checking distribution with {:} to be implemented'.format(
                    self.value))

        if self.trigger is McaTriggerType.clock:
            pass
        elif self.trigger is McaTriggerType.maxima:
            values = values[s.peak[self.channel]['index']]
        else:
            return NotImplementedError(
                'checking distributions with {:} to be implemented'.format(
                    self.trigger))

        binned = np.right_shift(values - self.lowest_value, self.bin_n)
        binned[binned < 0] = 0
        binned[binned > self.last_bin] = self.last_bin
        counts = np.bincount(binned, minlength=self.last_bin + 1)

        return counts

    def __repr__(self):
        return 'Distribution: {:s} {:s} start:{:d} stop:{:d}'.format(
            self.value, self.trigger, self.start_time, self.stop_time)
