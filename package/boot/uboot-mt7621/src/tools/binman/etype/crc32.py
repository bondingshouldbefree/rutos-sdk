from binman.entry import Entry
import zlib

class Entry_crc32(Entry):
    def __init__(self, section, etype, node):
        super().__init__(section, etype, node)
        self.align = 4
        self.size = 10

    def ObtainContents(self):
        self.SetContents('0000000000'.encode())
        return True

    def ProcessContents(self):
        data = self.section.GetData()
        crc = zlib.crc32(data[:-10])
        self.SetContents('{:010d}'.format(crc).encode())
        return True
