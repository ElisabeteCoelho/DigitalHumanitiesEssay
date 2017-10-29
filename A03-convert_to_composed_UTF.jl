open("A02-Composers.rdf") do file
    for line in eachline(file)
        open("A03-Composers_composedUTF.rdf", "a") do newfile
            write(newfile, string(normalize_string(line), '\n'))
         end
    end
end