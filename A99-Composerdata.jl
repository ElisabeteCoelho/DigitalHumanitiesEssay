#!/usr/env julia

using EzXML

# Reading composer's data and writing it to a tsv file

gnd = readxml("Composers_c.rdf")

# Loading the URIs
# uri = [string(el)[12:end] for el in find(root(gnd), "//x:Description/@x:about", ns)] # remove the rdf:about= 
function rl(s::String)
    l = String[]
    open(s) do f
        l = readlines(f)
    end
    return l
end

uri = [string("\"", el, "\"") for el in rl("codes.lst")]

# Defining the namespaces
ns = ["x" => namespace(root(gnd)), "y" => "http://d-nb.info/standards/elementset/gnd#"]

# Function to apply XPath query and return an appropriate response
function gnddata(xpath::String; x = 1, y = 0)
    l = length(find(root(gnd), xpath, ns))
    if l == 0
        return "NA"
    elseif l == 1
        return string(find(root(gnd), xpath, ns)[1])[x:end - y]
    else
        return join([string(el)[x:end - y] for el in find(root(gnd), xpath, ns)], "; ")
    end
end

open("Composerdata.tsv", "w") do f
    write(f, join(["URI", "Name", "Land", "Gender", "Birth", "Death", "VariantName"], '\t'), '\n')
end

for i in 35323:length(uri)
    pfx = "//x:Description[@x:about=" # prefix

    name = gnddata(string(pfx, uri[i], "]/y:preferredNameForThePerson/text()"))
    land =  gnddata(string(pfx, uri[i], "]/y:geographicAreaCode/@x:resource"), x = 74, y = 1)
    gender = gnddata(string(pfx, uri[i], "]/y:gender/@x:resource"), x = 60, y = 1)
    if gender == "male"
        gendernum = 1
    elseif gender == "female"
        gendernum = 2
    else
        gendernum = 0
    end
    birth = gnddata(string(pfx, uri[i], "]/y:dateOfBirth/text()"))
    death = gnddata(string(pfx, uri[i], "]/y:dateOfDeath/text()"))
    varname = gnddata(string(pfx, uri[i], "]/y:variantNameForThePerson/text()"))
    
    open("Composerdata.tsv", "a") do f
        write(f, join([uri[i], name, land, gendernum, birth, death, varname], '\t'), '\n')
    end
    
    println(i)
end
println("Writing done!")