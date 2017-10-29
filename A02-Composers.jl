using EzXML

gnd = open(EzXML.StreamReader, "GND.rdf")

# open("Composers.rdf", "a") do f
    # n = 1
    # cl = "</rdf:Description>\n"
    # write(f, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
    
    # open("codes.lst") do codes
        # code = readlines(codes)
        # for typ in gnd
            # if typ == EzXML.READER_ELEMENT && nodename(gnd) == "rdf:Description" && nodedepth(gnd) == 1 && gnd["rdf:about"] == code[n]
                # op = string('<', nodename(gnd), " rdf:about=\"", gnd["rdf:about"], "\">")
                # write(f, op)
                # node = expandtree(gnd)
                # for elem in eachnode(node)
                    # write(f, string(elem))
                # end
                # write(f, cl)
                # n < length(code) ? n +=1 : break # breaks when there are no more codes
            # end
        # end
        
        # close(gnd)
    # end    
    # write(f, "</rdf:RDF>")
# end

# open("Composers.rdf", "a") do f
    # n = 1
    # cl = "</rdf:Description>\n"
    # write(f, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
    
    # open("codes.lst") do codes
        # code = readlines(codes)
        # for typ in gnd
            # if typ == EzXML.READER_ELEMENT && nodename(gnd) == "rdf:Description" && nodedepth(gnd) == 1
                # if gnd["rdf:about"] in code
                    # op = string('<', nodename(gnd), " rdf:about=\"", gnd["rdf:about"], "\">")
                    # write(f, op)
                    # node = expandtree(gnd)
                    # for elem in eachnode(node)
                        # write(f, string(elem))
                    # end
                    # write(f, cl)
                    # n < length(code) ? n +=1 : break # breaks when there are no more codes
                # end
            # end
        # end
        
        # close(gnd)
    # end    
    # write(f, "</rdf:RDF>")
# end

function rl(s::String)
    l = String[]
    open(s) do f
        l = readlines(f)
    end
    return l
end

codes = rl("A01-composers_codes.lst")
gnd = open(EzXML.StreamReader, "GND.rdf")

open("A02-Composers.rdf", "a") do f
    cl = "</rdf:Description>\n"
    write(f, """
    <?xml version="1.0" encoding="UTF-8"?>
        <rdf:RDF
        xmlns:schema="http://schema.org/"
        xmlns:gndo="http://d-nb.info/standards/elementset/gnd#"
        xmlns:lib="http://purl.org/library/"
        xmlns:marcRole="http://id.loc.gov/vocabulary/relators/"
        xmlns:owl="http://www.w3.org/2002/07/owl#"
        xmlns:skos="http://www.w3.org/2004/02/skos/core#"
        xmlns:dcmitype="http://purl.org/dc/dcmitype/"
        xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
        xmlns:geo="http://www.opengis.net/ont/geosparql#"
        xmlns:umbel="http://umbel.org/umbel#"
        xmlns:dbp="http://dbpedia.org/property/"
        xmlns:dnbt="http://d-nb.info/standards/elementset/dnb#"
        xmlns:rdau="http://rdaregistry.info/Elements/u/"
        xmlns:sf="http://www.opengis.net/ont/sf#"
        xmlns:dnb_intern="http://dnb.de/"
        xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
        xmlns:v="http://www.w3.org/2006/vcard/ns#"
        xmlns:dcterms="http://purl.org/dc/terms/"
        xmlns:ebu="http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#"
        xmlns:bibo="http://purl.org/ontology/bibo/"
        xmlns:gbv="http://purl.org/ontology/gbv/"
        xmlns:isbd="http://iflastandards.info/ns/isbd/elements/"
        xmlns:foaf="http://xmlns.com/foaf/0.1/"
        xmlns:dc="http://purl.org/dc/elements/1.1/">
        """)
    
    for typ in gnd
        if typ == EzXML.READER_ELEMENT && nodename(gnd) == "rdf:Description" && nodedepth(gnd) == 1
            if gnd["rdf:about"] in codes
                op = string('<', nodename(gnd), " rdf:about=\"", gnd["rdf:about"], "\">")
                write(f, op)
                node = expandtree(gnd)
                for elem in eachnode(node)
                    write(f, string(elem))
                end
                write(f, cl)
                splice!(codes, findfirst(codes, gnd["rdf:about"]))
                println(length(codes))
            end
        end
    end
        
    close(gnd)
    write(f, "</rdf:RDF>")
end