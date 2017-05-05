# This script splits Web of Science XML files and is used along with thr parser in this folder.
# Creation Date: circa June 2016
# Modified: 3/30/2017, Samet Keserci and George Chacko added comments and a README# 

# 05/05/2017. While we have no record or notes of a fork, this new_xml_split.py script is an exact copy of
# https://gist.github.com/nicwolff/b4da6ec84ba9c23c8e59
# therefore, we acknowledge Nic Wolff's prior contribution with thanks. 

import os
import sys
from xml.sax import parse
from xml.sax.saxutils import XMLGenerator

class CycleFile(object):

    def __init__(self, filename):
        self.basename, self.ext = os.path.splitext(filename)
        self.index = 0
        self.open_next_file()

    def open_next_file(self):
        self.index += 1
        self.file = open(self.name(), 'w')

    def name(self):
        return '%s_SPLIT_%s%s' % (self.basename, self.index, self.ext)

    def cycle(self):
        self.file.close()
        self.open_next_file()

    def write(self, str):
        self.file.write(str)

    def close(self):
        self.file.close()

class XMLBreaker(XMLGenerator):

    def __init__(self, break_into=None, break_after=1000, out=None, *args, **kwargs):
        XMLGenerator.__init__(self, out, *args, **kwargs)
        self.out_file = out
        self.break_into = break_into
        self.break_after = break_after
        self.context = []
        self.count = 0

    def startElement(self, name, attrs):
        XMLGenerator.startElement(self, name, attrs)
        self.context.append((name, attrs))

    def endElement(self, name):
        XMLGenerator.endElement(self, name)
        self.context.pop()
        if name == self.break_into:
            self.count += 1
            if self.count == self.break_after:
                self.count = 0
                for element in reversed(self.context):
                    self.out_file.write("\n")
                    XMLGenerator.endElement(self, element[0])
                self.out_file.cycle()
                XMLGenerator.startDocument(self)
                for element in self.context:
                    XMLGenerator.startElement(self, *element)

filename, break_into, break_after = sys.argv[1:]
parse(filename, XMLBreaker(break_into, int(break_after), out=CycleFile(filename)))
