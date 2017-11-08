using DataFrames

## Reading and summarizing the CAMC composer's data
nmd = readtable("newmetadata_02.csv", encoding = :utf8)
ta = nmd[:, [:composer, :country, :birth, :death]]
ind  = []

comp = DataFrame(by(ta, :composer, ct -> DataFrame(count = Int16(nrow(ct)))))

# Removing the unidentified composers. Should have been done a long time ago.
comp = comp[[!ismatch(r"Anonymous|Traditional|Gregorian", el) for el in comp[:composer]], :]

# Lists the indexes of composers' names
for c in comp[:composer]
    push!(ind, findfirst(ta[:composer], c))
end

comp[:country] = [ta[i, :country] for i in ind]
comp[:birth] = [ta[i, :birth] for i in ind]
comp[:death] = [ta[i, :death] for i in ind]

camc = comp[:, [1, 3, 4, 5, 2]]
rename!(camc, [:composer, :country, :birth, :death, :count], [:CAMC_Name, :CAMC_Country, :CAMC_Birth, :CAMC_Death, :CAMC_Count])

# Avoiding troubles with a particular name. I should have removed the aposthophes from name since the beginning...
camc[[ismatch(r"Yung, Bosco", el) for el in camc[:CAMC_Name]], :CAMC_Name] = "Yung, Bosco H.K. \(Voyager\)"

## Reading the GND Data
gnd = readtable("A04-Composers_Corpus_GND.tsv", separator = '\t', encoding = :utf8)

rename!(gnd, :GND_Land, :GND_Country)

# Cleaning up country codes, so that they are in the same pattern as the CAMC
gnd[:GND_Country] = map(elem ->
    if typeof(elem) !== NAtype
        elem = replace(elem, r"X\D-", "")
        elem = replace(elem, r"; ", "\/")
        elem = replace(elem, r"DE-\D{2}", "DE")
        return strip(elem)
    else
        return elem
    end
    , gnd[:GND_Country])

ccode = readtable("CountryCodes.csv", separator = ';', encoding = :utf8)
ccode[154, :A2_code] = "NA" # correcting the problem that Namibia's code "NA" was interpreted as NAtype and not as string

gnd[:GND_Country] = map(elem ->
    if typeof(elem) !== NAtype
        if elem == "ZZ"
            return elem = NA
        else
            country = split(elem, '\/')
            newcountry = []
            for c in country
                newc = strip(ccode[findfirst(ccode[:A2_code], c), :A3_code])
                push!(newcountry, newc)
            end
            return elem = join(sort!(newcountry), "\/")
        end
    else
        return elem
    end
    , gnd[:GND_Country])

gnd = gnd[:, 2:9]


# Cleaning up birth and death information
function yearclean(s)
    s = replace(s, r"\[|\]|\?", "") # cleaning up info like [1540?]
    s = replace(s, r"nach|um|ca.", "") # cleaning up a few cases
    s = replace(s, r"\/\d{2}", "") # removing extra year information in formats like [1525/30]. Only the first year is kept.
    return strip(s)
end

# Removing month and day info from birth and death
gnd[:GND_Birth] = map(elem ->
    if typeof(elem) !== NAtype
        elem = yearclean(elem)
        if !ismatch(r"\d{4}\z", elem) # elem doesn't end in YYYY format
            return parse(Int64, elem[1:4]) # must be converted to Int or won't be able to compare
        else
            return parse(Int64, elem)
        end
    else
        return elem
    end
    , gnd[:GND_Birth])

gnd[:GND_Death] = map(elem ->
    if typeof(elem) !== NAtype
        elem = yearclean(elem)
        if !ismatch(r"\d{4}\z", elem) 
            return parse(Int64, elem[1:4])
        else
            return parse(Int64, elem)
        end
    else
        return elem
    end
    , gnd[:GND_Death])

 
# Joining the tables
gndc = DataFrame(by(gnd, :CAMC_Name, ct -> DataFrame(GND_Count = Int16(nrow(ct)))))
gndc = join(gndc, gnd, on = :CAMC_Name, kind = :left)
gndcamc = join(camc, gndc, on = :CAMC_Name, kind = :left)


