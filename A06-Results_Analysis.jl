using DataFrames

# Analysis of the resulting of joining the CAMC and GND

newcomp = readtable("A05-CAMC_GND.csv", encoding = :utf8)


# Checking which easily recognizable composers are missing
missing = sort(newcomp, cols = [:CAMC_Birth, :CAMC_Name], rev = [false, false])
missing = missing[isna.(missing[:GND_URI]), :]

# Saving the missing ones in a dictionary for later use
missing_uri = Dict(
    # don't match any variant name
    "Tchaikovsky, Pyotr Ilich" => "http://d-nb.info/gnd/118638157", 
    "Rachmaninov, Sergey Vasilyevich" => "http://d-nb.info/gnd/118641832", 
    "Nunes García, Jose Mauricio" => "http://d-nb.info/gnd/119432714", 
    "Strauss II, Johann" => "http://d-nb.info/gnd/11861908X", 
    "Des Prez, Josquin" => "http://d-nb.info/gnd/118524895", 
    "Gomolka, Mikolaj" => "http://d-nb.info/gnd/10284190X", # no variant name with roman characters
    "Coppinus, Alexandre" => "http://d-nb.info/gnd/134694163", # variation in personal name
    "Kircher, Athanasius" => "http://d-nb.info/gnd/118562347" # not marked as composer
)

# Summing up the information
tot = nrow(newcomp) # total of entries
# presumedly still living composers (up to 70 years old) should be added back to the death field count, since they obviously
# will have a NA in that column
living = nrow(newcomp[[!isna(b) && b >= 1947 && isna(d) for (b, d) in zip(newcomp[:Birth], newcomp[:Death])], :])

comparative = DataFrame( Database = @data(["Names", "Birth", "Death", "Country"]),
                         CAMC = @data([tot, length(dropna(newcomp[:CAMC_Birth])),
                                       length(dropna(newcomp[:CAMC_Death])) + living,
                                       length(dropna(newcomp[:CAMC_Country]))]),
                         GND = @data([length(dropna(newcomp[:GND_URI])), length(dropna(newcomp[:Birth])),
                                      length(dropna(newcomp[:Death])) + living, length(dropna(newcomp[:Country]))]))

comparative[:CAMC_Perc] = [trunc(i/tot * 100, 2) for i in comparative[:CAMC]]
comparative[:GND_Perc] = [trunc(i/tot * 100, 2) for i in comparative[:GND]]
comparative[:Improvement] = map((c, g) -> trunc((g/c - 1) * 100, 2), comparative[:CAMC_Perc], comparative[:GND_Perc])
comparative[1, :Improvement] = NA
display(comparative)


# Counting how much data was validated and how much was corrected
valname = 0
valbirth = 0
valdeath = 0
valcountry = 0

for i in 1:tot
    if isequal(newcomp[i, :CAMC_Name], newcomp[i, :GND_Name]) && !isna(newcomp[i, :GND_Name])
        valname += 1
    end
    if isequal(newcomp[i, :CAMC_Birth], newcomp[i, :GND_Birth]) && !isna(newcomp[i, :GND_Birth])
        valbirth += 1
    end
    if isequal(newcomp[i, :CAMC_Death], newcomp[i, :GND_Death]) && !isna(newcomp[i, :GND_Death])
        valdeath += 1
    end
    if isequal(newcomp[i, :CAMC_Country], newcomp[i, :GND_Country]) && !isna(newcomp[i, :GND_Country])
        valcountry += 1
    end
end

val = DataFrame( Database = @data(["Names", "Birth", "Death", "Country"]),
                 GND = @data([length(dropna(newcomp[:GND_URI])), length(dropna(newcomp[:Birth])),
                              length(dropna(newcomp[:Death])) + living, length(dropna(newcomp[:Country]))]),
                 Validated = @data([valname, valbirth, valdeath + living, valcountry])
                        )
val[:Corrected] = [(a - b) for (a, b) in zip(val[:GND], val[:Validated])]
val[:Validated_Perc] = [trunc(i/tot * 100, 2) for i in val[:Validated]]
val[:Corrected_Perc] = [trunc(i/tot * 100, 2) for i in val[:Corrected]]
display(val)

# Analysing if the composers with missing information belong to a group of 20th century people
missing[:Century] = map( y ->
    trunc(((y - 1) / 100) + 1, 0)
    , missing[:Birth])
display(missing)

# Further analysing if the belong to a certain country or region
ccountry = sort(by(missing, [:Country, :Century], ct -> DataFrame(Century_Count = Int16(nrow(ct)))), cols = [:Century, :Country, :Century_Count], rev = [false, false, true])
# showall(ccountry[[(!isna(el)) & (el .> 19.0) for el in ccountry[:Century]], [2, 1, 3]])
c = sort(by(missing, :Century, ct -> DataFrame(Century_Count = Int16(nrow(ct)))), cols = [:Century, :Century_Count], rev = [false, true])
display(c)
sum(c[:Century_Count])