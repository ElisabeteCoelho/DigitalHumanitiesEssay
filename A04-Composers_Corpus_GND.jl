###### SETTING UP THE ENVIRONMENT #####

### LIBRARIES
# Loading needed libraries
using DataFrames
using EzXML

##### READING AND ORGANIZING THE DATA ######

# Creates a tables from .csv file
nmd = readtable("newmetadata_02.csv", encoding = :utf8)

# Selects relevant info, summarizes and organizes it
comp = DataFrame(by(nmd, :composer, ct -> DataFrame(count = Int16(nrow(ct)))))

# Reads the GND into the memory
gnd = readxml("A03-Composers_composedUTF.rdf") 

# Defining the namespaces
ns = ["x" => namespace(root(gnd)), "y" => "http://d-nb.info/standards/elementset/gnd#"]

# Function to apply XPath query and return an appropriate response
function gnddata(node::EzXML.Node, xpath::String; x = 1, y = 0)
    n = EzXML.find(node, xpath, ns)
    l = length(n)
    if l == 0
        return "NA"
    elseif l == 1
        return string(n[1])[x:end - y]
    else
        if xpath == "y:geographicAreaCode" || xpath == "y:variantNameForThePerson/text()"
            return join([string(el)[x:end - y] for el in find(node, xpath, ns)], "; ")
        else
            return "MT1M" # more than one match
        end
    end
end

compfile = "A04-Composers_Corpus_GND.tsv"

# Function to clean up the composer names, so that they may be found in the GND
function replacenames(s::String)
    s = replace(s, r"'", "\'") # escaping apostrophes in names, like "Gomes, Miguel d'Andrade"
    s = replace(s, r"\(|\)", "") # removing parenthesis in the middle names, like "Dvořák, Antonín (Leopold)"
    s = replace(s, r"Sir ", "") # removing nobility title, like "Elgar, Sir Edward"
    s = replace(s, r"Comtesse ", "") # removing nobility title
    s = replace(s, r"(i, d.1560)", "") # solving one specific case
    s = replace(s, r"(Dresden)", "") # solving one specific case
    s = replace(s, r"(\"Voyager\")", "") # solving one specific case
    return strip(s)
end

# Writes header of .tsv file
open(compfile, "w") do f
    write(f, join(["Row", "CAMC_Name", "GND_URI", "GND_Name", "GND_Land", "GND_Gender", "GND_Birth", "GND_Death", "GND_VariantName"], '\t'), '\n')
end

for i in 1:length(comp[:composer])
    # Initializes default values for variables
    camc_comp = replacenames(comp[i, :composer])
    gnd_prefname = "not found"
    gnd_uri = gnd_land = gnd_gender = gnd_birth = gnd_death = gnd_varname = "NA" 
    gnd_gendernum = 0
#     println(camc_comp)
    
    mynodes = find(root(gnd),"//x:Description/y:preferredNameForThePerson[contains(.,\"$camc_comp\")]/parent::x:Description[@x:about]", ns)
    if isempty(mynodes)
        mynodes = find(root(gnd),"//x:Description/y:variantNameForThePerson[contains(.,\"$camc_comp\")]/parent::x:Description[@x:about]", ns)
    end

    # If a composer name is found among the preferredName, fills in the data
    # these cases will be dealt later with a search on variantName 
    if ~isempty(mynodes)
        for node in mynodes
            gnd_prefname = gnddata(node, "y:preferredNameForThePerson/text()")
            gnd_uri = node["rdf:about"]
            gnd_land = gnddata(node, "y:geographicAreaCode", x = 98, y = 3)
            gnd_gender = gnddata(node, "y:gender/@x:resource", x = 60, y = 1)
            if gnd_gender == "male"
                gnd_gendernum = 1
            elseif gnd_gender == "female"
                gnd_gendernum = 2
            else
                gnd_gendernum = 0
            end
            gnd_birth = gnddata(node, "y:dateOfBirth/text()")
            gnd_death = gnddata(node, "y:dateOfDeath/text()")
            gnd_varname = gnddata(node, "y:variantNameForThePerson/text()")
#             println(join([comp[:composer][i], gnd_uri, gnd_prefname, gnd_land, gnd_gendernum, gnd_birth, gnd_death, gnd_varname], '\n'))
            open(compfile, "a") do f
                write(f, join([i, comp[i, :composer], gnd_uri, gnd_prefname, gnd_land, gnd_gendernum, gnd_birth, gnd_death, gnd_varname], '\t'), '\n')
            end
        end
    else
#         println(join([comp[:composer][i], gnd_uri, gnd_prefname, gnd_land, gnd_gendernum, gnd_birth, gnd_death, gnd_varname], '\n'))
        open(compfile, "a") do f
            write(f, join([i, comp[i, :composer], gnd_uri, gnd_prefname, gnd_land, gnd_gendernum, gnd_birth, gnd_death, gnd_varname], '\t'), '\n')
        end
    end
    println(i, '\t', camc_comp, "\t\t", length(mynodes))
end

println("Writing done!")