# Defining which info, from GND or CAMC, should be taken as final
gndcamc[:Birth] = Any[NA for i in 1:nrow(gndcamc)]
gndcamc[:Death] = Any[NA for i in 1:nrow(gndcamc)]
gndcamc[:Country] = Any[NA for i in 1:nrow(gndcamc)]


for i in 1:nrow(gndcamc)

    # if either birth or death data exists in GND and they match CAMC, copy the GND data over
    if (!isna(gndcamc[i, :GND_Birth]) && isequal(gndcamc[i, :GND_Birth], gndcamc[i, :CAMC_Birth])) ||
       (!isna(gndcamc[i, :GND_Death]) && isequal(gndcamc[i, :GND_Death], gndcamc[i, :CAMC_Death]))
        gndcamc[i, :Birth] = gndcamc[i, :GND_Birth]
        gndcamc[i, :Death] = gndcamc[i, :GND_Death]
        
    elseif (isna(gndcamc[i, :CAMC_Birth])) && (isna(gndcamc[i, :CAMC_Death])) # both birth and death are missing from CAMC
        gndcamc[i, :Birth] = gndcamc[i, :GND_Birth]
        gndcamc[i, :Death] = gndcamc[i, :GND_Death]
    
    elseif (isna(gndcamc[i, :GND_Birth])) && (isna(gndcamc[i, :GND_Death])) # both birth and death are missing from GND
        gndcamc[i, :Birth] = gndcamc[i, :CAMC_Birth]
        gndcamc[i, :Death] = gndcamc[i, :CAMC_Death]
    
    else
        gndcamc[i, :Birth] = NA
        gndcamc[i, :Death] = NA
    
    end        
    
    if isna(gndcamc[i, :CAMC_Country]) # copy country info only if missing, since GND tends to cluster too many countries
                                                                 # for a single person
        gndcamc[i, :Country] = gndcamc[i, :GND_Country]
    else
        gndcamc[i, :Country] = gndcamc[i, :CAMC_Country]
    end
end

gndcamc[:, [:GND_Birth, :CAMC_Birth, :Birth, :GND_Death, :CAMC_Death, :Death, :GND_Country, :CAMC_Country, :Country]]


# In order to solve the problem of duplicate rows, it's better to split the df in two pieces, clean up the duplicates and
# then stack them again
gndcamc_u = gndcamc[gndcamc[:GND_Count] .< 2, :] # unique
gndcamc_nu = sort(gndcamc[gndcamc[:GND_Count] .>= 2, :], cols = [:GND_Count, :CAMC_Name], rev = true) # not unique

# Indexes of the registers we want to keep. Reviewed by hand and verified against totals.
indexes = [8, 15, 19, 23, 26, 28, 30, 33, 34, 36, 39, 41, 42, 45, 46, 48, 50,
    53, 54, 56, 58, 60, 62, 66, 69, 70, 72, 74, 76, 79, 80, 82, 85, 87, 88, 91, 93, 94]
gndcamc_nuc = gndcamc_nu[indexes, :]

# Manually correct "Fuchs, Christian" to GND_URI = NA since none of the found entries really match the person.
# Adding back the "Fuchs, Christian"
push!(gndcamc_nuc, @data ["Fuchs, Christian", NA, 1974, NA, 1, 2, NA, "not found", NA, NA, NA, NA, NA, 1974, NA, NA])

### Attention!
# Note that the case "Weck" (http://d-nb.info/gnd/1012790223) is problematic: since the full name wasn't provided,
# many entries matched the substring "Weck". At the same time, none of them correspond to the most probable real
# match, since the composer isn't properly marked with a "composer" occupation, although it is written down in
# node gndo:professionOrOccupationAsLiteral. Maybe a review of the initial selection of the GND with this key instead
# of the codes for componist would work better? But then we would be once more relying on strings instead of structured
# information.

## Notice that are cases of loss of information (http://d-nb.info/gnd/1089773307) due to non-standard register of information
# in format [1651/53-1703]

# Stacking the dfs back together
newcomp = [gndcamc_u; gndcamc_nuc]

# Saving in a new file
writetable("A05-CAMC_GND.csv", newcomp)

