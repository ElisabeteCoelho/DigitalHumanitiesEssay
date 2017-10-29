using EzXML

# Since the file is too big, we have to stream it instead of allocating it all in memory
# gnd = open(EzXML.StreamReader, "GND.rdf")

# Functions to read nodes and content on streaming
# done(gnd)
# a = nodetype(gnd)
# b = nodename(gnd)
# c = nodedepth(gnd)
# d = namespace(gnd)
# e = nodecontent(gnd)

# print(a, '\t', b, '\t', c, '\t', d, '\t', e)

# Close the stream
# close(gnd)

gnd = open(EzXML.StreamReader, "Composers.rdf")

open("A01-composers_codes.lst", "a") do f
    node = "notext"
    for typ in gnd
        if typ == EzXML.READER_ELEMENT
            elname = nodename(gnd)
            if elname == "rdf:Description" && nodedepth(gnd) == 1
                node = gnd["rdf:about"]
            elseif elname == "gndo:professionOrOccupation" && gnd["rdf:resource"] == "http://d-nb.info/gnd/4032009-1" # Composer (male)
                write(f, string(node, "\n"))
            elseif elname == "gndo:professionOrOccupation" && gnd["rdf:resource"] == "http://d-nb.info/gnd/4032010-8" # Composer (female)
                write(f, string(node, "\n"))
            end
        end
    end
end
close(gnd)

