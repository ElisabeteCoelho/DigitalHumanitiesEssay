
###### SETTING UP THE ENVIRONMENT #####

### LIBRARIES
# Loading needed libraries
using DataFrames
using Gadfly
using EzXML

##### READING AND ORGANIZING THE DATA ######

# Creates a tables from .csv file
nmd = readtable("newmetadata_02.csv", encoding = :utf8)

# Selects relevant info, summarizes and organizes it
ta = nmd[:, [:composer, :country, :birth, :death]]
ind  = []

comp = DataFrame(by(ta, :composer, ct -> DataFrame(count = Int16(nrow(ct)))))

# Lists the indexes of composers' names
for c in comp[:composer]
    push!(ind, findfirst(ta[:composer], c))
end

comp[:country] = [ta[i, :country] for i in ind]
comp[:birth] = [ta[i, :birth] for i in ind]
comp[:death] = [ta[i, :death] for i in ind]

comp = comp[:, [1, 3, 4, 5, 2]]

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

# Writes header of .tsv file
open(compfile, "w") do f
    write(f, join(["CAMC_Name", "GND_URI", "GND_Name", "GND_Land", "GND_Gender", "GND_Birth", "GND_Death", "GND_VariantName"], '\t'), '\n')
end

for i in 1440:length(comp[:composer])
    # Initializes default values for variables
    camc_comp = replace(replace(comp[i, :composer], r"'", "\'"), r"\(|\)", "")
    gnd_prefname = "not found"
    gnd_uri = gnd_land = gnd_gender = gnd_birth = gnd_death = gnd_varname = "NA" 
    gnd_gendernum = 0
    
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
                write(f, join([comp[i, :composer], gnd_uri, gnd_prefname, gnd_land, gnd_gendernum, gnd_birth, gnd_death, gnd_varname], '\t'), '\n')
            end
        end
    else
#         println(join([comp[:composer][i], gnd_uri, gnd_prefname, gnd_land, gnd_gendernum, gnd_birth, gnd_death, gnd_varname], '\n'))
        open(compfile, "a") do f
            write(f, join([comp[i, :composer], gnd_uri, gnd_prefname, gnd_land, gnd_gendernum, gnd_birth, gnd_death, gnd_varname], '\t'), '\n')
        end
    end
    println(i, '\t', camc_comp, "\t\t\t", length(mynodes))
end

println("Writing done!")