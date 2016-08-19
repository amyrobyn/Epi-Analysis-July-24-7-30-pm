/****************************************************
 *Amy Krystosik                  					*
 *chikv, dengue, and zika in cali, colombia       	*
 *PHD dissertation                   				*
 *last updated June 16, 2016  						*
 ***************************************************/
cd "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data"
capture log close 
log using "dissertation.smcl", text replace 
set scrollbufsize 100000
set more 1

/*********************************
 *Amy Krystosik                  *
 *chikv and dengue in cali       *
 *dissertation                   *
 *last updated April 28, 2016  *
 *********************************/
cd "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data"
capture log close 
log using "dissertation.smcl", text replace 
set scrollbufsize 100000
set more 1

*import origional datasets and merge the dengue 2014 and 2015 and chikungunya 2015 data
import excel "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\DENGUE_OCT_DIC_2014_PARA_ICESI.xls", sheet("Hoja1") firstrow clear
tostring fec_not fec_arc_xl fec_aju_, replace 
save "DENGUE_OCT_DIC_2014_PARA_ICESI.dta", replace
import excel "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\D_DG_M_CALI_2015.xls", sheet("Hoja1") firstrow clear
tostring fec_exa, replace
tostring fec_rec, replace
tostring fec_not, replace
tostring fec_arc_xl fec_aju_, replace 

append using "DENGUE_OCT_DIC_2014_PARA_ICESI.dta", generate(append20142015)
save "dengue_20142015_cali.dta", replace

insheet using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\Chik _ind2015.csv", comma clear 
tostring cod_eve, replace
tostring fec_not, replace
tostring semana, replace
tostring ao, replace
tostring cod_sub edad_ cod_pre uni_med_ cod_pais_o cod_dpto_o cod_mun_o area_ localidad_ ocupacion_ per_etn_ gp_discapa gp_desplaz gp_migrant gp_carcela gp_gestan gp_indigen  gp_pobicbf gp_mad_com gp_desmovi gp_psiquia gp_vic_vio gp_otros cod_dpto_r cod_mun_r tip_cas_ pac_hos_ , replace
drop nit_upgd 
tostring  con_fin_ cer_def_ fec_arc_xl fec_aju_ fm_fuerza fm_unidad fm_grado , replace 
append using "dengue_20142015_cali.dta", generate(chikv2015)
save "dengue_chkv_20142015_cali.dta", replace

*merge based on COD_BARRIO 
import excel "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\barrios.xls", sheet("barrios") firstrow clear
*add 9999 and 900 to barrios
set obs `=_N+1'
replace COD_BARRIO = "900 " in 339
replace NOMBRE = "FUERA DE CALI" in 339
set obs `=_N+1'
replace COD_BARRIO = "9999" in 340
replace NOMBRE = "Sin dato" in 340
save "barrios.dta", replace

use "dengue_chkv_20142015_cali.dta", clear
gen COD_BARRIO = substr(bar_ver,1,4)
gen NOMBRE = ""
replace NOMBRE = substr(bar_ver, 5, 64)
merge m:1 COD_BARRIO using "barrios.dta"
tabdisp COD_BARRIO, c(NOMBRE), if _merge==2
drop if _merge==2

save "chkvdenguebarriosmerged.dta", replace

cd "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data"
capture log close 
log using "dissertation.smcl", text replace 
set scrollbufsize 100000
set more 1
use "chkvdenguebarriosmerged.dta", clear
*keep cod_eve fec_not semana ao num_ide_ edad_ sexo_ bar_ver_ dir_res_ ocupacion_ NOMBRE ajuste_ resultado  tip_cas_ clasfinal nom_eve COD_BARRIO _merge ID_BARRIO nmun_resi ndep_resi ESTRATO_MO
sort num_ide_, stable
gen ID_CODE = _n
save "chkvdenguebarriosmerged.dta", replace

/**now add the zika data and create a second Z_ID_CODE to maintain the origional ID_CODE integrity and have a new one to match
import excel "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\d_ch_z_SEPT_2015_2016_ICESI.xls", sheet("Hoja1") firstrow clear
save "d_ch_z_SEPT_2015_2016_ICESI.dta", replace
tostring fec_not, replace
append using "chkvdenguebarriosmerged.dta"
save "dengue_zika_chkv_201420152016_cali.dta", replace

*zika id_code
sort num_ide_, stable
gen Z_ID_CODE = _n
save "dengue_zika_chkv_201420152016_cali.dta", replace

*re-run the merge on the neighborhood.
*merge based on COD_BARRIO 
merge m:1 COD_BARRIO using "barrios.dta", gen(zikabarrio)
tabdisp COD_BARRIO, c(NOMBRE), if zikabarrio==2
drop if zikabarrio==2
save "chkvdenguezikabarriosmerged.dta", replace*/

*generate dengue status as suspected = 1, confirmed = 2, or dead = 3
destring cod_eve , replace
gen dengue = .
replace dengue = 1 if cod_eve == 210 |cod_eve == 220 |cod_eve == 580
replace dengue = 0 if cod_eve == 217

replace ajuste_ = "8" if ajuste_ == "D"
destring ajuste_, generate (adjustment_num)
recast int adjustment_num, force
destring resultado, generate (resultado_num)
recast int resultado_num, force
destring tip_cas_ , generate (tip_cas_num)
recast int tip_cas_num, force
destring clasfinal, gen (classfinal_num)
recast int classfinal_num, force

gen dengue_status = . 
tab nom_eve, gen (dengue_death)

replace dengue_status = . 
replace dengue_status = 1 if tip_cas_num == 1|tip_cas_num == 2 & dengue == 1  
replace dengue_status = 2 if resultado_num == 1 & dengue == 1
replace dengue_status = 2 if tip_cas_num == 3|tip_cas_num == 4|tip_cas_num == 5 & dengue ==1
replace dengue_status = 2 if adjustment_num == 3|4|5 & dengue == 1
replace dengue_status = 2 if classfinal_num == 1|2|3|4|5|6|7 & dengue ==1
replace dengue_status = 3 if  dengue_death3 == 1 & dengue ==1

*generate chkv status as suspected = 1, confirmed = 2, or dead = 3
gen chkv_status = . 
replace chkv_status = . if dengue == 0

*replacing neighborhoods not in shapefile with nearby neighborhoods
replace COD_BARRIO = "0101" if COD_BARRIO == "0198"
replace COD_BARRIO = "1312" if COD_BARRIO == "1298"
replace COD_BARRIO = "1495" if COD_BARRIO == "1452"
replace COD_BARRIO = "1119" if COD_BARRIO == "1597"
replace COD_BARRIO = "1781" if COD_BARRIO == "1798"
replace COD_BARRIO = "1404" if COD_BARRIO == "2110"
replace COD_BARRIO = "1495" if COD_BARRIO == "5100"

list COD_BARRIO NOMBRE bar_ver_ in 1/10 if _merge == 1
rename _merge variabl_merge

*export number of cases by barrio
bysort COD_BARRIO: gen freq_COD_BARRIO = _N
tabdisp COD_BARRIO, c(freq_COD_BARRIO NOMBRE ESTRATO_MO)
export excel freq_COD_BARRIO NOMBRE COD_BARRIO using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\diseasefreq_Barrio.xls", firstrow(variables) replace

*standardize home addresses
gen manipadrsH = " "
replace dir_res_ = proper(dir_res_)
replace dir_res_ = itrim(dir_res_)
replace dir_res_ = trim(dir_res_)
replace manipadrsH = dir_res_ 
/*
gen length_manipadrsH_b = length(manipadrsH)
gsort -length_manipadrsH_b 
*/
replace NOMBRE = proper(NOMBRE)
replace NOMBRE = trim(NOMBRE)
gen drop_ = ""

foreach x in "Palmira" "Yumbo" "Hormigero" "Florida" "Jamundi" "Candelaria" "La Buitrera"{ 
replace drop_= "`x'" if regexm(manipadrsH, "`x'") ==1
replace drop_= "`x'" if regexm(NOMBRE, "`x'") ==1
}
list in 1/10 if drop_ != ""
drop if drop_ != "" 
list NOMBRE manipadrsH if regexm(NOMBRE, "Fuera De Cali")==1 
drop if regexm(NOMBRE, "Fuera De Cali")==1 

*remove all barrios names + misspellings I added "LLA# VERDE" "Felida" "Alferez Real" "Sorrento" "PORTALES DE ALAMEDA" "Portales De" "Caldas" "Lobo Guerrero" "Valle Lili" "Colserguros" "Vereda Altos Los Mangos" "Tequendama" "# Recuerda" "Capri" "Villa Del Sur" "Alto Napoles" "Alto" "Lla# Verde" "Valle Del Lili" "Golondrinas" "Floralia*"
*remove other suffixes with parse key words apt*, block*, piso*, manzana*
gen suffix = ""
split manipadrsH, parse("Esquina" "Alemeda" "Villa" "Dse" "Inv" "Conjunto" "Cristobal Colon" "Guabal" "Pance" "Sin" "No Dato" "No Sabe" "Sd" "No Se" "No Recuerda" "No Consignada" "Parques" "Oasis" "Camino" "S Arraya" "Tprres De" "1 Mayo" "Mayo" "Brisas" "St" "Meledez" "Marroquin" "Comuneros" "Por" "Bochalema" "Rep" "Cidudad" "Sna" "Cortijo" "Villas" "Cortijo" "Llsno" "San" "Nueva" "Brisasa" "Dos" "Libe" "Depar" "Aotop" "Villamercedes" "Refugio" "Agrupacion" "Comfandi" "Antonio" "El Castillo" "Republica" "Asen" "Comuneros" "Quin" "Bario" "Barrio" "Cuiudadela" "Morichal" "Ssin" "Por" "Quin" "Acen" "Centro" "Alonso" "Naples" "La" "Polvorines" "Quintas" "Portal" "Snata" "Portada" "Acentamiento" "Santa Fe" "B Gaitan" "Santa" "Nuena" "Asentamiento" "Talanga" "Alonso Lopez Ii" "Ciudadela Floralia" "Brisas de Los Alamos" "Menga" "Paso del Comercio" "Los Guaduales" "Area en desarrollo - Parque del Amor" "Urb. La Flora" "Altos de Menga" "Urb. Calimio" "San Luis II" "Sect. Puente del Comercio" "Los Alcazares" "Ciudad Los Alamos" "La Flora" "Calima" "El Bosque" "Fonaviemcali" "Metropolitano del Norte" "La Campina" "Vipasa" "San Luis" "Flora Industrial" "Villa del Sol" "Urb. La Merced" "La Paz" "Petecuy II" "Los Parques - Barranquilla" "Chiminangos II" "Olaya Herrera" "Chipichape" "Torres de Confandi" "Chiminangos I" "Petecuy III" "Evaristo Garcia" "La Isla" "Jorge Eliser Gaitan" "Prados del Norte" "La Rivera I" "Los Guayacanes" "Petecuy I" "La Alianza" "Guillermo Valencia" "Marco Fidel Suares" "Paseo de Los Almendros" "Santa Monica" "San Vicente" "Los Andes" "Ignacio Rengifo" "El Sena" "Popular" "Bolivariano" "Los Andes B - La Rivera - El Saman" "Villa del Prado - El Guabito" "Manzanares" "Unid. Residencial Bueno Madrid" "Salomia" "Sultana - Berlina" "Alfonso Lopez I" "Sect. Patio Bonito" "Santander" "Sect. Altos de Normandia - Bataclan" "Fepicol" "Fatima" "Las Delicas" "Industria de Licores" "Base Aerea" "Versalles" "Aguacatal" "Granada" "El Piloto" "Alfonso Lopez II" "Porvenir" "San Marino" "La Esmeralda" "Jorge Isaacs" "San Nicolas" "Los Pinos" "Vista Hermosa" "Las Ceibas" "El Hoyo" "Juanambu" "Parque de la Cana" "Puerto Nuevo" "Industrial" "Alfonso Lopez III" "San Pedro" "Normandia" "Terron Colorado" "Centenario" "Santa Rita" "Santa Teresita" "El Troncal" "La Merced" "Obrero" "Villacolombia" "Urb. La Base" "La Base" "Siete de Agosto" "Arboledas" "Sucre" "El Penon" "Puerto Mallarino" "Urb. El Angel del Hogar" "El Calvario" "Sect. Bosque Municipal" "Municipal" "San Antonio" "Las Americas" "Benjamin Herrera" "Planta de Tratamiento" "Santa Rosa" "Acueducto San Antonio" "Atanasio Giraldo" "Bellavista" "La Floresta" "Chapinero" "San Cayetano" "El Trebol" "San Pascual" "San Juan Bosco" "Saavedra Galindo" "Belalcazar" "Simon Bolivar" "El Nacional" "Ulpiano Lloreda" "Navarro - La chanca" "Charco Azul" "Nueva Floresta" "El Mortinal" "Santafe" "Los Libertadores" "Santa Barbara" "Lleras Restrepo II" "Guayaquil" "Bretana" "Miraflores" "Tejares - Cristales" "San Fernando Viejo" "Alameda" "Jose Manuel Marroquin II" "Rafael Uribe Uribe" "Manuel Maria Buenaventura" "Alirio Mora Beltran" "Valle Grande" "Primitivo Crespo" "Villa del Lago" "Santa Monica Polpular" "Sect. Laguna del Pondaje" "Fenalco Kennedy" "Asturias" "El Rodeo" "Santa Monica Belalcazar" "Aranjuez" "Lleras Restrepo" "El Cedro" "3 de Julio" "Ciudad Talanga" "20 de Julio" "Los Naranjos II" "El Prado" "Junin" "Alfonso Barberena A." "Ricardo Balcazar" "Sect. Altos de Santa Isabel" "Las Acaicas" "Los Naranjos" "San Cristobal" "Aguablanca" "Prados de Oriente" "Santa Isabel" "Marroquin III" "Champagnat" "Puerta del Sol" "Bello Horizonte" "Villanueva" "El Pondaje" "Urb. Colseguros" "El Paraiso" "Compartir" "Santa Elena" "Sindical" "San Fernando Nuevo" "Los Lagos" "Colseguros Andes" "Villablanca" "El Recuerdo" "Eduardo Santos" "San Benito" "Promociones Populares B" "Ciudadela del Rio" "Doce de Octubre" "Desepaz Invicali" "Belen" "El Jardin" "Julio Rincon" "Rodrigo Lara Bonilla" "Yira Castro" "Los Comuneros II" "Siloe" "La Fortaleza" "Eucaristico" "Cristobal Colon" "Leon XIII" "Los Conquistadores" "Omar Torrijos" "Jose Manuel Marroquin I" "Calipso" "San Pedro Claver" "Alfonzo Bonilla Aragon" "La Sultana" "Lleras Camargo" "Urb. Boyaca" "Manuela Beltran" "Urb. Nueva Granada" "San Carlos" "La Libertad" "Sect. Asprosocial - Diamante" "Olimpico" "Jose Maria Cordoba" "El Diamante" "Primavera" "Urb. Tequendama" "El Poblado II" "Los Robles" "El Lido" "La Gran Colombia" "El Dorado" "El Poblado I" "Los Cambulos" "Tierra Blanca" "Los Lideres" "La Esperanza" "Antonio Narino" "Departamental" "Brisas de Mayo" "El Remanso" "Pasoancho" "Los Sauces" "Maracaibo" "La Independencia" "El Vergel" "El Guabal" "Calimio Decepaz" "Mojica" "Cementerio - Carabineros" "Unid. Residencial Santiago de Cali" "El Cortijo" "Pueblo Joven" "Las Orquideas" "Nueva Tequendama" "Panamericano" "Belisario Caicedo" "Los Comuneros I" "Urb. Militar" "LLA# VERDE" "Felida" "Alferez Real" "Sorrento" "PORTALES DE ALAMEDA" "Portales De" "Caldas" "Lobo Guerrero" "Valle Lili" "Colserguros" "Vereda Altos Los Mangos" "Tequendama" "# Recuerda" "Capri" "Villa Del Sur" "Alto Napoles" "Alto" "Lla# Verde" "Valle Del Lili" "Golondrinas" "Floralia" "Melendez" "Alfonso Lopez" "Felidia" "LLA# VERDE" "Felida" "Alferez Real" "Sorrento" "PORTALES DE ALAMEDA" "Portales De" "Caldas" "Lobo Guerrero" "Valle Lili" "Colserguros" "Vereda Altos Los Mangos" "Tequendama" "# Recuerda" "Capri" "Villa Del Sur" "Alto Napoles" "Alto" "Lla# Verde" "Valle Del Lili" "Golondrinas" "Floralia" "Apt" "Apto" "Apartamento" "Casa" "Manzana" "1Er" "2Ndo" "3Er" "Piso" "Bloque" "Torre" "La Buitrera" "Ciudad Del Campo" "Sarrento" "Hacienda ElCastillo" "Sep Gbis" "Arboleda Campestre" "Via CaliJamundi" "Napoles" "12 De Octubre" "Mario Correa" "Unidad ResidenciasHorizonte" "Los Chorros" "Corregimiento" "Lourdes" "Sector Fincas" "NuevaIndependencia" "Limonar" "Antigua" "Las Palmas" "Pampas" "Primero" "Valle" "Entrada Via" "Montebello" "Prados" "Corregimiento" "El CarmeloLl" "Ciudad" "Conjunto C" "Barrio" "Miranda" "Dapa" "Vereda" "Via Cavasa" "Callejon" "Floralia" "El Vallado" "Urbanizacion" "Ap" "Torre " "Sector" "Unidad" "Aprt" "Manazana" "Coregimiento" "Ciudad" "Lote" "Fincas" "Plaza" "Invasion" "Callejon" "Estacion" "Ciudad Modelo" "La Rivera" "La Selva" "Seguros Patria" "Tejares" "Templete" "Villa Del Mar" "Villa Del Prad" "El Angel Del H" "Guadalupe" "Los Andes" "Los Samanes" "Nuevo Rey" "Pizamos Iii" "Sector  Altos" "Villa Luz" "20 De Julio" "3 De Julio" "3 Villamercedes" "Acueducto San" "Aguablanca" "Aguacatal" "Alameda" "Alferez Real" "Alfonso Barber" "Alfonso Bonill" "Alfonso Lopez" "Alirio Mora Be" "Alto Melendez" "Alto Napoles" "Altos De Menga" "Andres Sanin" "Antonio Nari•O" "Aranjuez" "Arboledas" "Asturias" "Atanasio Girar" "Bajo Cristo Re" "Bajos Ciudad C" "Barrio Obrero" "Base Aerea" "Batallon Pichi" "Belalcazar" "Belen" "Belisario Caic" "Bella Suiza" "Bellavista" "Bello Horizont" "Benjamin Herre" "Bolivariano" "Bosques Del Li" "Boyaca" "Breta•A" "Brisas De Los" "Brisas De Mayo" "Brisas Del Lim" "Bueno Madrid" "Buenos Aires" "Caldas" "Calima" "Calima - La 14" "Calimio Desepa" "Calimio Norte" "Calipso" "Camino Real -" "Caney" "Cascajal" "Ca•Averal" "Ca•Averalejo" "Ca•Averales" "Centenario" "Cerro Cristo R" "Champanagt" "Chapinero" "Charco Azul" "Chiminangos  S" "Chiminangos Pr" "Chipichape" "Cinta Belisari" "Ciudad 2000" "Ciudad Campest" "Ciudad Capri" "Ciudad Cordoba" "Ciudad Jardin" "Ciudad Los Ala" "Ciudad Talanga" "Ciudad Univers" "Ciudadela Comf" "Ciudadela Del" "Ciudadela Flor" "Club Campestre" "Colinas Del Su" "Colseguros And" "Compartir" "Corregimiento" "Cristales" "Cristobal Colo" "Cto.Los Andes" "Cto.Pance" "Cuarto De Legu" "Departamental" "Desepaz - Invi" "Doce De Octubr" "Eduardo Santos" "El  Pilar" "El Bosque" "El Calvario" "El Cedro" "El Cortijo" "El Diamante" "El Dorado" "El Gran Limona" "El Guabal" "El Guabito" "El Hormiguero" "El Hoyo" "El Ingenio" "El Jardin" "El Jordan" "El Lido" "El Limonar" "El Morichal De" "El Morti•Al" "El Nacional" "El Paraiso" "El Pe•On" "El Piloto" "El Poblado I" "El Poblado Ii" "El Pondaje" "El Prado" "El Recuerdo" "El Refugio" "El Remanso" "El Retiro" "El Rodeo" "El Sena" "El Trebol" "El Troncal" "El Vallado" "El Vergel" "Eucaristico" "Evaristo Garci" "Fatima" "Fenalco Kenned" "Fepicol" "Flora Industri" "Fonaviemcali" "Fuera De Cali" "Golondrinas" "Granada" "Gualanday" "Guayaquil" "Guillermo Vale" "Horizontes" "Ignacio Rengif" "Industria De L" "Industrial" "Inv. Brisas De" "Inv. Calibella" "Inv. Camilo To" "Inv. Las Palma" "Inv. Nueva Ilu" "Inv. Valladito" "Inv. Villa Del" "Invasion  La F" "Jorge Eliecer" "Jorge Isaacs" "Jorge Zawadsky" "Jose  Holguin" "Jose Manuel Ma" "Jose Maria Cor" "Juanambu" "Julio Rincon" "Junin" "La Alborada" "La Alianza" "La Base" "La Buitrera" "La Campi•A" "La Cascada" "La Elvira" "La Esmeralda" "La Esperanza" "La Flora" "La Floresta" "La Fortaleza" "La Gran Colomb" "La Hacienda" "La Independenc" "La Isla" "La Libertad" "La Merced" "La Paz" "La Playa" "La Reforma" "La Rivera 1" "La Selva" "Las Acacias" "Las Americas" "Las Ceibas" "Las Delicias" "Las Garzas" "Las Granjas" "Las Naranjos I" "Las Orquideas" "Las Quintas De" "Las Veraneras" "Laureano Gomez" "Leon Xiii" "Lili" "Lleras Camargo" "Lleras Restrep" "Los Alcazares" "Los Andes" "Los Cambulos" "Los Chorros" "Los Comuneros" "Los Conquistad" "Los Farallones" "Los Guaduales" "Los Guayacanes" "Los Lagos" "Los Libertador" "Los Lideres" "Los Naranjos I" "Los Parques Ba" "Los Pinos" "Los Portales" "Los Robles" "Los Sauces" "Lourdes" "Manuel Maria B" "Manuela Beltra" "Manzanares" "Maracaibo" "Marco Fidel Su" "Mariano Ramos" "Mario Correa R" "Marroquin Iii" "Mayapan Las Ve" "Melendez" "Menga" "Metropolitano" "Miraflores" "Mojica" "Montebello" "Multicentro" "Municipal" "Napoles" "Navarro" "Navarro La Cha" "Normandia" "Villa Gorgona" "Altos" "Quintas" "Barrio" "Coregimiento" "Alfonso" "Ca—Averales" "Mario Correa" "Los Geranios" "Pacara" "Conputo" "Acentamiento Brisas De Comunero" "Unidad" "Pampas Del Mirado" "Sec" "Llano Verde" "Via La Buitrera" "Quintas Don Simon" "Libertadores" "Ap" "No Sabe" "Manz" "Etapa" "Blq" "Bl" "Sin Informacion" "Conjun" "Colinas Del Sur" "Calicanto" "Jordan" "Caney" "El Portal" "Alfonso L”Pez I" "Segundo" "Buenos Aires" "Etapa" "Brisas De La Chorrera" "Sin Informacion" "Bosques Del" "Trabajo" "Sta Anita" "Ingenio" "Bella Suiza" "Brisas De Mayo" "Llano Grande" "Mariano Ramos" "Las Granjas" "Tercer" "Republica De Israel" "Atp" "Cali" "Vallado" "Esquina" "Urbanizaci”N Boyaca" "Urbanizaci”N" "Colseguros" "Col" "Laurano" "Oasis De" "2Do" "Pi" "Libertadores" "Bugalagrandes" "Uribe" "Palmeras" "Porton De Cali" "Villa Del Lago" "Jordan" "Caney" "La Caba—A" "Normania" "Sect" "Solares La Morada Et2" "Sirena Alta Los Mangos" "Sect 4 Agrup 6" "Sec 6 Agr 5" "Sardi L 165" "PJ De— Castillo Cs 12" "No Sabe" "Manzana")
list  dir_res_ manipadrsH1 manipadrsH2 if manipadrsH2!="" 
rename manipadrsH1 manipadrsH_origional
rename manipadrsH2 suffix2
rename manipadrsH3 suffix3
rename manipadrsH4 suffix4 
rename manipadrsH5 suffix5
order manipadrsH manipadrsH_origional suffix2 suffix3 suffix4 suffix5 NOMBRE dir_res_
gsort -manipadrsH_origional 
replace manipadrsH = manipadrsH_origional if suffix2!="" | manipadrsH_origional!=""
list manipadrsH manipadrsH_origional suffix2 suffix3 suffix4 suffix5 in 1/10 if suffix2!=""
drop manipadrsH_origional 

list manipadrsH  dir_res_ if regexm(manipadrsH, "Ta")==1 
list manipadrsH  NOMBRE if regexm(manipadrsH, "ta")==1 
replace manipadrsH = subinstr(manipadrsH, "Sexta", " ",. )
replace manipadrsH = subinstr(manipadrsH, "Ta", " ",. )
replace manipadrsH = subinstr(manipadrsH, "ta", " ",. )

list manipadrsH  dir_res_ if regexm(manipadrsH, "Na")==1 
list manipadrsH  NOMBRE if regexm(manipadrsH, "na")==1 
replace manipadrsH = subinstr(manipadrsH, "Na", " ",. )
replace manipadrsH = subinstr(manipadrsH, "na", " ",. )

replace manipadrsH = "" if manipadrsH == "CLinica Farallones"
replace manipadrsH = "" if manipadrsH == "El Reten"

replace manipadrsH ="999" if regexm(manipadrsH, "Sin Dato")==1 
replace manipadrsH ="999" if regexm(manipadrsH, "No Dato")==1 
replace manipadrsH ="999" if regexm(manipadrsH, "No Sabe")==1 
replace manipadrsH ="999" if regexm(manipadrsH, "Sd")==1 
replace manipadrsH ="999" if regexm(manipadrsH, "Sin Informacion")==1 
replace manipadrsH ="999" if regexm(manipadrsH, "No Se")==1 
replace manipadrsH ="999" if regexm(manipadrsH, "No Recuerda")==1 
replace manipadrsH ="999" if regexm(manipadrsH, "No Consignada")==1 
 
list manipadrsH if regexm(manipadrsH, "Sec")==1 
replace manipadrsH ="999" if regexm(manipadrsH, "Sec")==1 
gen homeless = ""
replace homeless ="1" if regexm(manipadrsH, "Habitante De La CL")==1 
replace manipadrsH ="999" if regexm(manipadrsH, "Habitante De La CL")==1 
drop if manipadrsH=="999"
drop if manipadrsH==""

rename ao year
order dir_res_ manipadrsH NOMBRE 

/*gen manipadrsH_l =length(manipadrsH) 
order manipadrsH_l
gsort -manipadrsH_l
*/

*streets dictionary 

replace manipadrsH = subinword(manipadrsH,"Cranorte"," KR Norte ",.)
replace manipadrsH = subinword(manipadrsH,"Carrrera"," KR ",.)
replace manipadrsH = subinword(manipadrsH,"Caarrea"," KR ",.)
replace manipadrsH = subinword(manipadrsH,"Karrera"," KR ",.)
replace manipadrsH = subinword(manipadrsH,"Caarrea"," KR ",.)
replace manipadrsH = subinword(manipadrsH,"Carreara"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Carerara"," K R",.)
replace manipadrsH = subinstr(manipadrsH,"Carera"," KR ",.)
replace manipadrsH = subinword(manipadrsH,"Karrera"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Carrear"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Carrera"," KR ",.)
replace manipadrsH = subinword(manipadrsH,"Carrea"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Carerra"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Cra"," KR ",.)
replace manipadrsH = subinword(manipadrsH,"Lr"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Carre"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Crr"," KR ",.)
replace manipadrsH = subinword(manipadrsH,"Lra"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Cara"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Carr"," KR ",.)
replace manipadrsH = subinword(manipadrsH,"Cra"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Cr"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Crra"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Crra"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Kra"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Crr"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Car"," KR ",.)
replace manipadrsH = subinword(manipadrsH,"Vr"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Cr"," KR ",.)

replace manipadrsH = subinword(manipadrsH,"Caller#","CL #",.)
replace manipadrsH = subinword(manipadrsH,"Call E","CL",.)
replace manipadrsH = subinstr(manipadrsH,"Calle","CL",.)
replace manipadrsH = subinword(manipadrsH,"Clle","CL",.)
replace manipadrsH = subinword(manipadrsH,"Cll","CL",.)
replace manipadrsH = subinword(manipadrsH,"Cale","CL",.)
replace manipadrsH = subinword(manipadrsH,"Cal","CL",.)
replace manipadrsH = subinword(manipadrsH,"Call","CL",.)
replace manipadrsH = subinword(manipadrsH,"Cll E","CL",.)
replace manipadrsH = subinword(manipadrsH,"Xcll E","CL",.)
replace manipadrsH = subinword(manipadrsH,"Xcalle","CL",.)
replace manipadrsH = subinword(manipadrsH,"Xalle","CL",.)
replace manipadrsH = subinword(manipadrsH,"Cl","CL",.)

replace manipadrsH = subinword(manipadrsH,"Pasaje","PJ",.)
replace manipadrsH = subinword(manipadrsH,"Pasajes","PJ",.)
replace manipadrsH = subinword(manipadrsH,"Pas","PJ",.)
replace manipadrsH = subinword(manipadrsH,"Paisaje","PJ",.)

replace manipadrsH = subinword(manipadrsH,"Transversal","TV",.)
replace manipadrsH = subinword(manipadrsH,"Tran","TV",.)
replace manipadrsH = subinword(manipadrsH,"Tb","TV",.)
replace manipadrsH = subinword(manipadrsH,"Trasversal","TV",.)
replace manipadrsH = subinword(manipadrsH,"Trasv","TV",.)
replace manipadrsH = subinword(manipadrsH,"Transversal","TV",.)
replace manipadrsH = subinword(manipadrsH,"Trasnv","TV",.)
replace manipadrsH = subinword(manipadrsH,"Trv","TV",.)
replace manipadrsH = subinword(manipadrsH,"Trav","TV",.)
replace manipadrsH = subinword(manipadrsH,"Trsv","TV",.)
replace manipadrsH = subinword(manipadrsH,"Trn","TV",.)
replace manipadrsH = subinword(manipadrsH,"Trv","TV",.)
replace manipadrsH = subinword(manipadrsH,"Trasnversal","TV",.)
replace manipadrsH = subinword(manipadrsH,"Tasnv","TV",.)
replace manipadrsH = subinword(manipadrsH,"Trasn","TV",.)
replace manipadrsH = subinword(manipadrsH,"Tras","TV",.)
replace manipadrsH = subinword(manipadrsH,"Tranvesal","TV",.)
replace manipadrsH = subinword(manipadrsH,"Tranv","TV",.)
replace manipadrsH = subinword(manipadrsH,"Tranversal","TV",.)
replace manipadrsH = subinword(manipadrsH,"Trans","TV",.)
replace manipadrsH = subinword(manipadrsH,"Tr","TV",.)
replace manipadrsH = subinword(manipadrsH,"Tra","TV",.)
replace manipadrsH = subinword(manipadrsH,"Traaversal","TV",.)
replace manipadrsH = subinword(manipadrsH,"Tans","TV",.)
replace manipadrsH = subinword(manipadrsH,"Transv","TV",.)
replace manipadrsH = subinword(manipadrsH,"Trasv","TV",.)
replace manipadrsH = subinword(manipadrsH,"Trav","TV",.)

replace manipadrsH = subinword(manipadrsH,"Diagnonal"," DG ",.)
replace manipadrsH = subinword(manipadrsH,"Diagonal"," DG ",.)
replace manipadrsH = subinword(manipadrsH,"Diagonal"," DG ",.)
replace manipadrsH = subinword(manipadrsH,"Diganoal","DG",.)
replace manipadrsH = subinword(manipadrsH,"Diag","DG",.)
replace manipadrsH = subinword(manipadrsH,"Diga"," DG ",.)
replace manipadrsH = subinword(manipadrsH,"Dig"," DG ",.)
replace manipadrsH = subinword(manipadrsH,"Dg","DG",.)

replace manipadrsH = subinword(manipadrsH,"Conjuto","Conjunto",.)
replace manipadrsH = subinword(manipadrsH,"Conjuto","Conjunto",.)

replace manipadrsH = subinword(manipadrsH,"1 Era","1",.)
replace manipadrsH = subinword(manipadrsH,"-Calle","Cl",.)
replace manipadrsH = subinword(manipadrsH,"2 E pa"," ",.)


*deal with this one later. it is causing problems in other words. i can use a regular expression to find times when "No" comes by itself. 
*replace manipadrsH = subinword(manipadrsH,"No","#",.)
replace manipadrsH = subinword(manipadrsH,"N∫"," # ",.)
replace manipadrsH = subinword(manipadrsH,"Nuemro"," # ",.)
replace manipadrsH = subinword(manipadrsH,"Numero#"," # ",.)
replace manipadrsH = subinword(manipadrsH,"Numero"," # ",.)
replace manipadrsH = subinword(manipadrsH,"No"," # ",.)

replace manipadrsH = subinword(manipadrsH,"Avenida","AV",.)
replace manipadrsH = subinword(manipadrsH,"Ae","AV",.)
replace manipadrsH = subinword(manipadrsH,"Av","Avenida",.)
replace manipadrsH = subinword(manipadrsH,"Avenida","AV",.)
replace manipadrsH = subinword(manipadrsH,"Aveniida","AV",.)
replace manipadrsH = subinword(manipadrsH,"Ave","AV",.)
replace manipadrsH = subinstr(manipadrsH,"Avendad","AV",.)

replace manipadrsH = subinstr(manipadrsH,"--","-",.)
replace manipadrsH = subinstr(manipadrsH,"--","-",.)
replace manipadrsH = subinstr(manipadrsH,"- -","-",.)
replace manipadrsH = subinstr(manipadrsH,"ñ", "-", .)

replace manipadrsH = subinword(manipadrsH,"Mz","Manzana",.)
replace manipadrsH = subinword(manipadrsH,"Mn","Manzana",.)
replace manipadrsH = subinword(manipadrsH,"Manz","Manzana",.)
replace manipadrsH = subinword(manipadrsH,"Manza","Manzana",.)
replace manipadrsH = subinword(manipadrsH,"Mansana","Manzana",.)

*remove other suffixes with parse key words apt*, block*, piso*, manzana*
split manipadrsH, parse("Apt" "Conjunto" "Cristobal Colon" "Guabal" "Pance" "Sin" "No Dato" "No Sabe" "Sd" "No Se" "No Recuerda" "No Consignada" "Parques" "Oasis" "Camino" "S Arraya" "Tprres De" "1 Mayo" "Mayo" "Brisas" "St" "Meledez" "Marroquin" "Comuneros" "Por" "Bochalema" "Rep" "Cidudad" "Sna" "Cortijo" "Villas" "Cortijo" "Llsno" "San" "Nueva" "Brisasa" "Dos" "Libe" "Depar" "Aotop" "Villamercedes" "Refugio" "Agrupacion" "Comfandi" "Antonio" "El Castillo" "Republica" "Asen" "Comuneros" "Quin" "Bario" "Barrio" "Cuiudadela" "Morichal" "Ssin" "Por" "Quin" "Acen" "Centro" "Alonso" "Naples" "La" "Polvorines" "Quintas" "Portal" "Snata" "Portada" "Acentamiento" "Santa Fe" "B Gaitan" "Santa" "Nuena" "Asentamiento" "Talanga" "Alonso Lopez Ii" "Ciudadela Floralia" "Brisas de Los Alamos" "Menga" "Paso del Comercio" "Los Guaduales" "Area en desarrollo - Parque del Amor" "Urb. La Flora" "Altos de Menga" "Urb. Calimio" "San Luis II" "Sect. Puente del Comercio" "Los Alcazares" "Ciudad Los Alamos" "La Flora" "Calima" "El Bosque" "Fonaviemcali" "Metropolitano del Norte" "La Campina" "Vipasa" "San Luis" "Flora Industrial" "Villa del Sol" "Urb. La Merced" "La Paz" "Petecuy II" "Los Parques - Barranquilla" "Chiminangos II" "Olaya Herrera" "Chipichape" "Torres de Confandi" "Chiminangos I" "Petecuy III" "Evaristo Garcia" "La Isla" "Jorge Eliser Gaitan" "Prados del Norte" "La Rivera I" "Los Guayacanes" "Petecuy I" "La Alianza" "Guillermo Valencia" "Marco Fidel Suares" "Paseo de Los Almendros" "Santa Monica" "San Vicente" "Los Andes" "Ignacio Rengifo" "El Sena" "Popular" "Bolivariano" "Los Andes B - La Rivera - El Saman" "Villa del Prado - El Guabito" "Manzanares" "Unid. Residencial Bueno Madrid" "Salomia" "Sultana - Berlina" "Alfonso Lopez I" "Sect. Patio Bonito" "Santander" "Sect. Altos de Normandia - Bataclan" "Fepicol" "Fatima" "Las Delicas" "Industria de Licores" "Base Aerea" "Versalles" "Aguacatal" "Granada" "El Piloto" "Alfonso Lopez II" "Porvenir" "San Marino" "La Esmeralda" "Jorge Isaacs" "San Nicolas" "Los Pinos" "Vista Hermosa" "Las Ceibas" "El Hoyo" "Juanambu" "Parque de la Cana" "Puerto Nuevo" "Industrial" "Alfonso Lopez III" "San Pedro" "Normandia" "Terron Colorado" "Centenario" "Santa Rita" "Santa Teresita" "El Troncal" "La Merced" "Obrero" "Villacolombia" "Urb. La Base" "La Base" "Siete de Agosto" "Arboledas" "Sucre" "El Penon" "Puerto Mallarino" "Urb. El Angel del Hogar" "El Calvario" "Sect. Bosque Municipal" "Municipal" "San Antonio" "Las Americas" "Benjamin Herrera" "Planta de Tratamiento" "Santa Rosa" "Acueducto San Antonio" "Atanasio Giraldo" "Bellavista" "La Floresta" "Chapinero" "San Cayetano" "El Trebol" "San Pascual" "San Juan Bosco" "Saavedra Galindo" "Belalcazar" "Simon Bolivar" "El Nacional" "Ulpiano Lloreda" "Navarro - La chanca" "Charco Azul" "Nueva Floresta" "El Mortinal" "Santafe" "Los Libertadores" "Santa Barbara" "Lleras Restrepo II" "Guayaquil" "Bretana" "Miraflores" "Tejares - Cristales" "San Fernando Viejo" "Alameda" "Jose Manuel Marroquin II" "Rafael Uribe Uribe" "Manuel Maria Buenaventura" "Alirio Mora Beltran" "Valle Grande" "Primitivo Crespo" "Villa del Lago" "Santa Monica Polpular" "Sect. Laguna del Pondaje" "Fenalco Kennedy" "Asturias" "El Rodeo" "Santa Monica Belalcazar" "Aranjuez" "Lleras Restrepo" "El Cedro" "3 de Julio" "Ciudad Talanga" "20 de Julio" "Los Naranjos II" "El Prado" "Junin" "Alfonso Barberena A." "Ricardo Balcazar" "Sect. Altos de Santa Isabel" "Las Acaicas" "Los Naranjos" "San Cristobal" "Aguablanca" "Prados de Oriente" "Santa Isabel" "Marroquin III" "Champagnat" "Puerta del Sol" "Bello Horizonte" "Villanueva" "El Pondaje" "Urb. Colseguros" "El Paraiso" "Compartir" "Santa Elena" "Sindical" "San Fernando Nuevo" "Los Lagos" "Colseguros Andes" "Villablanca" "El Recuerdo" "Eduardo Santos" "San Benito" "Promociones Populares B" "Ciudadela del Rio" "Doce de Octubre" "Desepaz Invicali" "Belen" "El Jardin" "Julio Rincon" "Rodrigo Lara Bonilla" "Yira Castro" "Los Comuneros II" "Siloe" "La Fortaleza" "Eucaristico" "Cristobal Colon" "Leon XIII" "Los Conquistadores" "Omar Torrijos" "Jose Manuel Marroquin I" "Calipso" "San Pedro Claver" "Alfonzo Bonilla Aragon" "La Sultana" "Lleras Camargo" "Urb. Boyaca" "Manuela Beltran" "Urb. Nueva Granada" "San Carlos" "La Libertad" "Sect. Asprosocial - Diamante" "Olimpico" "Jose Maria Cordoba" "El Diamante" "Primavera" "Urb. Tequendama" "El Poblado II" "Los Robles" "El Lido" "La Gran Colombia" "El Dorado" "El Poblado I" "Los Cambulos" "Tierra Blanca" "Los Lideres" "La Esperanza" "Antonio Narino" "Departamental" "Brisas de Mayo" "El Remanso" "Pasoancho" "Los Sauces" "Maracaibo" "La Independencia" "El Vergel" "El Guabal" "Calimio Decepaz" "Mojica" "Cementerio - Carabineros" "Unid. Residencial Santiago de Cali" "El Cortijo" "Pueblo Joven" "Las Orquideas" "Nueva Tequendama" "Panamericano" "Belisario Caicedo" "Los Comuneros I" "Urb. Militar" "LLA# VERDE" "Felida" "Alferez Real" "Sorrento" "PORTALES DE ALAMEDA" "Portales De" "Caldas" "Lobo Guerrero" "Valle Lili" "Colserguros" "Vereda Altos Los Mangos" "Tequendama" "# Recuerda" "Capri" "Villa Del Sur" "Alto Napoles" "Alto" "Lla# Verde" "Valle Del Lili" "Golondrinas" "Floralia" "Melendez" "Alfonso Lopez" "Felidia" "LLA# VERDE" "Felida" "Alferez Real" "Sorrento" "PORTALES DE ALAMEDA" "Portales De" "Caldas" "Lobo Guerrero" "Valle Lili" "Colserguros" "Vereda Altos Los Mangos" "Tequendama" "# Recuerda" "Capri" "Villa Del Sur" "Alto Napoles" "Alto" "Lla# Verde" "Valle Del Lili" "Golondrinas" "Floralia" "Apt" "Apto" "Apartamento" "Casa" "Manzana" "1Er" "2Ndo" "3Er" "Piso" "Bloque" "Torre" "La Buitrera" "Ciudad Del Campo" "Sarrento" "Hacienda ElCastillo" "Sep Gbis" "Arboleda Campestre" "Via CaliJamundi" "Napoles" "12 De Octubre" "Mario Correa" "Unidad ResidenciasHorizonte" "Los Chorros" "Corregimiento" "Lourdes" "Sector Fincas" "NuevaIndependencia" "Limonar" "Antigua" "Las Palmas" "Pampas" "Primero" "Valle" "Entrada Via" "Montebello" "Prados" "Corregimiento" "El CarmeloLl" "Ciudad" "Conjunto C" "Barrio" "Miranda" "Dapa" "Vereda" "Via Cavasa" "Callejon" "Floralia" "El Vallado" "Urbanizacion" "Ap" "Torre " "Sector" "Unidad" "Aprt" "Manazana" "Coregimiento" "Ciudad" "Lote" "Fincas" "Plaza" "Invasion" "Callejon" "Estacion" "Ciudad Modelo" "La Rivera" "La Selva" "Seguros Patria" "Tejares" "Templete" "Villa Del Mar" "Villa Del Prad" "El Angel Del H" "Guadalupe" "Los Andes" "Los Samanes" "Nuevo Rey" "Pizamos Iii" "Sector  Altos" "Villa Luz" "20 De Julio" "3 De Julio" "3 Villamercedes" "Acueducto San" "Aguablanca" "Aguacatal" "Alameda" "Alferez Real" "Alfonso Barber" "Alfonso Bonill" "Alfonso Lopez" "Alirio Mora Be" "Alto Melendez" "Alto Napoles" "Altos De Menga" "Andres Sanin" "Antonio Nari•O" "Aranjuez" "Arboledas" "Asturias" "Atanasio Girar" "Bajo Cristo Re" "Bajos Ciudad C" "Barrio Obrero" "Base Aerea" "Batallon Pichi" "Belalcazar" "Belen" "Belisario Caic" "Bella Suiza" "Bellavista" "Bello Horizont" "Benjamin Herre" "Bolivariano" "Bosques Del Li" "Boyaca" "Breta•A" "Brisas De Los" "Brisas De Mayo" "Brisas Del Lim" "Bueno Madrid" "Buenos Aires" "Caldas" "Calima" "Calima - La 14" "Calimio Desepa" "Calimio Norte" "Calipso" "Camino Real -" "Caney" "Cascajal" "Ca•Averal" "Ca•Averalejo" "Ca•Averales" "Centenario" "Cerro Cristo R" "Champanagt" "Chapinero" "Charco Azul" "Chiminangos  S" "Chiminangos Pr" "Chipichape" "Cinta Belisari" "Ciudad 2000" "Ciudad Campest" "Ciudad Capri" "Ciudad Cordoba" "Ciudad Jardin" "Ciudad Los Ala" "Ciudad Talanga" "Ciudad Univers" "Ciudadela Comf" "Ciudadela Del" "Ciudadela Flor" "Club Campestre" "Colinas Del Su" "Colseguros And" "Compartir" "Corregimiento" "Cristales" "Cristobal Colo" "Cto.Los Andes" "Cto.Pance" "Cuarto De Legu" "Departamental" "Desepaz - Invi" "Doce De Octubr" "Eduardo Santos" "El  Pilar" "El Bosque" "El Calvario" "El Cedro" "El Cortijo" "El Diamante" "El Dorado" "El Gran Limona" "El Guabal" "El Guabito" "El Hormiguero" "El Hoyo" "El Ingenio" "El Jardin" "El Jordan" "El Lido" "El Limonar" "El Morichal De" "El Morti•Al" "El Nacional" "El Paraiso" "El Pe•On" "El Piloto" "El Poblado I" "El Poblado Ii" "El Pondaje" "El Prado" "El Recuerdo" "El Refugio" "El Remanso" "El Retiro" "El Rodeo" "El Sena" "El Trebol" "El Troncal" "El Vallado" "El Vergel" "Eucaristico" "Evaristo Garci" "Fatima" "Fenalco Kenned" "Fepicol" "Flora Industri" "Fonaviemcali" "Fuera De Cali" "Golondrinas" "Granada" "Gualanday" "Guayaquil" "Guillermo Vale" "Horizontes" "Ignacio Rengif" "Industria De L" "Industrial" "Inv. Brisas De" "Inv. Calibella" "Inv. Camilo To" "Inv. Las Palma" "Inv. Nueva Ilu" "Inv. Valladito" "Inv. Villa Del" "Invasion  La F" "Jorge Eliecer" "Jorge Isaacs" "Jorge Zawadsky" "Jose  Holguin" "Jose Manuel Ma" "Jose Maria Cor" "Juanambu" "Julio Rincon" "Junin" "La Alborada" "La Alianza" "La Base" "La Buitrera" "La Campi•A" "La Cascada" "La Elvira" "La Esmeralda" "La Esperanza" "La Flora" "La Floresta" "La Fortaleza" "La Gran Colomb" "La Hacienda" "La Independenc" "La Isla" "La Libertad" "La Merced" "La Paz" "La Playa" "La Reforma" "La Rivera 1" "La Selva" "Las Acacias" "Las Americas" "Las Ceibas" "Las Delicias" "Las Garzas" "Las Granjas" "Las Naranjos I" "Las Orquideas" "Las Quintas De" "Las Veraneras" "Laureano Gomez" "Leon Xiii" "Lili" "Lleras Camargo" "Lleras Restrep" "Los Alcazares" "Los Andes" "Los Cambulos" "Los Chorros" "Los Comuneros" "Los Conquistad" "Los Farallones" "Los Guaduales" "Los Guayacanes" "Los Lagos" "Los Libertador" "Los Lideres" "Los Naranjos I" "Los Parques Ba" "Los Pinos" "Los Portales" "Los Robles" "Los Sauces" "Lourdes" "Manuel Maria B" "Manuela Beltra" "Manzanares" "Maracaibo" "Marco Fidel Su" "Mariano Ramos" "Mario Correa R" "Marroquin Iii" "Mayapan Las Ve" "Melendez" "Menga" "Metropolitano" "Miraflores" "Mojica" "Montebello" "Multicentro" "Municipal" "Napoles" "Navarro" "Navarro La Cha" "Normandia" "Villa Gorgona" "Altos" "Quintas" "Barrio" "Coregimiento" "Alfonso" "Ca—Averales" "Mario Correa" "Los Geranios" "Pacara" "Conputo" "Acentamiento Brisas De Comunero" "Unidad" "Pampas Del Mirado" "Sec" "Llano Verde" "Via La Buitrera" "Quintas Don Simon" "Libertadores" "Ap" "No Sabe" "Manz" "Etapa" "Blq" "Bl" "Sin Informacion" "Conjun" "Colinas Del Sur" "Calicanto" "Jordan" "Caney" "El Portal" "Alfonso L”Pez I" "Segundo" "Buenos Aires" "Etapa" "Brisas De La Chorrera" "Sin Informacion" "Bosques Del" "Trabajo" "Sta Anita" "Ingenio" "Bella Suiza" "Brisas De Mayo" "Llano Grande" "Mariano Ramos" "Las Granjas" "Tercer" "Republica De Israel" "Atp" "Cali" "Vallado" "Esquina" "Urbanizaci”N Boyaca" "Urbanizaci”N" "Colseguros" "Col" "Laurano" "Oasis De" "2Do" "Pi" "Libertadores" "Bugalagrandes" "Uribe" "Palmeras" "Porton De Cali" "Villa Del Lago" "Jordan" "Caney" "La Caba—A" "Normania" "Sect" "Solares La Morada Et2" "Sirena Alta Los Mangos" "Sect 4 Agrup 6" "Sec 6 Agr 5" "Sardi L 165" "PJ De— Castillo Cs 12" "No Sabe" "Manzana")
list  dir_res_ manipadrsH1 manipadrsH2 if manipadrsH2!="" 
rename manipadrsH1 manipadrsH_origional
rename manipadrsH2 suffix2b
order manipadrsH manipadrsH_origional suffix2b NOMBRE dir_res_
gsort -manipadrsH_origional 
replace manipadrsH = manipadrsH_origional if suffix2b!="" | manipadrsH_origional!=""
list manipadrsH manipadrsH_origional suffix2b in 1/10 if suffix2b!=""
drop manipadrsH_origional 


replace manipadrsH = subinword(manipadrsH,"Ktr","Carratera",.)

 
replace manipadrsH = subinword(manipadrsH,"Kilometro","KM",.)
replace manipadrsH = subinword(manipadrsH,"Ke","KM",.)

replace manipadrsH = subinword(manipadrsH,"Inv","Invasion",.)
replace manipadrsH = subinword(manipadrsH,"Invacion","Invasion",.)
replace manipadrsH = subinword(manipadrsH,"Con","-",.)

replace manipadrsH = subinword(manipadrsH,"Oeste N ","Oeste #",.)
replace manipadrsH = subinword(manipadrsH,"Oes N ","Oeste #",.)
replace manipadrsH = subinword(manipadrsH,"Oest N ","Oeste #",.)
replace manipadrsH = subinword(manipadrsH,"O N ","Oeste #",.)


replace manipadrsH = subinstr(manipadrsH, "Xcll", "Cl",. )
replace manipadrsH = subinstr(manipadrsH, "Union De Vivienda", "",. )
replace manipadrsH = subinstr(manipadrsH, "DIAGNONAL", "Dg",. )
replace manipadrsH = subinstr(manipadrsH, "Poblado Campestre", "",. )
replace manipadrsH = subinstr(manipadrsH, "con", " # ",. )
replace manipadrsH = subinstr(manipadrsH, "Cada", "CL",. )
replace manipadrsH = subinstr(manipadrsH, "Kcra", "KR",. )
replace manipadrsH = subinstr(manipadrsH, "via al mar", "Av 4 Oeste",. )
replace manipadrsH = subinstr(manipadrsH, "DIAGNONAL", "dg",. )
replace manipadrsH = subinstr(manipadrsH, "}", " # ",. )
replace manipadrsH = subinstr(manipadrsH, "Diagonal", "Dg",. )
replace manipadrsH = subinstr(manipadrsH, "Diagonal", "Dg",. )
replace manipadrsH = subinstr(manipadrsH, "Diagona", "Dg",. )
replace manipadrsH = subinstr(manipadrsH, "Diagon", "Dg",. )
replace manipadrsH = subinstr(manipadrsH, "1∫", "1",. )
replace manipadrsH = subinstr(manipadrsH, "1Ra", "1",. )
replace manipadrsH = subinstr(manipadrsH, "Diagon", "Dg",. )
replace manipadrsH = subinstr(manipadrsH, "Diago", "Dg",. )
replace manipadrsH = subinstr(manipadrsH, "DGna", "Dg",. )
replace manipadrsH = subinstr(manipadrsH, "Scarrera", "KR",. )


/*replace manipadrsH = subinstr(manipadrsH, "KR MANZANA", "KR M", .)
replace manipadrsH = subinstr(manipadrsH, "CL MANZANA", "Cl M", .)
replace manipadrsH = subinstr(manipadrsH, "AV MANZANA", "Av M", .)
replace manipadrsH = subinstr(manipadrsH, "TV MANZANA", "Tv M", .)
replace manipadrsH = subinstr(manipadrsH, "PJ MANZANA", "Pj M", .)*/



*remove those without any numbers in manipadrsH
list dir_res_ if regexm(manipadrsH, "[0-9]+")==0 
drop if regexm(manipadrsH, "[0-9]+")==0 
list dir_res_ if regexm(manipadrsH, "[ a-zA-Z ]+")==0 
drop if regexm(manipadrsH, "[ a-zA-Z ]+")==0 
drop if regexm(manipadrsH, "9999")==1 
drop if regexm(manipadrsH, "Sd")==1 
drop if regexm(manipadrsH, "No Dato")==1 

*Km is a rural address outside of cali. remove from observations
list dir_res_ if regexm(manipadrsH, "Km")==1 
drop if regexm(manipadrsH, "Km")==1 
list dir_res_ if regexm(manipadrsH, "KM")==1 
drop if regexm(manipadrsH, "KM")==1 
list dir_res_ if regexm(manipadrsH, "km")==1 
drop if regexm(manipadrsH, "km")==1 

*change common street names to numbers
replace manipadrsH = subinstr(manipadrsH, "Avenida Las Americas", "Av 3 Norte",. )
replace manipadrsH = subinstr(manipadrsH, "Las Americas", "Av 3 Norte",. )
replace manipadrsH = subinstr(manipadrsH, "Americas", "Av 3 Norte",. )
replace manipadrsH = subinstr(manipadrsH, "America", "Av 3 Norte",. )
replace manipadrsH = subinstr(manipadrsH, "AV Americas", "Av 3 Norte",. )

list manipadrsH dir_res_ if regexm(manipadrsH, "Los Libertadores")==1 
list manipadrsH dir_res_ if regexm(manipadrsH, "Libertadores")==1 
list manipadrsH dir_res_ if regexm(manipadrsH, "El Simon Bolivar")==1 
list manipadrsH dir_res_ if regexm(manipadrsH, "Simon Bolivar")==1 
list manipadrsH dir_res_ if regexm(manipadrsH, "La Roosevelt")==1 
list manipadrsH dir_res_ if regexm(manipadrsH, "El Roosevelt")==1 
list manipadrsH dir_res_ if regexm(manipadrsH, "Roosevelt")==1 
list manipadrsH dir_res_ if regexm(manipadrsH, "La Quinta")==1 
list manipadrsH dir_res_ if regexm(manipadrsH, "Quinta")==1 
list manipadrsH dir_res_ if regexm(manipadrsH, "La Novena")==1 
list manipadrsH dir_res_ if regexm(manipadrsH, "Novena")==1 
list manipadrsH dir_res_ if regexm(manipadrsH, "La Pasoancho")==1 
list manipadrsH dir_res_ if regexm(manipadrsH, "Pasoancho")==1 
list manipadrsH dir_res_ if regexm(manipadrsH, "La Carolina")==1 
list manipadrsH dir_res_ if regexm(manipadrsH, "Carolina")==1 


list manipadrsH  dir_res_ if regexm(manipadrsH, "No Saber")==1 
list manipadrsH  dir_res_ if regexm(manipadrsH, "No Sabe")==1 
list manipadrsH  dir_res_ if regexm(manipadrsH, "NS")==1 
list manipadrsH  dir_res_ if regexm(manipadrsH, "Ns")==1 
list manipadrsH  dir_res_ if regexm(manipadrsH, "Sin Informacion")==1 
list manipadrsH  dir_res_ if regexm(manipadrsH, "No Informacion")==1 
list manipadrsH  dir_res_ if regexm(manipadrsH, "Sin Dato")==1 
list manipadrsH  dir_res_ if regexm(manipadrsH, "SD")==1 

list manipadrsH  dir_res_ if regexm(manipadrsH, "∑")==1 
replace manipadrsH = subinstr(manipadrsH, "∑", " # ",. )

list manipadrsH  dir_res_ if regexm(manipadrsH, "]")==1 
replace manipadrsH = subinstr(manipadrsH, "]", " # ",. )

replace manipadrsH = subinstr(manipadrsH, "5 Ta", " 5 ",. )
replace manipadrsH = subinstr(manipadrsH, "5Ta", " 5 ",. )
replace manipadrsH = subinstr(manipadrsH, "Sexta", " 6 ",. )
replace manipadrsH = subinstr(manipadrsH, "Portada De Comfandi", "  ",. )
replace manipadrsH = subinstr(manipadrsH, "Alle", " Cl ",. )
replace manipadrsH = subinstr(manipadrsH, "N∞", " # ",. )
replace manipadrsH = subinstr(manipadrsH, "Diagnoal", " DG ",. )
replace manipadrsH = subinstr(manipadrsH, "Acenida", " AV ",. )
replace manipadrsH = subinstr(manipadrsH, "Avenidad", " AV ",. )
replace manipadrsH = subinstr(manipadrsH, "A Venidad", " AV ",. )
replace manipadrsH = subinstr(manipadrsH, "Ato", " Apt ",. )
replace manipadrsH = subinstr(manipadrsH, "Jarillon De Lopez", " ",. )
replace manipadrsH = subinstr(manipadrsH, "ø", " ",. )


/*exports to excel
*export suspected dengue- none
*export confirmed dengue
export excel using "dengue_confirmed.xls" if dengue_status == 2|3, sheet("dengue_confirmed") sheetreplace firstrow(variables)
*export dengue deaths
export excel using "dengue_death.xls" if dengue_status == 3, sheet("dengue_deaths") sheetreplace firstrow(variables)
*export full data set
export excel using "all_dengue.xls", sheet("dengue_all") sheetreplace firstrow(variables)
*/

/**export test google api 100
export excel using "testgoogleapi100" in 1/100, firstrow(variables) replace
*import google refine data
import excel "all_dengue_googlerefine_nov 14.xls", sheet("all_dengue xls") firstrow clear
drop ID_BARRIO ini_sin_ control fec_rec muestra prueba agente resultado resultado_num fec_exp valor cod_pre cod_sub tip_ide_ edad_ uni_med_ sexo_ cod_pais_o cod_dpto_o cod_mun_o area_ localidad_ cen_pobla_ vereda_ bar_ver_ ocupacion_ tip_ss_ cod_ase_ per_etn_ gp_discapa gp_desplaz gp_migrant gp_carcela gp_gestan gp_indigen gp_pobicbf gp_mad_com gp_desmovi gp_psiquia gp_vic_vio gp_otros cod_dpto_r cod_mun_r fec_con_ tip_cas_ tip_cas_num pac_hos_ fec_hos_ con_fin_ fec_def_ ajuste_ adjustment_num telefono_ fecha_nto_ cer_def_ cbmte_ nuni_modif fec_arc_xl nom_dil_f_ tel_dil_f_ fec_aju_ nit_upgd fm_fuerza fm_unidad fm_grado desplazami cod_mun_d famantdngu direclabor fiebre cefalea dolrretroo malgias artralgia erupcionr dolor_abdo vomito diarrea somnolenci hipotensio hepatomeg hem_mucosa hipotermia caida_plaq acum_liqui aum_hemato extravasac hemorr_hem choque dao_organ muesttejid mueshigado muesbazo muespulmon muescerebr muesmiocar muesmedula muesrion clasfinal classfinal_num conducta nom_upgd ndep_proce nmun_proce  nmun_notif ndep_notif nreg append20142015 COD_BARRIO COD_COMUNA AREA PERIMETRO ESTRATO_MO ACUERDO LIMITES variabl_merge direccion_work
*/



*remake the address variable with updated addreses 
gen country = "Colombia"
egen address_complete = concat(manipadrsH NOMBRE nmun_resi ndep_resi country), punct(, " ")
order address_complete 
replace address_complete  = proper(address_complete)
order num_ide_ ID_CODE address_complete manipadrsH NOMBRE ID_BARRIO nom_eve fec_not semana year

*export back to google api for geocoding
*ëhttps://maps.google.com/maps/api/geocode/json?key= AIzaSyAKegm2d1GFwrycpXosp3CovJ_jng50a0k&sensor=false&address=í+ escape(value, ëurlí)
*3rd attempt succesfull: 


/*geocode using mapquest
geocodeopen,  key("SiJaN36FLhrzDlMbvEV6LgaArtTR6fF2")  fulladdr( address_complete)   
writekml, filename(kmlout_mapquest) plcategory(nom_eve) pldesc(address_complete)
rename latitude latitude_mq
rename longitude longitude_mq

*geocode using google api
geocode3, address(address_complete)
rename g_lat latitude
rename g_lon longitude
writekml, filename(kmlout_google) plcategory(nom_eve) pldesc(address_complete)

*next step in arcgis 10.3- project lat/long
*/
*import shortened excel files from arcgis from openrefine
*import excel "all_dengue_googlerefine_nov-16C_short.xls", sheet("all_dengue_googlerefine_nov 14B") firstrow clear
*save all_dengue_googlerefine_nov-16_C.dta, replace 

*creating regular expressions and subexpresions
*create regular expression to parse the words after the numbers that are not a single letter. 
*e.g. KR 1 a 120 b O 17 ciudad jardin = KR 1a 120b O 17
*e.g. KR 1 a 120 b O 17 ciudad jardin apto 4 manzana 4 = KR 1a 120b O 17

/*
gen clipped_homeaddress = gen home_address_cali  firstpart minus words at end of expression
replace clipped_homeaddress = gen home_address_cali  first part minus words at begining of expression that are not KR or CL or PJ or TV or DG. */

*create expression to put together numbers and letters that are not "N" or "O" 
*e.g. KR 1 a 120 b O 17 = KR 1a 120b O 17
*number always goes with number after it
*remove space between number and following single letters that are not "O"s or "N"s or E's

replace manipadrsH = "." if manipadrsH == "999" 

*split stndadrsH into various variables number of segments seperated by length. 
*split manipadrsH, parse(" ")

*local numbers "0 1 2 3 4 5 6 7 8 9" 
*local streets "Kr Cl Av Pj Tv Dg"
/*foreach number in "0" "1" "2" "3" "4" "5" "6" "7" "8" "9" {
	foreach street in "Kr" "Cl" "Av" "Pj" "Tv" "Dg"{
		display("`street'`number'")
	}
}
foreach number in "0" "1" "2" "3" "4" "5" "6" "7" "8" "9" {
	foreach street in "Kr" "Cl" "Av" "Pj" "Tv" "Dg"{
		display("`street' `number'")
	}
}*/

*cleaning
replace manipadrsH = subinword(manipadrsH,"#"," # ",.)

replace manipadrsH = subinword(manipadrsH,"Kr"," KR ",.)
replace manipadrsH = subinstr(manipadrsH, "Cl", " CL ",.)
replace manipadrsH = subinstr(manipadrsH, "Av", " AV ",.)
replace manipadrsH = subinstr(manipadrsH, "Pj", " PJ ",.)
replace manipadrsH = subinstr(manipadrsH, "Tv", " TV ",.)
replace manipadrsH = subinstr(manipadrsH, "Dg", " DG ",.)

replace manipadrsH = subinword(manipadrsH,"kr"," KR ",.)
replace manipadrsH = subinstr(manipadrsH, "cl", " CL ",.)
replace manipadrsH = subinstr(manipadrsH, "av", " AV ",.)
replace manipadrsH = subinstr(manipadrsH, "pj", " PJ ",.)
replace manipadrsH = subinstr(manipadrsH, "tv", " TV ",.)
replace manipadrsH = subinstr(manipadrsH, "dg", " DG ",.)

replace manipadrsH = trim(manipadrsH)
replace manipadrsH = itrim(manipadrsH)


foreach number in "0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "-" {
	foreach street in "KR" "CL" "AV" "PJ" "TV" "DG"{
		replace manipadrsH = subinstr(manipadrsH, ("`street'`number'"), "`street' `number'", .)
	}
}
/*foreach n in "([ 0-9]*)"{
	foreach x in "Kr"`n' "Cl"`n' "Av"`n' "Pj"`n' "Tv"`n' "Dg"`n'{
	replace manipadrsH = subinstr(manipadrsH, "`x'", "#", .)
	}
}
foreach x in "Kr[ 0-9]*" "Cl`n'" "Av`n'" "Pj`n'" "Tv`n'" "Dg`n'"{
	replace manipadrsH = subinstr(manipadrsH, "`x'", "#", .)
	}*/

*remove second street keyword
*"Kr" = dog "Cl" = cat "Av" = bird "Pj" = fish "Tv" = hat "Dg" = doug
replace manipadrsH = subinword(manipadrsH,"KR","dog",1)
replace manipadrsH = subinstr(manipadrsH, "CL", "cat",1)
replace manipadrsH = subinstr(manipadrsH, "AV", "bird",1)
replace manipadrsH = subinstr(manipadrsH, "PJ", "fish",1)
replace manipadrsH = subinstr(manipadrsH, "TV", "hat",1)
replace manipadrsH = subinstr(manipadrsH, "DG", "doug",1)

foreach x in "KR" "Cl" "AV" "PJ" "TV" "DG"{
	replace manipadrsH = subinstr(manipadrsH, "`x'", " # ", .)
	}
*"Kr" = dog "Cl" = cat "Av" = bird "Pj" = fish "Tv" = hat "Dg" = doug
replace manipadrsH = subinstr(manipadrsH, "dog", "KR", .)
replace manipadrsH = subinstr(manipadrsH, "cat", "CL", .)
replace manipadrsH = subinstr(manipadrsH, "bird", "AV", .)
replace manipadrsH = subinstr(manipadrsH, "fish", "PJ", .)
replace manipadrsH = subinstr(manipadrsH, "hat", "TV", .)
replace manipadrsH = subinstr(manipadrsH, "doug", "DG", .)

*split into with or without # sign
replace manipadrsH = subinstr(manipadrsH, "s #Rmania","", .)
replace manipadrsH = subinstr(manipadrsH, "Transv","Tv", .)
replace manipadrsH = subinstr(manipadrsH, "Bue#S Aires","", .)
replace manipadrsH = subinstr(manipadrsH, "9#Rte","9N", .)
replace manipadrsH = subinstr(manipadrsH, "Cra#Rte  # 72 - A  - 20","KR 72A N #20", .)
replace manipadrsH = subinstr(manipadrsH, "# Recueda","", .)
replace manipadrsH = subinstr(manipadrsH, "Diga#Al 49 O # 13 ‚Äì 26","Dg 49 O # 13 - 26", .)
replace manipadrsH = subinstr(manipadrsH, "Cl 4#Rte #2An-26","Cl 4 N # 2An - 26", .)
replace manipadrsH = subinstr(manipadrsH, "Av 5 #Re # 44N-65","Av 5 N # 44N - 65", .)
replace manipadrsH = subinstr(manipadrsH, "Diag#Al 26G 7 # Tv 72 T - 53","Dg 26G7 # 72T - 53", .)
replace manipadrsH = subinstr(manipadrsH, "Kr 26 N # Diag#Al 28 B- 20", "KR 26 N # 28B - 20", .)
replace manipadrsH = trim(manipadrsH) 
foreach x in "KR" "CL" "AV" "PJ" "TV" "DG"{
replace manipadrsH = subinstr(manipadrsH, "`x'", strupper("`x'"), .)
}

*I have to treat each second pound differently. 
*use regular expressions to identify those which are street # or street# from other
* for each x in "Kr" "Av" "Pj" "Dg" "Tv"
*if `x['0-9]*[#]" then `x'[0-9]*[]"

*replace all other second "#" with with "-"
*# = pound
replace manipadrsH = subinword(manipadrsH,"#","pound",1)
replace manipadrsH = subinstr(manipadrsH, "#", " - ", .)
replace manipadrsH = subinstr(manipadrsH, "pound", " # ", .)

save temp.dta, replace

*From HERE
/*********************************
 *Amy Krystosik                  *
 *chikv and dengue in cali       *
 *dissertation                   *
 *last updated December 1, 2015  *
 *********************************/

cd "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data"
capture log close 
log using "dissertation_fromHERE.smcl", text replace 
set scrollbufsize 100000
set more 1
use temp.dta, clear
sort ID_CODE
order ID_CODE


*those without "#"
gen nopound = ""
replace nopound = manipadrsH if strpos(manipadrsH, "#")==0
order nopound dir_res manipadrsH NOMBRE
gsort -nopound 

*consider the "Bis" in the cleaning here too
replace manipadrsH = subinstr(manipadrsH, "Biss", " Bis ", .)
replace manipadrsH = subinstr(manipadrsH, "bis", " Bis ", .)
replace manipadrsH = subinstr(manipadrsH, "Bos", " Bis ", .)
replace manipadrsH = subinstr(manipadrsH, "bos", " Bis ", .)
replace manipadrsH = trim(manipadrsH)
replace manipadrsH = itrim(manipadrsH)
split manipadrsH, parse("Bis")
rename manipadrsH manipadrsH_origional
order manipadrsH_origional manipadrsH1 manipadrsH2 manipadrsH3
gsort -manipadrsH2
replace manipadrsH_origional = trim(manipadrsH1) + " Bis " + trim(manipadrsH2) if manipadrsH2!=""
replace manipadrsH_origional = trim(manipadrsH1) + " Bis " + trim(manipadrsH2)+ " Bis " + trim(manipadrsH3) if manipadrsH3!=""
drop manipadrsH1 manipadrsH2 manipadrsH3
rename manipadrsH_origional manipadrsH 
replace manipadrsH = trim(manipadrsH)
replace manipadrsH = itrim(manipadrsH)

split manipadrsH, parse("-")
rename manipadrsH manipadrsH_origional
order manipadrsH_origional manipadrsH1 manipadrsH2 manipadrsH3 manipadrsH4
gsort -manipadrsH2
replace manipadrsH_origional = trim(manipadrsH1) + " - " + trim(manipadrsH2) if manipadrsH2!=""
replace manipadrsH_origional = trim(manipadrsH1) + " - " + trim(manipadrsH2)+ " - " + trim(manipadrsH3) if manipadrsH3!=""
replace manipadrsH_origional = trim(manipadrsH1) + " - " + trim(manipadrsH2)+ " - " + trim(manipadrsH3)+ " - " + trim(manipadrsH4) if manipadrsH4!=""
drop manipadrsH1 manipadrsH2 manipadrsH3 manipadrsH4
rename manipadrsH_origional manipadrsH 
replace manipadrsH  = trim(manipadrsH)
replace manipadrsH  = itrim(manipadrsH)


*sort based on number of [ ] in string nopound so we can select better the before and after pound variables
replace nopound = trim(nopound)
replace nopound = itrim(nopound)
replace nopound = subinstr(nopound, "-", " - ", .)
foreach street in "KR" "CL" "AV" "PJ" "TV" "DG"{
	display("`street'")
	replace nopound = subinstr(nopound, "`street'", " `street' ", .)
}
replace nopound = trim(nopound)
replace nopound = itrim(nopound)

moss nopound, match(" ")
foreach number in "1" "2" "3" "4" "5" "6" "7" "8" "9" "10"{
	gen nopound`number' = nopound if _count==`number'
}

**take a break to eat. when i get back, i can use each category to do next step given below. 
**add a "#" for those in nopound
*select part that should come before the pound so we can put a pound at the end. 
*drop beforepound_np 
replace nopound = trim(nopound)
replace nopound = itrim(nopound)

foreach number in "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" {
	gen beforepound_np`number'= ""
}
*select part that should come after the pound so we can put reconstruct nopound. 
foreach number in "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" {
	gen afterpound_np`number'= ""
}
*now select using regex based on number of spaces
*np1
replace beforepound_np1= regexs(0) if regexm(nopound1, "^[a-zA-Z]+[ ]?[0-9]*[ ]?[a-zA-Z]*")==1 & nopound1!=""
replace afterpound_np1 = regexs(0) if regexm(nopound1, "[0-9]*$")==1 & nopound1!=""
drop if strpos(nopound1, "Km")!=0 
drop if strpos(nopound1, "KM")!=0 
list beforepound_np1 afterpound_np1 manipadrsH if nopound1!=""
*np1 has problems. i have to clean manipadrsH  better first. 

*np2
replace beforepound_np2= regexs(0) if regexm(nopound2, "^[a-zA-Z]+[ ]?[0-9]*[ ]?[a-zA-Z]*")==1 & nopound2!=""
replace afterpound_np2 = regexs(0) if regexm(nopound2, "[0-9]+[a-zA-Z]*[ ]?[-]?[ ]?[0-9]*[ ]?[a-zA-Z]*$")==1 & nopound2!="" 
drop if strpos(nopound2, "Km")!=0 
drop if strpos(nopound2, "KM")!=0 
list beforepound_np2 afterpound_np2 manipadrsH if nopound2!=""
*this one  has problems too. maybe i will have to seperate by size and then select multiple before and after pounds. 

*np3
replace beforepound_np3= regexs(0) if regexm(nopound3, "^[a-zA-Z]+[ ]?[0-9]*[ ]?[a-zA-Z]*[ ]?[a-zA-Z]*")==1 & nopound3!=""
replace afterpound_np3 = regexs(0) if regexm(nopound3, "[0-9]+[ ]?[a-zA-Z]*[-]?[ ]?[0-9]*$")==1 & nopound3!="" 
list beforepound_np3 afterpound_np3 manipadrsH if nopound3!=""

*np4
replace beforepound_np4= regexs(0) if regexm(nopound4, "^[a-zA-Z]+[ ]?[0-9]*[ ]?[a-zA-Z]*[ ]?[a-zA-Z]*")==1 & nopound4!=""
replace afterpound_np4 = regexs(0) if regexm(nopound4, "[0-9]+[a-zA-Z]*[ ]?[-]?[ ]?[0-9]*[ ]?[a-zA-Z]*[ ]?[0-9]*$")==1 & nopound4!=""
list beforepound_np4 afterpound_np4 manipadrsH if nopound4!=""

*np5
replace beforepound_np5= regexs(0) if regexm(nopound5, "^[a-zA-Z]+[ ]?[0-9]*[ ]?[a-zA-Z]*[ ]?[a-zA-Z]*")==1 & nopound5!=""
replace afterpound_np5 = regexs(0) if regexm(nopound5, "[0-9]+[a-zA-Z]*[ ]?[-]?[ ]?[0-9]*[ ]?[a-zA-Z]*[ ]?[0-9]*$")==1 & nopound5!=""
list beforepound_np5 afterpound_np5 manipadrsH if nopound5!=""

*np6
replace beforepound_np6= regexs(0) if regexm(nopound6, "^[a-zA-Z]+[ ]?[0-9]*[ ]?[a-zA-Z]*[ ]?[a-zA-Z]*")==1 & nopound6!=""
replace afterpound_np6 = regexs(0) if regexm(nopound6, "[0-9]+[a-zA-Z]*[ ]?[-]?[ ]?[0-9]*[ ]?[a-zA-Z]*[ ]?[0-9]*$")==1 & nopound6!="" 
list beforepound_np6 afterpound_np6 manipadrsH if nopound6!=""

*np7
replace beforepound_np7= regexs(0) if regexm(nopound7, "^[a-zA-Z]+[ ]?[0-9]*[ ]?[a-zA-Z]*[ ]?[a-zA-Z]*")==1  & nopound7!=""
replace afterpound_np7 = regexs(0) if regexm(nopound7, "[0-9]+[a-zA-Z]*[ ]?[-]?[ ]?[0-9]*[ ]?[a-zA-Z]*[ ]?[0-9]*$")==1  & nopound7!=""
list beforepound_np7 afterpound_np7 manipadrsH if nopound7!=""

*np8
replace beforepound_np8= regexs(0) if regexm(nopound8, "^[a-zA-Z]+[ ]?[0-9]*[ ]?[a-zA-Z]*[ ]?[a-zA-Z]*")==1 & nopound8!=""
replace afterpound_np8 = regexs(0) if regexm(nopound8, "[0-9]+[a-zA-Z]*[ ]?[-]?[ ]?[0-9]*[ ]?[a-zA-Z]*[ ]?[0-9]*$")==1 & nopound8!="" 
list beforepound_np8 afterpound_np8 manipadrsH if nopound8!=""

*np9
replace beforepound_np9= regexs(0) if regexm(nopound9, "^[a-zA-Z]+[ ]?[0-9]*[ ]?[a-zA-Z]*[ ]?[a-zA-Z]*")==1 & nopound9!=""
replace afterpound_np9 = regexs(0) if regexm(nopound9, "[0-9]+[a-zA-Z]*[ ]?[-]?[ ]?[0-9]*[ ]?[a-zA-Z]*[ ]?[0-9]*$")==1 & nopound9!="" 
list beforepound_np9 afterpound_np9 manipadrsH if nopound9!=""

*np10
list nopound nopound10 dir_res_ if nopound10!=""
replace beforepound_np10 = regexs(0) if regexm(nopound, "^[a-zA-Z]+[0-9]*[a-zA-Z]*")==1 & nopound10!="" 
replace afterpound_np10 = regexs(0) if regexm(nopound, "[0-9]+[a-zA-Z]*[ ]?[-]?[ ]?[0-9]*[ ]?[a-zA-Z]*[ ]?[0-9]*$")==1 & nopound10!=""
list beforepound_np10  afterpound_np10  nopound nopound10 dir_res_ if nopound10!=""

foreach number in "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" {
	order beforepound_np`number' 
	gsort -beforepound_np`number'
	order beforepound_np`number' afterpound_np`number'
	replace nopound`number'= beforepound_np`number'+" # " + afterpound_np`number' if nopound`number'!=""
	replace nopound = nopound`number' if nopound`number'!=""
	drop nopound`number' beforepound_np`number' afterpound_np`number'
}
order nopound manipadrsH dir_res_
replace manipadrsH = nopound if nopound!="" 
drop nopound 



*those with "#"
gen pound = ""
replace pound = manipadrsH if strpos(manipadrsH, "#")!=0
split pound, parse(pound, "#")
replace pound1=trim(pound1)
replace pound1=itrim(pound1)
replace pound2=itrim(pound2)
replace pound2=trim(pound2)
gen first_homeaddressP= "."
replace first_homeaddressP = pound1
gen last_homeaddressP= "."
replace last_homeaddressP= pound2

*standardize the pound2

*from here for the bis to put insdie the parse. 
*clean the bis 
*drop pound2bis 
gen pound2bis=""
*replace pound2spacenodash = pound2 if regexm(pound2, "[0-9]+[a-zA-Z]*[ ][0-9]+")==1
replace pound2 = proper(pound2)
replace pound2 = subinstr(pound2, "Biss", "Bis", .)
replace pound2 = subinstr(pound2, "bis", "Bis", .)
replace manipadrsH = subinstr(manipadrsH, "Bos", "Bis", .)
replace manipadrsH = subinstr(manipadrsH, "bos", "Bis", .)

replace pound2bis= pound2 if strpos(pound2, "Bis")!=0
replace pound2bis= pound2 if strpos(pound2, "bis")!=0

*find instances with Bis and suffix of oeste, norte, or este
*drop bissuffix 
gen bissuffix=""
replace bissuffix= regexs(0) if regexm(pound2bis, "Bis Oe|Bis Oeste|Bis Norte|Bis N|Bis No|Bis Este|Bis E")==1
order bissuffix pound2bis
gsort -bissuffix
*drop these suffixes
replace pound2bis = subinstr(pound2bis, "Bis Oe", "Bis", .)
replace pound2bis = subinstr(pound2bis, "Bis N", "Bis", .)
*add this bissuffix back later when i reconstruct the bis. 

*nuisance characters to remove. 
replace pound2bis= subinstr(pound2bis, "s De", "", .)

order pound2bis
gsort -pound2bis
split pound2bis, parse(Bis)
rename pound2bis pound2bis_origional
order pound2bis_origional pound2bis1 pound2bis2 pound2 dir_res_ 
gsort -pound2bis_origional

*for each side of the bis, run the " "parse

*from here pound2bis1 
*from here for the parse on space section. to use on each side of the bis
*select pound2 cases with "[0-9] [a-Z]"
*drop pound2bis1space
gen pound2bis1space=""
order pound2bis1space pound2bis1 pound2
replace pound2bis1 = itrim(pound2bis1)
replace pound2bis1 = trim(pound2bis1)
*
replace pound2bis1space=regexs(0) if regexm(trim(pound2bis1), "[0-9]*[ ][a-d]?[A-D]?[f-m]?[F-M]?[p-z]?[P-Z]?")==1
*this one is excluded because it has an extra DG. This DG is a mistake and shoudl be dealt with later. "pound2bis1 = DG 72 E"
replace pound2bis1space= trim(pound2bis1space)
replace pound2bis1space= itrim(pound2bis1space)
gsort -pound2bis1space
*parse on " " those with "[0-9] [a-Z]"
split pound2bis1space, parse(" ") 
replace pound2bis1space= trim(pound2bis1space1) 
replace pound2bis1space= itrim(pound2bis1space1) 
replace pound2bis1space= trim(pound2bis1space2) 
replace pound2bis1space= itrim(pound2bis1space2) 
order pound2bis1space pound2bis1space1 pound2bis1space2
gsort -pound2bis1space1
rename pound2bis1space pound2bis1space_origional 
replace pound2bis1space_origional = pound2bis1space1+pound2bis1space2 if pound2bis1space_origional !=""

*gen pound2bis1spacebeforedash = pound2bis1space_origional if pound2bis1space_origional !=""
*drop  pound2bis1space1 pound2bis1space2
rename pound2bis1space_origional pound2bis1space
*to here. 
*to here pound2bis1

*add the dashes on either side of the bis if pound2bis1space!=""
gsort - pound2bis1space 
replace pound2bis1space = subinstr(trim(pound2bis1space), " ", "-", .) if pound2bis1space!=""
replace pound2bis1space= subinstr(trim(pound2bis1space), "--", "-", .) if pound2bis1space!=""
replace pound2bis1space = subinstr(trim(pound2bis1space), "---", "-", .) if pound2bis1space!=""
replace pound2bis1 = pound2bis1space if pound2bis1space!=""
order pound2bis_origional pound2bis1 
gsort -pound2bis_origional  
drop pound2bis1space pound2bis1space1 pound2bis1space2
*to here


*from here pound2bis2
*from here for the parse on space section. to use on each side of the bis
*select pound2 cases with "[0-9] [a-Z]"
*drop pound2bis2space
*select those with a space
gen pound2bis2space=""
order pound2bis2space pound2bis2 pound2
replace pound2bis2 = itrim(pound2bis2)
replace pound2bis2 = trim(pound2bis2)
replace pound2bis2space=regexs(0) if regexm(trim(pound2bis2), "[ - ]*[ 0-9]*[ - ]*[ 0-9]*[ ]*[a-d]?[A-D]?[f-m]?[F-M]?[p-z]?[P-Z]?[-]?[ 0-9 ]*")==1
gsort -pound2bis2space
replace pound2bis2space= trim(pound2bis2space)
replace pound2bis2space= itrim(pound2bis2space)
gsort -pound2bis2space
*parse on " "|"-" those with "[0-9] [a-Z]"
split pound2bis2space, parse(" " "-" " -" "- "" - ") 
rename pound2bis2space pound2bis2space_origional 
order pound2bis2space_origional pound2bis2space1 pound2bis2space2 
replace pound2bis2space1 = trim(pound2bis2space1) if pound2bis2space1 !=""
replace pound2bis2space1 = itrim(pound2bis2space1) if pound2bis2space1 !="" 
replace pound2bis2space2 = trim(pound2bis2space2) if pound2bis2space2 !=""
replace pound2bis2space2 = itrim(pound2bis2space2) if pound2bis2space2 !="" 
*replace pound2bis2space3 = trim(pound2bis2space3) if pound2bis2space3 !=""
*replace pound2bis2space3 = itrim(pound2bis2space3) if pound2bis2space3 !="" 
replace pound2bis2space_origional = " - " + pound2bis2space1 if pound2bis2space1!=""
replace pound2bis2space_origional = " - " + pound2bis2space1 + " - " + pound2bis2space2 if pound2bis2space1!="" & pound2bis2space2!=""
*replace pound2bis2space_origional = " - " + pound2bis2space1 + " - " + pound2bis2space2 + " - " + pound2bis2space3 if pound2bis2space1!="" & pound2bis2space2!="" & pound2bis2space3!=""
*replace pound2bis2space_origional = " - " + pound2bis2space1 + " - " + pound2bis2space2 + " - " + pound2bis2space3 + " - " + pound2bis2space4 if pound2bis2space1!="" & pound2bis2space2!="" & pound2bis2space3!="" & pound2bis2space4!=""
rename pound2bis2space_origional pound2bis2space
drop pound2bis2space1  - pound2bis2space2 
replace pound2bis2space = itrim(pound2bis2space)
replace pound2bis2space = trim(pound2bis2space)
replace pound2bis2space= subinstr(trim(pound2bis2space), "---", " - ", .) if pound2bis2space!=""
replace pound2bis2space= subinstr(trim(pound2bis2space), "--", " - ", .) if pound2bis2space!=""
replace pound2bis2space= subinstr(trim(pound2bis2space), "- -", " - ", .) if pound2bis2space!=""
replace pound2bis2space= subinstr(trim(pound2bis2space), "-", " - ", .) if pound2bis2space!=""
replace pound2bis2space= itrim(pound2bis2space)
replace pound2bis2space= trim(pound2bis2space)
order pound2bis2space pound2bis2 
gsort -pound2bis2space

/**select those with Oe|Oeste|O
drop pound2bis2spaceoeste 
gen pound2bis2spaceoeste=""
replace pound2bis2 = itrim(pound2bis2)
replace pound2bis2 = trim(pound2bis2)
order pound2bis2spaceoeste pound2bis2 pound2
replace pound2bis2spaceoeste= pound2bis2 if strpos(pound2bis2, "O")!=0
replace pound2bis2spaceoeste= pound2bis2 if strpos(pound2bis2, "Oe")!=0
replace pound2bis2spaceoeste= pound2bis2 if strpos(pound2bis2, "Oeste")!=0
replace pound2bis2spaceoeste= pound2bis2 if strpos(pound2bis2, "Norte")!=0
replace pound2bis2spaceoeste= pound2bis2 if strpos(pound2bis2, "N")!=0
replace pound2bis2spaceoeste= pound2bis2 if strpos(pound2bis2, "E")!=0
order pound2bis2spaceoeste
gsort -pound2bis2spaceoeste
drop pound2bis2spaceoeste
*there are none. good. I don't have to do anythign else with this variable. */
*to here. 
*to here pound2bis2

*add the dashes on either side of the bis if pound2bis1space!=""
*to here
replace pound2bis2 = pound2bis2space if pound2bis2space!=""
drop pound2bis2space
*reconstruct the variable pound2bis
replace pound2bis_origional=  pound2bis1 + " Bis " + pound2bis2 if pound2bis_origional!=""
*add this bissuffix back later when i reconstruct the bis. 
replace pound2bis_origional=  pound2bis1 + " Bis " + bissuffix + pound2bis2 if pound2bis_origional!="" & bissuffix !=""
rename pound2bis_origional pound2bis 
drop pound2bis1 pound2bis2
order pound2bis pound2 dir_res_ 
gsort -pound2bis 
replace pound2 = pound2bis if pound2bis!=""
 
*
order last_homeaddressP pound2
gsort -pound2
replace last_homeaddressP = pound2 if pound2!=""

*standardize pound1, first part if has #
*First step, standardize the "Bis" so I can parse on "Bis"
*drop pound1bis 
gen pound1bis=""	
order pound1bis
replace pound1bis= pound1 if strpos(pound1, "Bis")!=0
replace pound1bis= pound1 if strpos(pound1, "bis")!=0
replace pound1bis= pound1 if strpos(pound1, "BIS")!=0
replace pound1bis = subinstr(pound1bis, "bis", "Bis", .)
replace pound1bis= subinstr(pound1bis, "bis", "Bis", .)
replace pound1bis= subinstr(pound1bis, "BIS", "Bis", .)
replace pound1bis= subinstr(pound1bis, "bIS", "Bis", .)
replace pound1bis= subinstr(pound1bis, "BIs", "Bis", .)
replace pound1bis= subinstr(pound1bis, "bIs", "Bis", .)
replace pound1bis = subinstr(pound1bis, "biS", "Bis", .)
replace pound1bis = subinstr(pound1bis, "Bist", "Bis", .)
*those with "Bis" in the peice before pound, parse on "Bis"
split pound1bis, parse(Bis)
rename pound1bis pound1bis_origional
order pound1bis_origional pound1bis1 pound1bis2 pound1 dir_res_ 
gsort -pound1bis1
*drop pound1space
replace pound1bis1=trim(pound1bis1)
*here we are making a second variable for the peice before the pound before the bis so we can find those with [0-9][ ][a-zA-Z]. 
*first we will remove the first section by using a parse and reconstructing it without the first peice (KR, CL...).
gen pound1bis1space = pound1bis1 if pound1bis1!=""
order pound1bis1 
gsort - pound1bis1 
split pound1bis1space, parse("")
rename pound1bis1space pound1bis1space_origional
order pound1bis1space_origional dir_res_
gsort -pound1bis1space_origional   
*here we reconstruct pound1bis1space_origional wihtout the KR|CL... 
replace pound1bis1space_origional = pound1bis1space2 + " " + pound1bis1space3 + " " + pound1bis1space4 + " " + pound1bis1space5

*drop pound1bis1spaceB
*here we create a second variable where we search for those pound1bis1space_origional with [0-9][ ][a-zA-Z].  
gen pound1bis1spaceB = ""
order pound1bis1spaceB 
replace pound1bis1spaceB= regexs(0) if regexm(trim(pound1bis1space_origional), "[0-9]+[ ][a-zA-Z]*[ ]?[a-zA-Z]*[0-9]?[-]?")==1
*remove the "-" here and repalce with " "
replace pound1bis1spaceB = subinstr(itrim(pound1bis1spaceB), "-", " ", .) if pound1bis1spaceB !=""
*here we parse on " " those those pound1bis1space_origional with [0-9][ ][][a-zA-Z].  
replace pound1bis1spaceB = itrim(pound1bis1spaceB)
split pound1bis1spaceB, parse(" ")
rename pound1bis1spaceB pound1bis1spaceB_origional 
*here we reconstruct those those pound1bis1space_origional with [0-9][ ][][a-zA-Z] so that [0-9][a-zA-Z]
replace pound1bis1space_origional = pound1bis1space1 + " " + pound1bis1spaceB1 + pound1bis1spaceB2+ pound1bis1spaceB3 if pound1bis1spaceB_origional !=""
replace pound1bis1space_origional = subinstr(pound1bis1space_origional, "KR 7MaPJ","KR 7Map",.) 
gsort -pound1bis1space_origional 
replace pound1bis1space_origional = pound1bis1space1 +" "+ pound1bis1space2 + " " + pound1bis1space3 + " " + pound1bis1space4 + " " + pound1bis1space5 if pound1bis1spaceB_origional ==""
drop pound1bis1space1 - pound1bis1space5 
drop pound1bis1spaceB1 - pound1bis1spaceB3 
drop pound1bis1spaceB_origional
rename pound1bis1space_origional pound1bis1space
replace pound1bis1space = trim(pound1bis1space)
order pound1bis1 pound1bis1space 
*pound1bis1space will be the first part of pound 1 before the bis
replace pound1bis1 = pound1bis1space if pound1bis1space !=""
drop pound1bis1space 

*now put the before and after bis together
order pound1bis_origional  pound1bis1 pound1bis2 
gsort -pound1bis2 
replace pound1bis_origional = trim(pound1bis1) + " Bis " + trim(pound1bis2) if pound1bis_origional !=""
order pound1bis_origional pound1   
gsort -pound1bis_origional
replace pound1 = pound1bis_origional if pound1bis_origional!=""
drop pound1bis1 pound1bis2 

*now deal with those without bis: if pound1bis_origional!=""
*drop pound1space_origional 
gen pound1space = pound1
split pound1space, parse(" ")
rename pound1space pound1space_origional 
*in this step we remove the KR|CL so we can select without it. we will add it back later to the pound1space_origional + pound1space1
replace pound1space_origional = pound1space2 + " " + pound1space3 + " " + pound1space4 + " " + pound1space5 + " " + pound1space6
drop pound1space2-pound1space6  
*drop pound1space_origionalB 
gen pound1space_origionalB =""
replace pound1space_origional = trim(pound1space_origional)
replace pound1space_origional = itrim(pound1space_origional)
replace pound1space_origionalB=pound1space_origional if regexm(trim(pound1space_origional), "[0-9]+[ ]+[a-d]?[A-D]?[f-m]?[F-M]?[p-z]?[P-Z]?[ 0-9]*")==1 & pound1bis_origional==""
order pound1space_origional pound1space_origionalB dir_res_
*parse those with "[0-9][ ][a-Z]"
replace pound1space_origionalB= trim(pound1space_origionalB)
split pound1space_origionalB, parse(" ") 
rename pound1space_origionalB pound1space_origionalB_A
*put the peices back together without space
replace pound1space_origionalB_A= pound1space_origionalB1+pound1space_origionalB2+pound1space_origionalB3+pound1space_origionalB4+pound1space_origionalB5 if pound1space_origionalB_A!=""
*replace pound1 with  pound1space_origionalB_A + pound1space1 for street 
replace pound1 = pound1space1 + " " + pound1space_origionalB_A  if pound1space_origionalB_A !=""
order pound1 pound1space_origionalB_A pound1space_origionalB1 pound1space_origionalB2 
gsort -pound1space_origionalB_A


/*
*select last two numbers and add a hyphen and cut two hyphens into two
gen lasttwo = "."
replace lasttwo = last_homeaddressP 
*turn over the last homeaddress and select the first two

replace lasttwo = split(last_homeaddressP), parse(" ") 
*/

*reconstruct manipadrsHP from first_homeaddressP last_homeaddressP
gen manipadrsHP="."
replace first_homeaddressP = trim(first_homeaddressP)
replace last_homeaddressP = trim(last_homeaddressP)
replace manipadrsHP = trim(first_homeaddressP + " # " + last_homeaddressP)
replace manipadrsHP = subinstr(manipadrsHP, "--", " - ", .)
replace manipadrsHP = subinstr(manipadrsHP, "- -", " - ", .)
replace manipadrsHP = subinstr(manipadrsHP, "-", " - ", .)
replace manipadrsHP = trim(manipadrsHP)
replace manipadrsHP = itrim(manipadrsHP)
order dir_res_ manipadrsHP last_homeaddressP
gsort -pound

*consider the "Bis" in the cleaning here too
replace manipadrsHP = subinstr(manipadrsHP, "Biss", " Bis ", .)
replace manipadrsHP = subinstr(manipadrsHP, "bis", " Bis ", .)
replace manipadrsHP = subinstr(manipadrsHP, "Bos", " Bis ", .)
replace manipadrsHP = subinstr(manipadrsHP, "bos", " Bis ", .)
replace manipadrsHP = trim(manipadrsHP)
replace manipadrsHP = itrim(manipadrsHP)

/*
split manipadrsHP, parse("Bis")
rename manipadrsHP manipadrsHP_origional
replace manipadrsHP_origional = trim(manipadrsHP1) + " Bis " + trim(manipadrsHP2) if manipadrsH2!=""
replace manipadrsH_origional = trim(manipadrsH1) + " Bis " + trim(manipadrsH2)+ " Bis " + trim(manipadrsH3) if manipadrsH3!=""
drop manipadrsH1 manipadrsH2 manipadrsH3
rename manipadrsH_origional manipadrsH 
replace manipadrsH = trim(manipadrsH)
replace manipadrsH = itrim(manipadrsH)
*/


list manipadrsHP dir_res_ if regexm(manipadrsHP , "Ta")==1 
list manipadrsHP NOMBRE if regexm(manipadrsHP , "ta")==1 
replace manipadrsHP  = subinstr(manipadrsHP , "Ta", " ",. )
replace manipadrsHP = subinstr(manipadrsHP , "ta", " ",. )

list manipadrsHP dir_res_ if regexm(manipadrsHP , "Na")==1 
list manipadrsHP NOMBRE if regexm(manipadrsHP , "na")==1 
replace manipadrsHP  = subinstr(manipadrsHP , "Na", " ",. )
replace manipadrsHP  = subinstr(manipadrsHP , "na", " ",. )

list manipadrsHP dir_res_ if regexm(manipadrsHP , "ma")==1 
list manipadrsHP NOMBRE if regexm(manipadrsHP , "Ma")==1 
replace manipadrsHP  = subinstr(manipadrsHP , "Ma", " ",. )
replace manipadrsHP = subinstr(manipadrsHP , "Ma", " ",. )

list manipadrsHP dir_res_ if regexm(manipadrsHP , "Ra")==1 
list manipadrsHP NOMBRE if regexm(manipadrsHP , "ra")==1 
replace manipadrsHP  = subinstr(manipadrsHP , "Ra", " ",. )
replace manipadrsHP  = subinstr(manipadrsHP , "ra", " ",. )

list manipadrsHP dir_res_ if regexm(manipadrsHP , "Va")==1 
list manipadrsHP NOMBRE if regexm(manipadrsHP , "va")==1 
replace manipadrsHP  = subinstr(manipadrsHP , "Va", " ",. )
replace manipadrsHP  = subinstr(manipadrsHP , "va", " ",. )

*remove space between all letters and numbers unless it is a N, E, O, S
*replace N, O, E, S, KR, AV, PJ, TV, DG to other symbols
foreach x in "A" "B" "C" "D" "F" "G" "H" "I" "J" "K" "L" "M" "P" "Q" "R" "T" "U" "V" "W" "X" "Y" "Z"{
	replace manipadrsHP = subinstr(manipadrsHP, " `x' ", "`x'", .)
	}

*once all of the directions are cleaned, replace each the oeste, norte, este, with " O ", " E " " N " then itrim and trim the variable 
replace manipadrsHP = subinstr(manipadrsHP, "Norte", " N ", .)
replace manipadrsHP = subinstr(manipadrsHP, "Nte", " N ", .)
replace manipadrsHP = subinstr(manipadrsHP, "Oeste", " O ", .)
replace manipadrsHP = subinstr(manipadrsHP, "Oste", " O ", .)
replace manipadrsHP = subinstr(manipadrsHP, "Oes", " O ", .)
replace manipadrsHP = subinstr(manipadrsHP, "Oest", " O ", .)
replace manipadrsHP = subinstr(manipadrsHP, "Ose", " O ", .)
replace manipadrsHP = subinstr(manipadrsHP, "Oe", " O ", .)
replace manipadrsHP = subinstr(manipadrsHP, "Este", " E ", .)
replace manipadrsHP = subinstr(manipadrsHP, "Sur", " S ", .)


/*replace manipadrsHP = subinstr(manipadrsHP, "O", " O ", .)
replace manipadrsHP = subinstr(manipadrsHP, "E", " E ", .)
replace manipadrsHP = subinstr(manipadrsHP, "N", " N ", .)*/

replace manipadrsHP = subinstr(manipadrsHP, "Bis", " Bis ", .)
replace manipadrsHP = subinstr(manipadrsHP, "Bis Bis", " Bis ", .)
replace manipadrsHP = subinstr(manipadrsHP, "#", " # ", .)
replace manipadrsHP = subinstr(manipadrsHP, "- Bis", "Bis", .)
replace manipadrsHP = subinstr(manipadrsHP, "-", " - ", .)


*remove missing
replace manipadrsHP = "." if manipadrsHP==""  
list if manipadrsHP=="."  
drop if manipadrsHP=="."  

/**we have to remove strings like "Polverines" "La Luisa" "La Choclona" "Acentamiento Brisas De Comunero" "municipal En Candelaria" "Brisas De Los Alamos" 
gen manipadrsHP_l =length(manipadrsHP) 
order manipadrsHP
gsort -manipadrsHP_l
*/

replace manipadrsHP = trim(manipadrsHP)
replace manipadrsHP = itrim(manipadrsHP)
replace manipadrsHP = proper(manipadrsHP)


replace manipadrsHP = subinword(manipadrsHP,"Kr","KR",.)
replace manipadrsHP = subinstr(manipadrsHP, "Cl", "CL",.)
replace manipadrsHP = subinstr(manipadrsHP, "Av", "AV",.)
replace manipadrsHP = subinstr(manipadrsHP, "Pj", "PJ",.)
replace manipadrsHP = subinstr(manipadrsHP, "Tv", "TV",.)
replace manipadrsHP = subinstr(manipadrsHP, "Dg", "DG",.)

replace manipadrsHP = subinword(manipadrsHP,"kr","KR",.)
replace manipadrsHP = subinstr(manipadrsHP, "cl", "CL",.)
replace manipadrsHP = subinstr(manipadrsHP, "av", "AV",.)
replace manipadrsHP = subinstr(manipadrsHP, "pj", "PJ",.)
replace manipadrsHP = subinstr(manipadrsHP, "tv", "TV",.)
replace manipadrsHP = subinstr(manipadrsHP, "dg", "DG",.)


*split on pound sign and replace the spaces with dashes. 
split manipadrsHP, parse("#")
rename manipadrsHP manipadrsHP_origional
replace manipadrsHP2 = subinstr(trim(manipadrsHP2), " ", " - ", .) if manipadrsHP2!=""
replace manipadrsHP2 = subinstr(trim(manipadrsHP2), " - - - - ", " - ", .) if manipadrsHP2!=""
replace manipadrsHP2 = subinstr(trim(manipadrsHP2), " - - - ", " - ", .) if manipadrsHP2!=""
replace manipadrsHP2 = subinstr(trim(manipadrsHP2), " - - ", " - ", .) if manipadrsHP2!=""
replace manipadrsHP2 = subinstr(trim(manipadrsHP2), "-  -", " - ", .) if manipadrsHP2!=""
replace manipadrsHP2 = subinstr(trim(manipadrsHP2), "- Bis", " Bis ", .) if manipadrsHP2!=""

replace manipadrsHP2 = subinstr(trim(manipadrsHP2), " - E ", " E ", .) if manipadrsHP2!=""
replace manipadrsHP2 = subinstr(trim(manipadrsHP2), " - O ", " O ", .) if manipadrsHP2!=""
replace manipadrsHP2 = subinstr(trim(manipadrsHP2), " - S ", " S ", .) if manipadrsHP2!=""
replace manipadrsHP2 = subinstr(trim(manipadrsHP2), " - N ", " N ", .) if manipadrsHP2!=""

replace manipadrsHP2 = trim(manipadrsHP2) if manipadrsHP2!=""
replace manipadrsHP2 = itrim(manipadrsHP2) if manipadrsHP2!=""
replace manipadrsHP_origional = trim(manipadrsHP1) + " # " + trim(manipadrsHP2) if manipadrsHP2!=""
rename manipadrsHP_origional manipadrsHP  
drop manipadrsHP1 manipadrsHP2 

*order
order manipadrsHP dir_res

*make variable I will edit by hand
gen byhand_manipadrsHP = "."
replace byhand_manipadrsHP = manipadrsHP
order dir_res_ byhand_manipadrsHP NOMBRE manipadrsHP 

*stable sort so that the observations stay in the right order for hand edits
sort ID_CODE, stable
sort NOMBRE, stable

*export to excel a coopy
export excel using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\byhand.xls", firstrow(variables) replace

*manual edits in stata edit window
replace byhand_manipadrsHP = "KR 40 # 31A - 49" in 1
replace byhand_manipadrsHP = "KR 41 # 30A - 56" in 8
replace byhand_manipadrsHP = "KR 39A # 30A - 42" in 20
replace byhand_manipadrsHP = "KR 41A # 30C - 30" in 47
replace byhand_manipadrsHP = "KR 41A # 30C - 93" in 46
replace byhand_manipadrsHP = "KR 41 # 30A - 56" in 39
replace byhand_manipadrsHP = "KR 41 # 30A - 56" in 40
replace byhand_manipadrsHP = "KR 41 # 30A - 56" in 41
replace byhand_manipadrsHP = "KR 2 # 64A - 22" in 71
replace byhand_manipadrsHP = "KR 13 # 62 - 36" in 73
replace byhand_manipadrsHP = "CL 59 # 59 - 2F38" in 74
replace byhand_manipadrsHP = "KR 1H Bis # 64 - 22" in 90
replace byhand_manipadrsHP = "KR 1H # 62 - 70" in 91
replace byhand_manipadrsHP = "CL 62 # 1B - 90" in 92
replace byhand_manipadrsHP = "KR 1 # 1 - 68 - 52" in 98
replace byhand_manipadrsHP = "KR 1D # 70C - 18" in 99
replace byhand_manipadrsHP = "KR 1D # 70C - 18" in 100
replace byhand_manipadrsHP = "KR 1F # 71 - 77" in 102
replace byhand_manipadrsHP = "KR 1J # 62A - 28" in 113
replace byhand_manipadrsHP = "CL 71A # 9D - 35" in 114
replace byhand_manipadrsHP = "KR 1H # 64A - 48" in 115
replace byhand_manipadrsHP = "KR 35 O # 7 - 13" in 125
replace byhand_manipadrsHP = "CL 7 O # 25 - 153" in 126
replace byhand_manipadrsHP = "KR 4 E # 62B - 40" in 133
replace byhand_manipadrsHP = "KR 3A # 62A - 47" in 136
replace byhand_manipadrsHP = "CL 59 # 4D - 59" in 137
replace byhand_manipadrsHP = "CL 60D # 4D - 65" in 145
replace byhand_manipadrsHP = "KR 5 # 28A - 99" in 146
replace byhand_manipadrsHP = "CL 60C # 4D B - 15 - 46" in 149

replace byhand_manipadrsHP = "KR 4C1 # 62B - 53" in 152
replace byhand_manipadrsHP = "KR 4C1 # 62B - 53" in 153
replace byhand_manipadrsHP = "KR 3 # 63 - 70" in 154
replace byhand_manipadrsHP = "KR 3 # 63 - 70" in 155
replace byhand_manipadrsHP = "CL 59D # 3 Bis - 10" in 159
replace byhand_manipadrsHP = "KR 4B # 58 - 28" in 160
replace byhand_manipadrsHP = "KR 4 # 63 - 13 - 05" in 161
replace byhand_manipadrsHP = "KR 4C1 # 59C Bis - 04" in 165
replace byhand_manipadrsHP = "CL 92 # 8A - 10" in 170
replace byhand_manipadrsHP = "CL 95 # 19 - 91" in 173
replace byhand_manipadrsHP = "CL 18A # 55 - 105" in 177
replace byhand_manipadrsHP = "CL 18 Bis # 52A - 11" in 178
replace byhand_manipadrsHP = "CL 14B # 14 N - 86" in 180
replace byhand_manipadrsHP = "CL 18 # 35 - 40" in 181
replace byhand_manipadrsHP = "CL 18 # 35 - 40" in 182
replace byhand_manipadrsHP = "CL 18 # 35 - 40" in 183
replace byhand_manipadrsHP = "CL 18 # 35 - 40" in 184
replace byhand_manipadrsHP = "CL 18 # 50 - 97" in 185
replace byhand_manipadrsHP = "CL 57 # 1G - 06" in 194
replace byhand_manipadrsHP = "KR 52A # 16 - 65" in 200
replace byhand_manipadrsHP = "CL 18 # 53A  - 88" in 204
replace byhand_manipadrsHP = "CL 13 Cn # 15 - 22" in 227
replace byhand_manipadrsHP = "CL 13 Cn # 20 - 15" in 228
replace byhand_manipadrsHP = "CL 122 # 28F - 1 - 53" in 231
replace byhand_manipadrsHP = "CL 110 # 29 - 48" in 232
replace byhand_manipadrsHP = "KR 28D # 5 - 120A - 57B" in 235
replace byhand_manipadrsHP = "KR 28C # 120B - 58" in 237
replace byhand_manipadrsHP = "KR 28D4 # 120A - 127" in 239
replace byhand_manipadrsHP = "KR 28D4 # 120A - 127" in 240
replace byhand_manipadrsHP = "CL 18 # 28 E - 51" in 241
replace byhand_manipadrsHP = "KR 28 # 120B - 63" in 242
replace byhand_manipadrsHP = "KR 28D6 # 120A - 27" in 243
replace byhand_manipadrsHP = "KR 28D4 # 120B - 58" in 244
replace byhand_manipadrsHP = "CL 5 O" in 245
replace byhand_manipadrsHP = "CL 2 O N" in 246
replace byhand_manipadrsHP = "CL 26B # 27 - 24" in 250
replace byhand_manipadrsHP = "CL 26B # 27 - 24" in 251
replace byhand_manipadrsHP = "CL 26B # 27 - 24" in 252
replace byhand_manipadrsHP = "CL 26B # 27 - 24" in 253
replace byhand_manipadrsHP = "DG l # 25 - 17" in 254
replace byhand_manipadrsHP = "TV 29 # 26 - 30" in 255
replace byhand_manipadrsHP = "TV 29 # 26 - 30" in 256
replace byhand_manipadrsHP = "TV 29 # 26 - 30" in 257
replace byhand_manipadrsHP = "TV 29 # 26 - 30" in 258
replace byhand_manipadrsHP = "KR 45 # 45 - 96C - 79" in 259
replace byhand_manipadrsHP = "DG 24A # T25 - 104" in 260
replace byhand_manipadrsHP = "KR 33 # 96A - 98" in 263
replace byhand_manipadrsHP = "TV 25 # D24 - B11" in 264
replace byhand_manipadrsHP = "DG 18 # 17F1 - 07" in 265
replace byhand_manipadrsHP = "DG 24B # 25 - 102" in 271

replace byhand_manipadrsHP = "DG 24B # 25 - 102" in 272
replace byhand_manipadrsHP = "KR 7 # 74 - 38" in 273
replace byhand_manipadrsHP = "DG 24B # 25 - 66" in 276
replace byhand_manipadrsHP = "DG 23 # 25 - 68" in 277
replace byhand_manipadrsHP = "KR 11E # 39 - 04" in 278
replace byhand_manipadrsHP = "CL 40 N # 3 N - 2D" in 281
replace byhand_manipadrsHP = "TV 29 # 26 - 36" in 282
replace byhand_manipadrsHP = "TV 29 # 26 - 36" in 283
replace byhand_manipadrsHP = "TV 29 # 26 - 36" in 284
replace byhand_manipadrsHP = "TV 29 # 26 - 36" in 285
replace byhand_manipadrsHP = "TV 2 # 26 - 104" in 289
replace byhand_manipadrsHP = "KR 30 # 26B - 91" in 290
replace byhand_manipadrsHP = "CL 57An # 2An - 51" in 292
replace byhand_manipadrsHP = "KR 7U # 69 - 05" in 293
replace byhand_manipadrsHP = "DG 24C # T25 - 80" in 295
replace byhand_manipadrsHP = "DG 24C # T25 - 80" in 296
replace byhand_manipadrsHP = "CL 57A N # 2A N - 51" in 292

replace byhand_manipadrsHP = "AV 7B #" in 299
replace byhand_manipadrsHP = "CL 4 # 39 - 58" in 303
replace byhand_manipadrsHP = "DG 24A # 25 - 44" in 305
replace byhand_manipadrsHP = "KR 46 # 44 - 48" in 306
replace byhand_manipadrsHP = "CL 23 # 17B - 24" in 308
replace byhand_manipadrsHP = "TV 29D # 24D - 26" in 314
replace byhand_manipadrsHP = "CL 23A # 9 E - 111" in 317
replace byhand_manipadrsHP = "CL 72 # 3 N - 06" in 319
replace byhand_manipadrsHP = "KR 34 # 54A - 38" in 320
replace byhand_manipadrsHP = "KR 29 # 28H - 21" in 325
replace byhand_manipadrsHP = "CL 117 # 28E - 04 - 60" in 327
replace byhand_manipadrsHP = "CL 115 # 28E4 - 42" in 328
replace byhand_manipadrsHP = "CL 115 # 28E4 - 42" in 329
replace byhand_manipadrsHP = "CL 117 # 28E4 - 36" in 330
replace byhand_manipadrsHP = "CL 118 # 28E - 97" in 331
replace byhand_manipadrsHP = "KR 25 # 26B - 80" in 336
replace byhand_manipadrsHP = "CL 27 # 24A - 40" in 351
replace byhand_manipadrsHP = "KR 24B # 26B - 05" in 352
replace byhand_manipadrsHP = "KR 25B # 26B - 111" in 355
replace byhand_manipadrsHP = "KR 25B # 26B - 25" in 357
replace byhand_manipadrsHP = "KR 26Q # 72T - 03" in 358
replace byhand_manipadrsHP = "KR 25B # 26B - 52" in 367
replace byhand_manipadrsHP = "KR 25E # 26B - 52" in 368
replace byhand_manipadrsHP = "KR 26B # 26B - 126" in 369
replace byhand_manipadrsHP = "KR 25B # 26B - 85" in 373
replace byhand_manipadrsHP = "KR 25A # 25 - 120" in 374
replace byhand_manipadrsHP = "KR 25 # 25 - 48" in 378
replace byhand_manipadrsHP = "CL 26B # 27 - 26" in 380
replace byhand_manipadrsHP = "DG 24 # 25 - 104" in 386
replace byhand_manipadrsHP = "DG 24 # 25 102" in 387
replace byhand_manipadrsHP = "DG 24CT # 25 - 104" in 386
replace byhand_manipadrsHP = "DG 24C # 25 - 102" in 387
replace byhand_manipadrsHP = "KR 28 # 26B - 86" in 399
replace byhand_manipadrsHP = "CL 26C # 29A - 27" in 400
replace byhand_manipadrsHP = "KR 26H - 2 N # 72U - 49" in 401
replace byhand_manipadrsHP = "A4 N # 32 - 44 - 158" in 402
replace byhand_manipadrsHP = "AV 4 N # 32 - 44 - 158" in 402
replace byhand_manipadrsHP = "CL 22 O # 2A - 124" in 412
replace byhand_manipadrsHP = "CL 2C # 92A - 11" in 419
replace byhand_manipadrsHP = "AV 6 O # 6B - 26" in 420
replace byhand_manipadrsHP = "CL 13 O # 6 Bis O - 31" in 421
replace byhand_manipadrsHP = "CL 90 O # 15 - 96" in 422

replace byhand_manipadrsHP = "CL 9 O # 15 - 80" in 436
replace byhand_manipadrsHP = "KR 23B # 9B - 30" in 440
replace byhand_manipadrsHP = "CL 7G # 25L - 27" in 441
replace byhand_manipadrsHP = "CL 12 # 24 - 90" in 442
replace byhand_manipadrsHP = "CL 9B # 19 - 28" in 450
replace byhand_manipadrsHP = "CL 19 # 37" in 461
replace byhand_manipadrsHP = "CL 9F # 23C - 98" in 470
replace byhand_manipadrsHP = "DG 7 TA1 # 20 - H3 - 50" in 472
replace byhand_manipadrsHP = "DG 24B # 25 - 102" in 475
replace byhand_manipadrsHP = "KR 2 O # 9 E - 63" in 483
replace byhand_manipadrsHP = "KR 23A # 13 - 90" in 484
replace byhand_manipadrsHP = "KR 23A # 13 - 90" in 485
replace byhand_manipadrsHP = "CL 7A # 17C - 21" in 487
replace byhand_manipadrsHP = "CL 8 # 22 - 53" in 488
replace byhand_manipadrsHP = "KR 23 # 8 07" in 490
replace byhand_manipadrsHP = "KR 23 # 8 - 07" in 490
replace byhand_manipadrsHP = "CL 9 E # 18 - 49" in 492
replace byhand_manipadrsHP = "KR 23C # 23C 84 - 24" in 493
replace byhand_manipadrsHP = "KR 23C # 84 - 24" in 493
replace byhand_manipadrsHP = "KR 23 # 5A - 47" in 500
replace byhand_manipadrsHP = "CL 9 # 23 - 65" in 501
replace byhand_manipadrsHP = "CL 7A # 19 - 28" in 504
replace byhand_manipadrsHP = "CL 23A # 7A - 39" in 506
replace byhand_manipadrsHP = "KR 23 # 15B - 38" in 512
replace byhand_manipadrsHP = "KR 75 # 3P - 32" in 521
replace byhand_manipadrsHP = "KR 33 E # 46" in 545
replace byhand_manipadrsHP = "KR 28D # 99 - 27D - 60" in 558
replace byhand_manipadrsHP = "CL 79 # 02 - 8D" in 566
replace byhand_manipadrsHP = "KR 28 # 99 - 28 - 32" in 567


replace byhand_manipadrsHP = "CL 80 N # 26P - 46" in 569
replace byhand_manipadrsHP = "CL 81 # 26P - 40" in 570
replace byhand_manipadrsHP = "CL 93 N # 27D - 136" in 573
replace byhand_manipadrsHP = "CL 84 # 26P - 10" in 574
replace byhand_manipadrsHP = "KR 26C # 80C - 10" in 578
replace byhand_manipadrsHP = "CL 93M N # 27D - 95" in 581
replace byhand_manipadrsHP = "CL 92 # 28A- 04" in 583
replace byhand_manipadrsHP = "CL 78 # 26 - P18" in 584
replace byhand_manipadrsHP = "DG 26H5 # 72U - 74" in 601
replace byhand_manipadrsHP = "CL 89 # 28 - 24" in 603

replace byhand_manipadrsHP = "KR 25F # 70A - 41" in 609
replace byhand_manipadrsHP = "CL 17 # 26I - 3 - 11" in 614
replace byhand_manipadrsHP = "CL 85 # 27 - 112" in 623
replace byhand_manipadrsHP = "KR 27 # 27 - 23" in 626
replace byhand_manipadrsHP = "KR 28 - 3 # 95 - 52" in 630
replace byhand_manipadrsHP = "KR 26I - 3 # 72 - 69" in 631
replace byhand_manipadrsHP = "CL 85 # 28 - E3 - 41" in 632
replace byhand_manipadrsHP = "CL 91 N # 27D - 101" in 636
replace byhand_manipadrsHP = "KR 28 # 88A - 18" in 637
replace byhand_manipadrsHP = "KR 26U # 76 - 32" in 639
replace byhand_manipadrsHP = "CL 83 # 28C1 - 34" in 642
replace byhand_manipadrsHP = "KR 26R # 73A - 81" in 666
replace byhand_manipadrsHP = "KR 28 # 81 - 26P - 54" in 671
replace byhand_manipadrsHP = "CL 78 # 27C - 10" in 674
replace byhand_manipadrsHP = "CL 79 # 26P - 109" in 675
replace byhand_manipadrsHP = "CL 78 # 26P - 03" in 676
replace byhand_manipadrsHP = "CL 82 # 28D - 151" in 686
replace byhand_manipadrsHP = "CL 90 # 28E3 - 71" in 700
replace byhand_manipadrsHP = "CL 91A # 26P - 47" in 701
replace byhand_manipadrsHP = "CL 88A N # 28 - 38" in 704
replace byhand_manipadrsHP = "CL 83A # 28E3 - 83" in 712
replace byhand_manipadrsHP = "KR 27 # 78A - 59" in 714
replace byhand_manipadrsHP = "KR 28C # 2 - 88 - 10" in 716
replace byhand_manipadrsHP = "CL 90 # 27D - 107" in 718
replace byhand_manipadrsHP = "KR 84 # 36" in 720
replace byhand_manipadrsHP = "CL 85 # 26P - 121" in 737
replace byhand_manipadrsHP = "KR 7 S Bis # 72 - 44" in 741

replace byhand_manipadrsHP = "KR 7R # 73 - 34" in 744
replace byhand_manipadrsHP = "KR 7T Bis # 72 - 104" in 749
replace byhand_manipadrsHP = "KR 7 E # 70 - 107" in 750
replace byhand_manipadrsHP = "CL 7A # 76 Bis - 03" in 757
replace byhand_manipadrsHP = "KR 7B Bis # 86 - 29" in 765
replace byhand_manipadrsHP = "CL 7D # 1 - 82 - 30" in 773
replace byhand_manipadrsHP = "CL 7D 1 # 82 - 30" in 773
replace byhand_manipadrsHP = "KR 1AB # 76 - 08" in 774
replace byhand_manipadrsHP = "KR 7CB # 14 - 84 - 43" in 775
replace byhand_manipadrsHP = "KR 7R Bis # 76 - 87" in 776

replace byhand_manipadrsHP = "KR 75 # 77 - 87" in 784
replace byhand_manipadrsHP = "KR 7L Bis # 70 - 28" in 785
replace byhand_manipadrsHP = "KR 7L Bis # 76 - 103" in 786
replace byhand_manipadrsHP = "CL 82 # 7H Bis - 48" in 794
replace byhand_manipadrsHP = "KR 7T # 74 - 75" in 795
replace byhand_manipadrsHP = "CL 81 # 7 N - 35" in 803
replace byhand_manipadrsHP = "CL 81 # 7 N - 35" in 804
replace byhand_manipadrsHP = "CL 72A # 3 N - 87" in 807
replace byhand_manipadrsHP = "KR 7L Bis # 70 - 39" in 819
replace byhand_manipadrsHP = "KR 7T Bis # 72 - 124" in 821
replace byhand_manipadrsHP = "KR 7 S Bis # Z2 - 44" in 822
replace byhand_manipadrsHP = "KR 7S Bis # 72 - 44" in 822
replace byhand_manipadrsHP = "KR 7L3 # 81 - 45" in 824
replace byhand_manipadrsHP = "KR 7T Bis # 77 - 137" in 825
replace byhand_manipadrsHP = "KR 7 Bis # 72 - 85" in 832
replace byhand_manipadrsHP = "KR 7D1 # 82 - 98" in 835
replace byhand_manipadrsHP = "CL 70 # 74 Bis - 29" in 842
replace byhand_manipadrsHP = "KR 7E # 81 - 70" in 860
replace byhand_manipadrsHP = "CL 88 # 7HI - 13" in 864
replace byhand_manipadrsHP = "KR 7P Bis # 72 - 48" in 870
replace byhand_manipadrsHP = "KR 7 Bis # 86 - 04" in 871
replace byhand_manipadrsHP = "KR 7T1 # 76 - 22" in 873

replace byhand_manipadrsHP = "KR 7H # 70 - 97" in 875
replace byhand_manipadrsHP = "KR 7H # 70 - 97" in 876
replace byhand_manipadrsHP = "KR 76 # 92 - 04" in 878
replace byhand_manipadrsHP = "CL 72 # 7T Bis - 22" in 887
replace byhand_manipadrsHP = "CL 88 # 88 73BN - 13" in 895
replace byhand_manipadrsHP = "KR 7D Bis # 3 - 81 - 28" in 900
replace byhand_manipadrsHP = "KR 7D Bis # 81 - 28" in 900
replace byhand_manipadrsHP = "KR 7T # 10 - 73 - 53" in 907
replace byhand_manipadrsHP = "KR 32 # 19 - 11" in 910
replace byhand_manipadrsHP = "CL 41 # 7 E - 20" in 918
replace byhand_manipadrsHP = "KR 7U # 72 - 21" in 922
replace byhand_manipadrsHP = "KR 7L Bis # 76 - 11B" in 923
replace byhand_manipadrsHP = "KR 7P Bis # 78 - 48" in 924
replace byhand_manipadrsHP = "CL 74 # 7T Bis - 36" in 927
replace byhand_manipadrsHP = "CL 72 Bis # 7 - 72" in 932
replace byhand_manipadrsHP = "CL 72 Bis # 7 - 72" in 933
replace byhand_manipadrsHP = "CL 72 Bis # 7 - 72" in 934
replace byhand_manipadrsHP = "KR 7 Bis # 72 - 93" in 939
replace byhand_manipadrsHP = "CL 88 # 7 - 19" in 940
replace byhand_manipadrsHP = "KR 7U # 76 - 50" in 944
replace byhand_manipadrsHP = "KR 7P Bis # 81 - 05" in 947
replace byhand_manipadrsHP = "KR 7P Bis # 81 - 05" in 948
replace byhand_manipadrsHP = "KR 7M Bis # 74 - 03" in 951
replace byhand_manipadrsHP = "CL 70 # 7C Bis - 18" in 952
replace byhand_manipadrsHP = "CL 70 # 7E Bis - 14" in 955
replace byhand_manipadrsHP = "KR 7B Bis # 70 - 100" in 958
replace byhand_manipadrsHP = "KR 7D # 70 - 113" in 959
replace byhand_manipadrsHP = "KR 7 E Bis # 73 - 62" in 962
replace byhand_manipadrsHP = "KR 7D Bis # 76 - 61" in 963
replace byhand_manipadrsHP = "KR 7C # 81 - 116" in 976
replace byhand_manipadrsHP = "KR 7C # 81 - 116" in 977
replace byhand_manipadrsHP = "KR 7WB # 64 - 77" in 980
replace byhand_manipadrsHP = "KR 7L # 76 - 86" in 988
replace byhand_manipadrsHP = "KR 7 R Bis # 72 - 31" in 991
replace byhand_manipadrsHP = "KR T Bis # 76 - 11" in 995
replace byhand_manipadrsHP = "CL 70 # 70 7B - 16" in 999
replace byhand_manipadrsHP = "KR 7MR Bis # 73 - 77" in 1005

replace byhand_manipadrsHP = "KR 7B Bis # 70 - 125" in 1010
replace byhand_manipadrsHP = "KR 7 # 77 - 80" in 1012
replace byhand_manipadrsHP = "KR 7L Bis # 76 - 109" in 1013
replace byhand_manipadrsHP = "KR 7L Bis # 76 - 109" in 1014
replace byhand_manipadrsHP = "KR 7A # 84 - 95" in 1018
replace byhand_manipadrsHP = "KR 7A Bis # 72A - 30" in 1023
replace byhand_manipadrsHP = "CL 71 # 7R Bis - 56" in 1024
replace byhand_manipadrsHP = "KR 70 Bis # 70 - 99" in 1028

replace byhand_manipadrsHP = "KR 7P # 72 - 72" in 1030

replace byhand_manipadrsHP = "CL 72 # 7 Bis - 10" in 1134
replace byhand_manipadrsHP = "KR 7 E Bis # 73 - 93" in 1137
replace byhand_manipadrsHP = "KR 7 E Bis # 73 - 93 " in 1138
replace byhand_manipadrsHP = "KR 7 E Bis # 73 - 93" in 1138
replace byhand_manipadrsHP = "CL 81 # 7 Bis - 65" in 1140
replace byhand_manipadrsHP = "KR 7D 3 # 81 - 31" in 1141
replace byhand_manipadrsHP = "KR 7D3 # 81 - 31" in 1141
replace byhand_manipadrsHP = "CL 86 # 3 - 7A - 02" in 1142
replace byhand_manipadrsHP = "CL 86 # 37A - 02" in 1143
replace byhand_manipadrsHP = "CL 86 # 37A - 02" in 1142
replace byhand_manipadrsHP = "CL 88 # 7G Bis - 01" in 1149
replace byhand_manipadrsHP = "KR 7E # 66 - 19" in 1152
replace byhand_manipadrsHP = "CL 84A Bis # 86A - 24" in 1168
replace byhand_manipadrsHP = "CL 72FR # 7C - 100" in 1170
replace byhand_manipadrsHP = "KR 7Tb1 # 76 - 54" in 1186
replace byhand_manipadrsHP = "KR 28 # 36A - 37" in 1189


replace byhand_manipadrsHP = "CL 88 # 7E Bis - 17" in 1191
replace byhand_manipadrsHP = "CL 70 # 7A Bis - 29" in 1195
replace byhand_manipadrsHP = "KR 26A1 # 78 - 40" in 1215
replace byhand_manipadrsHP = "KR 26C 62 # 64 - 19" in 1216
replace byhand_manipadrsHP = "TV 103 # 26B3 - 29" in 1217
replace byhand_manipadrsHP = "KR 26A2 # 75 - 34" in 1230
replace byhand_manipadrsHP = "CL 76 # 26E - 12" in 1231
replace byhand_manipadrsHP = "CL 78AN # 26G - 27" in 1237
replace byhand_manipadrsHP = "KR 7 E # 72A - 69" in 1053

replace byhand_manipadrsHP = "KR 26C2 # 74 - 88" in 1238
replace byhand_manipadrsHP = "KR 26C1 # 74 - 27" in 1239
replace byhand_manipadrsHP = "CL 78 # 26A - 229" in 1241
replace byhand_manipadrsHP = "CL 79 # 26B3 - 21" in 1242
replace byhand_manipadrsHP = "CL 79 # 26 - B3 - 21" in 1242
replace byhand_manipadrsHP = "KR 26 # 107 - 03" in 1251

replace byhand_manipadrsHP = "CL 11A #  33" in 1257
replace byhand_manipadrsHP = "KR 26B2 # 75 - 61" in 1265
replace byhand_manipadrsHP = "CL 77 # 26A - 20" in 1266
replace byhand_manipadrsHP = "CL 78 # 26A - 12" in 1274
replace byhand_manipadrsHP = "KR 27C # 72B - 16" in 1275
replace byhand_manipadrsHP = "CL 78 # 26A - 12" in 1277
replace byhand_manipadrsHP = "KR 26A # 77 - 56" in 1279

replace byhand_manipadrsHP = "KR 26C2 # 74 - 53" in 1281
replace byhand_manipadrsHP = "KR 26F1 # 75 - 19" in 1304
replace byhand_manipadrsHP = "CL 76 # 26E - 04" in 1311
replace byhand_manipadrsHP = "KR 26B1 # 75 - 39" in 1313
replace byhand_manipadrsHP = "KR 26A1 # 78 - 76" in 1319
replace byhand_manipadrsHP = "CL 77 # 26B33 - 26" in 1322
replace byhand_manipadrsHP = "CL 77 # 26B3 - 26" in 1322
replace byhand_manipadrsHP = "KR 26B1 # 77 - 75" in 1323
replace byhand_manipadrsHP = "CL 80F # 26G3 - 34" in 1325
replace byhand_manipadrsHP = "CL 77 # 26B2 - 04" in 1326
replace byhand_manipadrsHP = "CL 80 # 80R8 - 04" in 1328
replace byhand_manipadrsHP = "CL 77 # 26A3 - 13" in 1329
replace byhand_manipadrsHP = "KR 76A # 26 -" in 1331
replace byhand_manipadrsHP = "KR 76A # 26" in 1331
replace byhand_manipadrsHP = "KR 26U # 3 - 88 - 12" in 1332
replace byhand_manipadrsHP = "KR 26B2 # 78 - 32" in 1335
replace byhand_manipadrsHP = "CL 5" in 1343
replace byhand_manipadrsHP = "KR 94B O # 3 - 17" in 1344
replace byhand_manipadrsHP = "KR 85 # 29 - 35" in 1345
replace byhand_manipadrsHP = "KR 94 # 3W O" in 1350
replace byhand_manipadrsHP = "AV 46 # 96 - 46" in 1358
replace byhand_manipadrsHP = "KR 96 # 1 - 53 O" in 1359
replace byhand_manipadrsHP = "KR 93 # 2 - 35" in 1365

replace byhand_manipadrsHP = "KR 90C O # 4 - 37" in 1366
replace byhand_manipadrsHP = "KR 96 O # 2B - 08" in 1382
replace byhand_manipadrsHP = "CL 3C # 94A - 51" in 1387
replace byhand_manipadrsHP = "CL 1Ba # 94B - 09" in 1390
replace byhand_manipadrsHP = "KR 95 # 1 Bis - 97" in 1391
replace byhand_manipadrsHP = "CL 5 O # 81B - 08" in 1397
replace byhand_manipadrsHP = "CL 3C O # 94A - 14" in 1408
replace byhand_manipadrsHP = "CL 5" in 1415
replace byhand_manipadrsHP = "" in 1415

replace byhand_manipadrsHP = "CL 1C O # 94C - 50" in 1419
replace byhand_manipadrsHP = "CL 2B O # 83B - 16" in 1433
replace byhand_manipadrsHP = "KR 80 # 1B - 34" in 1441
replace byhand_manipadrsHP = "KR 80A Bis O # 2 - 23" in 1445
replace byhand_manipadrsHP = "CL 1B O # 78A - 10" in 1454
replace byhand_manipadrsHP = "CL 1B O # 78A - 10" in 1455

drop if byhand_manipadrsHP  ==""


replace byhand_manipadrsHP = "KR 79A # 1 - 15 O" in 1487
replace byhand_manipadrsHP = "KR 83 # 1 O - 24" in 1490
replace byhand_manipadrsHP = "AV 8A1N # 53B - 09" in 1507
replace byhand_manipadrsHP = "AV 7C1 # 53A - 02" in 1509
replace byhand_manipadrsHP = "CL 53 # 7C1 - 48" in 1510
replace byhand_manipadrsHP = "CL 2A # 9 Bis" in 1511
replace byhand_manipadrsHP = "AV 6F # 53BN - 09" in 1515
replace byhand_manipadrsHP = "CL 53 N # 8AN - 90" in 1518
replace byhand_manipadrsHP = "CL 53 AN # 7C - 119" in 1524
replace byhand_manipadrsHP = "AV 8N3 # 52B - 34" in 1526
replace byhand_manipadrsHP = "AV 8N3 # 52B - 34" in 1527
replace byhand_manipadrsHP = "AV 8A1 # 50 - 190" in 1529
replace byhand_manipadrsHP = "CL 53AN # 8 - 163" in 1530
replace byhand_manipadrsHP = "AV 22 # 53A - 11" in 1535
replace byhand_manipadrsHP = "CL 53AN # 7A - 142" in 1536
replace byhand_manipadrsHP = "CL 53 # 91 - 32" in 1539
replace byhand_manipadrsHP = "AV 7C1 # 53 - 19" in 1541
replace byhand_manipadrsHP = "AV 7CN # 53 - 133" in 1542
replace byhand_manipadrsHP = "AV 8 N # 52B - 66" in 1545
replace byhand_manipadrsHP = "CL 52NA # 181 - 35" in 1546
replace byhand_manipadrsHP = "AV 7 CN # 52 - 157" in 1548
replace byhand_manipadrsHP = "AV 7C1 # 52 - 164" in 1550
replace byhand_manipadrsHP = "CL 5 # 9BN - 14" in 1551
replace byhand_manipadrsHP = "CL 52N #  7C1 - 34" in 1556
replace byhand_manipadrsHP = "CL 13 # 16" in 1559
replace byhand_manipadrsHP = "KR 8AB # 73A - 05" in 1574
replace byhand_manipadrsHP = "CL 63NA # 23" in 1591
replace byhand_manipadrsHP = "KR 39E # 48 - 48" in 1625
replace byhand_manipadrsHP = "KR 39E # 48 - 48" in 1626

replace byhand_manipadrsHP = "CL 43A # 34 - 16" in 1648
replace byhand_manipadrsHP = "CL 47 # 39A - 45" in 1699
replace byhand_manipadrsHP = "CL 37 # 39E - 52" in 1711
replace byhand_manipadrsHP = "CL 42 # 39E - 11" in 1714
replace byhand_manipadrsHP = "KR 33 # 30 - 19" in 1780

replace byhand_manipadrsHP = "CL 40 # 41D - 08" in 1855
replace byhand_manipadrsHP = "KR 41F # 41E - 39" in 1867
replace byhand_manipadrsHP = "CL 46D # 39A - 100" in 1875
replace byhand_manipadrsHP = "KR 42 # 40 - 15" in 1877
replace byhand_manipadrsHP = "CL 47 # 39G - 15" in 1882
replace byhand_manipadrsHP = "CL 37 # 39C - 12" in 1916
replace byhand_manipadrsHP = "CL 15A # 23B - 07" in 1960
replace byhand_manipadrsHP = "CL 16A # 19A - 03" in 1986
replace byhand_manipadrsHP = "CL 61" in 2022

replace byhand_manipadrsHP = "CL 61" in 2022
replace byhand_manipadrsHP = "CL 36A # 25A - 87" in 2053
replace byhand_manipadrsHP = "CL 41 # 24B - 10" in 2063
replace byhand_manipadrsHP = "CL 36 # 11F - 80" in 2066
replace byhand_manipadrsHP = "KR 1D1 # 52 - 88" in 2069
replace byhand_manipadrsHP = "CL # 13 - 12" in 2080
replace byhand_manipadrsHP = "KR 14A3 # 35 - 78" in 2084
replace byhand_manipadrsHP = "CL 41 # 17B - 27" in 2087
replace byhand_manipadrsHP = "KR 17 # 33F - 25" in 2098
replace byhand_manipadrsHP = "CL 34 # 17B - 06" in 2103
replace byhand_manipadrsHP = "KR 12 # 33A - 33" in 2115
replace byhand_manipadrsHP = "KR 17B # 33F - 124" in 2123
replace byhand_manipadrsHP = "KR 1D # 46A - 36" in 2128
replace byhand_manipadrsHP = "KR 15 # 33B - 55" in 2131
replace byhand_manipadrsHP = "CL 56F1 # 48B - 17" in 2137
replace byhand_manipadrsHP = "CL 46A # 49A - 48" in 2138
replace byhand_manipadrsHP = "KR 42A # 54C - 74" in 2149
replace byhand_manipadrsHP = "KR 42 Bis N # 54C - 83" in 2150
replace byhand_manipadrsHP = "KR 46B # 56F1 - 16" in 2154
replace byhand_manipadrsHP = "KR 46B # 56F - 120" in 2158
replace byhand_manipadrsHP = "KR 50 # 56B - 15" in 2162
replace byhand_manipadrsHP = "CL 47A # 49A - 36" in 2167
replace byhand_manipadrsHP = "CL 55N # 47C - 64" in 2172
replace byhand_manipadrsHP = "CL 56 # 49G - 78" in 2173
replace byhand_manipadrsHP = "CL 56 # 49G - 78" in 2174
replace byhand_manipadrsHP = "CL 56A # 49F - 19" in 2181
replace byhand_manipadrsHP = "CL 56D # 42C2 - 86" in 2187
replace byhand_manipadrsHP = "KR 44A # 55C - 55" in 2197
replace byhand_manipadrsHP = "CL 22" in 2201
replace byhand_manipadrsHP = "KR 11D # 22A - 35" in 2206
replace byhand_manipadrsHP = "KR 10 Bis # 18 - 70" in 2214
replace byhand_manipadrsHP = "CL 22 # 8A - 59" in 2222
replace byhand_manipadrsHP = "CL 10" in 2225
replace byhand_manipadrsHP = "CL 18 # 17 - 36" in 2230
replace byhand_manipadrsHP = "KR 26CN # 97 - 30" in 2235
replace byhand_manipadrsHP = "KR 10 # 19 - 20" in 2241
replace byhand_manipadrsHP = "KR 9 # 6 - 04" in 2243
replace byhand_manipadrsHP = "CL 22A # 8 - 58" in 2245
replace byhand_manipadrsHP = "CL 22A # 8A - 34" in 2258
replace byhand_manipadrsHP = "KR 27D # 72F - 70" in 2270
replace byhand_manipadrsHP = "CL 23 # 19A - 49" in 2275
replace byhand_manipadrsHP = "CL 21 # 17B - 61" in 2287
replace byhand_manipadrsHP = "CL 23 # 13F - 21" in 2294
replace byhand_manipadrsHP = "KR 18B # 17 - 26" in 2310
replace byhand_manipadrsHP = "CL 23 # 17F - 33" in 2316
replace byhand_manipadrsHP = "KR 28J # 72T - 116" in 2329
replace byhand_manipadrsHP = "KR 40 # 1A - 14 O" in 2342
replace byhand_manipadrsHP = "AV 12 O # 39 - 05" in 2349
replace byhand_manipadrsHP = "KR 40N # 1A - 96" in 2352
replace byhand_manipadrsHP = "CL 1F # 38B - 83" in 2354
replace byhand_manipadrsHP = "CR 39 O # 14 - 15" in 2355
replace byhand_manipadrsHP = "KR 38B # 1D - 02" in 2356
replace byhand_manipadrsHP = "CL O # 38 - C28" in 2357
replace byhand_manipadrsHP = "" in 2357
replace byhand_manipadrsHP = "DG 72C" in 2362
replace byhand_manipadrsHP = "DG 72C N" in 2366
replace byhand_manipadrsHP = "DG 72C" in 2373
replace byhand_manipadrsHP = "CL 3 O # 51 - 81" in 2375
replace byhand_manipadrsHP = "KR 55 O # 1A - 75" in 2388
replace byhand_manipadrsHP = "KR 9 # 8 O - 30" in 2397
replace byhand_manipadrsHP = "CL 13B # 4A - 11" in 2400
replace byhand_manipadrsHP = "CL 14 O # 4A - 04" in 2401
replace byhand_manipadrsHP = "KR 2 O # 21 - 36" in 2402
replace byhand_manipadrsHP = "CL 82 # 28D4 - 10" in 2406
replace byhand_manipadrsHP = "CL 82 # 28D4 - 10" in 2407
replace byhand_manipadrsHP = "KR 22A # 7A O - 84" in 2410
replace byhand_manipadrsHP = "KR 4 O # 312A - 67" in 2411
replace byhand_manipadrsHP = "KR 4 O # 312A - 67" in 2412
replace byhand_manipadrsHP = "KR 12A # 2A - 37 O" in 2415
replace byhand_manipadrsHP = "CL 23 O # 33A - 09" in 2416
replace byhand_manipadrsHP = "KR 2D # 12A - 45 O" in 2419
replace byhand_manipadrsHP = "KR 2A # 21 - 67" in 2422
replace byhand_manipadrsHP = "CL 72J # 28G - 141" in 2425
replace byhand_manipadrsHP = "CL 72J # 28G - 104" in 2428
replace byhand_manipadrsHP = "CL 72I # 28F - 98" in 2434
replace byhand_manipadrsHP = "KR 26 O # 28B - 28" in 2437
replace byhand_manipadrsHP = "CL 72K # 28H - 72" in 2439
replace byhand_manipadrsHP = "CL 30A # 11D - 12" in 2445
replace byhand_manipadrsHP = "KR 13A # 27B - 22" in 2453
replace byhand_manipadrsHP = "CL 29 # 11B - 22" in 2456
replace byhand_manipadrsHP = "CL 30 # 11G - 53" in 2461
replace byhand_manipadrsHP = "CL 38N3 # 2N - 50" in 2470
replace byhand_manipadrsHP = "KR 5 AN # 38AN - 133" in 2471
replace byhand_manipadrsHP = "KR 2N # 38N - 35" in 2474
replace byhand_manipadrsHP = "KR 69A # 13B2 - 56" in 2485
replace byhand_manipadrsHP = "CL 11C # 24D - 20" in 2494
replace byhand_manipadrsHP = "KR 23B # 9B - 63" in 2495
replace byhand_manipadrsHP = "CL 9F # 23A - 10" in 2504
replace byhand_manipadrsHP = "KR 23C # 13B - 90" in 2508
replace byhand_manipadrsHP = "KR 209E # 63" in 2517
replace byhand_manipadrsHP = "CL 9E # 23B - 41" in 2518
replace byhand_manipadrsHP = "KR 20 # 09 - 12" in 2521
replace byhand_manipadrsHP = "KR 23 # 9C - 2A" in 2523
replace byhand_manipadrsHP = "KR 18 # 10 - 44" in 2529
replace byhand_manipadrsHP = "CL 9 # 23A - 54" in 2534
replace byhand_manipadrsHP = "CL 9 # 23A - 54" in 2535
replace byhand_manipadrsHP = "CL 11 # 15 - 17" in 2536
replace byhand_manipadrsHP = "CL 55AN # 2AN - 107" in 2540
replace byhand_manipadrsHP = "KR 8BN # 72B - 17" in 2545
replace byhand_manipadrsHP = "AV 2A5 # 75EN - 06" in 2547
replace byhand_manipadrsHP = "AV 2A # 75HN - 89" in 2548
replace byhand_manipadrsHP = "CL 57BN # 2BN - 69" in 2550
replace byhand_manipadrsHP = "CL 83A # 3AN - 38" in 2552
replace byhand_manipadrsHP = "AV 2B2 # 72N Bis - 99" in 2554
replace byhand_manipadrsHP = "AV 2B2N # 74N - 34" in 2555
replace byhand_manipadrsHP = "AV 2B2 # 73N Bis - 98" in 2556
replace byhand_manipadrsHP = "AV 2B2 # 73N Bis - 99" in 2557
replace byhand_manipadrsHP = "CL 77A # 3BN - 36" in 2558
replace byhand_manipadrsHP = "CL 73CN # 2 - 82" in 2559
replace byhand_manipadrsHP = "AV 2B3 # 72N - 43" in 2562
replace byhand_manipadrsHP = "AV 2B2 # 73N Bis - 57" in 2564
replace byhand_manipadrsHP = "CL 67N # 2A - 50" in 2566
replace byhand_manipadrsHP = "KR 3DN # 71F - 12" in 2569
replace byhand_manipadrsHP = "KR 3 FN # 70 - 50" in 2571
replace byhand_manipadrsHP = "CL 59AN # 2DN - 60" in 2572
replace byhand_manipadrsHP = "CL 73 BN # 2A - 87" in 2573
replace byhand_manipadrsHP = "CL 55 AN # 2AN - 20" in 2575
replace byhand_manipadrsHP = "CL 71I # 3BN - 64" in 2577
replace byhand_manipadrsHP = "CL 74CN # 2 - 24" in 2578
replace byhand_manipadrsHP = "AV 2B2 # 73N Bis - 98" in 2582
replace byhand_manipadrsHP = "AV 2B2 # 73N Bis - 98" in 2583
replace byhand_manipadrsHP = "AV 2B1 # 73 - 65" in 2584
replace byhand_manipadrsHP = "AV 2BN # 74N - 35" in 2586
replace byhand_manipadrsHP = "CL 73AN # 2A - 50" in 2588
replace byhand_manipadrsHP = "AV 2B5 # 72N - 51" in 2589

replace byhand_manipadrsHP = "CL 73CN # 2 - 27" in 2590
replace byhand_manipadrsHP = "CL 62N # 2F - 09" in 2592
replace byhand_manipadrsHP = "AV 2A5N # 75EN - 12" in 2593
replace byhand_manipadrsHP = "AV 2A5N # 75E - 12" in 2593
replace byhand_manipadrsHP = "AV 2N # 75N - 28" in 2594
replace byhand_manipadrsHP = "AV 2B2 # 73N Bis - 59" in 2595
replace byhand_manipadrsHP = "CL 84 # 3BN - 32E" in 2596
replace byhand_manipadrsHP = "CL 60 # 2DN - 95" in 2598
replace byhand_manipadrsHP = "CL 83 # 3BN - 90" in 2599
replace byhand_manipadrsHP = "CL 72JN # 8N - 34" in 2600
replace byhand_manipadrsHP = "AV 2 # 75NE - 35" in 2601
replace byhand_manipadrsHP = "CL 75CN # 2A Bis - 63" in 2602
replace byhand_manipadrsHP = "AV 2AN # 75H - 35" in 2603
replace byhand_manipadrsHP = "AV 2B1 # 73N Bis 4 - 65" in 2604
replace byhand_manipadrsHP = "AV 2B1 # 73N Bis 4 - 65" in 2605
replace byhand_manipadrsHP = "AV 2BN # 73N Bis - 59" in 2607
replace byhand_manipadrsHP = "CL 72AN # 3 - 50" in 2611
replace byhand_manipadrsHP = "KR 3AN # 71C - 26" in 2612
replace byhand_manipadrsHP = "AV 2BL # 73 Bis - 65" in 2613
replace byhand_manipadrsHP = "AV 2B2 # 74 - 34" in 2615
replace byhand_manipadrsHP = "AV 2N # 74AN - 27" in 2619
replace byhand_manipadrsHP = "CL 11 Bis O # S2B - 09" in 2620
replace byhand_manipadrsHP = "CL 11 Bis O # 52B - 09" in 2620
replace byhand_manipadrsHP = "KR 52 E O # 9A - 56" in 2628
replace byhand_manipadrsHP = "KR 52C # 9A - 42 O" in 2630
replace byhand_manipadrsHP = "CL 38 # 5 N" in 2662
replace byhand_manipadrsHP = "KR 3AN # 34N - 146" in 2663
replace byhand_manipadrsHP = "KR 3 N # 33N - 45B8 " in 2668
replace byhand_manipadrsHP = "KR 5 N # 38 - 30B1" in 2669
replace byhand_manipadrsHP = "KR 76 # 2A - 31" in 2685

replace byhand_manipadrsHP = "KR 73 # 3C - 08" in 2702
replace byhand_manipadrsHP = "KR 69 # 2C - 15" in 2718
replace byhand_manipadrsHP = "KR 73 # 2B - 35" in 2721
replace byhand_manipadrsHP = "CL 72B # 1A4 - 52" in 2734
replace byhand_manipadrsHP = "KR 73A # 1J - 82" in 2743
replace byhand_manipadrsHP = "CL 62AN # 2N - 68" in 2748
replace byhand_manipadrsHP = "CL 69 # 4AN - 52" in 2755
replace byhand_manipadrsHP = "CL 60 # 5N - 45" in 2756
replace byhand_manipadrsHP = "CL 62 # 4AN - 24" in 2757
replace byhand_manipadrsHP = "CL 71D # 3A1N - 08" in 2760
replace byhand_manipadrsHP = "CL 71D # 3A 1N - 08" in 2760
replace byhand_manipadrsHP = "CL 69 # 4AN - 60" in 2762
replace byhand_manipadrsHP = "CL 67 # 4AN - 74" in 2764
replace byhand_manipadrsHP = "CL 68 # 4AN - 26" in 2767
replace byhand_manipadrsHP = "KR 1 # 66 - 42" in 2770
replace byhand_manipadrsHP = "CL 71L # 3DN - 13" in 2779
replace byhand_manipadrsHP = "" in 2795
replace byhand_manipadrsHP = "CL 88 # 28E6 - 90" in 2796
replace byhand_manipadrsHP = "CL 125 # 28F - 55" in 2799
replace byhand_manipadrsHP = "KR 26D # 125 - CVC - 018" in 2803
replace byhand_manipadrsHP = "KR 26PN # 124 - 156" in 2810
replace byhand_manipadrsHP = "KR 26PN # 124 - 156" in 2811
replace byhand_manipadrsHP = "KR 27 DN # 122 - 70" in 2827
replace byhand_manipadrsHP = "KR 27BN # 123 - 75" in 2836
replace byhand_manipadrsHP = "KR 26R1 # 124 - 13" in 2837
replace byhand_manipadrsHP = "KR 26M4 # 124 - 60" in 2838
replace byhand_manipadrsHP = "KR 26I2 # 123 - 83" in 2847
replace byhand_manipadrsHP = "KR 27F # 1 - 23" in 2860
replace byhand_manipadrsHP = "KR 26M1 # 121 - 88" in 2867
replace byhand_manipadrsHP = "KR 26U # 123 - 27" in 2892
replace byhand_manipadrsHP = "CL 84N # 3BN - 45" in 2906
replace byhand_manipadrsHP = "CL 8H # 104" in 2925
replace byhand_manipadrsHP = "CL 84A # 1C5 Bis - 56" in 2927
replace byhand_manipadrsHP = "KR 14A Bis # 76 - 06" in 2931
replace byhand_manipadrsHP = "CL 72L # 3BN - 51" in 2934
replace byhand_manipadrsHP = "CL 84 # 1A5 Bis - 57" in 2937
replace byhand_manipadrsHP = "CL 84N # 1H - 16" in 2938
replace byhand_manipadrsHP = "KR 1A5 Bis # 83 - 39" in 2940
replace byhand_manipadrsHP = "CL 84 # 1KN - 04" in 2943
replace byhand_manipadrsHP = "KR 19 # 4B - 73A - 10" in 2944
replace byhand_manipadrsHP = "KR 1A8 # 73A - 88" in 2945
replace byhand_manipadrsHP = "KR 1A6 # 73 - 16" in 2946
replace byhand_manipadrsHP = "DG 1 # 77 - 52" in 2947
replace byhand_manipadrsHP = "KR 1B Bis # 76 - 11" in 2949
replace byhand_manipadrsHP = "CL 84 # 1CN - 72" in 2951
replace byhand_manipadrsHP = "CL 84 # 1 LN - 72" in 2952
replace byhand_manipadrsHP = "KR 1A 8 Bis # 76 - 77" in 2953
replace byhand_manipadrsHP = "KR 5 1A # 5A - 73 - 14" in 2954
replace byhand_manipadrsHP = "KR 1A 5A # 73 - 14" in 2954
replace byhand_manipadrsHP = "CL 85 # 1A 11 - 89" in 2955
replace byhand_manipadrsHP = "KR 1A 9 Bis # 76 - 28" in 2956
replace byhand_manipadrsHP = "KR 1 A 10 # 76 - 46" in 2957
replace byhand_manipadrsHP = "KR 1A 7 Bis # 73 - A" in 2958
replace byhand_manipadrsHP = "CL 73 2 N # 1A - 46" in 2960
replace byhand_manipadrsHP = "KR 2 Bis # 23A - 36" in 2961
replace byhand_manipadrsHP = "KR 1A8 Bis # 76 - 77" in 2953
replace byhand_manipadrsHP = "KR 1A5A # 73 - 14" in 2954
replace byhand_manipadrsHP = "CL 84 # 1KN - 04" in 2972
replace byhand_manipadrsHP = "CL 84 # 1LN - 26" in 2973
replace byhand_manipadrsHP = "KR 1A4D # 76 - 06" in 2975
replace byhand_manipadrsHP = "KR 1A4D Bis # 76 - 40" in 2976
replace byhand_manipadrsHP = "CL 841D # 83 - 05" in 2980
replace byhand_manipadrsHP = "KR 10 # 73A - 53" in 2981
replace byhand_manipadrsHP = "KR 1ASF # 73A - 04" in 2983
replace byhand_manipadrsHP = "KR 14 5F # 73A - 04" in 2984
replace byhand_manipadrsHP = "CL 72B # 28E - 34" in 2988
replace byhand_manipadrsHP = "DG 71B # 26 - 40" in 3002
replace byhand_manipadrsHP = "KR 284 # 72Z3 - 21" in 3005
replace byhand_manipadrsHP = "CL 72I # 28J - 72" in 3008
replace byhand_manipadrsHP = "CR 25A # 124 - 45" in 3009
replace byhand_manipadrsHP = "CL 72B # 28D3 - 39" in 3010

replace byhand_manipadrsHP = "TV 72F # 28D1 - 24" in 3018
replace byhand_manipadrsHP = "CL 72B # 28D3 - 91" in 3025
replace byhand_manipadrsHP = "KR 28A # 1 - 72W - 52" in 3028
replace byhand_manipadrsHP = "KR 72C # 28D3 - 15" in 3038
replace byhand_manipadrsHP = "CL 72F5 # 28D3 - 22" in 3041
replace byhand_manipadrsHP = "CL 72 # 28D - 315" in 3047
replace byhand_manipadrsHP = "DG 28ND1 # 72F - 24" in 3048
replace byhand_manipadrsHP = "CL 71BN # 28D3 - 119" in 3053
replace byhand_manipadrsHP = "CL 72C # 28D3 - 99" in 3054
replace byhand_manipadrsHP = "CL 72F6 # 28EJ - 5" in 3055
replace byhand_manipadrsHP = "KR 28D4 # 72 - 22" in 3065
replace byhand_manipadrsHP = "CL 73B1 # 26A - 28" in 3078
replace byhand_manipadrsHP = "CL 72G # 28D3 - 47" in 3079
replace byhand_manipadrsHP = "CL 72F3 # 28E - 84" in 3090
replace byhand_manipadrsHP = "KR 28D2 # 73P - 73" in 3104
replace byhand_manipadrsHP = "CL 72F3 # 28D3 - 35" in 3111
replace byhand_manipadrsHP = "CL 72F5 # 28E - 44" in 3114
replace byhand_manipadrsHP = "CL 72F # 28E - 65" in 3118
replace byhand_manipadrsHP = "CL 72F2 # 28F - 29" in 3119
replace byhand_manipadrsHP = "CL 72F3 # 28D3 - 03" in 3128
replace byhand_manipadrsHP = "KR 26I # 70 - 49" in 3132
replace byhand_manipadrsHP = "CL 28 # 3 - 35" in 3133
replace byhand_manipadrsHP = "CL 72F4 # 28E - 12" in 3135
replace byhand_manipadrsHP = "CL 72F4 N # 28E - 44" in 3136
replace byhand_manipadrsHP = "KR 28C3 # 129A - 20" in 3143
replace byhand_manipadrsHP = "KR 54 O # 12 - 07" in 3155
replace byhand_manipadrsHP = "CL 70 # 28D - 60" in 3156
replace byhand_manipadrsHP = "DG 28D2 # 72A - 60" in 3164
replace byhand_manipadrsHP = "CL 70" in 3166
replace byhand_manipadrsHP = "KR 72U # 42 - 14" in 3176
replace byhand_manipadrsHP = "CL 72H Bis # 28E - 26" in 3199
replace byhand_manipadrsHP = "CL 72H Bis # 28E - 54" in 3200
replace byhand_manipadrsHP = "TV 28 # 72E2 - 50" in 3203
replace byhand_manipadrsHP = "CL 72F4 # 28E - 29" in 3207
replace byhand_manipadrsHP = "KR 28D # 71A - 57" in 3210
replace byhand_manipadrsHP = "CL 71 3 # 11 - 101" in 3211
replace byhand_manipadrsHP = "DG 26P8 # 83 - 25" in 3212
replace byhand_manipadrsHP = "CL 71 - 3 # 11 - 101" in 3211
replace byhand_manipadrsHP = "CL 72F1 # 28E - 42" in 3216
replace byhand_manipadrsHP = "CL 3 # 80 - 46" in 3221
replace byhand_manipadrsHP = "CL 72 # 28 - B70" in 3222
replace byhand_manipadrsHP = "KR 28B # 72 - 48" in 3225
replace byhand_manipadrsHP = "CL 72F2 # 28D3 - 69" in 3227
replace byhand_manipadrsHP = "CL 72U # 26I2 - 44" in 3250
replace byhand_manipadrsHP = "KR 28D1 # 72W" in 3251
replace byhand_manipadrsHP = "CL 72F2 # 28D3 - 02" in 3258
replace byhand_manipadrsHP = "CL 72 Bis # 28 - 21" in 3262
replace byhand_manipadrsHP = "CL 72F2 # 28D3 - 22" in 3263
replace byhand_manipadrsHP = "CL 70 # 26D - 10" in 3265
replace byhand_manipadrsHP = "CL 70 # 26D - 10" in 3266
replace byhand_manipadrsHP = "DG 26P6 # 87 - 17" in 3282
replace byhand_manipadrsHP = "CL 72F1 # 28 E - 16" in 3283
replace byhand_manipadrsHP = "CL 72F1 # 28D3 - 17" in 3284
replace byhand_manipadrsHP = "KR 28D6 # 72 - 35" in 3298
replace byhand_manipadrsHP = "CL 72F # 28E - 25" in 3302
replace byhand_manipadrsHP = "CL 72F # 28E - 25" in 3303
replace byhand_manipadrsHP = "KR 28E Bis # 72F4 - 21" in 3305
replace byhand_manipadrsHP = "CL 9C NR # 143 - 41" in 3312
replace byhand_manipadrsHP = "KR 50 # 5 - 173" in 3326
replace byhand_manipadrsHP = "KR 81AN # 42 - 25" in 3352
replace byhand_manipadrsHP = "KR 83B2 # 42A - 40" in 3354
replace byhand_manipadrsHP = "CL 48 Bis" in 3364

replace byhand_manipadrsHP = "KR 85C1 # 54B - 27" in 3374
replace byhand_manipadrsHP = "KR 51 O # 8D - 34" in 3377
replace byhand_manipadrsHP = "KR 85AnN# 45 - 31" in 3392
replace byhand_manipadrsHP = "KR 85AN# 45 - 31" in 3392
replace byhand_manipadrsHP = "KR 85E # 4B - 86" in 3395
replace byhand_manipadrsHP = "KR 82AN # 45 - 59" in 3426
replace byhand_manipadrsHP = "KR 85C1 # 55B - 27" in 3440
replace byhand_manipadrsHP = "KR 83CE # 46 - 24" in 3441
replace byhand_manipadrsHP = "KR 83E # 42 - 71" in 3446
replace byhand_manipadrsHP = "KR 85B # 43" in 3447
replace byhand_manipadrsHP = "CL 28 # 85C - 30" in 3449
replace byhand_manipadrsHP = "KR 82A # 45 - 01" in 3450
replace byhand_manipadrsHP = "KR 83B3 # 45 - 87" in 3458

replace byhand_manipadrsHP = "KR 83B3 # 45 - 87" in 3458
replace byhand_manipadrsHP = "KR 83A # 45 - 23" in 3469
replace byhand_manipadrsHP = "CL 42 # 95A - 15" in 3471
replace byhand_manipadrsHP = "CL 45 # 45 - 83D - 37" in 3480
replace byhand_manipadrsHP = "CL 95 # 83D - 37" in 3482
replace byhand_manipadrsHP = "CL 46 # 83B1 - 30" in 3485
replace byhand_manipadrsHP = "KR 83B1 # 48A - 23" in 3504
replace byhand_manipadrsHP = "KR 83B1 # 48A - 23" in 3505
replace byhand_manipadrsHP = "KR 83B2 # 42A - 40" in 3509
replace byhand_manipadrsHP = "KR 143 #" in 3531

replace byhand_manipadrsHP = "DG 51 # 11 - 77" in 3540
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, "DG L", " DG ",. )
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, "- O", " O ",. )
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, "An", "AN",. )
replace byhand_manipadrsHP = trim(byhand_manipadrsHP)
replace byhand_manipadrsHP = itrim(byhand_manipadrsHP)

replace byhand_manipadrsHP = "DG 51 # 11 - 77" in 3540
replace byhand_manipadrsHP = "KR 56 # 7 - 96 O" in 3544
replace byhand_manipadrsHP = "CL 18 # 61 - 29" in 3552
replace byhand_manipadrsHP = "CL 18AN # 55 - 96" in 3555
replace byhand_manipadrsHP = "KR 1A9n # 3A - 76" in 3568
replace byhand_manipadrsHP = "DG 51 # 9 - 46" in 3577
replace byhand_manipadrsHP = "CL 12C # 29A5 - 09" in 3583
replace byhand_manipadrsHP = "CL 9B # 29A - 22" in 3587
replace byhand_manipadrsHP = "KR 31 # 9B - 25" in 3594
replace byhand_manipadrsHP = "CL 49 # 13A - 23" in 3600
replace byhand_manipadrsHP = "KR 23 # 70C - 09" in 3647
replace byhand_manipadrsHP = "KR 23 # 70B - 03" in 3648

replace byhand_manipadrsHP = "KR 23 # 70B - 09" in 3656
replace byhand_manipadrsHP = "KR 25P # 72U - 22" in 3657

replace byhand_manipadrsHP = "DG 71AN" in 3659
replace byhand_manipadrsHP = "KR 25Q # 72U - 33" in 3661
replace byhand_manipadrsHP = "DG 71A # 23A" in 3662
replace byhand_manipadrsHP = "KR 23 # 70C - 09" in 3663
replace byhand_manipadrsHP = "KR 24 # 70 - 93" in 3665
replace byhand_manipadrsHP = "DG 70 # 23A - 41" in 3669
replace byhand_manipadrsHP = "" in 3671
replace byhand_manipadrsHP = "" in 3681

replace byhand_manipadrsHP = "KR 25 # 72U - 20" in 3683
replace byhand_manipadrsHP = "CL 2B14 # 61 - 85" in 3692
replace byhand_manipadrsHP = "CL 62B # 1A61 - 85" in 3693
replace byhand_manipadrsHP = "CL 62B # 1A - 98" in 3697
replace byhand_manipadrsHP = "CL 23 # 1A9 - 9 - 205" in 3698
replace byhand_manipadrsHP = "CL 62B # 1A9 - 205" in 3699
replace byhand_manipadrsHP = "CL 62B # 1A9 - 275" in 3701
replace byhand_manipadrsHP = "KR 1C1 # 68 - 11" in 3700
replace byhand_manipadrsHP = "CL 62B # 1A9 - 365 - 2B2" in 3702
replace byhand_manipadrsHP = "KR 1C3 # 64 - 12" in 3703
replace byhand_manipadrsHP = "CL 62B # 19 - 9 - 205" in 3705
replace byhand_manipadrsHP = "KR 1A # 1 - 24" in 3712
replace byhand_manipadrsHP = "CL 62B # 1A9 - 36" in 3714
replace byhand_manipadrsHP = "CL 62B # 1A9 - 205" in 3716
replace byhand_manipadrsHP = "CL 11 # 64C - 35" in 3720
replace byhand_manipadrsHP = "CL 62B # 1A9 - 80" in 3721
replace byhand_manipadrsHP = "CL 66 # 1A6 - 33" in 3722
replace byhand_manipadrsHP = "CL 62B # 1A9 - 80" in 3723
replace byhand_manipadrsHP = "KR 1B3 # 63 - 28" in 3724
replace byhand_manipadrsHP = "CL 62 # 1A6 - 185" in 3734
replace byhand_manipadrsHP = "CL 62B # 1-9 - 275" in 3741
replace byhand_manipadrsHP = "CL 62B # 1A - 27" in 3742
replace byhand_manipadrsHP = "CL 62 # 1A9 - 250" in 3748
replace byhand_manipadrsHP = "" in 3751
replace byhand_manipadrsHP = "CL 62B # 1A9 - 80" in 3755
replace byhand_manipadrsHP = "KR 1B2 # 64 - 21" in 3757
replace byhand_manipadrsHP = "KR 1C5 # 63 - 80" in 3759
replace byhand_manipadrsHP = "CL 62B # 1A9 - 75" in 3767
replace byhand_manipadrsHP = "CL 59 # 1 Bis - 35" in 3770
replace byhand_manipadrsHP = "AV 6B N # 35 - 34" in 3773
replace byhand_manipadrsHP = "" in 3774
replace byhand_manipadrsHP = "AV 6BN # 35 - 35" in 3776
replace byhand_manipadrsHP = "KR 26JTL # 351" in 3780
replace byhand_manipadrsHP = "KR 54 N # 32A - 81" in 3832
replace byhand_manipadrsHP = "KR 25 - 4 # 45 - 79" in 3834
replace byhand_manipadrsHP = "CL 59 # 58 - 17" in 3844
replace byhand_manipadrsHP = "CL 92 # 28D - 94" in 3845
replace byhand_manipadrsHP = "DG 66 # 33B - 35" in 3873
replace byhand_manipadrsHP = "KR 60 # 33B - 28" in 3874
replace byhand_manipadrsHP = "KR 71 # 45A - 172" in 3880
replace byhand_manipadrsHP = "KR 40A # 32A - 10" in 3890
replace byhand_manipadrsHP = "KR 101 # 12A Bis - 15" in 3898
replace byhand_manipadrsHP = "KR 7M1 # 92 - 46" in 3900
replace byhand_manipadrsHP = "KR 70 # 210" in 3925
replace byhand_manipadrsHP = "CL 54C # 41E3 - 54" in 3958

replace byhand_manipadrsHP = "KR 41BN # 45 - 81" in 3968
replace byhand_manipadrsHP = "KR 49B N # 56D - 37" in 3982

replace byhand_manipadrsHP = "CL 54 # 42C - 23" in 4000
replace byhand_manipadrsHP = "CL 47 # 49a - 89" in 4002
replace byhand_manipadrsHP = "KR 42A1 # 51 - 101" in 4007
replace byhand_manipadrsHP = "KR 45 # 48 - 47C" in 4013

replace byhand_manipadrsHP = "CL 57 # 47D - 14" in 4017
replace byhand_manipadrsHP = "KR 47 # 55C - 14" in 4019
replace byhand_manipadrsHP = "CL 56FI # 46B - 76" in 4024
replace byhand_manipadrsHP = "KR 49D # 56D - 58" in 4028
replace byhand_manipadrsHP = "KR 43 # 53 - 51" in 4046
replace byhand_manipadrsHP = "KR 48B # 51 - 40" in 4057
replace byhand_manipadrsHP = "KR 43B # 48A - 102" in 4070
replace byhand_manipadrsHP = "KR 47A # 56D - 60" in 4072
replace byhand_manipadrsHP = "CL 56J # 47D - 38" in 4078
replace byhand_manipadrsHP = "CL 47A N # 48C - 35" in 4083
replace byhand_manipadrsHP = "CL 56C # 43A - 75" in 4084

replace byhand_manipadrsHP = "CL 56C # 43A - 75" in 4085
replace byhand_manipadrsHP = "CL 56D N # 49A - 07" in 4090
replace byhand_manipadrsHP = "KR E2 # 55B - 93" in 4092
replace byhand_manipadrsHP = "CL 53 # 47D - 73" in 4095
replace byhand_manipadrsHP = "KR 52 # 49 - 54" in 4120
replace byhand_manipadrsHP = "KR 41E2 # 49 - 65" in 4121
replace byhand_manipadrsHP = "KR 43 # 48A - 28" in 4125
replace byhand_manipadrsHP = "KR 47 - 3 # 51 - 70" in 4130
replace byhand_manipadrsHP = "KR 42D1 # 49 - 42" in 4132
replace byhand_manipadrsHP = "CL 41 # 41E3 - 18" in 4136
replace byhand_manipadrsHP = "CL 54C # 49G - 06" in 4154
replace byhand_manipadrsHP = "KR 41E2 # 49 - 23" in 4158
replace byhand_manipadrsHP = "KR 41E27 # 48 - 76" in 4165
replace byhand_manipadrsHP = "KR 41E2 # 48 - 76" in 4165
replace byhand_manipadrsHP = "CL 56C # 47D - 97" in 4172
replace byhand_manipadrsHP = "CL 51 # 49 - 05" in 4179
replace byhand_manipadrsHP = "KR 42D1 # 48 - 48" in 4187
replace byhand_manipadrsHP = "KR 41E3 # 55B - 93" in 4198
replace byhand_manipadrsHP = "CL 55 # 41D2 - 8DL" in 4200
replace byhand_manipadrsHP = "KR 49 # 56 - 50" in 4212
replace byhand_manipadrsHP = "KR 41E3 # 52 - 16" in 4217
replace byhand_manipadrsHP = "KR 115 # 20 - 61" in 4224

replace byhand_manipadrsHP = "KR 103 # 12B - 106" in 4232
replace byhand_manipadrsHP = "KR 106 # 12B - 155" in 4261
replace byhand_manipadrsHP = "CL 73A2 # 3 N - 78" in 4277

replace byhand_manipadrsHP = "CL 60 # 2FN - 29" in 4278
replace byhand_manipadrsHP = "CL 7C # 2AN - 121" in 4281
replace byhand_manipadrsHP = "CL 59A N # 2AN - 29" in 4282
replace byhand_manipadrsHP = "CL 61AN # 2AN - 97" in 4283
replace byhand_manipadrsHP = "CL 70 # 2AN - 51" in 4284
replace byhand_manipadrsHP = "AV 66 # 2AN - 50" in 4285
replace byhand_manipadrsHP = "KR 23A # 101D - 12" in 4286
replace byhand_manipadrsHP = "KR 23A # 101D - 12" in 4287
replace byhand_manipadrsHP = "KR 23A # 101D - 12" in 4288
replace byhand_manipadrsHP = "CL 56 N # 2HN - 89" in 4290
replace byhand_manipadrsHP = "CL 73BN # 2A - 87" in 4292
replace byhand_manipadrsHP = "CL 62A # 2BN - 93" in 4293
replace byhand_manipadrsHP = "CL 52AN # 2EN - 95" in 4294
replace byhand_manipadrsHP = "CL 52AN # 2N - 95" in 4297
replace byhand_manipadrsHP = "AV 2A N # 75HN - 89" in 4298
replace byhand_manipadrsHP = "AV 2AN # 52 N - 75" in 4299
replace byhand_manipadrsHP = "CL 55BN # 2EN - 64" in 4305
replace byhand_manipadrsHP = "CL 61N # 2AN - 21" in 4306
replace byhand_manipadrsHP = "CL 70N # 2AN - 121" in 4307
replace byhand_manipadrsHP = "CL 55AN # 2AN - 107" in 4309
replace byhand_manipadrsHP = "CL 58 N # 2GN - 69" in 4313
replace byhand_manipadrsHP = "AV 2TN # 53DN - 05" in 4314
replace byhand_manipadrsHP = "AV 2E N # 53AN - 05" in 4315
replace byhand_manipadrsHP = "AV 2HN # 52A - 05" in 4317
replace byhand_manipadrsHP = "CL 74AN # 2A - 63" in 4319
replace byhand_manipadrsHP = "CL 59 # 2DN - 31" in 4321
replace byhand_manipadrsHP = "AV 2B1 # 73 N Bis - 65" in 4322
replace byhand_manipadrsHP = "AV 2B1 # 73N Bis - 65" in 4322
replace byhand_manipadrsHP = "CL 100C # 22B - 85" in 4323

replace byhand_manipadrsHP = "CL 106D # 20 - 85" in 4344

replace byhand_manipadrsHP = "CL 106D # 20 - 85" in 4344
replace byhand_manipadrsHP = "CL 100B # 22B - 31" in 4353
replace byhand_manipadrsHP = "CL 24M # 86 - 34" in 4364
replace byhand_manipadrsHP = "KR 24M # 86 - 34" in 4364
replace byhand_manipadrsHP = "CL 94A # 22A - 14" in 4368
replace byhand_manipadrsHP = "KR 83B1 # 45 - 87" in 4386
replace byhand_manipadrsHP = "CL 45 # 83B - 4N" in 4402
replace byhand_manipadrsHP = "CL 85 # 43B - 4N" in 4404
replace byhand_manipadrsHP = "KR 83C1 # 45 - 36" in 4418

replace byhand_manipadrsHP = "CL 30 # 3 - 75 - 59" in 4420
replace byhand_manipadrsHP = "CL 30 # 75 - 59" in 4420
replace byhand_manipadrsHP = "CL 26 # 83C - 40" in 4431
replace byhand_manipadrsHP = "CL 26 # 83C - 40" in 4432
replace byhand_manipadrsHP = "KR 83B1 # 45 - 60" in 4436

replace byhand_manipadrsHP = "CL 45 - 3 # 83D - 37" in 4441
replace byhand_manipadrsHP = "KR 26H5 # 125 - 28" in 4446
replace byhand_manipadrsHP = "CL 11 # 23 - 139" in 4475
replace byhand_manipadrsHP = "KR 26G2 # 122 - 40" in 4476
replace byhand_manipadrsHP = "KR 26G2 # 122 - 40" in 4477
replace byhand_manipadrsHP = "KR 26G2 # 122 - 04" in 4488
replace byhand_manipadrsHP = "KR 26G2 # 122 - 39" in 4492
replace byhand_manipadrsHP = "CL 103A # 23 Bis - 60" in 4500
replace byhand_manipadrsHP = "KR 26FB # 12 - 09" in 4506
replace byhand_manipadrsHP = "KR 26A Bis # 122R - 21" in 4512
replace byhand_manipadrsHP = "KR 26K1 # 122 - 94" in 4516
replace byhand_manipadrsHP = "CL 72K # 3N - 31" in 4524
replace byhand_manipadrsHP = "CL 72 # 3BN - 15" in 4527
replace byhand_manipadrsHP = "CL 72H # 2BN - 63" in 4528
replace byhand_manipadrsHP = "CL 75 # 3BN - 08" in 4529
replace byhand_manipadrsHP = "CL 77 # 3N - 42" in 4533
replace byhand_manipadrsHP = "CL 84 # 1IN - 22" in 4536
replace byhand_manipadrsHP = "KR 9 # 83F - 63" in 4537
replace byhand_manipadrsHP = "CL 72 E # 3BN - 91" in 4544
replace byhand_manipadrsHP = "CL 72 E # 3BN - 91" in 4545
replace byhand_manipadrsHP = "CL 72K # 3N - 27" in 4548
replace byhand_manipadrsHP = "CL 83A # 2 Bis N - 26" in 4551
replace byhand_manipadrsHP = "CL 82 # 2 Bis N - 26" in 4552
replace byhand_manipadrsHP = "CL 84 # 2A - 52B" in 4553
replace byhand_manipadrsHP = "CL 73 # 3BN - 39" in 4554
replace byhand_manipadrsHP = "CL 72K # 3AN - 19" in 4558
replace byhand_manipadrsHP = "CL 78 # 3BN - 20" in 4564
replace byhand_manipadrsHP = "CL 77 # 3N - 03" in 4566

replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, "- Bn", "BN",. )
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, " Bn", "BN",. )


replace byhand_manipadrsHP = "KR 1AB Bis # 73A - 70" in 4569
replace byhand_manipadrsHP = "KR 2 BN # 72J - 10" in 4571
replace byhand_manipadrsHP = "CL 76 # 2BN - 25" in 4573
replace byhand_manipadrsHP = "CL 76 # 2BN - 34" in 4574
replace byhand_manipadrsHP = "CL 72K # 3BN - 62" in 4575
replace byhand_manipadrsHP = "CL 72F # 2BN - 58" in 4576
replace byhand_manipadrsHP = "CL 72F # 2BN - 58" in 4577
replace byhand_manipadrsHP = "CL 72F # 2BN - 58" in 4578
replace byhand_manipadrsHP = "CL 7A # 2BN - 37" in 4579
replace byhand_manipadrsHP = "CL 7A # 2BN - 37" in 4580
replace byhand_manipadrsHP = "CL 70 # 3BN - 68" in 4583
replace byhand_manipadrsHP = "CL 82 # 2BN - 55" in 4585
replace byhand_manipadrsHP = "CL 73 # 8N - 31" in 4588
replace byhand_manipadrsHP = "CL 75 # 5N - 83" in 4589
replace byhand_manipadrsHP = "CL 72J # 8GN - 38" in 4590
replace byhand_manipadrsHP = "CL 72A2 # 03AN - 90" in 4594
replace byhand_manipadrsHP = "CL 75 # 2BN - 05" in 4595
replace byhand_manipadrsHP = "CL 71I # 2 - 33" in 4599
replace byhand_manipadrsHP = "CL 71I2 # 3 - 3" in 4599
replace byhand_manipadrsHP = "CL 72F # 3BN - 15" in 4601
replace byhand_manipadrsHP = "CL 72C # C3BN - 86" in 4602
replace byhand_manipadrsHP = "CL 75 # 2BN - 20" in 4605
replace byhand_manipadrsHP = "CL 84 # 3BN - 42" in 4606
replace byhand_manipadrsHP = "CL 72G # 2BN - 75" in 4607
replace byhand_manipadrsHP = "KR 3FN # 70 - 50" in 4608
replace byhand_manipadrsHP = "CL 83A # 3B - 16" in 4609
replace byhand_manipadrsHP = "CL 83A # 3B - 16" in 4610
replace byhand_manipadrsHP = "CL 72C # 14N - 18" in 4611
replace byhand_manipadrsHP = "CL 79 # 2BN - 37" in 4614
replace byhand_manipadrsHP = "CL 79 # 2BN - 37" in 4616
replace byhand_manipadrsHP = "CL 75 # 3BN - 83" in 4618
replace byhand_manipadrsHP = "CL 7 - 2DN # 4N - 27" in 4621
replace byhand_manipadrsHP = "CL 73 # 3BN - 78" in 4631
replace byhand_manipadrsHP = "CL 81 # 2AN - 08" in 4634
replace byhand_manipadrsHP = "CL 72I # 3BN - 31" in 4638
replace byhand_manipadrsHP = "CL 72L # 2BN - 55" in 4640

replace byhand_manipadrsHP = "CL 74 # 2BN - 72" in 4646
replace byhand_manipadrsHP = "CL 76 # 3N - 28" in 4647
replace byhand_manipadrsHP = "CL 71I1 # 3AN - 29" in 4650
replace byhand_manipadrsHP = "CL 71H # 3EN - 10" in 4651

replace byhand_manipadrsHP = "CL 79 # 3BN - 22" in 4656
replace byhand_manipadrsHP = "CL 74 # 8N - 36" in 4658
replace byhand_manipadrsHP = "CL 72F # 3AN - 35" in 4660
replace byhand_manipadrsHP = "CL 71C # 3C N - 48" in 4663
replace byhand_manipadrsHP = "CL 83A # 3AN - 32" in 4664
replace byhand_manipadrsHP = "CL 72F # 3BN - 47" in 4667
replace byhand_manipadrsHP = "CL 84B # 3BN - 45" in 4669
replace byhand_manipadrsHP = "CL 84B # 12" in 4670
replace byhand_manipadrsHP = "CL 78 # 3BN - 50" in 4672
replace byhand_manipadrsHP = "CL 72 # 3N - 60" in 4676
replace byhand_manipadrsHP = "CL 46 # 3BN - 38" in 4681
replace byhand_manipadrsHP = "CL 72C # 4N - 34" in 4682
replace byhand_manipadrsHP = "CL 70A # 4CN - 24" in 4684
replace byhand_manipadrsHP = "CL 80 # 3BN - 27" in 4685
replace byhand_manipadrsHP = "CL 82 # 8 N - 56" in 4686
replace byhand_manipadrsHP = "CL 83A # 4N - 19" in 4687
replace byhand_manipadrsHP = "CL 78 # 3BN - 32" in 4691

replace byhand_manipadrsHP = "CL 78 # 3BN - 32" in 4692
replace byhand_manipadrsHP = "KR 3 EN # 70 - 90" in 4693
replace byhand_manipadrsHP = "CL 72 E # 2BN - 74" in 4694
replace byhand_manipadrsHP = "CL 72 E # 2BN - 74" in 4695
replace byhand_manipadrsHP = "CL 72 # 2BN - 79" in 4698
replace byhand_manipadrsHP = "CL 72C # 13BN - 43" in 4699
replace byhand_manipadrsHP = "CL 84 # 2BN - 45" in 4700
replace byhand_manipadrsHP = "KR 83 # 3AN - 15" in 4704
replace byhand_manipadrsHP = "CL 71 E # 3BN - 17" in 4708
replace byhand_manipadrsHP = "KR 1H N # 82 - 58" in 4713
replace byhand_manipadrsHP = "CL 72F # 3BN - 39" in 4715
replace byhand_manipadrsHP = "CL 79 # 4 N - 75" in 4725
replace byhand_manipadrsHP = "CL 72L # 3AN - 54" in 4728
replace byhand_manipadrsHP = "CL 83A # 3BN - 05" in 4735
replace byhand_manipadrsHP = "CL 74CN # 2 - 55" in 4736
replace byhand_manipadrsHP = "CL 75 # 3BN - 32" in 4738
replace byhand_manipadrsHP = "CL 72J # 3BN - 91" in 4739
replace byhand_manipadrsHP = "CL 77 # 3AN - 63" in 4742
replace byhand_manipadrsHP = "CL 82 # 5N - 02" in 4743
replace byhand_manipadrsHP = "CL 72 E # 2BN - 87" in 4747
replace byhand_manipadrsHP = "CL 70 # 3BN - 68" in 4755
replace byhand_manipadrsHP = "CL 70 # 3BN - 68" in 4756
replace byhand_manipadrsHP = "CL 72A2 # 3AN - 72" in 4758
replace byhand_manipadrsHP = "CL 84 # 4 N - 10" in 4759
replace byhand_manipadrsHP = "CL 73 N # 2B - 03" in 4763

replace byhand_manipadrsHP = "CL 82 # 2AN - 05" in 4764
replace byhand_manipadrsHP = "CL 72K # 3BN - 67" in 4767
replace byhand_manipadrsHP = "CL 79 # 3BN - 40" in 4768
replace byhand_manipadrsHP = "CL 76 # 3AN - 25" in 4769
replace byhand_manipadrsHP = "CL 83 CN # 4N - 55" in 4774
replace byhand_manipadrsHP = "CL 83A # 3BN - 89" in 4784
replace byhand_manipadrsHP = "CL 72 # 2BN - 51" in 4789
replace byhand_manipadrsHP = "CL 72 # 2BN - 51" in 4790
replace byhand_manipadrsHP = "CL 38A # 3BN - 71" in 4793
replace byhand_manipadrsHP = "CL 83D # 8N - 45" in 4798
replace byhand_manipadrsHP = "CL 72AN # 03 - 62" in 4800
replace byhand_manipadrsHP = "CL 72J # 3BN - 74" in 4802
replace byhand_manipadrsHP = "CL 80 # 3BN - 45" in 4803
replace byhand_manipadrsHP = "CL 72 # 3BN - 43" in 4805
replace byhand_manipadrsHP = "KR 73 # 2C - 90" in 4806
replace byhand_manipadrsHP = "CL 82 # 3BN - 76" in 4807
replace byhand_manipadrsHP = "AV 2A3 # 75C - 115" in 4809
replace byhand_manipadrsHP = "CL 84 # 3AN - 42" in 4810
replace byhand_manipadrsHP = "CL 75 # 2BN - 56" in 4813
replace byhand_manipadrsHP = "CL 83F1 # 9 - 133" in 4815
replace byhand_manipadrsHP = "CL 79 # 2BN - 25" in 4819
replace byhand_manipadrsHP = "CL 76 # 4 N - 65" in 4821
replace byhand_manipadrsHP = "CL 77 # 3A - 39" in 4824
replace byhand_manipadrsHP = "KR 3A1 N # 71D - 17" in 4827
replace byhand_manipadrsHP = "CL 84N # 2AN - 46" in 4828
replace byhand_manipadrsHP = "CL 70 N # 5N - 43" in 4830
replace byhand_manipadrsHP = "CL 72 N # 8N - 38" in 4831
replace byhand_manipadrsHP = "CL 80 # 2BN - 09" in 4834
replace byhand_manipadrsHP = "CL 72B # 3AN - 53" in 4839
replace byhand_manipadrsHP = "KR 28A # 10A - 27" in 4870
replace byhand_manipadrsHP = "CL 10N # 29A - 09" in 4871
replace byhand_manipadrsHP = "C 32 # 13 - 50" in 4873
replace byhand_manipadrsHP = "KR 32 # 13 - 50" in 4873
replace byhand_manipadrsHP = "KR 12C # 3 - 29B - 115" in 4874
replace byhand_manipadrsHP = "CL 12B # 42A - 32" in 4875
replace byhand_manipadrsHP = "KR 25 # 14 - 38" in 4878
replace byhand_manipadrsHP = "KR 29A5 # 12B - 41" in 4879
replace byhand_manipadrsHP = "CL 12 # 29B - 72" in 4880
replace byhand_manipadrsHP = "KR 33A # 10A - 60" in 4885

replace byhand_manipadrsHP = "CL 102 # 23B - 10" in 4923
replace byhand_manipadrsHP = "CL 102E # 23B - 57" in 4927
replace byhand_manipadrsHP = "CL 101D # 24B - 51" in 4933
replace byhand_manipadrsHP = "KR 4C N # 72B - 18" in 4947
replace byhand_manipadrsHP = "CL 102H24 # 13 - 19" in 4950
replace byhand_manipadrsHP = "CL 102B # 22B - 69" in 4964
replace byhand_manipadrsHP = "CL 124 # 26I3 - 40" in 4973
replace byhand_manipadrsHP = "CL 101B # 22B - 10" in 4988
replace byhand_manipadrsHP = "CL 101B # 22B - 10" in 4989
replace byhand_manipadrsHP = "" in 4995
replace byhand_manipadrsHP = "" in 4996
replace byhand_manipadrsHP = "CL 10 O # 24C - 100" in 5002
replace byhand_manipadrsHP = "KR 31A # 14C - 47" in 5016
replace byhand_manipadrsHP = "CL 15 # 36B" in 5029
replace byhand_manipadrsHP = "CL 15A # 39A - 61" in 5032
replace byhand_manipadrsHP = "KR 3 # 13B - 96" in 5050
replace byhand_manipadrsHP = "CL 18 # 38A - 26" in 5084

replace byhand_manipadrsHP = "CL 18 # 38A - 26" in 5085
replace byhand_manipadrsHP = "KR 38 # 18 - 36" in 5093
replace byhand_manipadrsHP = "CL 14 # 37A - 49" in 5094
replace byhand_manipadrsHP = "CL 35AN # 2AN - 107" in 5095
replace byhand_manipadrsHP = "CL 7 # 31 - 41 - 180" in 5137
replace byhand_manipadrsHP = "KR 1D # 56 - 123" in 5140
replace byhand_manipadrsHP = "KR 53 # 11A - 47" in 5194

replace byhand_manipadrsHP = "KR 40A # 12B - 77" in 5196
replace byhand_manipadrsHP = "KR 102 # 24B - 28" in 5215
replace byhand_manipadrsHP = "CL 122A # 26I3" in 5267
replace byhand_manipadrsHP = "KR 26K2 # 124 - 39" in 5273
replace byhand_manipadrsHP = "KR 26S3 # 124 - 47" in 5281
replace byhand_manipadrsHP = "CL 101C N # 22B - 62" in 5286
replace byhand_manipadrsHP = "KR 26I2 # 122 - 04" in 5293
replace byhand_manipadrsHP = "CL 94 # 20A - 98" in 5300
replace byhand_manipadrsHP = "KR 26 IG # 124 - 40" in 5304
replace byhand_manipadrsHP = "CL 23 # 114" in 5316
replace byhand_manipadrsHP = "KR 26M1 # 122 - 29" in 5317
replace byhand_manipadrsHP = "CL 120 # 26B - 210" in 5318
replace byhand_manipadrsHP = "CL 120 # 22 - 15" in 5325
replace byhand_manipadrsHP = "CL 122 # 2H - 06" in 5329
replace byhand_manipadrsHP = "KR 26G2 # 121 - 57" in 5331
replace byhand_manipadrsHP = "KR 26E # 124 - 52" in 5335
replace byhand_manipadrsHP = "KR 27D72 # 121 - 48" in 5342
replace byhand_manipadrsHP = "KR 27D # 121 - 48" in 5342
replace byhand_manipadrsHP = "CL 109Q # 79Q - 10" in 5345
replace byhand_manipadrsHP = "KR 28D3 # 120B - 33" in 5348
replace byhand_manipadrsHP = "CL 50 # 28F - 65" in 5363
replace byhand_manipadrsHP = "CL 46 # 28D - 113" in 5364
replace byhand_manipadrsHP = "CL 52 # 28E - 72" in 5365
replace byhand_manipadrsHP = "CL 48 # 28G - 50" in 5369
replace byhand_manipadrsHP = "" in 5392
replace byhand_manipadrsHP = "CL 52 # 28D - 45" in 5415
replace byhand_manipadrsHP = "CL 54 # 28 E - 66" in 5433
replace byhand_manipadrsHP = "DG 28D # 33 - 645" in 5438
replace byhand_manipadrsHP = "CL 44 # 29 - 69" in 5439
replace byhand_manipadrsHP = "TV 33 E # 29 - 35" in 5440
replace byhand_manipadrsHP = "TV 33 # 28 E - 39" in 5441


replace byhand_manipadrsHP = "TV 29 # 28D - 09" in 5442
replace byhand_manipadrsHP = "DG 29B # 33G - 51" in 5444
replace byhand_manipadrsHP = "DG 28D # 33G - 54" in 5445
replace byhand_manipadrsHP = "DG 28D # 33 - E79" in 5448
replace byhand_manipadrsHP = "DG 28D # 33E - 79" in 5448
replace byhand_manipadrsHP = "DG 28E # 29 - 42" in 5449
replace byhand_manipadrsHP = "CL 44 # 33G - 64" in 5450
replace byhand_manipadrsHP = "DG 29A # 30 - 18" in 5451
replace byhand_manipadrsHP = "DG 28E # 33 - E09" in 5452
replace byhand_manipadrsHP = "DG 28E # 33E - 09" in 5452
replace byhand_manipadrsHP = "TV 33E # 28B - 04" in 5458
replace byhand_manipadrsHP = "DG 29 # 30 - 35" in 5459
replace byhand_manipadrsHP = "DG 29 # 30 - 33" in 5460
replace byhand_manipadrsHP = "DG 29B # 50 - 44" in 5461
replace byhand_manipadrsHP = "DG 29 # 30 - 33" in 5462
replace byhand_manipadrsHP = "TV 33G # 28D - 33" in 5463
replace byhand_manipadrsHP = "DG 29B # 33E - 12" in 5466
replace byhand_manipadrsHP = "DG 28 # 33E - 24" in 5467
replace byhand_manipadrsHP = "CL 44 # 33E - 49" in 5468
replace byhand_manipadrsHP = "TV 33E # 28D - 34" in 5470
replace byhand_manipadrsHP = "DG 29 # 33E - 25" in 5472
replace byhand_manipadrsHP = "DG 29 # 33E - 25" in 5473
replace byhand_manipadrsHP = "TV 33E # 28 - 29" in 5475
replace byhand_manipadrsHP = "DG 28 E # 29 - 48" in 5476
replace byhand_manipadrsHP = "DG 28E  # 29 - 48" in 5477
replace byhand_manipadrsHP = "AV 10 N # 54 - 136" in 5480
replace byhand_manipadrsHP = "AV 8N # 52 - 81 - 85" in 5484
replace byhand_manipadrsHP = "CL 51N # 9N - 18" in 5489
replace byhand_manipadrsHP = "AV 10 N # 54 N - 134" in 5491
replace byhand_manipadrsHP = "CL 51 N # 9N - 18" in 5489
replace byhand_manipadrsHP = "AV 9 N # 46N -  20" in 5497
replace byhand_manipadrsHP = "AV 9 N # 46N - 20" in 5497
replace byhand_manipadrsHP = "CL 46C # 7N - 66" in 5499
replace byhand_manipadrsHP = "KR 4C # 65B - 13" in 5500
replace byhand_manipadrsHP = "CL 49 N # 8AN - 52" in 5504
replace byhand_manipadrsHP = "AV 9 N # 51 - 76" in 5507
replace dir_res_ = "AV 6 # 29 - 71" in 5527
replace dir_res_ = "CL 6 # 29 - 71" in 5527
replace byhand_manipadrsHP = "KR 29 # 28D - D07" in 5542
replace byhand_manipadrsHP = "KR 29 # 28D - 07" in 5542
replace byhand_manipadrsHP = "DG 65 # 8 - 28" in 5552
replace byhand_manipadrsHP = "CL 9 O # 51A - 19" in 5557
replace byhand_manipadrsHP = "CL 29 # 39A - 28" in 5571
replace byhand_manipadrsHP = "KR 29 # 75 - 36" in 5606
replace byhand_manipadrsHP = "KR 29 # 36 - 75" in 5606
replace byhand_manipadrsHP = "CL 42 # 42 - 33A - 12" in 5629
replace byhand_manipadrsHP = "KR 30A # 39 - 11" in 5631

replace byhand_manipadrsHP = "KR 28-1 # 72W - 27" in 5654
replace byhand_manipadrsHP = "CL 42B # 32B - 14" in 5664
replace byhand_manipadrsHP = "CL 36 # 30 - 25" in 5667
replace byhand_manipadrsHP = "DG # 72B - 31" in 5674
replace byhand_manipadrsHP = "CL 72F2 Bis # 28F - 40" in 5676
replace byhand_manipadrsHP = "Cl 41 # 33 - 19" in 5700
replace byhand_manipadrsHP = "KR 33B # 41 - 27" in 5701
replace byhand_manipadrsHP = "KR 29 # 39" in 5702
replace byhand_manipadrsHP = "KR 29A # 38 - 89" in 5709
replace byhand_manipadrsHP = "KR 28 # 72T - 122" in 5750

replace byhand_manipadrsHP = "" in 5753
replace byhand_manipadrsHP = "CL 37 # 34 - 58" in 5754
replace byhand_manipadrsHP = "KR 33A # 38 - 83" in 5762
replace byhand_manipadrsHP = "KR 16A # 13A - 04" in 5797
replace byhand_manipadrsHP = "KR 28C # 4 - 28 - 48" in 5808
replace byhand_manipadrsHP = "KR 1A11 # 71 - 51" in 5832
replace byhand_manipadrsHP = "KR 40B # 13A - 34A" in 5839

replace byhand_manipadrsHP = "CL 16 # 42A - 29" in 5840
replace byhand_manipadrsHP = "KR 43 # 14A - 12" in 5851
replace byhand_manipadrsHP = "KR 43A # 13C - 80" in 5854
replace byhand_manipadrsHP = "CL 15B # 41B - 49" in 5896
replace byhand_manipadrsHP = "KR 40 # 13C - 88" in 5915
replace byhand_manipadrsHP = "KR 43A # 13B - 46" in 5928
replace byhand_manipadrsHP = "CL 16 # 41C - 24" in 5931
replace byhand_manipadrsHP = "CL 15A # 41A - 24" in 5937
replace byhand_manipadrsHP = "KR 1 # 43 - 14 - 76" in 5941
replace byhand_manipadrsHP = "KR 43 # 14 - 76" in 5941
replace byhand_manipadrsHP = "KR 46B # 14A - 20" in 5951
replace byhand_manipadrsHP = "KR 46B # 14A - 20" in 5952
replace byhand_manipadrsHP = "KR 42A # 14B - 30" in 5959
replace byhand_manipadrsHP = "CL 60 # 4D Bis - 47" in 5963
replace byhand_manipadrsHP = "CL 62A # 2E1 - 26" in 5968
replace byhand_manipadrsHP = "CL 64 # 5B" in 5971
replace byhand_manipadrsHP = "CL 58B # 4D - 10" in 5978
replace byhand_manipadrsHP = "KR 4E # 52A - 65" in 5980
replace byhand_manipadrsHP = "CL 64 # 5B - 183" in 5982
replace byhand_manipadrsHP = "KR 1D1 # 61A - 55" in 5983
replace byhand_manipadrsHP = "KR 89 # 18 - 72" in 5985
replace byhand_manipadrsHP = "KR 89 # 18 - 72" in 5998
replace byhand_manipadrsHP = "KR 84 # 15 - 10" in 6011
replace byhand_manipadrsHP = "KR 29B3 # 27 - 56" in 6026

replace byhand_manipadrsHP = "KR 30 # 26B - 63" in 6038
replace byhand_manipadrsHP = "KR 29A # 26B - 108" in 6042
replace byhand_manipadrsHP = "KR 29A # 26B - 108" in 6043
replace byhand_manipadrsHP = "KR 29 # 26B - 87" in 6050
replace byhand_manipadrsHP = "CL 27 # 30 - 20" in 6054
replace byhand_manipadrsHP = "CL 29 # 36H - 18" in 6058
replace byhand_manipadrsHP = "KR 30 # 26B - 68" in 6059
replace byhand_manipadrsHP = "KR 32B # 26B - 89" in 6066
replace byhand_manipadrsHP = "KR 31A # 26B - 62" in 6079
replace byhand_manipadrsHP = "CL 5 # 1DN - 24" in 6081

replace byhand_manipadrsHP = "KR 35 # 27 - 87" in 6097
replace byhand_manipadrsHP = "CL 29 # 30A - 35" in 6106
replace byhand_manipadrsHP = "KR 33 N # 26B - 123" in 6116
replace byhand_manipadrsHP = "KR 32 # 26B - 49" in 6148
replace byhand_manipadrsHP = "CL 2 # 92A - 01" in 6165
replace byhand_manipadrsHP = "KR 28 # 26B - 19" in 6190
replace byhand_manipadrsHP = "KR 96 # 1A - 161" in 6204
replace byhand_manipadrsHP = "KR 94A1 # 1 - 94" in 6218
replace byhand_manipadrsHP = "CL 1A7C # 4 - 43" in 6221
replace byhand_manipadrsHP = "KR 94 # 2 O 1B - 03" in 6222
replace byhand_manipadrsHP = "KR 94 # 2 O - 1B - 03" in 6222
replace byhand_manipadrsHP = "KR 2B # 40A - 75" in 6235
replace byhand_manipadrsHP = "KR 39 # 1 - 24" in 6242
replace byhand_manipadrsHP = "KR 49C1 # 7 - 26" in 6251
replace byhand_manipadrsHP = "45 # 2 - 40" in 6262
replace byhand_manipadrsHP = "KR 45 # 2 - 40" in 6262
replace byhand_manipadrsHP = "CL 1A # 42 - 55" in 6265
replace byhand_manipadrsHP = "KR 40 -3  # 40 - 12" in 6280
replace byhand_manipadrsHP = "KR 47C" in 6284
replace byhand_manipadrsHP = "CL 66B # 404C" in 6285
replace byhand_manipadrsHP = "CL 13A # 66B - 60" in 6316
replace byhand_manipadrsHP = "KR 62B # 14 3 - 65" in 6317
replace byhand_manipadrsHP = "KR 64A # 14 - 28" in 6326
replace byhand_manipadrsHP = "KR 64A # 14C - 71" in 6369
replace byhand_manipadrsHP = "KR 64A # 14C - 71" in 6370
replace byhand_manipadrsHP = "CL 12 # 65A - 45" in 6378
replace byhand_manipadrsHP = "KR 64A # 14 - 75" in 6380

replace byhand_manipadrsHP = "KR 42B Bis # 54C - 94" in 6403
replace byhand_manipadrsHP = "KR 55C N # 49F - 21" in 6407
replace byhand_manipadrsHP = "KR 50 N # 55C - 03" in 6411
replace byhand_manipadrsHP = "KR 50 N # 55C - 03B" in 6412
replace byhand_manipadrsHP = "KR 56 E # 48B - 45" in 6414
replace byhand_manipadrsHP = "CL 56D # 49B - 30" in 6418
replace byhand_manipadrsHP = "KR 49H # 56I - 22" in 6423
replace byhand_manipadrsHP = "KR 42E1 # 54 - 53" in 6427
replace byhand_manipadrsHP = "KR 45 # 56E - 56" in 6421
replace byhand_manipadrsHP = "KR 45A # 56F1 - 30" in 6428
replace byhand_manipadrsHP = "CL 56I N # 49G - 08" in 6430
replace byhand_manipadrsHP = "CL 56I # 49G - 08" in 6430
replace byhand_manipadrsHP = "KR 47B # 56D - 1" in 6432
replace byhand_manipadrsHP = "KR 47A # 56D - 44" in 6439
replace byhand_manipadrsHP = "CL 56C # 49G50" in 6444
replace byhand_manipadrsHP = "CL 56C # 49G - 50" in 6444
replace byhand_manipadrsHP = "KR 42C2 # 56C - 16" in 6448
replace byhand_manipadrsHP = "KR 46A # 56G - 76" in 6450
replace byhand_manipadrsHP = "KR 49 # 55A - 73" in 6452
replace byhand_manipadrsHP = "CL 125 # 26H - 215" in 6453
replace byhand_manipadrsHP = "CL 56E # 42C2 - 56" in 6457
replace byhand_manipadrsHP = "CL 56C # 47B - 36" in 6461
replace byhand_manipadrsHP = "KR 43 # 56E - 46" in 6467
replace byhand_manipadrsHP = "CL 72 # 4N - 55" in 6475
replace byhand_manipadrsHP = "CL 56D N # 49D - 07" in 6476
replace byhand_manipadrsHP = "CL 56 # 49A - 02" in 6481
replace byhand_manipadrsHP = "CL 54 # 43C - 36" in 6490
replace byhand_manipadrsHP = "KR 50 # 55C - 03" in 6491
replace byhand_manipadrsHP = "CL 7W # 28A - 07" in 6492
replace byhand_manipadrsHP = "KR 48B # 56H - 16" in 6493
replace byhand_manipadrsHP = "KR 43 # 56E - 40" in 6494
replace byhand_manipadrsHP = "CL 56 N # 48B - 26" in 6495
replace byhand_manipadrsHP = "KR 48B N # 56I - 50" in 6497
replace byhand_manipadrsHP = "KR 56F1 # 47D - 61" in 6498
replace byhand_manipadrsHP = "CL 56CE # 49G - 42" in 6505
replace byhand_manipadrsHP = "KR 49F # 56D - 106" in 6513
replace byhand_manipadrsHP = "KR 42B Bis # 54C - 22" in 6521
replace byhand_manipadrsHP = "KR 46 # 56F1 - 31" in 6523
replace byhand_manipadrsHP = "KR 42D1 # 56E - 21" in 6525
replace byhand_manipadrsHP = "KR 42C2 # 54 - 94" in 6529

replace byhand_manipadrsHP = "CL 14C # 64B - 90" in 6540
replace byhand_manipadrsHP = "CL 12 O # 24C Bis - 51" in 6533
replace byhand_manipadrsHP = "KR 24C # 11C - 107" in 6548
replace byhand_manipadrsHP = "CL 5 O # 14 - 40" in 6549
replace byhand_manipadrsHP = "KR 27AT # 29 - 33" in 6563
replace byhand_manipadrsHP = "KR 27AT # 29 - 33" in 6564
replace byhand_manipadrsHP = "KR 27AT # 29 - 33" in 6565


replace byhand_manipadrsHP = "KR 28 # 29 - 10" in 6576
replace byhand_manipadrsHP = "KR 27 # 29 - 114" in 6583
replace byhand_manipadrsHP = "KR 3 # 01 - 03" in 6596
replace byhand_manipadrsHP = "CL 5B # 2" in 6602
replace byhand_manipadrsHP = "CL 3A # 1AB - 06" in 6603
replace byhand_manipadrsHP = "KR 1 # 26" in 6608
replace byhand_manipadrsHP = "CL 12A # 28 E - 267" in 6614
replace byhand_manipadrsHP = "CL 72Y # 28H - 29" in 6615
replace byhand_manipadrsHP = "KR 28J # 20 - 72" in 6617
replace byhand_manipadrsHP = "" in 6618
replace byhand_manipadrsHP = "KR 29B # 45A - 02" in 6623
replace byhand_manipadrsHP = "KR 28B1 # 72Y - 37" in 6625
replace byhand_manipadrsHP = "CL 76 # 28D6 - 22" in 6643
replace byhand_manipadrsHP = "KR 28-2 # 72F - 76" in 6636
replace byhand_manipadrsHP = "KR 28 - 2 # 72F - 76" in 6636
replace byhand_manipadrsHP = "KR 28 # 72T - 68" in 6651
replace byhand_manipadrsHP = "KR 29D # 43A - 18" in 6652
replace byhand_manipadrsHP = "KR 28E6W # 72U - 69" in 6671
replace byhand_manipadrsHP = "KR 28 - 2 # 72W - 22" in 6704
replace byhand_manipadrsHP = "KR 30A # 42A - 28" in 6707
replace byhand_manipadrsHP = "KR 28H N # 72J - 36" in 6732

replace byhand_manipadrsHP = "KR 28E6 # 72V - 51" in 6733
replace byhand_manipadrsHP = "KR 28EG # 72V - 31" in 6735
replace byhand_manipadrsHP = "KR 28DA # 72T - 47" in 6751
replace byhand_manipadrsHP = "KR 27G # 72W2 - 95" in 6752
replace byhand_manipadrsHP = "CL 72Z2 # 28A1 - 31" in 6765
replace byhand_manipadrsHP = "CL 72T2 # 28E - 13" in 6769
replace byhand_manipadrsHP = "KR 26I2 # 72W - 136" in 6771
replace byhand_manipadrsHP = "KR 28E3 # 72T - 16" in 6777
replace byhand_manipadrsHP = "KR 31 # 42A - 71" in 6783
replace byhand_manipadrsHP = "KR 28 - 1 # 72W - 27" in 6788
replace byhand_manipadrsHP = "KR 28 - 2 # 112 - 72" in 6803
replace byhand_manipadrsHP = "KR 28 # 72M - 18" in 6804
replace byhand_manipadrsHP = "KR 28D4 # 72 - 41" in 6809
replace byhand_manipadrsHP = "KR 28B2 # 72U - 14" in 6814
replace byhand_manipadrsHP = "KR 28G # 72ET - 98" in 6820
replace byhand_manipadrsHP = "KR 21A # 42A - 14" in 6821
replace byhand_manipadrsHP = "KR 28E3 # 72 - 77" in 6823
replace byhand_manipadrsHP = "KR 29A # 46 - 60" in 6829
replace byhand_manipadrsHP = "KR 28E2 # 72T2 - 02" in 6836
replace byhand_manipadrsHP = "KR 28E5 # 72T - 82" in 6837
replace byhand_manipadrsHP = "CL 73 # 28F - 66" in 6843
replace byhand_manipadrsHP = "CL 72U # 28 1 - 19" in 6844
replace byhand_manipadrsHP = "CL 72U # 28 - 1 - 19" in 6844
replace byhand_manipadrsHP = "CL 72D2 # 28E - 13" in 6846
replace byhand_manipadrsHP = "CL 72W # 28E1 - 01" in 6849
replace byhand_manipadrsHP = "KR 28E6 # 72D - 42" in 6850
replace byhand_manipadrsHP = "KR 28E6 # 72D - 42" in 6851
replace byhand_manipadrsHP = "CL 72 # 28E - 52" in 6858
replace byhand_manipadrsHP = "KR 28A # 72W - 18" in 6859
replace byhand_manipadrsHP = "KR 28D3 # 72W - 37" in 6864
replace byhand_manipadrsHP = "KR 283 N # 72Z - 41" in 6865
replace byhand_manipadrsHP = "CL 72 # 28E6 - 65" in 6870
replace byhand_manipadrsHP = "KR 28P3 # 72T - 39" in 6871
replace byhand_manipadrsHP = "CL 72U # 28E6 - 16" in 6872
replace byhand_manipadrsHP = "KR 28A1 # 72U - 31" in 6873
replace byhand_manipadrsHP = "KR 26B # 72B - 12" in 6877
replace byhand_manipadrsHP = "KR 28A # 72W - 01" in 6885
replace byhand_manipadrsHP = "KR 28E5 # 72TC - 32" in 6887
replace byhand_manipadrsHP = "KR 28E2 # 72V - 44" in 6892
replace byhand_manipadrsHP = "KR 28 N # 72S - 52" in 6896
replace byhand_manipadrsHP = "KR 28E1 # 72W - 30" in 6897
replace byhand_manipadrsHP = "KR 28EG # 72U - 59" in 6904
replace byhand_manipadrsHP = "TV 28F # 72L2 - 131" in 6907
replace byhand_manipadrsHP = "KR 28D4 # 72 - 22" in 6909

replace byhand_manipadrsHP = "CL 85E # 3 - 29" in 6913
replace byhand_manipadrsHP = "CL 85 # 43 - 29" in 6913
replace byhand_manipadrsHP = "CL 85 # E3 - 29" in 6913
replace byhand_manipadrsHP = "KR 28E4 # 72B - 27" in 6927
replace byhand_manipadrsHP = "KR 28 - 3 # 72Y - 67" in 6929
replace byhand_manipadrsHP = "CL 72U1 N # 28E - 52" in 6931
replace byhand_manipadrsHP = "CL 42A1 # 39E - 29" in 6932
replace byhand_manipadrsHP = "KR 28E3 # 72U - 32" in 6934
replace byhand_manipadrsHP = "KR 28 - 01 N  # 72T - 52" in 6942
replace byhand_manipadrsHP = "KR 28EG # 72V - 72" in 6944
replace byhand_manipadrsHP = "KR 28E7 # 72B - 51" in 6955

replace byhand_manipadrsHP = "KR 28E3 N # 72 - 06" in 6956
replace byhand_manipadrsHP = "KR 28A1 # 72Z - 101" in 6957
replace byhand_manipadrsHP = "KR 28F4 # 72B - 47" in 6961
replace byhand_manipadrsHP = "KR 28E7 # 72V - 37" in 6965
replace byhand_manipadrsHP = "KR 28F # 73L - 74" in 6966

replace byhand_manipadrsHP = "KR 28 - 1 # 72Z - 77" in 6969
replace byhand_manipadrsHP = "KR 28D4 # 72B - 01" in 6970
replace byhand_manipadrsHP = "CL 51 # 29A - 102" in 6980
replace byhand_manipadrsHP = "KR 28D2 # 72U - 06" in 6991
replace byhand_manipadrsHP = "KR 28E6 # 72U - 77" in 6998
replace byhand_manipadrsHP = "KR 28 E # 72U - 59" in 7004
replace byhand_manipadrsHP = "KR 28 - 4 # 2Y - 124" in 7005
replace byhand_manipadrsHP = "CL 53 # 304A - 40" in 7012
replace byhand_manipadrsHP = "CL 88 # 28G - 87" in 7020
replace byhand_manipadrsHP = "CL 72 # 28E - 94" in 7025

replace byhand_manipadrsHP = "KR 28D2 # 72U - 16" in 7027
replace byhand_manipadrsHP = "CL 72U # 282 - 07" in 7029
replace byhand_manipadrsHP = "KR 261 # 72U - 86" in 7032
replace byhand_manipadrsHP = "" in 7036
replace byhand_manipadrsHP = "CL 72T2 # 28E - 47" in 7047
replace byhand_manipadrsHP = "KR 26H1 # 8D - 80" in 7053
replace byhand_manipadrsHP = "KR 28 - 1 # 72Z - 62" in 7057
replace byhand_manipadrsHP = "KR 28 - 2 # 72Z - 27" in 7060

replace byhand_manipadrsHP = "KR 28 - 1 # 72Z - 02" in 7071
replace byhand_manipadrsHP = "KR 28 - A1 # 72W - 27" in 7074
replace byhand_manipadrsHP = "CL 72 # 28EA - 15" in 7076
replace byhand_manipadrsHP = "KR 28A1 # 72U - 31" in 7080
replace byhand_manipadrsHP = "KR 28D5 # 72Y - 52" in 7088
replace byhand_manipadrsHP = "KR 26H # 72C - 18B" in 7093
replace byhand_manipadrsHP = "CL 72A # 28B - 70" in 7094
replace byhand_manipadrsHP = "CL 72W1 # 27 - 87" in 7095
replace byhand_manipadrsHP = "KR 26H2 # 720 - 50" in 7097
replace byhand_manipadrsHP = "CL 72F2 # 28F - 64" in 7099
replace byhand_manipadrsHP = "DG 29B # 30 - 12" in 7109
replace byhand_manipadrsHP = "CL 72W1 # 27 - 32" in 7114
replace byhand_manipadrsHP = "CL 72P # 28J - 10" in 7116
replace byhand_manipadrsHP = "KR 28B # 72A - 28" in 7127
replace byhand_manipadrsHP = "CL 71A # 26 - 22" in 7130
replace byhand_manipadrsHP = "KR 28B # 72A - 11" in 7131
replace byhand_manipadrsHP = "CL 72 N # 28E - 6" in 7133
replace byhand_manipadrsHP = "KR 28 - 3 # 95 - 65" in 7136
replace byhand_manipadrsHP = "KR 28D # 72F4 - 60" in 7137
replace byhand_manipadrsHP = "KR 283 # 72 - 59" in 7143
replace byhand_manipadrsHP = "CL 72F3 # 28D3 - 80" in 7146
replace byhand_manipadrsHP = "KR 28 Bis # 72A - 52" in 7168
replace byhand_manipadrsHP = "CL 72B # 28D3 - 81" in 7177
replace byhand_manipadrsHP = "CL 72B # 28D3 - 81" in 7178
replace byhand_manipadrsHP = "KR 28E6 # 72T - 86" in 7179
replace byhand_manipadrsHP = "KR 28E6 # 72T - 86" in 7180

replace byhand_manipadrsHP = "KR 42A  N # 14 - 50" in 7219
replace byhand_manipadrsHP = "KR 42A N # 14 - 50" in 7219
replace byhand_manipadrsHP = "CL 1 # 67 - 68" in 7225
replace byhand_manipadrsHP = "CL 1 # 67 - 68" in 7226
replace byhand_manipadrsHP = "CL 1 # 67 - 68" in 7227

replace byhand_manipadrsHP = "CL 3D # 66B - 11" in 7243
replace byhand_manipadrsHP = "CL 1 # 67 - 56" in 7244
replace byhand_manipadrsHP = "CL 1A # 67 - 68B" in 7250
replace byhand_manipadrsHP = "CL 2C3 # 68 - 27" in 7252
replace byhand_manipadrsHP = "CL 2A # 66B - 120" in 7259
replace byhand_manipadrsHP = "CL 1A # 62A - 130" in 7274
replace byhand_manipadrsHP = "CL 3 # 65A - 16" in 7283
replace byhand_manipadrsHP = "KR 70 # 1 Bis 5 - 03" in 7287
replace byhand_manipadrsHP = "KR 26J1 # 123 - 38" in 7290
replace byhand_manipadrsHP = "CL 7 # 24I3 - 28" in 7292
replace byhand_manipadrsHP = "KR 26 - 14 # 124 - 21" in 7294
replace byhand_manipadrsHP = "KR 26H3 # 122 - 55" in 7295
replace byhand_manipadrsHP = "CL 123 # 26I - 336" in 7297
replace byhand_manipadrsHP = "CL 123 # 26I - 336" in 7298
replace byhand_manipadrsHP = "KR 26J1 # 124M - 51" in 7299
replace byhand_manipadrsHP = "CL 125 # 28A1 - 27" in 7300
replace byhand_manipadrsHP = "KR 26I2 # 125A - 28" in 7302
replace byhand_manipadrsHP = "CL 123 # 26H - 411" in 7303
replace byhand_manipadrsHP = "KR 26J3 # 121 - 23" in 7304
replace byhand_manipadrsHP = "KR 39 # 50A - 21" in 7308

replace byhand_manipadrsHP = "KR 38A # 52A - 21" in 7318
replace byhand_manipadrsHP = "CL 53 # 33 - 03" in 7355
replace byhand_manipadrsHP = "KR 41E1 # 52 - 53" in 7368
replace byhand_manipadrsHP = "KR 38A # 41A - 48" in 7371
replace byhand_manipadrsHP = "CL 39 # 24D - 50" in 7384
replace byhand_manipadrsHP = "KR 24D # 33F - 80" in 7387
replace byhand_manipadrsHP = "CL 34 # 24C - 16" in 7392
replace byhand_manipadrsHP = "KR 26 # 33E - 43" in 7405
replace byhand_manipadrsHP = "KR 26O # 28C - 04" in 7432

replace byhand_manipadrsHP = "CL 36A # 25A - 63" in 7433
replace byhand_manipadrsHP = "CL 36A # 25A - 63" in 7434
replace byhand_manipadrsHP = "KR 24 # 45B - 22" in 7437
replace byhand_manipadrsHP = "KR 26PD # 28C - 23" in 7440
replace byhand_manipadrsHP = "KR 26M # 2FB - 49" in 7442
replace byhand_manipadrsHP = "CL 39 # 24D - 60" in 7472
replace byhand_manipadrsHP = "CL 36 # 24D - 83" in 7475
replace byhand_manipadrsHP = "KR 26P # 28C - 27" in 7480
replace byhand_manipadrsHP = "KR 26P # 28C - 27" in 7481

replace byhand_manipadrsHP = "DG 30 # 42A - 05" in 7486
replace byhand_manipadrsHP = "DG 30 # 42A - 05" in 7487
replace byhand_manipadrsHP = "KR 26 O # 28C - 36" in 7489
replace byhand_manipadrsHP = "CL 33H # 24" in 7492
replace byhand_manipadrsHP = "KR 26 N # 28B - 20" in 7494

replace byhand_manipadrsHP = "KR 2DB1 # 47 - 57" in 7502
replace byhand_manipadrsHP = "CL 49 # 2B1 - 21" in 7503
replace byhand_manipadrsHP = "CL 49 # 2B1 - 21" in 7504
replace byhand_manipadrsHP = "CL 14" in 7508
replace byhand_manipadrsHP = "CL 49 N # 2IN - 15" in 7513
replace byhand_manipadrsHP = "CL 47 # 1D1 - 05" in 7514
replace byhand_manipadrsHP = "CL 47AN # 2G - 98" in 7515
replace byhand_manipadrsHP = "CL 52AN # 2EN - 95" in 7531
replace byhand_manipadrsHP = "KR 4D # 52A - 58" in 7532
replace byhand_manipadrsHP = "CL 54B # 47 - 76" in 7533
replace byhand_manipadrsHP = "CL 52 # 15 - 37" in 7559

replace byhand_manipadrsHP = "KR 24A # 56A - 35" in 7567
replace byhand_manipadrsHP = "KR 11 # 39 - 90" in 7583
replace byhand_manipadrsHP = "KR 41 # 10A - 16" in 7594
replace byhand_manipadrsHP = "CL 36 # 11C - 83" in 7600
replace byhand_manipadrsHP = "CL 42 " in 7607
replace byhand_manipadrsHP = "CL 42C" in 7607
replace byhand_manipadrsHP = "KR 11AF # 36 - 04" in 7615
replace byhand_manipadrsHP = "KR 11F # 36 - 04" in 7616

replace byhand_manipadrsHP = "KR 11F # 36 - 04" in 7615
replace byhand_manipadrsHP = "CL 35 # 11B - 08" in 7617
replace byhand_manipadrsHP = "CL 36 # 11C - 49" in 7621
replace byhand_manipadrsHP = "CL 44B # 10 - 26" in 7626

replace byhand_manipadrsHP = "KR 8A # 34A - 38B" in 7630
replace byhand_manipadrsHP = "CL 37 # 8A - 45" in 7636
replace byhand_manipadrsHP = " CL 35 # 8A - 12" in 7645
replace byhand_manipadrsHP = "KR 8 # 42AN - 25" in 7646
replace byhand_manipadrsHP = "KR 11C # 37 - 07" in 7654
replace byhand_manipadrsHP = "CL 46 # 11D - 49" in 7667
replace byhand_manipadrsHP = "KR 11B3 # 36 - 02" in 7672
replace byhand_manipadrsHP = "KR 11B3 # 36 - 02" in 7673
replace byhand_manipadrsHP = "KR 12AE # 36 - 17" in 7681
replace byhand_manipadrsHP = "KR 39G # 51A - 90" in 7686
replace byhand_manipadrsHP = "CL 53 # 39E - 44" in 7692
replace byhand_manipadrsHP = "KR 41A # 56 - 75" in 7701
replace byhand_manipadrsHP = "KR 38B # 55A - 68" in 7703
replace byhand_manipadrsHP = "CL 55B # 39C - 77" in 7712
replace byhand_manipadrsHP = "KR 39A # 56A - 74" in 7718
replace byhand_manipadrsHP = "CL 55 # 41E3 - 24" in 7733
replace byhand_manipadrsHP = "CL 76A # 28A - 33" in 7737
replace byhand_manipadrsHP = "KR 38B # 66A - 69" in 7739
replace byhand_manipadrsHP = "KR 46 # 49 - 14" in 7744
replace byhand_manipadrsHP = "KR 29 # 56I - 20" in 7755

replace byhand_manipadrsHP = "CL 36D # 48B - 57" in 7756
replace byhand_manipadrsHP = "KR 39B # 54B - 31" in 7760
replace byhand_manipadrsHP = "KR 39E" in 7761
replace byhand_manipadrsHP = "KR 40 # 49A - 22" in 7773
replace byhand_manipadrsHP = "KR 39A # 36A - 74" in 7776
replace byhand_manipadrsHP = "KR 39A # 56A - 74" in 7777
replace byhand_manipadrsHP = "CL 50 # 39G - 21" in 7802
replace byhand_manipadrsHP = "KR 38 # 56A - 65" in 7803
replace byhand_manipadrsHP = "KR 41b # 52 - 39" in 7807
replace byhand_manipadrsHP = "KR 41B # 52 - 39" in 7807
replace byhand_manipadrsHP = "KR 40B # 52A - 28" in 7839
replace byhand_manipadrsHP = "CL 55A # 32A - 95" in 7844
replace byhand_manipadrsHP = "CL 55A # 32A - 95" in 7845

replace byhand_manipadrsHP = "KR 32 Bis # 42C - 56" in 7881
replace byhand_manipadrsHP = "CL 46 # 33C - 04" in 7884
replace byhand_manipadrsHP = "CL 46 # 33C - 04" in 7885
replace byhand_manipadrsHP = "CL 43B # 32B - 29" in 7912
replace byhand_manipadrsHP = "CL 43B # 32B - 29" in 7913
replace byhand_manipadrsHP = "KR 33A # 42C - 40" in 7921
replace byhand_manipadrsHP = "KR 32A Bis # 42C - 103" in 7933
replace byhand_manipadrsHP = "KR 33B # 42B - 30" in 7934
replace byhand_manipadrsHP = "KR 34 N # 42B - 06" in 7940
replace byhand_manipadrsHP = "CL 43A # 73C - 26" in 7945
replace byhand_manipadrsHP = "KR 39M # 44A - 105" in 7947
replace byhand_manipadrsHP = "CL 43 # 31A - 25" in 7948
replace byhand_manipadrsHP = "CL 33C # 84C - 27" in 7954
replace byhand_manipadrsHP = "CL 48 # 34A - 28" in 7995
replace byhand_manipadrsHP = "KR 33B Bis # 46B - 22" in 8015
replace byhand_manipadrsHP = "CL 43B # 32B - 29" in 8024
replace byhand_manipadrsHP = "CL 4 Bis # 33BN - 83" in 8043

replace byhand_manipadrsHP = "CL 45 # 33B - 16" in 8059
replace byhand_manipadrsHP = "KR 42C # 33C - 14" in 8061
replace byhand_manipadrsHP = "KR 28E7  # 72 - 07" in 8086
replace byhand_manipadrsHP = "KR 33A # 33A - 15" in 8087
replace byhand_manipadrsHP = "KR 33 # 42 - 20" in 8094
replace byhand_manipadrsHP = "KR 32A Bis # 46 - 22" in 8095
replace byhand_manipadrsHP = "KR 32A # 44 - 51" in 8102
replace byhand_manipadrsHP = "CL 52 N # 4N - 27" in 8110

replace byhand_manipadrsHP = "KR 5 N # 49AN - 02" in 8111
replace byhand_manipadrsHP = "KR 20 # 13 - 08" in 8113
replace byhand_manipadrsHP = "KR 3 N # 30 N - 08" in 8116
replace byhand_manipadrsHP = "KR 2BN # 30N - 50" in 8117
replace byhand_manipadrsHP = "KR 2 # 7 - 32" in 8123
replace byhand_manipadrsHP = "KR 24 # 70A1 - 64" in 8132
replace byhand_manipadrsHP = "CL 52 # 8 N - 94T3" in 8143
replace byhand_manipadrsHP = "CL 52 # 8 N - 94T3" in 8144
replace byhand_manipadrsHP = "CL 60DN # 5N - 26" in 8147

replace byhand_manipadrsHP = "CL 70A # 1A5 - 207" in 8152
replace byhand_manipadrsHP = "KR 1A5 - 2 # 70 - 67" in 8159
replace byhand_manipadrsHP = "KR 1A5 - 2 # 70 - 67" in 8160
replace byhand_manipadrsHP = "CL 70A # 1A5 - 207" in 8161
replace byhand_manipadrsHP = "CL 70A # 1A5 - 4 - 11" in 8162
replace byhand_manipadrsHP = "CL 16 # 9AN - 37" in 8165
replace byhand_manipadrsHP = "AV 34 # 97" in 8173
replace byhand_manipadrsHP = "CL 98 # 23A - 21" in 8174
replace byhand_manipadrsHP = "CL 100 # 23A - 28" in 8178

replace byhand_manipadrsHP = "KR 19 # 12 - 53B" in 8193
replace byhand_manipadrsHP = "KR 16 # 13A - 54" in 8194
replace byhand_manipadrsHP = "CL 14 # 19 - 31B" in 8195
replace byhand_manipadrsHP = "CL 13 # 22B - 04" in 8199
replace byhand_manipadrsHP = "CL 13A # 22B - 04" in 8210
replace byhand_manipadrsHP = "KR 7 N # 46B - 08" in 8221

replace byhand_manipadrsHP = "CL 72F 3T # 28F - 56" in 8225
replace byhand_manipadrsHP = "KR 78H # 2B - 29" in 8227
replace byhand_manipadrsHP = "CL 35" in 8242
replace byhand_manipadrsHP = "KR 20" in 8250
replace byhand_manipadrsHP = "CL 88 # 7I - 27" in 8256
replace byhand_manipadrsHP = "KR 7A # 88G - 29" in 8257
replace byhand_manipadrsHP = "KR 7 B  Bis  # 66 - 22" in 8260
replace byhand_manipadrsHP = "CL 66  # 7B Bis - 56" in 8262
replace byhand_manipadrsHP = "KR 7 # 8 Bis 65 - 16" in 8263
replace byhand_manipadrsHP = "CL 69 # 7 Bis - 12" in 8267
replace byhand_manipadrsHP = "CL 66A # 7B Bis - 79" in 8268
replace byhand_manipadrsHP = "CL 69 # 7B Bis - 12" in 8269
replace byhand_manipadrsHP = "CL 69 # 7B Bis - 12" in 8270
replace byhand_manipadrsHP = "" in 8279
replace byhand_manipadrsHP = "CL 2 E O # 91 Bis - 1 - 12" in 8293
replace byhand_manipadrsHP = "CL 2 E O # 91 Bis - 1 - 12" in 8294
replace byhand_manipadrsHP = "KR 87 O #  97" in 8295
replace byhand_manipadrsHP = "KR 87 O # 97" in 8296
replace byhand_manipadrsHP = "KR 87 O # 97" in 8297
replace byhand_manipadrsHP = "KR 7A" in 8298
replace byhand_manipadrsHP = "CL 73 - 3 # 12 - 103" in 8306
replace byhand_manipadrsHP = "CL 71 # 2E - 18" in 8307
replace byhand_manipadrsHP = "CL 71F # 3EN - 11" in 8313

replace byhand_manipadrsHP = "CL 71F # 3EN - 11" in 8314
replace byhand_manipadrsHP = "KR 7AL # 76 - 85" in 8319
replace byhand_manipadrsHP = "KR 2C # 70A - 20" in 8320
replace byhand_manipadrsHP = "KR 2C # 70A - 20" in 8321
replace byhand_manipadrsHP = "KR 2C # 70A - 20" in 8322
replace byhand_manipadrsHP = "KR 2C # 70A - 20" in 8323
replace byhand_manipadrsHP = "KR 7 CN # 13BN - 21" in 8331
replace byhand_manipadrsHP = "KR 7CN # 13BN - 21" in 8331
replace byhand_manipadrsHP = "CL 73 # 2A - 21" in 8339
replace byhand_manipadrsHP = "CL 73IA # 42" in 8341
replace byhand_manipadrsHP = "CL 72 # 2C - 27" in 8347
replace byhand_manipadrsHP = "CL 73A # 1J - 82" in 8350
replace byhand_manipadrsHP = "CL 71 # 1 Bis - 2E 12" in 8355
replace byhand_manipadrsHP = "CL 71 # 1 Bis 2E - 12" in 8355

replace byhand_manipadrsHP = "CL 72 # 3AN - 16" in 8359
replace byhand_manipadrsHP = "CL 81 # 37T - 35" in 8365
replace byhand_manipadrsHP = "CL 13 # 44A - 32" in 8383
replace byhand_manipadrsHP = "KR 48A # 13A - 41" in 8384
replace byhand_manipadrsHP = "CL 13A # 49A - 20" in 8386
replace byhand_manipadrsHP = "KR 49A # 32A - 03" in 8390
replace byhand_manipadrsHP = "CL 86A # 26 - 65 - 51" in 8399
replace byhand_manipadrsHP = "KR 26H4 # 87 - 46" in 8400
replace byhand_manipadrsHP = "KR 26F1 # 77 - 46" in 8403
replace byhand_manipadrsHP = "DG 26P16 # 104 - 45" in 8406
replace byhand_manipadrsHP = "DG 26O # 87 - 66" in 8407
replace byhand_manipadrsHP = "DG 26O # 87 - 66" in 8408
replace byhand_manipadrsHP = "KR 26E # 73A - 17" in 8410
replace byhand_manipadrsHP = "DG 26G12 # 83 - 66" in 8411
replace byhand_manipadrsHP = "DG 26 O # 87 - 66" in 8412
replace byhand_manipadrsHP = "DG 26E6 # 72S - 138" in 8414
replace byhand_manipadrsHP = "DG 26P20 N # 105T - 20" in 8416
replace byhand_manipadrsHP = "DG 26B10 # 96 - 24" in 8417
replace byhand_manipadrsHP = "DG 26P6 # 96 - 59" in 8418
replace byhand_manipadrsHP = "TV 94 N # 26P16 - 25" in 8419
replace byhand_manipadrsHP = "DG 27G12 # 73 - 03" in 8420
replace byhand_manipadrsHP = "DG 27G12 # 73 - 03" in 8421
replace byhand_manipadrsHP = "DG 26H4 # 80 - 74" in 8423
replace byhand_manipadrsHP = "DG 26P11 # 96 - 11" in 8424
replace byhand_manipadrsHP = "KR 26P # 80" in 8426
replace byhand_manipadrsHP = "KR 26G6 # 73 - 67" in 8429
replace byhand_manipadrsHP = "DG 26P13 # 106 - 39" in 8430
replace byhand_manipadrsHP = "DG 26H4 # 83 - 80" in 8431
replace byhand_manipadrsHP = "DG 26P13 # 105A - 66" in 8432
replace byhand_manipadrsHP = "DG 26 N # 96 - 10" in 8433
replace byhand_manipadrsHP = "DG 26 # 96 - 10" in 8433
replace byhand_manipadrsHP = "DG 26G # 27T - 17" in 8434
replace byhand_manipadrsHP = "DG 26G8 # 27T - 17" in 8434
replace byhand_manipadrsHP = "DG 26P13 # 105 - 70" in 8439
replace byhand_manipadrsHP = "DG 26P2 # 96 - 52" in 8440
replace byhand_manipadrsHP = "DG 26G8 # 77 - 10" in 8442
replace byhand_manipadrsHP = "TV 94 # 26P16 - 25" in 8419
replace byhand_manipadrsHP = "DG 26P20 # 105T - 20" in 8416

replace byhand_manipadrsHP = "DG 26B # 93 - 20" in 8444
replace byhand_manipadrsHP = "DG 26P5 # 87 - 80" in 8445
replace byhand_manipadrsHP = "DG 26P4 # 87 - 38" in 8446
replace byhand_manipadrsHP = "DG 26B12 # 87 - 04" in 8448
replace byhand_manipadrsHP = "DG 26N # 96 - 10" in 8450
replace byhand_manipadrsHP = "DG 26I # 80 - 11" in 8451
replace byhand_manipadrsHP = "KR 26C2 # 73 - 16" in 8452
replace byhand_manipadrsHP = "DG 26B10 # 104 - 59" in 8454
replace byhand_manipadrsHP = "DG 26P16 # 105A - 45" in 8457
replace byhand_manipadrsHP = "DG 26P1 # 83 - 45" in 8459
replace byhand_manipadrsHP = "DG 26 # 80 - 75P4" in 8460
replace byhand_manipadrsHP = "DG 20P1 # 37A - 32" in 8463
replace byhand_manipadrsHP = "KR 26K # 10" in 8473
replace byhand_manipadrsHP = "DG 26H # 77 - 25" in 8476
replace byhand_manipadrsHP = "DG 26P18 # 105A - 17" in 8477


replace byhand_manipadrsHP = "CL 47 Bis # 40 - 68" in 8482
replace byhand_manipadrsHP = "CL 47 Bis N # 40 - 68" in 8482
replace byhand_manipadrsHP = "DG 28E # 54 - 51" in 8488
replace byhand_manipadrsHP = "CL 55A # 28G - 48" in 8491
replace byhand_manipadrsHP = "KR 25 # 26B - 70" in 8517
replace byhand_manipadrsHP = "KR 17 # 15A - 33" in 8528

replace byhand_manipadrsHP = "KR 23C # 12 - 02" in 8533
replace byhand_manipadrsHP = "CL 12 # 23D - 112" in 8534
replace byhand_manipadrsHP = "KR 29A # 26B - 41" in 8535
replace byhand_manipadrsHP = "CL 11 # 23C - 79" in 8538
replace byhand_manipadrsHP = "KR 23C # 13B - 92" in 8552
replace byhand_manipadrsHP = "CL 11 # 23D - 14" in 8553
replace byhand_manipadrsHP = "DG 58 # 25 - 26" in 8558
replace byhand_manipadrsHP = "KR 1B # 51 - 36" in 8563
replace byhand_manipadrsHP = "CL 45B # 1D - 82" in 8564
replace byhand_manipadrsHP = "KR 12A Bis # 62 - 20" in 8605

replace byhand_manipadrsHP = "CL 58 # 6A - 28" in 8630
replace byhand_manipadrsHP = "CL 64 # 71" in 8653
replace byhand_manipadrsHP = "CL 54 # 11A - 39" in 8658
replace byhand_manipadrsHP = "CL 49 # 8A - 32" in 8661
replace byhand_manipadrsHP = "CL 44 N " in 8663
replace byhand_manipadrsHP = "CL 42 N # 6A - 04" in 8666
replace byhand_manipadrsHP = "CL 44 - 3 # 7N - 22" in 8667
replace byhand_manipadrsHP = "AV 7CN1 # 42 - 153" in 8670
replace byhand_manipadrsHP = "CL 44 N  # 7CN1 - 48" in 8663
replace byhand_manipadrsHP = "CL 44 N " in 8663

replace byhand_manipadrsHP = "KR 65 # 1A - 93" in 8673
replace byhand_manipadrsHP = "CL 44 # 6A - 57" in 8685
replace byhand_manipadrsHP = "KR 6AC # 42 - 55" in 8686
replace byhand_manipadrsHP = "CL 41 # 6B - 00" in 8690
replace byhand_manipadrsHP = "KR 38 # 26A - 27" in 8707

replace byhand_manipadrsHP = "" in 8716
replace byhand_manipadrsHP = "" in 8717
replace byhand_manipadrsHP = "AV 2IN # 45N - 83" in 8718
replace byhand_manipadrsHP = "AV 2I # 45 - 83" in 8719
replace byhand_manipadrsHP = "AV 2IN # 45N - 83" in 8720
replace byhand_manipadrsHP = "AV 2IN # 45N - 83" in 8721
replace byhand_manipadrsHP = "CL 50 N # 3FN - 30" in 8723
replace byhand_manipadrsHP = "AV 6A # 42 - 05" in 8725
replace byhand_manipadrsHP = "AV 3 EN # 59 - 130" in 8732
replace byhand_manipadrsHP = "AV 2HN # 352 - 05" in 8734
replace byhand_manipadrsHP = "CL 50 N # 5AN - 52" in 8737
replace byhand_manipadrsHP = "CL 58 N # 2GN - 69" in 8741

replace byhand_manipadrsHP = "CL 54 # 3BN - 49" in 8748
replace byhand_manipadrsHP = "CL 47BN # 5AN - 45" in 8749
replace byhand_manipadrsHP = "CL 72 N # 3BN - 39" in 8750
replace byhand_manipadrsHP = "AV 3F N # 59 - 125" in 8753
replace byhand_manipadrsHP = "CL 52 # 4AN - 25" in 8756

replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, "Bn", "BN",. )
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, " BN", "BN",. )
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, " Fn", "FN",. )

replace byhand_manipadrsHP = "CL 47A N # 5AN - 60" in 8765
replace byhand_manipadrsHP = "AV 5 N # 44N - 65" in 8766
replace byhand_manipadrsHP = "CL 47BN # 5AN - 45" in 8767
replace byhand_manipadrsHP = "CL 47 N # 5CN - 23" in 8772
replace byhand_manipadrsHP = "KR 31 # 42A - 86" in 8776
replace byhand_manipadrsHP = "CL 62 # 3GN - 80" in 8777
replace byhand_manipadrsHP = "AV 4 # 47AN - 05" in 8781
replace byhand_manipadrsHP = "AV 9 N # 54 - 13" in 8787
replace byhand_manipadrsHP = "AV 9 N # 54 - 13" in 8788
replace byhand_manipadrsHP = "CL 49A # 4N - 23" in 8791
replace byhand_manipadrsHP = "AV 4BN # 47 - 64B" in 8792
replace byhand_manipadrsHP = "CL 52 N # 3FN - 131" in 8793
replace byhand_manipadrsHP = "CL 59 # 2AN - 88" in 8801
replace byhand_manipadrsHP = "AV 4B # 44N - 25" in 8811
replace byhand_manipadrsHP = "CL 44 N 3 # 3E - 07" in 8812
replace byhand_manipadrsHP = "AV 4 N # 47AN - 27" in 8813
replace byhand_manipadrsHP = "AV 6 O # 30B - 40" in 8814
replace byhand_manipadrsHP = "CL 33F # 11H - 28" in 8820
replace byhand_manipadrsHP = "KR 12 # 31A - 23" in 8838
replace byhand_manipadrsHP = "KR 15 # 33F - 23" in 8845
replace byhand_manipadrsHP = "KR 19 # 33F - 43" in 8846

replace byhand_manipadrsHP = "TV 30 # 33A - 30" in 8873
replace byhand_manipadrsHP = "KR 15 # 32B15 - 21" in 8882
replace byhand_manipadrsHP = "KR 28C # 28C - 66" in 8888
replace byhand_manipadrsHP = "KR 27A # 32 - 41P2" in 8896
replace byhand_manipadrsHP = "KR 29B # 30A - 20" in 8952
replace byhand_manipadrsHP = "CL 34B # 29B - 27" in 8962

replace byhand_manipadrsHP = "KR 31 - 3 # 32A - 31" in 8977
replace byhand_manipadrsHP = "DG 33 # 32A - 45" in 8992
replace byhand_manipadrsHP = "KR 32A # 30 - 49" in 8993
replace byhand_manipadrsHP = "KR 35D # 30 - 71" in 8994
replace byhand_manipadrsHP = "KR 32A # 30 - 85" in 8997
replace byhand_manipadrsHP = "KR 32B # 30 - 87" in 9000
replace byhand_manipadrsHP = "KR 32AD # 30 - 110" in 9006
replace byhand_manipadrsHP = "KR 34 # 30 - 53P3" in 9011
replace byhand_manipadrsHP = "KR 33B # 30 - 48" in 9013
replace byhand_manipadrsHP = "CL 13E # 68 - 90" in 9014
replace byhand_manipadrsHP = "CL 13E # 68 - 90" in 9020
replace byhand_manipadrsHP = "CL 15 # 69 - 31" in 9025
replace byhand_manipadrsHP = "" in 9045
replace byhand_manipadrsHP = "KR 41C # 30D - 95" in 9050
replace byhand_manipadrsHP = "KR 41C # 30D - 95" in 9051
replace byhand_manipadrsHP = "DG 28D7 # 28D3 - 59" in 9061
replace byhand_manipadrsHP = "DG 28D7 # 28D3 - 59" in 9062
replace byhand_manipadrsHP = "DG 28D7 # 28D3 - 59" in 9063
replace byhand_manipadrsHP = "DG 28D7 # 28D3 - 59" in 9064
replace byhand_manipadrsHP = "KR 42 # 26B - 27" in 9076
replace byhand_manipadrsHP = "CL 26 # 41B - 21" in 9094

replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, "- Gn", "GN",. )
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, " Gn", "GN",. )
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, "Gn", "GN",. )
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, " GN", "GN",. )
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, "- AN", "AN",. )
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, " AN", "AN",. )


replace byhand_manipadrsHP = "CL 26 # 41B - 21" in 9104
replace byhand_manipadrsHP = "CL 29 # 40B - 19" in 9106
replace byhand_manipadrsHP = "KR 41B # 26C - 2" in 9119
replace byhand_manipadrsHP = "KR 41 # 26C - 36" in 9120
replace byhand_manipadrsHP = "KR 7 # 42 N 7N - 17" in 9137
replace byhand_manipadrsHP = "KR 7 # 45N7N - 29" in 9139
replace byhand_manipadrsHP = "KR 6N # 40N - 39" in 9144
replace byhand_manipadrsHP = "KR 8 # 39 N - 16" in 9146
replace byhand_manipadrsHP = "CL 44 # 8N - 3" in 9147
replace byhand_manipadrsHP = "CL 48 N # 2GN - 21" in 9155
replace byhand_manipadrsHP = "CL 47 # 2EN - 05" in 9175
replace byhand_manipadrsHP = "AV 2 EN # 53AN - 05" in 9176


replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, " Fn", "FN",. )
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, "Fn", "FN",. )
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, "Am", "AM",. )
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, "- Hn", "HN",. )
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, "Cn", "CN",. )

replace byhand_manipadrsHP = "CL 58 N # 2FN - 29" in 9179
replace byhand_manipadrsHP = "CL 47B # 2AN - 52" in 9195

replace byhand_manipadrsHP = "CL 49 N # 2IN - 15" in 9197
replace byhand_manipadrsHP = "" in 9202
replace byhand_manipadrsHP = "KR 3 # 9C - 128" in 9207

replace byhand_manipadrsHP = "CL 47CN # 26N - 105" in 9209
replace byhand_manipadrsHP = "KR 1A6 # 72 - 04" in 9218
replace byhand_manipadrsHP = "KR 1A6 # 12 - 04" in 9219
replace byhand_manipadrsHP = "CL 72T1 # 27A - 80" in 9227
replace byhand_manipadrsHP = "CL 72T1 # 27A - 80" in 9228
replace byhand_manipadrsHP = "KR 72S # 27 - 59" in 9231
replace byhand_manipadrsHP = "CL 72P1 # 26N - 52" in 9232
replace byhand_manipadrsHP = "CL 72 - 11 # 27A - 66" in 9240
replace byhand_manipadrsHP = "CL 72P # 26IO1 - 79" in 9248
replace byhand_manipadrsHP = "CL 7A # 5 I Bis - 36" in 9265
replace byhand_manipadrsHP = "KR 1AD Bis # 76 - 40" in 9266
replace byhand_manipadrsHP = "KR 70B # 1C2 - 08" in 9267
replace byhand_manipadrsHP = "KR 70B # 1C2 - 08" in 9268
replace byhand_manipadrsHP = "KR 70B # 1C2 - 08" in 9269
replace byhand_manipadrsHP = "CL 71A # 2C - 87" in 9270
replace byhand_manipadrsHP = "KR 1A54 # 71 - 72" in 9279
replace byhand_manipadrsHP = "KR 1A5B # 73A - 16" in 9285
replace byhand_manipadrsHP = "CL 70A # 1I Bis - 37" in 9286
replace byhand_manipadrsHP = "CL 70C # 1J - 24" in 9288
replace byhand_manipadrsHP = "CL 15 # 48 - 21" in 9291
replace byhand_manipadrsHP = "KR 46B # 14A - 36" in 9297
replace byhand_manipadrsHP = "KR 43 # 14B - 62" in 9306
replace byhand_manipadrsHP = "KR 55 # 12A- 58" in 9307
replace byhand_manipadrsHP = "CL 15 # 45 - 18" in 9312
replace byhand_manipadrsHP = "KR 46 # 14B - 57" in 9319
replace byhand_manipadrsHP = "KR 25 # 426E - 36" in 9324
replace byhand_manipadrsHP = "CL 19A # 24B - 35" in 9356
replace byhand_manipadrsHP = "CL 44 # 13A - 19" in 9379
replace byhand_manipadrsHP = "KR 11F # 42 - 73" in 9381
replace byhand_manipadrsHP = "KR 11F # 42 - 73" in 9382
replace byhand_manipadrsHP = "KR 12BNC # 42 - 91" in 9389
replace byhand_manipadrsHP = "KR 12BNC # 42 - 91" in 9390

replace byhand_manipadrsHP = "KR 116 # 42 - 65B" in 9400
replace byhand_manipadrsHP = "PJ 7F1 # 64 - 11" in 9419
replace byhand_manipadrsHP = "CL 68 # 7A R Bis - 07" in 9433
replace byhand_manipadrsHP = "CL 7V Bis # 62 - 67" in 9448
replace byhand_manipadrsHP = "CL 64 PJ 7F # 64 - 40" in 9465
replace byhand_manipadrsHP = "CL 66 PJ 7" in 9466
replace byhand_manipadrsHP = "KR 14 # 6 - 54B" in 9469
replace byhand_manipadrsHP = "KR 7AJ # 60 - 67" in 9473
replace byhand_manipadrsHP = "KR 7T2 # 69 - 64" in 9482
replace byhand_manipadrsHP = "KR 7 - 3 # 69 -27" in 9501
replace byhand_manipadrsHP = "CL 43 # 4B - 50" in 9521

replace byhand_manipadrsHP = "CL 44A # 430" in 9530
replace byhand_manipadrsHP = "CL 16B # 49A - 57" in 9550
replace byhand_manipadrsHP = "CL 17 N # 46A - 45" in 9568

replace byhand_manipadrsHP = "CL 79 # 26G3 - 27" in 9593
replace byhand_manipadrsHP = "KR 26G2 # 73B - 11" in 9596
replace byhand_manipadrsHP = "KR 26D # 80c - 17" in 9597
replace byhand_manipadrsHP = "KR 26D # 80C - 17" in 9597
replace byhand_manipadrsHP = "CL 80B # 26D - 95" in 9600
replace byhand_manipadrsHP = "CL 80A # 26G2 - 58" in 9601
replace byhand_manipadrsHP = "CL 10R # 27D - 11" in 9604
replace byhand_manipadrsHP = "KR 284 # 103 - 55" in 9606
replace byhand_manipadrsHP = "KR 284 # 103 - 55" in 9607
replace byhand_manipadrsHP = "KR 27 # 82 - 26P - 61" in 9608
replace byhand_manipadrsHP = "CL 108 # 27G - 24" in 9617

replace byhand_manipadrsHP = "KR 96A # 26I1 - 27" in 9619
replace byhand_manipadrsHP = "CL 96A # 26 1 - 27" in 9620
replace byhand_manipadrsHP = "CL 83 # 27F - 24" in 9644
replace byhand_manipadrsHP = "CL 112 # 27F - 19" in 9648

replace byhand_manipadrsHP = "KR 28 # 72L - 06" in 9653
replace byhand_manipadrsHP = "KR 28E3 # 72T - 64" in 9656
replace byhand_manipadrsHP = "KR 28E3 # 72T - 64" in 9657
replace byhand_manipadrsHP = "CL 104 # 27C - 17" in 9658
replace byhand_manipadrsHP = "CL 80 # 28D4 - 04" in 9659
replace byhand_manipadrsHP = "CL 111 # 28  4 - 31" in 9664
replace byhand_manipadrsHP = "CL 105 # 27D - 87" in 9668

replace byhand_manipadrsHP = "KR 28 2 # 103 - 78" in 9692
replace byhand_manipadrsHP = "CL 72 # 7R - 28" in 9694
replace byhand_manipadrsHP = "CL 110 # 28 4 - 73" in 9696
replace byhand_manipadrsHP = "PJ 7F # 68A - 53" in 9725

replace byhand_manipadrsHP = "CL 49A N # 32A - 61" in 9729
replace byhand_manipadrsHP = "CL 50 # 32A - 27" in 9749
replace byhand_manipadrsHP = "CL 53 # 32A - 119" in 9768
replace byhand_manipadrsHP = "CL 50 # 32A - 116" in 9773

replace byhand_manipadrsHP = "CL 54 # 30B - 94" in 9778
replace byhand_manipadrsHP = "CL 48A # 30B - 05" in 9790
replace byhand_manipadrsHP = "C 49 # 24 - 25" in 9798
replace byhand_manipadrsHP = "CL 49 # 24 - 25" in 9798
replace byhand_manipadrsHP = "CL 50 # 33 - 32" in 9800
replace byhand_manipadrsHP = "CL 48A # 32A - 15" in 9808

replace byhand_manipadrsHP = "CL 32A # 30 - 39" in 9839
replace byhand_manipadrsHP = "DG 29A # 27 - 89" in 9860
replace byhand_manipadrsHP = "CL 34 # 29A - 40" in 9864
replace byhand_manipadrsHP = "CL 34C # 29D - 46" in 9873
replace byhand_manipadrsHP = "KR 32 # 34 - 105" in 9878
replace byhand_manipadrsHP = "TV 26 # 28A - 107" in 9886
replace byhand_manipadrsHP = "TV 26 # 28A - 107" in 9887
replace byhand_manipadrsHP = "CL 35D # 29B - 57" in 9888


replace byhand_manipadrsHP = "KR 93 # 102" in 9895
replace byhand_manipadrsHP = "CL 56 # 86CI - 72" in 9967
replace byhand_manipadrsHP = "CL 34 4 # 98B - 35" in 9980
replace byhand_manipadrsHP = "CL 34 4 # 98B - 35" in 9981
replace byhand_manipadrsHP = "KR 95 # 50B - 45" in 9986
replace byhand_manipadrsHP = "CL 28 # 96 - 161" in 9995


replace byhand_manipadrsHP = "CL 44A # 430" in 9530
replace byhand_manipadrsHP = "CL 16B # 49A - 57" in 9550
replace byhand_manipadrsHP = "CL 17 N # 46A - 45" in 9568
replace byhand_manipadrsHP = "CL 79 # 26G3 - 27" in 9593
replace byhand_manipadrsHP = "KR 26G2 # 73B - 11" in 9596
replace byhand_manipadrsHP = "KR 26D # 80c - 17" in 9597
replace byhand_manipadrsHP = "KR 26D # 80C - 17" in 9597
replace byhand_manipadrsHP = "CL 80B # 26D - 95" in 9600
replace byhand_manipadrsHP = "CL 80A # 26G2 - 58" in 9601
replace byhand_manipadrsHP = "CL 10R # 27D - 11" in 9604
replace byhand_manipadrsHP = "KR 284 # 103 - 55" in 9606
replace byhand_manipadrsHP = "KR 284 # 103 - 55" in 9607
replace byhand_manipadrsHP = "KR 27 # 82 - 26P - 61" in 9608
replace byhand_manipadrsHP = "CL 108 # 27G - 24" in 9617
replace byhand_manipadrsHP = "KR 96A # 26I1 - 27" in 9619
replace byhand_manipadrsHP = "CL 96A # 26 1 - 27" in 9620
replace byhand_manipadrsHP = "CL 83 # 27F - 24" in 9644
replace byhand_manipadrsHP = "CL 112 # 27F - 19" in 9648
replace byhand_manipadrsHP = "KR 28 # 72L - 06" in 9653
replace byhand_manipadrsHP = "KR 28E3 # 72T - 64" in 9656
replace byhand_manipadrsHP = "KR 28E3 # 72T - 64" in 9657
replace byhand_manipadrsHP = "CL 104 # 27C - 17" in 9658
replace byhand_manipadrsHP = "CL 80 # 28D4 - 04" in 9659
replace byhand_manipadrsHP = "CL 111 # 28  4 - 31" in 9664
replace byhand_manipadrsHP = "CL 105 # 27D - 87" in 9668
replace byhand_manipadrsHP = "KR 28 2 # 103 - 78" in 9692
replace byhand_manipadrsHP = "CL 72 # 7R - 28" in 9694
replace byhand_manipadrsHP = "CL 110 # 28 4 - 73" in 9696
replace byhand_manipadrsHP = "PJ 7F # 68A - 53" in 9725
replace byhand_manipadrsHP = "CL 49A N # 32A - 61" in 9729
replace byhand_manipadrsHP = "CL 50 # 32A - 27" in 9749
replace byhand_manipadrsHP = "CL 53 # 32A - 119" in 9768
replace byhand_manipadrsHP = "CL 50 # 32A - 116" in 9773
replace byhand_manipadrsHP = "CL 54 # 30B - 94" in 9778
replace byhand_manipadrsHP = "CL 48A # 30B - 05" in 9790
replace byhand_manipadrsHP = "C 49 # 24 - 25" in 9798
replace byhand_manipadrsHP = "CL 49 # 24 - 25" in 9798
replace byhand_manipadrsHP = "CL 50 # 33 - 32" in 9800
replace byhand_manipadrsHP = "CL 48A # 32A - 15" in 9808
replace byhand_manipadrsHP = "CL 32A # 30 - 39" in 9839
replace byhand_manipadrsHP = "DG 29A # 27 - 89" in 9860
replace byhand_manipadrsHP = "CL 34 # 29A - 40" in 9864
replace byhand_manipadrsHP = "CL 34C # 29D - 46" in 9873
replace byhand_manipadrsHP = "KR 32 # 34 - 105" in 9878
replace byhand_manipadrsHP = "TV 26 # 28A - 107" in 9886
replace byhand_manipadrsHP = "TV 26 # 28A - 107" in 9887
replace byhand_manipadrsHP = "CL 35D # 29B - 57" in 9888
replace byhand_manipadrsHP = "KR 93 # 102" in 9895
replace byhand_manipadrsHP = "CL 56 # 86CI - 72" in 9967
replace byhand_manipadrsHP = "CL 34 4 # 98B - 35" in 9980
replace byhand_manipadrsHP = "CL 34 4 # 98B - 35" in 9981
replace byhand_manipadrsHP = "KR 95 # 50B - 45" in 9986
replace byhand_manipadrsHP = "CL 28 # 96 - 161" in 9995
replace byhand_manipadrsHP = "CL 45 # 86 - 38" in 10024
replace byhand_manipadrsHP = "DG 22 # 30 - 90" in 10034
replace byhand_manipadrsHP = "CL 54D # 85C1 - 60" in 10057
replace byhand_manipadrsHP = "CL 54D # 85C1 - 60" in 10058
replace byhand_manipadrsHP = "CL 54D # 85C1 - 60" in 10059
replace byhand_manipadrsHP = "CL 54D # 85C1 - 60" in 10060
replace byhand_manipadrsHP = "CL 54D # 85C1 - 60" in 10061
replace byhand_manipadrsHP = "CL 54D # 85C1 - 60" in 10062
replace byhand_manipadrsHP = "KR 97 # 42 - 57" in 10072
replace byhand_manipadrsHP = "CL 19 # 50C - 36" in 10076
replace byhand_manipadrsHP = "CL 10 O # 50 - 16" in 10080
replace byhand_manipadrsHP = "KR 5AN # 6N - 41" in 10082
replace byhand_manipadrsHP = "CL 13 O # 49C - 14" in 10083
replace byhand_manipadrsHP = "CL 13 O # 49C - 14" in 10084
replace byhand_manipadrsHP = "CL 13 O # 46A - 59" in 10098
replace byhand_manipadrsHP = "KR 1AW # 10 - 60" in 10099
replace byhand_manipadrsHP = "KR 1AW # 10 - 60" in 10100
replace byhand_manipadrsHP = "CL 12 # 16B - 40" in 10111
replace byhand_manipadrsHP = "KR 26I # 72C - 45" in 10114
replace byhand_manipadrsHP = "KR 26 - 1 # 72W - 22" in 10116
replace byhand_manipadrsHP = "CL 72B # 24D - 05" in 10125
replace byhand_manipadrsHP = "KR 23 A # 13" in 10129
replace byhand_manipadrsHP = "CL 72B # 24D - 59" in 10135
replace byhand_manipadrsHP = "KR 1 # 7D - 102" in 10144
replace byhand_manipadrsHP = "KR 1A # 3A - 70C" in 10151
replace byhand_manipadrsHP = "KR 1A # 3A - 70C" in 10152
replace byhand_manipadrsHP = "KR 1A3 # 70B - 44" in 10155
replace byhand_manipadrsHP = "CL 1B # 73D - 36" in 10158
replace byhand_manipadrsHP = "CL 81 # 1J - 19" in 10159
replace byhand_manipadrsHP = "CL 70A # 13A - 49" in 10162
replace byhand_manipadrsHP = "CL 70A # 13A - 49" in 10163
replace byhand_manipadrsHP = "KR 1 # 70 - " in 10167
replace byhand_manipadrsHP = "KR 1 # 70A - 14 " in 10167
replace byhand_manipadrsHP = "CL 70B Bis # 1 3 - 26" in 10173
replace byhand_manipadrsHP = "CL 70B Bis # 1 3 - 26" in 10174
replace byhand_manipadrsHP = "KR 1A5" in 10175
replace byhand_manipadrsHP = "KR 1A # 70A - 72" in 10176
replace byhand_manipadrsHP = "KR 1AB Bis" in 10181
replace byhand_manipadrsHP = "KR 1A A1 # 70D - 11" in 10182
replace byhand_manipadrsHP = "CL 70A # 1A4B - 35" in 10183
replace byhand_manipadrsHP = "" in 10184
replace byhand_manipadrsHP = "KR 1LN # 82 - 34" in 10190
replace byhand_manipadrsHP = "CL 70A1A # 223B - 17" in 10192
replace byhand_manipadrsHP = "CL 70A # 1A - 304" in 10195
replace byhand_manipadrsHP = "KR 1A # 7A Bis - 33" in 10196
replace byhand_manipadrsHP = "CL 70 # 2AN 1S1N - 203" in 10199
replace byhand_manipadrsHP = "CL 70 # 2AN  1S1N - 203" in 10200
replace byhand_manipadrsHP = "CL 70C # 1A3 - 14" in 10201
replace byhand_manipadrsHP = "CL 60A # 2D - 14" in 10202
replace byhand_manipadrsHP = "KR 1D1BN # 57 - 154" in 10204
replace byhand_manipadrsHP = "KR 1D # 2A 57 - 26" in 10210
replace byhand_manipadrsHP = "KR 1AF # 57 - 63" in 10217
replace byhand_manipadrsHP = "KR 2 E # 59D - 53" in 10220
replace byhand_manipadrsHP = "KR 3 N # 71I - 206" in 10221
replace byhand_manipadrsHP = "CL 56 # 1E - 41B" in 10225
replace byhand_manipadrsHP = "KR 1C3 # 53B - 02" in 10226
replace byhand_manipadrsHP = "KR 1A Bis # 52 - 26" in 10228
replace byhand_manipadrsHP = "KR 2DB # 59D - 35" in 10231
replace byhand_manipadrsHP = "KR 1D Bis # 59C - 1B" in 10233
replace byhand_manipadrsHP = "KR 1D1 # 52 - 74" in 10237
replace byhand_manipadrsHP = "KR 1C4 # 53B - 05" in 10238
replace byhand_manipadrsHP = "KR 2AC # 57 - 93" in 10241
replace byhand_manipadrsHP = "KR 1D1 # 52 - 40" in 10244
replace byhand_manipadrsHP = "CL 52A # 1F - 90" in 10246
replace byhand_manipadrsHP = "KR 1D2A # 57 - 14" in 10247
replace byhand_manipadrsHP = "CL 61 # 1B - 90" in 10248
replace byhand_manipadrsHP = "KR 40 # 7 - 679" in 10262
replace byhand_manipadrsHP = "KR 39 # 9B - 56" in 10263
replace byhand_manipadrsHP = "CL 4B O # 73D Bis - 86" in 10279
replace byhand_manipadrsHP = "CL 2C 3 O # 76B - 76" in 10280

replace byhand_manipadrsHP = "CL 2C O # 74 E - 98" in 10292
replace byhand_manipadrsHP = "KR 67 O # 3 - 16" in 10299
replace byhand_manipadrsHP = "CL 3 O #71 Bis - 04" in 10300
replace byhand_manipadrsHP = "KR 76 BO # 2C - 316" in 10301
replace byhand_manipadrsHP = "KR 76 BO # 2C - 316" in 10302
replace byhand_manipadrsHP = "KR 76 BO # 2C - 316" in 10303	

replace byhand_manipadrsHP = "CL 3 O # 73B - 55" in 10335
replace byhand_manipadrsHP = "KR 73 O" in 10337
replace byhand_manipadrsHP = "CL 3 O # 74G - 33" in 10351
replace byhand_manipadrsHP = "CL 3 O # 74G - 33" in 10352
replace byhand_manipadrsHP = "KR 26I2 # 72U - 37" in 10353
replace byhand_manipadrsHP = "CL 2C O # 73C - 71" in 10358
replace byhand_manipadrsHP = "KR 69 # 3 O - 16" in 10370
replace byhand_manipadrsHP = "CL 3 # 66C - 12" in 10375
replace byhand_manipadrsHP = "CL 55 # 29A - 80" in 10386
replace byhand_manipadrsHP = "CL 72Z2 # 28F - 87" in 10387
replace byhand_manipadrsHP = "CL 55 # 32A - 49" in 10390
replace byhand_manipadrsHP = "CL 52 # 29B - 32" in 10398
replace byhand_manipadrsHP = "CL 54 # 29A - 24" in 10407

replace byhand_manipadrsHP = "KR 28D # 72F4 - 59" in 10409
replace byhand_manipadrsHP = "CL 72S # 28 1 - 77" in 10422
replace byhand_manipadrsHP = "CL 52 # 29B - 52" in 10436
replace byhand_manipadrsHP = "KR 28D1 # 72F4 - 94" in 10439
replace byhand_manipadrsHP = "CL 56A # 32A - 38" in 10445
replace byhand_manipadrsHP = "CL 72I # 27C - 61" in 10453
replace byhand_manipadrsHP = "CL 805 # 32" in 10463
replace byhand_manipadrsHP = "KR 28D2 # 72 N - 53" in 10480
replace byhand_manipadrsHP = "KR 28D # 72F4 - 115" in 10491
replace byhand_manipadrsHP = "KR 28D2 # 72F4 - 115" in 10491
replace byhand_manipadrsHP = "KR 28 2 # 72T - 87" in 10494
replace byhand_manipadrsHP = "CL 54 # 29A - 74" in 10499
replace byhand_manipadrsHP = "KR 28 1 # 72T - 114" in 10503
replace byhand_manipadrsHP = "CL 72P # 28 1 - 31" in 10512
replace byhand_manipadrsHP = "CL 84 # 3BN - 60" in 10526
replace byhand_manipadrsHP = "CL 56GN # 49A - 07" in 10536
replace byhand_manipadrsHP = "KR 28J # 72Z - 232" in 10541
replace byhand_manipadrsHP = "CL 52A # 30A - 52" in 10554
replace byhand_manipadrsHP = "CL 72P # 28I - 62" in 10560

replace byhand_manipadrsHP = "KR 28D2 # 72P - 45" in 10564
replace byhand_manipadrsHP = "CL 76 # 30B - 20" in 10565
replace byhand_manipadrsHP = "CL 72S # 28 1 - 125" in 10576
replace byhand_manipadrsHP = "KR 28D # 72P - 35" in 10580
replace byhand_manipadrsHP = "KR 28E # 72G - 66" in 10592
replace byhand_manipadrsHP = "CL 52AA # 30A - 94" in 10595
replace byhand_manipadrsHP = "CL 52A # 30A - 94" in 10595
replace byhand_manipadrsHP = "KR 28B # 72T - 38" in 10602
replace byhand_manipadrsHP = "CL 72S # 28 1 - 125" in 10608
replace byhand_manipadrsHP = "KR 33 #" in 10622
replace byhand_manipadrsHP = "CL 72 2Q # 28A - 102" in 10628
replace byhand_manipadrsHP = "CL 54B # 29A - 03" in 10633
replace byhand_manipadrsHP = "CL 54 4 # 30B - 87" in 10638
replace byhand_manipadrsHP = "CL 72S # 28 1 - 81" in 10642
replace byhand_manipadrsHP = "CL 5 # 30B - 19" in 10656
replace byhand_manipadrsHP = "CL 78 # 28F - 51" in 10662
replace byhand_manipadrsHP = "CL 72L2 # 28F - 82" in 10664

replace byhand_manipadrsHP = "CL 50 # 29A - 18" in 10670
replace byhand_manipadrsHP = "CL 72L # 28B - 46" in 10680
replace byhand_manipadrsHP = "CL 76 # 28F - 20" in 10706

replace byhand_manipadrsHP = "CL 35 # 29A - 49" in 10717
replace byhand_manipadrsHP = "KR 31 # 35B - 48" in 10726
replace byhand_manipadrsHP = "CL 35D # 29A - 27" in 10727
replace byhand_manipadrsHP = "DG 29B # 27 - 17" in 10730
replace byhand_manipadrsHP = "KR 33 # 33C - 133" in 10734
replace byhand_manipadrsHP = "DG 2 QB # 27 - 05" in 10735
replace byhand_manipadrsHP = "CL 35D # 29A - 27" in 10736
replace byhand_manipadrsHP = "KR 29 # 35 E - 17" in 10750
replace byhand_manipadrsHP = "DG 29A # 28 - 34" in 10762
replace byhand_manipadrsHP = "KR 29 3 # 35 - 10" in 10764
replace byhand_manipadrsHP = "KR 76C # 2B - 15" in 10770
replace byhand_manipadrsHP = "TV 2A # 1C - 140 - B" in 10771
replace byhand_manipadrsHP = "TV 2A # 1C - 140B" in 10771
replace byhand_manipadrsHP = "KR 72A 19 # 71A - 95" in 10778
replace byhand_manipadrsHP = "KR 72A # 71A - 95" in 10778
replace byhand_manipadrsHP = "CL 19 # 71A - 95" in 10778
replace byhand_manipadrsHP = "CL 79 # 4 N - 86" in 10782
replace byhand_manipadrsHP = "CL 72C # 4CN - 09" in 10783
replace byhand_manipadrsHP = "KR 8 N # 91J - 30" in 10785
replace byhand_manipadrsHP = "CL 71B # 8N - 41" in 10793
replace byhand_manipadrsHP = "CL 72C # 5N - 45" in 10794
replace byhand_manipadrsHP = "CL 72 CN # 4CN - 23" in 10796
replace byhand_manipadrsHP = "KR 4C # 71F - 59" in 10797
replace byhand_manipadrsHP = "CL 72A Bis # 8N - 49" in 10804
replace byhand_manipadrsHP = "CL 72A Bis # 8N - 49" in 10805
replace byhand_manipadrsHP = "CL 70 Bis # 4CN - 103" in 10808
replace byhand_manipadrsHP = "CL 71B N # 8N - 36" in 10809
replace byhand_manipadrsHP = "CL 71B N # 8N - 36" in 10810
replace byhand_manipadrsHP = "CL 71 # 4CN - 15" in 10815

replace byhand_manipadrsHP = "CL 62 # 2B - 32" in 10823
replace byhand_manipadrsHP = "KR 2B # 65A - 32" in 10825
replace byhand_manipadrsHP = "KR 26K # 72U - 28" in 10838
replace byhand_manipadrsHP = "DG 26G11 # 72U - 54" in 10841
replace byhand_manipadrsHP = "KR 26I # 72U - 79" in 10843
replace byhand_manipadrsHP = "CL 11A # 33" in 10848
replace byhand_manipadrsHP = "CL 72P # 26H3 - 23" in 10850
replace byhand_manipadrsHP = "CL 72E52 # 26K - 21" in 10851
replace byhand_manipadrsHP = "KR 26H2 # 72U - 49" in 10852
replace byhand_manipadrsHP = "KR 26H2 # 72U - 49" in 10853
replace byhand_manipadrsHP = "KR 26I1 # 72P1 - 87" in 10854
replace byhand_manipadrsHP = "KR 26 # 72WS - 31" in 10869
replace byhand_manipadrsHP = "" in 10871
replace byhand_manipadrsHP = "KR 26M # 72U - 85" in 10878
replace byhand_manipadrsHP = "KR 26I1 # 72N - 46" in 10881

replace byhand_manipadrsHP = "KR 26K # 72P1 - 16" in 10882
replace byhand_manipadrsHP = "KR 26H3 # 72W - 15" in 10883
replace byhand_manipadrsHP = "KR 26I # 72P - 1" in 10884
replace byhand_manipadrsHP = "CL 72P # 26 1 - 110" in 10885
replace byhand_manipadrsHP = "CL 72P # 26 1 - 110" in 10886
replace byhand_manipadrsHP = "CL 72P # 26 1 - 110" in 10887
replace byhand_manipadrsHP = "CL 72P # 26 1 - 110" in 10888
replace byhand_manipadrsHP = "KR 26I 1 # 72W - 03" in 10897
replace byhand_manipadrsHP = "KR 26H3 # 72P1 - 27" in 10898
replace byhand_manipadrsHP = "KR 26I2 # 72P - 16" in 10899
replace byhand_manipadrsHP = "KR 26I1 # 72P1 - 10" in 10901

replace byhand_manipadrsHP = "KR 26H # 72U - 82" in 10913
replace byhand_manipadrsHP = "KR 26K # 72U - 56" in 10919
replace byhand_manipadrsHP = "KR 26F N # 740 - 32" in 10940
replace byhand_manipadrsHP = "KR 26I2 # 72P1 - 52" in 10942
replace byhand_manipadrsHP = "CL 72P # 26L - 03" in 10948
replace byhand_manipadrsHP = "KR 26H3 # 72P - 10" in 10950
replace byhand_manipadrsHP = "CL 72 # 26G - 445" in 10963
replace byhand_manipadrsHP = "CL 2 # 22 - 47" in 10970

replace byhand_manipadrsHP = "KR 18 N # 3 - 02B" in 10986
replace byhand_manipadrsHP = "CL 2AB # 18 - 28" in 10987
replace byhand_manipadrsHP = "KR 26H9 # 123 - 10" in 11005
replace byhand_manipadrsHP = "KR 26G3 # 75 - 10" in 11012
replace byhand_manipadrsHP = "KR 26G3 # 75 - 10" in 11013
replace byhand_manipadrsHP = "KR 26G3 # 75 - 10" in 11014

replace byhand_manipadrsHP = "CL 78 # 26G - 94" in 11016
replace byhand_manipadrsHP = "CL 88 # 26B - 36" in 11033
replace byhand_manipadrsHP = "KR 80A # 26G2 - 47" in 11035
replace byhand_manipadrsHP = "CL 80AN # 26D - 11" in 11036
replace byhand_manipadrsHP = "CL 76 # 26B - 12" in 11039
replace byhand_manipadrsHP = "CL 80 Bis # 26C - 55" in 11044
replace byhand_manipadrsHP = "CL 80 # 26F - 05" in 11046
replace byhand_manipadrsHP = "CL 79 # 26G3 - 22" in 11056
replace byhand_manipadrsHP = "CL 80 # 103 - 28" in 11062
replace byhand_manipadrsHP = "CL 62B # 1A9 - 75" in 11066

replace byhand_manipadrsHP = "CL 58 # 1D - 56" in 11067
replace byhand_manipadrsHP = "CL 58 # 1D - 56" in 11068
replace byhand_manipadrsHP = "KR 1B3 # 61A - 26" in 11071
replace byhand_manipadrsHP = "KR 1B33 # 61A - 26" in 11071
replace byhand_manipadrsHP = "KR 1 # 66" in 11072

replace byhand_manipadrsHP = "KR 1F # 61A - 14" in 11076
replace byhand_manipadrsHP = "CL 62B # 1A9 - 365" in 11078
replace byhand_manipadrsHP = "CL 64 # 1" in 11082
replace byhand_manipadrsHP = "KR 1B1 # 61A - 25" in 11086
replace byhand_manipadrsHP = "KR 1 C2 # 61A - 69" in 11087
replace byhand_manipadrsHP = "KR 1C2 # 61A - 69" in 11088
replace byhand_manipadrsHP = "KR 2A1 # 59D - 25" in 11090
replace byhand_manipadrsHP = "CL 62B # 1A9 - 365" in 11111
replace byhand_manipadrsHP = "KR 1B2 # 59 - 126" in 11112

replace byhand_manipadrsHP = "KR 1D Bis # 61A - 32" in 11113
replace byhand_manipadrsHP = "CL 62A # 6 - 185" in 11118
replace byhand_manipadrsHP = "CL 62A # 1A - 6 - 185" in 11118
replace byhand_manipadrsHP = "KR 1E Bis # 61B - 34" in 11121
replace byhand_manipadrsHP = "KR 1B2 # 61 - 03" in 11122
replace byhand_manipadrsHP = "CL 59 # 1 Bis - 35" in 11123
replace byhand_manipadrsHP = "CL 59 # 1 Bis - 35" in 11124
replace byhand_manipadrsHP = "KR 1B2 # 61A - 57" in 11125
replace byhand_manipadrsHP = "CL 69A # 7ML Bis - 742" in 11127

replace byhand_manipadrsHP = "KR 7L Bis # 67 - 64" in 11129
replace byhand_manipadrsHP = "KR 7L Bis # 67 - 64" in 11130
replace byhand_manipadrsHP = "PJ 7F13 # 68A - 53" in 11132
replace byhand_manipadrsHP = "KR 7ME Bis # 78 - 72" in 11136
replace byhand_manipadrsHP = "CL 69A # 7B Bis - 70" in 11140
replace byhand_manipadrsHP = "PJ 7F # 68A - 64" in 11142
replace byhand_manipadrsHP = "CL 62A # 2E1 - 57" in 11147
replace byhand_manipadrsHP = "CL 72R # 25D5 - 10" in 11150
replace byhand_manipadrsHP = "CL 72 # 28BS - 28" in 11153
replace byhand_manipadrsHP = "CL 72L 32 # 8 E - 26" in 11160
replace byhand_manipadrsHP = "CL 72R # 28D5 - 59" in 11166
replace byhand_manipadrsHP = "CL 72L # 28D2 - 25" in 11167
replace byhand_manipadrsHP = "CL 72 L1 # 28G - 07" in 11170
replace byhand_manipadrsHP = "CL 72L 1 # 28I - 01" in 11172
replace byhand_manipadrsHP = "CL 72L 1 # 28I - 01" in 11173
replace byhand_manipadrsHP = "CL 72L 1 # 28I - 01" in 11174
replace byhand_manipadrsHP = "CL 72L 1 # 28I - 01" in 11175
replace byhand_manipadrsHP = "CL 72L2 # 28E3 - 74" in 11182
replace byhand_manipadrsHP = "CL 72S # 28E2 - 22" in 11201
replace byhand_manipadrsHP = "CL 72S # 28E2 - 22" in 11202

replace byhand_manipadrsHP = "CL 72Z2 # 28F - 27" in 11209
replace byhand_manipadrsHP = "CL 72L2 # 28F - 31" in 11210
replace byhand_manipadrsHP = "CL 72L1 # 28 - 27" in 11216
replace byhand_manipadrsHP = "CL 72L2 # 28F - 27" in 11217
replace byhand_manipadrsHP = "CL 72 # 28E - 82" in 11221
replace byhand_manipadrsHP = "CL 72L2 # 28F - 27" in 11222
replace byhand_manipadrsHP = "CL 72K # 28D4 - 35" in 11223
replace byhand_manipadrsHP = "KR 3 O E # 73B - 20" in 11234
replace byhand_manipadrsHP = "KR 3 O E # 73B - 20" in 11235
replace byhand_manipadrsHP = "KR 74 # 1A - 79" in 11236
replace byhand_manipadrsHP = "KR 75 # 1 Bis - 37" in 11247
replace byhand_manipadrsHP = "DG F1 # 73 - 53" in 11252
replace byhand_manipadrsHP = "KR 75A O # 2B - 13" in 11255
replace byhand_manipadrsHP = "DG 1 # 73 - 53" in 11252
replace byhand_manipadrsHP = "CL 3 DN # 75 - 21" in 11259

replace byhand_manipadrsHP = "KR 74B # 1B" in 11265
replace byhand_manipadrsHP = "KR 73B # 1B - 51" in 11274
replace byhand_manipadrsHP = "KR 72 # 1A - 77" in 11278
replace byhand_manipadrsHP = "TV 2 3 # 1 - 76" in 11282
replace byhand_manipadrsHP = "CL 1 Bis O # 73B - 53" in 11283
replace byhand_manipadrsHP = "KR 74A3 # 98 - 103" in 11285
replace byhand_manipadrsHP = "CL 3 O # 66C - 31" in 11291
replace byhand_manipadrsHP = "CL 3 O # 66C - 31" in 11292
replace byhand_manipadrsHP = "CL 99 N # 26G - 04" in 11298
replace byhand_manipadrsHP = "CL 117 # 26H - 130" in 11310

replace byhand_manipadrsHP = "CL 35 # 7A - 102" in 11311
replace byhand_manipadrsHP = "CL 111 # 26Q" in 11312
replace byhand_manipadrsHP = "CL 108 # 26H1 - 24" in 11314
replace byhand_manipadrsHP = "CL 108 # 26H1 - 24" in 11315
replace byhand_manipadrsHP = "CL 106 # 26 O - 10" in 11321
replace byhand_manipadrsHP = "CL 120 # 26I - 52" in 11322
replace byhand_manipadrsHP = "CL 107 # 26P - 45" in 11340
replace byhand_manipadrsHP = "CL 117 # 26H - 18" in 11346
replace byhand_manipadrsHP = "KR 26H3 # 112 - 162" in 11358
replace byhand_manipadrsHP = "CL 99 N # 26I2 - 04" in 11377

replace byhand_manipadrsHP = "KR 26 # 8 112 - 148" in 11385
replace byhand_manipadrsHP = "CL 114 3 # 26I - 68" in 11393
replace byhand_manipadrsHP = "KR 26I # 123 - 56" in 11394
replace byhand_manipadrsHP = "CL 107 # 26L " in 11400
replace byhand_manipadrsHP = "CL 116 # 26I - 24" in 11409
replace byhand_manipadrsHP = "CL 104 # 26I - 10" in 11425
replace byhand_manipadrsHP = "CL 104 # 26I - 10" in 11426
replace byhand_manipadrsHP = "CL 26 # 117I - 13 - 11B" in 11434
replace byhand_manipadrsHP = "CL 112 # 26I - 66" in 11437
replace byhand_manipadrsHP = "KR 26I # 103A - 16" in 11438
replace byhand_manipadrsHP = "CL 115 # 26Q - 120" in 11447
replace byhand_manipadrsHP = "CL 40 # 1A - 18" in 11455

replace byhand_manipadrsHP = "KR 40M # 30C - 71" in 11476
replace byhand_manipadrsHP = "KR 43 # 24" in 11478
replace byhand_manipadrsHP = "CL 39A # 47C - 16" in 11502

replace byhand_manipadrsHP = "KR 46A # 38A - 55" in 11540
replace byhand_manipadrsHP = "KR 46C # 38A - 49" in 11542
replace byhand_manipadrsHP = "KR 46B  # 46 - 73" in 11543
replace byhand_manipadrsHP = "KR 47 # 42A - 43" in 11584
replace byhand_manipadrsHP = "KR 49A # 42 - 76" in 11590
replace byhand_manipadrsHP = "KR 48A # 44 - 97" in 11619

replace byhand_manipadrsHP = "KR 47 # 46 - 29" in 11663
replace byhand_manipadrsHP = "CL 39A # 46A - 13" in 11672
replace byhand_manipadrsHP = "CL 42 N # 46A - 18" in 11675
replace byhand_manipadrsHP = "KR 46 # 41A - 26" in 11724
replace byhand_manipadrsHP = "KR 47 # 36H - 113" in 11736
replace byhand_manipadrsHP = "CL 2A # 74B - 15" in 11761
replace byhand_manipadrsHP = "CL 2A # 74B - 15" in 11762
replace byhand_manipadrsHP = "DG 26P # 86 - 60" in 11763

replace byhand_manipadrsHP = "DG 26P1 # 83 - 32" in 11768
replace byhand_manipadrsHP = "DG P2 # 93 - 74" in 11769
replace byhand_manipadrsHP = "DG 26N # 96 - 17" in 11772

replace byhand_manipadrsHP = "TV 103 # 26P4 - 20" in 11775
replace byhand_manipadrsHP = "TV 103 # 26P4 - 20" in 11776
replace byhand_manipadrsHP = "KR 26H3H # 72W - 33" in 11780
replace byhand_manipadrsHP = "DG 26 G5 # 72T - 17" in 11783
replace byhand_manipadrsHP = "DG 26 G5 # 72T - 17" in 11784
replace byhand_manipadrsHP = "DG 26 G5 # 72T - 17" in 11785
replace byhand_manipadrsHP = "DG 26 G5 # 72T - 17" in 11786
replace byhand_manipadrsHP = "DG 26P2 # 92 - 123" in 11789
replace byhand_manipadrsHP = "DG 26G4 # 72T - 74" in 11790
replace byhand_manipadrsHP = "DG 26P 19 # 105 - 15" in 11796
replace byhand_manipadrsHP = "DG 26I # 96 - 81" in 11797
replace byhand_manipadrsHP = "DG 26G10 # 72U - 70" in 11802
replace byhand_manipadrsHP = "DG 26G5 # 72U - 46" in 11804
replace byhand_manipadrsHP = "DG 26G8 # 1N2T - 66" in 11806
replace byhand_manipadrsHP = "DG 26G10 # 62T - 18" in 11810
replace byhand_manipadrsHP = "CL 71" in 11815
replace byhand_manipadrsHP = "CL 71" in 11816
replace byhand_manipadrsHP = "CL 26I3 # 105 - 155" in 11818
replace byhand_manipadrsHP = "KR 26H4 # 96 - 63" in 11819
replace byhand_manipadrsHP = "DG 26I2 # 87 - 54" in 11822
replace byhand_manipadrsHP = "DG 26P5 # 80 - 74" in 11823
replace byhand_manipadrsHP = "DG 26H4 # 73 - 67" in 11824
replace byhand_manipadrsHP = "DG 26BP2 # 93 - 80" in 11828
replace byhand_manipadrsHP = "DG 26 # 6P - 18" in 11837
replace byhand_manipadrsHP = "DG 6H3 # 83 - 04" in 11839
replace byhand_manipadrsHP = "DG 26 # 72U - 52" in 11847
replace byhand_manipadrsHP = "DG 26 64 # 72U - 52" in 11847
replace byhand_manipadrsHP = "DG 26F22 # 104 - 03" in 11848
replace byhand_manipadrsHP = "DG 26 P22 # 104 - 03" in 11849
replace byhand_manipadrsHP = "DG 26P # 87 - 46" in 11854
replace byhand_manipadrsHP = "DG 26G4 # 72U - 45" in 11856
replace byhand_manipadrsHP = "DG 26P3 # 83 - 39" in 11857
replace byhand_manipadrsHP = "DG 26P8 # 105 - 11" in 11858
replace byhand_manipadrsHP = "DG 26G11 # 72S1 - 53" in 11864
replace byhand_manipadrsHP = "DG 26P19 # 105B - 17" in 11867
replace byhand_manipadrsHP = "DG 26P9 # 105A - 03" in 11868
replace byhand_manipadrsHP = "KR 26G # 73" in 11879
replace byhand_manipadrsHP = "KR 26G # 73" in 11880
replace byhand_manipadrsHP = "KR 26G # 73" in 11881
replace byhand_manipadrsHP = "DG 26 # 73 - 13" in 11883
replace byhand_manipadrsHP = "DG 26G5 # 72U - 60" in 11890
replace byhand_manipadrsHP = "DG 26 # 87 - 24" in 11892
replace byhand_manipadrsHP = "DG 26P # 105A - 15" in 11893

replace byhand_manipadrsHP = "DG 26H1 # 83 - 73" in 11895
replace byhand_manipadrsHP = "DG 26K # 83 - 26" in 11896
replace byhand_manipadrsHP = "DG 26P3 # 93 - 59" in 11899
replace byhand_manipadrsHP = "DG 26P16 # 93 - 17" in 11902
replace byhand_manipadrsHP = "DG 26I1 # 87 - 10" in 11903
replace byhand_manipadrsHP = "DG 26G 7 # 72T - 53" in 11904
replace byhand_manipadrsHP = "DG 26B4 # 96 - 80" in 11908
replace byhand_manipadrsHP = "" in 11909
replace byhand_manipadrsHP = "DG 26G5 # 73 - 14" in 11912

replace byhand_manipadrsHP = "KR 26I2 # 96 - 74" in 11914
replace byhand_manipadrsHP = "DG 26G12 # 77 - 83" in 11918
replace byhand_manipadrsHP = "DG 26P14 # 105A - 66" in 11922
replace byhand_manipadrsHP = "DG 26P14 # 105A - 66" in 11923
replace byhand_manipadrsHP = "DG 26P14 # 105A - 66" in 11924
replace byhand_manipadrsHP = "DG 26G10 # 72 - 46" in 11925
replace byhand_manipadrsHP = "DG 26P8 # 105 - 24" in 11926
replace byhand_manipadrsHP = "DG 26 O # 83 - 32" in 11927
replace byhand_manipadrsHP = "KR 26L # 72W1 - 53" in 11930
replace byhand_manipadrsHP = "DG 26I1 # 73 - 81" in 11931
replace byhand_manipadrsHP = "DG 26G7 # 72 - 11" in 11932
replace byhand_manipadrsHP = "DG 26J # 77 - 57" in 11937
replace byhand_manipadrsHP = "DG 26G6 # 72T - 38" in 11938
replace byhand_manipadrsHP = "DG 26G6 # 72T - 38" in 11939
replace byhand_manipadrsHP = "DG 26 4 # 180 - 24" in 11942
replace byhand_manipadrsHP = "DG 26G4 # 60" in 11943
replace byhand_manipadrsHP = "CL 26B2 # 73D - 10" in 11944
replace byhand_manipadrsHP = "DG 26P18 # 105A - 39" in 11946
replace byhand_manipadrsHP = "DG 26I3 # 96 - 38" in 11947
replace byhand_manipadrsHP = "DG 26K # 87 - 38" in 11950
replace byhand_manipadrsHP = "DG 26 4 # 93 - 25" in 11951
replace byhand_manipadrsHP = "DG 26 1 # 73 - 73" in 11956
replace byhand_manipadrsHP = "DG 26P15 # 105A - 11" in 11960

replace byhand_manipadrsHP = "DG 26P15 # 105A - 11" in 11961
replace byhand_manipadrsHP = "DG 26P1 # 73 - 39" in 11966
replace byhand_manipadrsHP = "DG 26B1 # 73 - 52" in 11969
replace byhand_manipadrsHP = "CL 103D # 26P10 - 94 - 74" in 11971
replace byhand_manipadrsHP = "KR 82 # 6A - 17" in 11973

replace byhand_manipadrsHP = "KR 85C # 9 - 28" in 11975
replace byhand_manipadrsHP = "KR 83 # 6A - 32" in 11982
replace byhand_manipadrsHP = "KR 84 # 13B1 - 48" in 12004

replace byhand_manipadrsHP = "CL 9 # 83A - 24" in 12015
replace byhand_manipadrsHP = "KR 94D # 80" in 12026
replace byhand_manipadrsHP = "CL 94D O # 1A - 56" in 12031
replace byhand_manipadrsHP = "KR 93 O # 2C - 13" in 12046
replace byhand_manipadrsHP = "KR 93 O # 2C - 13" in 12047
replace byhand_manipadrsHP = "KR 97 # 2A - 44" in 12054
replace byhand_manipadrsHP = "KR 97 # 2A - 44" in 12055
replace byhand_manipadrsHP = "KR 92 # 2C - 30" in 12061
replace byhand_manipadrsHP = "KR 94A1 E # 4A - 11" in 12067
replace byhand_manipadrsHP = "KR 100A O # 1D - 10" in 12080

replace byhand_manipadrsHP = "KR 9AB # 3 - 2 - 46" in 12081
replace byhand_manipadrsHP = "CL 12 O # 94B - 12" in 12098
replace byhand_manipadrsHP = "KR 93C Bis # 2B - 12" in 12105
replace byhand_manipadrsHP = "KR 93C Bis # 2B - 12" in 12106
replace byhand_manipadrsHP = "KR 90 3 # 16 - 129" in 12107

replace byhand_manipadrsHP = "" in 12126
replace byhand_manipadrsHP = "KR 98 # 2D - 11" in 12128
replace byhand_manipadrsHP = "KR 92 O # 2C2 - 06" in 12144
replace byhand_manipadrsHP = "KR 92 O # 2C2- 06" in 12145
replace byhand_manipadrsHP = "" in 12161
replace byhand_manipadrsHP = "KR 94 O # 3 Bis - 62" in 12165
replace byhand_manipadrsHP = "KR 82 Bis" in 12180
replace byhand_manipadrsHP = "KR 82 Bis" in 12181
replace byhand_manipadrsHP = "AV 2 O # 89 - 40" in 12183
replace byhand_manipadrsHP = "AV 2 O # 89 - 40" in 12184
replace byhand_manipadrsHP = "KR 96 # 3B - 45" in 12197
replace byhand_manipadrsHP = "KR 96 # 3B - 45" in 12198
replace byhand_manipadrsHP = "KR 96 # 3B - 45" in 12199
replace byhand_manipadrsHP = "KR 96 # 3B - 45" in 12200
replace byhand_manipadrsHP = "KR 93 # 2B - 130" in 12227
replace byhand_manipadrsHP = "KR 94A O # 3 2B - 46" in 12228
replace byhand_manipadrsHP = "KR 94A O # 3 2B - 46" in 12229
replace byhand_manipadrsHP = "KR 94A O # 3 2B - 46" in 12230
replace byhand_manipadrsHP = "KR 94A O # 3 2B - 46" in 12231
replace byhand_manipadrsHP = "KR 94A O # 3 2B - 46" in 12232
replace byhand_manipadrsHP = "KR 94A O # 3 2B - 46" in 12233
replace byhand_manipadrsHP = "KR 94A O # 3 2B - 46" in 12234
replace byhand_manipadrsHP = "KR 94A O # 3 2B - 46" in 12235
replace byhand_manipadrsHP = "KR 94A O # 3 2B - 46" in 12236
replace byhand_manipadrsHP = "KR 94A O # 3 2B - 46" in 12237
replace byhand_manipadrsHP = "KR 94A O # 3 2B - 46" in 12238
replace byhand_manipadrsHP = "CL 3B # 97A - 05" in 12266

replace byhand_manipadrsHP = "CL 49 N # 6N2 - 68" in 12288
replace byhand_manipadrsHP = "AV 7AM # 53A - 77" in 12290
replace byhand_manipadrsHP = "AV 7AM # 53A - 77" in 12291
replace byhand_manipadrsHP = "AV 8 N # 52B - 20" in 12300
replace byhand_manipadrsHP = "CL 53AN # 7A - 124" in 12302
replace byhand_manipadrsHP = "CL 67 # 1AG - 24" in 12316
replace byhand_manipadrsHP = "KR 1A 11 # 69 - 94" in 12319
replace byhand_manipadrsHP = "KR 1A 9 # 69 - 16" in 12322
replace byhand_manipadrsHP = "KR 1A 11 # 69 - 38" in 12325
replace byhand_manipadrsHP = "KR 1 Bis # 62A - 95" in 12326
replace byhand_manipadrsHP = "KR 1A 9 # 69 - 39" in 12333
replace byhand_manipadrsHP = "CL 69 # 1A5 - 156" in 12337
replace byhand_manipadrsHP = "CL 1 # 21M - 02" in 12347
replace byhand_manipadrsHP = "CL 2 O # 24E - 46" in 12348
replace byhand_manipadrsHP = "CL 2 O # 24E - 46" in 12349
replace byhand_manipadrsHP = "CL 4A # 24A - 65" in 12352
replace byhand_manipadrsHP = "CL 88 # 28E - 622" in 12358
replace byhand_manipadrsHP = "CL 83 # 4 - 3" in 12360
replace byhand_manipadrsHP = "CL 84 # 28D - 244" in 12361
replace byhand_manipadrsHP = "CL 82 # 28D - 94" in 12363
replace byhand_manipadrsHP = "CL 9 # 28C - 15" in 12365
replace byhand_manipadrsHP = "CL 86A # 28E6 - 25" in 12368
replace byhand_manipadrsHP = "CL 88 # 28E3 - 40" in 12372
replace byhand_manipadrsHP = "CL 92 # 28D - 268" in 12374
replace byhand_manipadrsHP = "CL 80 # 28D4 - 52" in 12382
replace byhand_manipadrsHP = "CL 76 N # 28B - 52" in 12394
replace byhand_manipadrsHP = "CL 90 # 9028E - 19" in 12400
replace byhand_manipadrsHP = "CL 90 # 28E - 19" in 12400
replace byhand_manipadrsHP = "KR 43A # 46 - 139" in 12401
replace byhand_manipadrsHP = "CL 85 # 28D2 - 30" in 12404
replace byhand_manipadrsHP = "CL 82 # 28D2 - 106" in 12405
replace byhand_manipadrsHP = "CL 84 # 28D4 - 16" in 12406

replace byhand_manipadrsHP = "KR 28 E # 76A - 10" in 12413
replace byhand_manipadrsHP = "KR 28 E # 76A - 10" in 12414
replace byhand_manipadrsHP = "CL 82 # 28E3 - 39" in 12416
replace byhand_manipadrsHP = "CL 82 # 28E3 - 39" in 12417
replace byhand_manipadrsHP = "CL 76 # 28E2 - 96" in 12418
replace byhand_manipadrsHP = "CL 83A N # 28D - 33" in 12421
replace byhand_manipadrsHP = "CL 83A # 28D - 417" in 12425
replace byhand_manipadrsHP = "CL 85 # 28DG4 " in 12426
replace byhand_manipadrsHP = "CL 85A # 28EG - 74" in 12428
replace byhand_manipadrsHP = "CL 78 N # 28E - 228" in 12433
replace byhand_manipadrsHP = "CL 83 # 28D1 - 13" in 12436
replace byhand_manipadrsHP = "CL 88 # 28D - 275" in 12437
replace byhand_manipadrsHP = "CL 81 # 28E3 - 11" in 12443
replace byhand_manipadrsHP = "CL 79 N # 28E - 21" in 12445
replace byhand_manipadrsHP = "CL 76 # 28E1 - 09" in 12446
replace byhand_manipadrsHP = "CL 77 # 28D - 09" in 12449
replace byhand_manipadrsHP = "CL 96 # 28I - 19" in 12453
replace byhand_manipadrsHP = "CL 96 # 28I - 19" in 12454
replace byhand_manipadrsHP = "CL 94 # 28D2 - 83" in 12457
replace byhand_manipadrsHP = "CL 82 # 28D2 - 95" in 12458
replace byhand_manipadrsHP = "CL 79 # 28E6 - 57" in 12459

replace byhand_manipadrsHP = "CL 96 # 27E6 - 46" in 12466
replace byhand_manipadrsHP = "CL 82 # 28D - 75" in 12470
replace byhand_manipadrsHP = "DG 28D # 33 - 31" in 12471
replace byhand_manipadrsHP = "CL 77 # 28F - 75" in 12472
replace byhand_manipadrsHP = "CL 92 # 28D4 - 73" in 12475
replace byhand_manipadrsHP = "CL 78 #" in 12476
replace byhand_manipadrsHP = "CL 91 # 28D2 - 35" in 12480
replace byhand_manipadrsHP = "CL 96 # 28I - 18" in 12484
replace byhand_manipadrsHP = "CL 93 # 28D2 - 10" in 12485
replace byhand_manipadrsHP = "CL 86 # 28D - 39" in 12493
replace byhand_manipadrsHP = "CL 76 # 28E - 110" in 12496
replace byhand_manipadrsHP = "CL 78 # 28D - 16" in 12503
replace byhand_manipadrsHP = "CL 79 # 28D2 - 09" in 12506
replace byhand_manipadrsHP = "CL 83 # 28D2 - 22" in 12508
replace byhand_manipadrsHP = "CL 80 # 28D2 - 106" in 12515
replace byhand_manipadrsHP = "CL 80 # 28D2T - 06" in 12516
replace byhand_manipadrsHP = "CL 80 # 28D4 - 27" in 12521
replace byhand_manipadrsHP = "CL 86 # 28D1 - 09" in 12531
replace byhand_manipadrsHP = "CL 96 # 28I - 19" in 12533
replace byhand_manipadrsHP = "CL 112 # 28 2 - 12" in 12543
replace byhand_manipadrsHP = "CL 81 # 28D2 - 71" in 12551
replace byhand_manipadrsHP = "CL 77 # 28E5 - 29" in 12552
replace byhand_manipadrsHP = "CL 77 # 28E5 - 29" in 12553
replace byhand_manipadrsHP = "CL 96 3 # 28H - 04" in 12564
replace byhand_manipadrsHP = "CL 83B1 # 45 - 61" in 12567
replace byhand_manipadrsHP = "CL 90 # 28K1 - 45" in 12571
replace byhand_manipadrsHP = "CL 85 # 28D2 - 50" in 12572
replace byhand_manipadrsHP = "CL 92 # 28E4 - 64" in 12579
replace byhand_manipadrsHP = "CL 86 # 28D - 61" in 12585

replace byhand_manipadrsHP = "KR 26G # 12 - 63" in 12601
replace byhand_manipadrsHP = "CL 77 # 28D2 - 27" in 12606
replace byhand_manipadrsHP = "KR 28D1 # 85 - 20" in 12614
replace byhand_manipadrsHP = "CL 85 # 28E - 341" in 12627
replace byhand_manipadrsHP = "CL 57 # 28 - 82" in 12641

replace byhand_manipadrsHP = "CL 91 # 28D - 86" in 12645
replace byhand_manipadrsHP = "CL 76A # 28DZ - 35" in 12646
replace byhand_manipadrsHP = "CL 76A # 28D2 - 35" in 12646
replace byhand_manipadrsHP = "CL 83 # 28E3 - 67" in 12652
replace byhand_manipadrsHP = "KR 28G # 107" in 12664
replace byhand_manipadrsHP = "CL 85A # 28E6 - 70" in 12679
replace byhand_manipadrsHP = "KR 28E5 # 36E - 17" in 12683
replace byhand_manipadrsHP = "CL 26 # 28C - 06" in 12691
replace byhand_manipadrsHP = "" in 12693
replace byhand_manipadrsHP = "CL 44" in 12694
replace byhand_manipadrsHP = "AV 43B O # 5B - 53" in 12696
replace byhand_manipadrsHP = "CL 5 O # 43A - 01" in 12700
replace byhand_manipadrsHP = "CL 33B O # 5A - 44" in 12703
replace byhand_manipadrsHP = "AV 46 O # 10C - 30" in 12711
replace byhand_manipadrsHP = "CL 9 O # 43A - 43" in 12717
replace byhand_manipadrsHP = "KR 95 # 11 - 73" in 12731
replace byhand_manipadrsHP = "CL 33F # 11M - 28" in 12740
replace byhand_manipadrsHP = "CL 1A11G # 33A - 100" in 12746

replace byhand_manipadrsHP = "DG 72E Bis # 15 - 26L72" in 12758
replace byhand_manipadrsHP = "KR 11B # 33B - 44" in 12761
replace byhand_manipadrsHP = "KR 11F # 33F - 63" in 12763
replace byhand_manipadrsHP = "KR 11F # 33F - 33" in 12764
replace byhand_manipadrsHP = "CL 31 # 11G - 26" in 12772
replace byhand_manipadrsHP = "KR 11C # 33A - 37" in 12774
replace byhand_manipadrsHP = "KR 79 # 1B2 - 16" in 12790
replace byhand_manipadrsHP = "KR 80 # 2C - 33" in 12793
replace byhand_manipadrsHP = "KR 77 # 3A - 22" in 12796
replace byhand_manipadrsHP = "CL 21B N # 78A - 30" in 12806
replace byhand_manipadrsHP = "KR 76C # 2D - 77" in 12809
replace byhand_manipadrsHP = "KR 5 O # 2 - 58" in 12810
replace byhand_manipadrsHP = "KR 82 # 1B - 06" in 12821
replace byhand_manipadrsHP = "KR 82 # 1B - 06" in 12822
replace byhand_manipadrsHP = "KR 82 # 1B - 06" in 12823
replace byhand_manipadrsHP = "KR 82 # 1B - 06" in 12824
replace byhand_manipadrsHP = "KR 82 # 1B - 06" in 12825
replace byhand_manipadrsHP = "TV 2A # 74 Bis 5 - 97" in 12826
replace byhand_manipadrsHP = "KR 78 # 2C - 105" in 12829
replace byhand_manipadrsHP = "KR 78 # 2C - 105" in 12830
replace byhand_manipadrsHP = "KR 78 # 2C - 105" in 12831
replace byhand_manipadrsHP = "KR 78 # 2C - 105" in 12832
replace byhand_manipadrsHP = "KR 78 # 2C - 105" in 12833
replace byhand_manipadrsHP = "KR 78 # 2C - 105" in 12834
replace byhand_manipadrsHP = "KR 78 # 2C - 105" in 12835
replace byhand_manipadrsHP = "KR 78 # 2C - 105" in 12836
replace byhand_manipadrsHP = "KR 78 # 2C - 105" in 12837
replace byhand_manipadrsHP = "KR 78A # 1 Bis - 10" in 12857
replace byhand_manipadrsHP = "CL 2B Bis O # 82D - 11" in 12860
replace byhand_manipadrsHP = "CL 2B # 76C - 26" in 12865

replace byhand_manipadrsHP = "KR 78 # 3 - 56" in 12872
replace byhand_manipadrsHP = "KR 94 1 # 3 O - 66" in 12888
replace byhand_manipadrsHP = "KR 94 1 # 3 O - 66" in 12889
replace byhand_manipadrsHP = "CL 79 # 26C1 - 12" in 12891
replace byhand_manipadrsHP = "CL 79 # 26C1 - 12" in 12892
replace byhand_manipadrsHP = "KR 3D O # 82C - 32" in 12893
replace byhand_manipadrsHP = "KR 3D O # 82C - 32" in 12894
replace byhand_manipadrsHP = "KR 77 # 3D - 92" in 12923
replace byhand_manipadrsHP = "KR 78 N # 2C - 91B" in 12929
replace byhand_manipadrsHP = "KR 77A # 2A - 37" in 12948
replace byhand_manipadrsHP = "KR 93C Bis O # 2B - 30" in 12955
replace byhand_manipadrsHP = "CL 2 O # 7 Bis C - 232" in 12956
replace byhand_manipadrsHP = "CL 1B O # 4 O - 201" in 12961
replace byhand_manipadrsHP = "CL 1B # 4A - 201" in 12962
replace byhand_manipadrsHP = "AV 7 O" in 12963
replace byhand_manipadrsHP = "CL 50 # 25A - 30" in 12968
replace byhand_manipadrsHP = "KR 25A # 56A - 10" in 12979
replace byhand_manipadrsHP = "CL 70 # 26I - 14" in 12986
replace byhand_manipadrsHP = "CL 70 # 28B - 06" in 12995
replace byhand_manipadrsHP = "KR 24B # 59A - 23" in 12997
replace byhand_manipadrsHP = "KR 26 O # 54 - 56" in 13004
replace byhand_manipadrsHP = "KR 26M2 # 49 - 04" in 13007
replace byhand_manipadrsHP = "KR 26 5N # 52 - 39" in 13018
replace byhand_manipadrsHP = "KR 17D # 28A - 43" in 13036
replace byhand_manipadrsHP = "CL 57 # 24B - 14" in 13053
replace byhand_manipadrsHP = "KR 26M # 56A - 13" in 13068
replace byhand_manipadrsHP = "KR 22 # 51 - 24" in 13087
replace byhand_manipadrsHP = "KR 56 # 44" in 13097
replace byhand_manipadrsHP = "CL 72F1 # 28D3 - 75" in 13110
replace byhand_manipadrsHP = "KR 26 O # 28C - 05" in 13123
replace byhand_manipadrsHP = "CL 72H # 27C - 26" in 13130
replace byhand_manipadrsHP = "" in 13157
replace byhand_manipadrsHP = "KR 26 O # 54 - 56" in 13160

replace byhand_manipadrsHP = "CL 54 # 28 E - 66" in 13177
replace byhand_manipadrsHP = "CL 34 CA # 29B - 09" in 13208
replace byhand_manipadrsHP = "CL 153" in 13209
replace byhand_manipadrsHP = "CL 153" in 13210
replace byhand_manipadrsHP = "CL 8A # 44A - 37" in 13227
replace byhand_manipadrsHP = "CL 70 # 7G Bis - 05" in 13230
replace byhand_manipadrsHP = "KR 53 # 5B - 12" in 13233
replace byhand_manipadrsHP = "CL 3 # 0 - 51" in 13234
replace byhand_manipadrsHP = "KR 3 DN # 71C - 59" in 13241
replace byhand_manipadrsHP = "KR 3BN # 71F - 55" in 13242
replace byhand_manipadrsHP = "CL 71D # 3A 2A - 35" in 13244
replace byhand_manipadrsHP = "CL 71D # 3A 2N - 35" in 13245
replace byhand_manipadrsHP = "KR 3 CN # 71C - 78" in 13247
replace byhand_manipadrsHP = "CL 72B # 5A - 36" in 13248
replace byhand_manipadrsHP = "CL 71D # 3CN - 24" in 13249
replace byhand_manipadrsHP = "CL 71C # 3A5N - 05" in 13250
replace byhand_manipadrsHP = "KR 3EN # 70 - 90" in 13251
replace byhand_manipadrsHP = "KR 3EN # 70 - 50" in 13254
replace byhand_manipadrsHP = "CL 71C # 3A 4N - 05" in 13258
replace byhand_manipadrsHP = "CL 71C # 3A 4N - 05" in 13259
replace byhand_manipadrsHP = "CL 70 # 3 N - 110" in 13261
replace byhand_manipadrsHP = "CL 51 # 6 N - 44" in 13265
replace byhand_manipadrsHP = "KR 5 N # 51N - 53" in 13266
replace byhand_manipadrsHP = "CL 48 # 5N - 34" in 13274
replace byhand_manipadrsHP = "CL 51AN # 7AN - 17" in 13280
replace byhand_manipadrsHP = "CL 10A # 36A - 35" in 13281
replace byhand_manipadrsHP = "KR 35 # 12A - 104" in 13297
replace byhand_manipadrsHP = "CL 57 N # 5N - 41" in 13305
replace byhand_manipadrsHP = "CL 60 # 2DN - 32" in 13314
replace byhand_manipadrsHP = "CL 60 # 2DN - 32" in 13315
replace byhand_manipadrsHP = "CL 60 # 2DN - 32" in 13316
replace byhand_manipadrsHP = "CL 72Y # 27D - 17" in 13319
replace byhand_manipadrsHP = "KR 27 DN # 72W2 - 19" in 13322
replace byhand_manipadrsHP = "KR 27A1 # 72Y - 24" in 13323

replace byhand_manipadrsHP = "CL 77 # 28F - 69" in 13329
replace byhand_manipadrsHP = "KR 27 # 72UB - 07" in 13340
replace byhand_manipadrsHP = "KR 27D # 72Y - 94" in 13346
replace byhand_manipadrsHP = "KR 27D # 72Y - 94" in 13347
replace byhand_manipadrsHP = "KR 27 # 72V - 73" in 13355
replace byhand_manipadrsHP = "KR 26R # 72 0 - 12" in 13361
replace byhand_manipadrsHP = "CL 72P # 28 1 - 20" in 13364
replace byhand_manipadrsHP = "KR 27 # 72 UV - 07" in 13375
replace byhand_manipadrsHP = "KR 27D # 71 - 02" in 13376
replace byhand_manipadrsHP = "AV 9 O # 19C - 12" in 13396
replace byhand_manipadrsHP = "KR 47 3 # 12A - 75" in 13419
replace byhand_manipadrsHP = "KR 45 # 12B - 67" in 13432
replace byhand_manipadrsHP = "KR 44A # 12 - 70" in 13450
replace byhand_manipadrsHP = "KR 36 3 # 10 - 155" in 13461
replace byhand_manipadrsHP = "KR 10 # 12A Bis - 70 - 28" in 13463
replace byhand_manipadrsHP = "CL 16A # 107A - 60" in 13477
replace byhand_manipadrsHP = "KR 1D Bis # 5AB - 10" in 13485
replace byhand_manipadrsHP = "KR 1D Bis # 5AB - 10" in 13486
replace byhand_manipadrsHP = "KR 4 N # 36" in 13491
replace byhand_manipadrsHP = "KR 1KN # 82 - 38" in 13492
replace byhand_manipadrsHP = "" in 13494
replace byhand_manipadrsHP = "KR 1DN # 77 - 70" in 13499
replace byhand_manipadrsHP = "KR 3 EN # 70 - 69" in 13500
replace byhand_manipadrsHP = "CL 72 EN # 41" in 13503
replace byhand_manipadrsHP = "KR 1J # 73A - 27" in 13511
replace byhand_manipadrsHP = "KR 3 N # 72 2 - 28" in 13512
replace byhand_manipadrsHP = "CL 71G # 3EN - 23" in 13513
replace byhand_manipadrsHP = "CL 71G # 3EN - 59" in 13514
replace byhand_manipadrsHP = "CL 70 # 13N - 80" in 13515
replace byhand_manipadrsHP = "KR 1DN # 77 - 33" in 13520
replace byhand_manipadrsHP = "KR 1 DN # 77 - 33" in 13521
replace byhand_manipadrsHP = "KR 1A # 54A - 110" in 13529
replace byhand_manipadrsHP = "KR 1A HN # 50 - 04" in 13530
replace byhand_manipadrsHP = "CL 63A # 2B1 - 03" in 13540
replace byhand_manipadrsHP = "CL 81 # 2 Bis - 17" in 13551
replace byhand_manipadrsHP = "" in 13552
replace byhand_manipadrsHP = "KR 1T # 4 74 - 18" in 13556
replace byhand_manipadrsHP = "KR 1S # 71A - 26B" in 13559
replace byhand_manipadrsHP = "CL 84 # 1 C3 - 24" in 13563
replace byhand_manipadrsHP = "KR 2C Bis # 75 - 07" in 13567
replace byhand_manipadrsHP = "KR 2D # 73A - 74" in 13571
replace byhand_manipadrsHP = "KR 1DN # 82 - 46" in 13574
replace byhand_manipadrsHP = "CL 70 N # 2 - 2N - 271" in 13577
replace byhand_manipadrsHP = "CL 70 N # 2 2N - 271" in 13577
replace byhand_manipadrsHP = "KR 1 KN # 82 - 56" in 13580
replace byhand_manipadrsHP = "KR 2B # 73A - 68" in 13585
replace byhand_manipadrsHP = "CL 84 1B # 3 - 30" in 13590
replace byhand_manipadrsHP = "KR 1C 4 # 67A - 70" in 13592
replace byhand_manipadrsHP = "KR 1J # 75 - 61" in 13594
replace byhand_manipadrsHP = "KR 2 # 75 - 63" in 13595
replace byhand_manipadrsHP = "KR 1B2 # 73A - 39" in 13597
replace byhand_manipadrsHP = "KR 1B2 # 73A - 39" in 13598
replace byhand_manipadrsHP = "KR 1B2 # 73A - 39" in 13599
replace byhand_manipadrsHP = "KR 1C4 # 78 - 31" in 13601
replace byhand_manipadrsHP = "KR 1N # 77 Bis - 31" in 13610
replace byhand_manipadrsHP = "KR 2 E # 73A - 47" in 13612
replace byhand_manipadrsHP = "KR 1B3 # 76 - 10" in 13613
replace byhand_manipadrsHP = "KR 2C Bis # 75 - 23" in 13615
replace byhand_manipadrsHP = "KR 67 # 150" in 13617
replace byhand_manipadrsHP = "KR 1B1 # 77 - 59" in 13618
replace byhand_manipadrsHP = "KR 2 Bis # 78 - 59" in 13625
replace byhand_manipadrsHP = "KR 1C4 # 77 - 34" in 13629
replace byhand_manipadrsHP = "CL 77 # 1C2 - 23" in 13632
replace byhand_manipadrsHP = "KR 1B2 # 73A - 48" in 13635
replace byhand_manipadrsHP = "KR 1B1 # 74 - 12" in 13637
replace byhand_manipadrsHP = "CL 77 # 1B3 - 18" in 13639
replace byhand_manipadrsHP = "CL 77 # 1B3 - 31" in 13644
replace byhand_manipadrsHP = "CL 73A # 1I - 19" in 13649

replace byhand_manipadrsHP = "KR 1 # 73 - 27" in 13650
replace byhand_manipadrsHP = "KR 1 Bis 3 # 73A - 68" in 13652
replace byhand_manipadrsHP = "KR 1 EW # 75 - 16" in 13659
replace byhand_manipadrsHP = "KR 1 EW # 75 - 16" in 13661
replace byhand_manipadrsHP = "KR 41 # 96A - 115" in 13678
replace byhand_manipadrsHP = "KR 1B1 # 76 - 29" in 13681
replace byhand_manipadrsHP = "CL 123A # 28D - 108" in 13683
replace byhand_manipadrsHP = "KR 28 # 123A4 - 39" in 13686
replace byhand_manipadrsHP = "KR 28D6 # 12B - 63" in 13687

replace byhand_manipadrsHP = "CL 123 # 2BA1 - 97" in 13689
replace byhand_manipadrsHP = "KR 28FS # 122A - 40" in 13690
replace byhand_manipadrsHP = "KR 28A 10 # 123A - 09" in 13692
replace byhand_manipadrsHP = "KR 28F4 # 122A - 10" in 13694
replace byhand_manipadrsHP = "CL 122" in 13699
replace byhand_manipadrsHP = "KR 28 # 122A - 26" in 13701
replace byhand_manipadrsHP = "KR 28E3 # 120B - 52" in 13702
replace byhand_manipadrsHP = "KR 28 E # 121D - 06" in 13705
replace byhand_manipadrsHP = "KR 28F6 # 122A - 35" in 13708
replace byhand_manipadrsHP = "KR 28E4 # 113A - 29" in 13712
replace byhand_manipadrsHP = "KR 28G # 122A - 47" in 13713
replace byhand_manipadrsHP = "KR 28GN # 122A - 83" in 13720
replace byhand_manipadrsHP = "KR 28B1 # 12 Bis - 20" in 13721
replace byhand_manipadrsHP = "KR 28 5 # 122E - 19" in 13723
replace byhand_manipadrsHP = "KR 28FA # 121A - 10" in 13725
replace byhand_manipadrsHP = "KR 28 # 122D - 62" in 13726
replace byhand_manipadrsHP = "CL 122F Bis # 28E2 - 56" in 13727
replace byhand_manipadrsHP = "KR 28D7 # 120A - 69" in 13729

replace byhand_manipadrsHP = "KR 28 D2 # 120B - 21" in 13732
replace byhand_manipadrsHP = "CL 122F # 28D10 - 32" in 13734
replace byhand_manipadrsHP = "KR 4 N # 43C - 31" in 13739
replace byhand_manipadrsHP = "KR 7 # 46NB - 20" in 13741
replace byhand_manipadrsHP = "KR 8 # 43N - 37" in 13745
replace byhand_manipadrsHP = "KR 8 # 43N - 37" in 13746
replace byhand_manipadrsHP = "CL 42 # 7 N - 16" in 13751
replace byhand_manipadrsHP = "KR 27G # 72W - 226" in 13754
replace byhand_manipadrsHP = "KR 4N # 46A - 29" in 13762
replace byhand_manipadrsHP = "CL 46B N # 8AN - 23" in 13763
replace byhand_manipadrsHP = "CL 46B N # 8AN - 23" in 13764

replace byhand_manipadrsHP = "KR 4A N # 44AN - 18" in 13776
replace byhand_manipadrsHP = "KR 5 N # 42N - 35" in 13802
replace byhand_manipadrsHP = "" in 13803
replace byhand_manipadrsHP = "CL 46B # 4N - 31" in 13806
replace byhand_manipadrsHP = "KR 7 # 47N - 21CA - 176" in 13811
replace byhand_manipadrsHP = "KR 1 # 45 N - 38" in 13815
replace byhand_manipadrsHP = "CL 5N # 39" in 13816
replace byhand_manipadrsHP = "CL 45A # 5N - 87" in 13819
replace byhand_manipadrsHP = "KR 1C S # 10C - 74" in 13823
replace byhand_manipadrsHP = "CL 64B # 2D - 33" in 13826
replace byhand_manipadrsHP = "CL 65B # 2D - 02" in 13829
replace byhand_manipadrsHP = "CL 32B3 # 12 - 57" in 13846
replace byhand_manipadrsHP = "KR 4B # 34 - 47" in 13853
replace byhand_manipadrsHP = "KR 28D4 # 121B - 12" in 13867
replace byhand_manipadrsHP = "KR 28 DC # 121 - 33" in 13868
replace byhand_manipadrsHP = "KR 28B # 122D - 16" in 13870
replace byhand_manipadrsHP = "CL 121A # 28B6 - 13" in 13871
replace byhand_manipadrsHP = "KR 28 N # 124B - 36" in 13872
replace byhand_manipadrsHP = "KR 28E3 # 123B - 25" in 13874
replace byhand_manipadrsHP = "CL 122B # 28A - 113" in 13879
replace byhand_manipadrsHP = "KR 28N # 124BP - 24" in 13881
replace byhand_manipadrsHP = "CL 125 # 28E - 75" in 13882
replace byhand_manipadrsHP = "CL 121C # 09" in 13883
replace byhand_manipadrsHP = "CL 125A # 28B - 119" in 13884
replace byhand_manipadrsHP = "KR 28 DC # 121 - 33" in 13885
replace byhand_manipadrsHP = "CL 122 Bis # 28D4 - 45" in 13887
replace byhand_manipadrsHP = "CL 122 Bis # 28D7 - 38" in 13888
replace byhand_manipadrsHP = "CL 121 # 28B - 49" in 13889
replace byhand_manipadrsHP = "CL 124B # 28B1 - 51" in 13891
replace byhand_manipadrsHP = "KR 28D 8 # 122D - 44" in 13892
replace byhand_manipadrsHP = "CL 122 # 18B - 212" in 13893
replace byhand_manipadrsHP = "KR 28G2 # 124C - 45" in 13894
replace byhand_manipadrsHP = "CL 124A # 28B1 - 79" in 13898
replace byhand_manipadrsHP = "CL 121 # 28B - 49" in 13899
replace byhand_manipadrsHP = "KR 28D N # 121A - 20" in 13901
replace byhand_manipadrsHP = "KR 28D4 # 121B - 05" in 13902
replace byhand_manipadrsHP = "CL 123 # 38A Bis - 25" in 13904
replace byhand_manipadrsHP = "CL 125A # 28B - 120" in 13915
replace byhand_manipadrsHP = "KR 28F" in 13918
replace byhand_manipadrsHP = "KR 28F # 28D - 446" in 13919
replace byhand_manipadrsHP = "CL 124B # 28B1 - 04" in 13922
replace byhand_manipadrsHP = "CL 122 # 28D4 - 31" in 13923
replace byhand_manipadrsHP = "KR 10 # 1 S - 260" in 13924
replace byhand_manipadrsHP = "CL 123D2 Bis # 23" in 13926
replace byhand_manipadrsHP = "KR 28A # 124N - 28" in 13930
replace byhand_manipadrsHP = "KR 28E3 # 124C - 42" in 13939
replace byhand_manipadrsHP = "KR 28 C11 # 125 - 76" in 13941
replace byhand_manipadrsHP = "KR 28 E 3A # 124A - 27" in 13946
replace byhand_manipadrsHP = "KR 28D # 123A - 49" in 13947
replace byhand_manipadrsHP = "CL 22 - # 28D1 - 25" in 13948
replace byhand_manipadrsHP = "CL 22 # 28D1 - 25" in 13948
replace byhand_manipadrsHP = "CL 122 - # 28D1 - 25" in 13949
replace byhand_manipadrsHP = "KR 28" in 13950
replace byhand_manipadrsHP = "CL 32 # 27B - 12" in 14003

replace byhand_manipadrsHP = "CL 28 # 24A - 104" in 14007
replace byhand_manipadrsHP = "CL 18 3 # 67 - 48" in 14016
replace byhand_manipadrsHP = "AV 2 # 36 N - 38" in 14023
replace byhand_manipadrsHP = "CL 49 N # 3EN - 49" in 14029
replace byhand_manipadrsHP = "CL 39 N # 3CN - 129" in 14035
replace byhand_manipadrsHP = "CL 34 N # 2NA - 63" in 14040
replace byhand_manipadrsHP = "CL 36AN # 3CN - 31" in 14046
replace byhand_manipadrsHP = "CL 37A # 3CN - 31" in 14047
replace byhand_manipadrsHP = "CL 36AN # 3CN - 31" in 14048
replace byhand_manipadrsHP = "CL 37A # 3CN - 31" in 14049
replace byhand_manipadrsHP = "CL 37A # 3CN - 31" in 14050
replace byhand_manipadrsHP = "CL 33A N # 2EN - 54" in 14052
replace byhand_manipadrsHP = "CL 38A # 2A - 67" in 14056
replace byhand_manipadrsHP = "CL 34A N # 2AN - 63" in 14060
replace byhand_manipadrsHP = "CL 34A N # 2AN - 63" in 14061
replace byhand_manipadrsHP = "KR 76AB1 # 05" in 14068
replace byhand_manipadrsHP = "KR 76AB1 # 05" in 14069
replace byhand_manipadrsHP = "KR 74C # 1B - 105" in 14072
replace byhand_manipadrsHP = "KR 74A # 1B - 135" in 14156
replace byhand_manipadrsHP = "KR 78 # 1H - 23" in 14160
replace byhand_manipadrsHP = "TV 2 # 1C - 140" in 14175
replace byhand_manipadrsHP = "C 37 # 34B - 35" in 14193
replace byhand_manipadrsHP = "KR 37 # 34B - 35" in 14193
replace byhand_manipadrsHP = "" in 14202
replace byhand_manipadrsHP = "KR 33 # 34B - 10" in 14207
replace byhand_manipadrsHP = "KR 33A # 35A - 10" in 14210
replace byhand_manipadrsHP = "KR 32C # 35 - 16" in 14224
replace byhand_manipadrsHP = "KR 32A # 35 - 29" in 14226
replace byhand_manipadrsHP = "KR 33D3 # 35 - 52" in 14227
replace byhand_manipadrsHP = "KR 33A # 34B - 30" in 14232
replace byhand_manipadrsHP = "KR 32B # 34C - 31" in 14248
replace byhand_manipadrsHP = "KR 53 # 13A - 60" in 14259
replace byhand_manipadrsHP = "CL 18 # 56" in 14263
replace byhand_manipadrsHP = "KR 56A # 13E - 45" in 14302
replace byhand_manipadrsHP = "CL 13A3 # 50 - 57" in 14306
replace byhand_manipadrsHP = "CL 13A3 # 50 - 57" in 14308
replace byhand_manipadrsHP = "CL 13A3 # 50 - 57" in 14309
replace byhand_manipadrsHP = "CL 13A3 # 50 - 57" in 14310
replace byhand_manipadrsHP = "CL 13A3 # 50 - 57" in 14311
replace byhand_manipadrsHP = "CL 13A3 # 50 - 57" in 14312
replace byhand_manipadrsHP = "CL 13A3 # 50 - 57" in 14313
replace byhand_manipadrsHP = "CL 13A3 # 50 - 57" in 14314
replace byhand_manipadrsHP = "CL 13A3 # 50 - 57" in 14315
replace byhand_manipadrsHP = "KR 58 # 13A - 58" in 14320
replace byhand_manipadrsHP = "CL 47 # 50 - 38" in 14329
replace byhand_manipadrsHP = "CL 13C # 57A - 16" in 14343
replace byhand_manipadrsHP = "KR 013 # 42" in 14356
replace byhand_manipadrsHP = "KR 50 # 13 E - 66" in 14378
replace byhand_manipadrsHP = "KR 50 # 13 E - 66" in 14379
replace byhand_manipadrsHP = "KR 54 # 11A - 04" in 14380
replace byhand_manipadrsHP = "KR 53 # 11A - 47" in 14381
replace byhand_manipadrsHP = "KR 17 # 18 - 49" in 14388
replace byhand_manipadrsHP = "KR 17 # 18 - 49" in 14389
replace byhand_manipadrsHP = "CL 27A # 17F2 - 03" in 14390
replace byhand_manipadrsHP = "KR 17S # 28A - 23" in 14392
replace byhand_manipadrsHP = "KR 17F2 # 18 - 52" in 14393
replace byhand_manipadrsHP = "DG 18A # 17G - 26" in 14396
replace byhand_manipadrsHP = "DG 18 # 17G - 85" in 14405
replace byhand_manipadrsHP = "DG 18A # 17F1 - 15" in 14406
replace byhand_manipadrsHP = "DG 20 # 28A - 11" in 14413
replace byhand_manipadrsHP = "KR 17F1 # 18 - 35" in 14414
replace byhand_manipadrsHP = "KR 17 F1 # 18 - 35" in 14415
replace byhand_manipadrsHP = "KR 17 F1 # 18 - 35" in 14416
replace byhand_manipadrsHP = "KR 17 F1 # 18 - 35" in 14417
replace byhand_manipadrsHP = "KR 17 F1 # 18 - 35" in 14418
replace byhand_manipadrsHP = "KR 17F # 33A - 27" in 14419
replace byhand_manipadrsHP = "KR 17 EN # 25 - 74" in 14420
replace byhand_manipadrsHP = "DG 18B # 17C - 40" in 14421
replace byhand_manipadrsHP = "KR 17 D1 # 28A - 52" in 14424
replace byhand_manipadrsHP = "KR 17 D1 # 28A - 52" in 14425
replace byhand_manipadrsHP = "DG 18E # 17G - 55" in 14427
replace byhand_manipadrsHP = "DG 18E # 17G - 55" in 14428
replace byhand_manipadrsHP = "KR 17D1 # 28A - 38" in 14429
replace byhand_manipadrsHP = "KR 17D1 # 28A - 38" in 14430
replace byhand_manipadrsHP = "KR 17D # 28A - 54" in 14435
replace byhand_manipadrsHP = "KR 17B1 # 28A - 38" in 14436
replace byhand_manipadrsHP = "TV 28A # 18A - 58" in 14437
replace byhand_manipadrsHP = "KR 26F1 # 97 - 65" in 14438
replace byhand_manipadrsHP = "DG 110 # 26C - 44" in 14443
replace byhand_manipadrsHP = "CL 88D # 28D2 - 72" in 14457
replace byhand_manipadrsHP = "CL 109 # 26B1 - 49" in 14461
replace byhand_manipadrsHP = "CL 99 # 26I - 18" in 14462
replace byhand_manipadrsHP = "DG 46 O # 54A - 31" in 14472
replace byhand_manipadrsHP = "CL 100 # 26B - 138" in 14474
replace byhand_manipadrsHP = "KR 26B3 # 89 - 46" in 14475
replace byhand_manipadrsHP = "KR 28C1 # 85 - 24" in 14480
replace byhand_manipadrsHP = "" in 14482
replace byhand_manipadrsHP = "KR 26G # 97 - 45" in 14484
replace byhand_manipadrsHP = "CL 80 Bis # 26 - 71" in 14485
replace byhand_manipadrsHP = "KR 26D1 # 91 - 46" in 14488
replace byhand_manipadrsHP = "DG 110 # 26I I3 - 29" in 14489
replace byhand_manipadrsHP = "DG 109 # 26G - 14" in 14490
replace byhand_manipadrsHP = "KR 26B3 # 80 - 47" in 14492
replace byhand_manipadrsHP = "KR 26C1 # 94 - 58" in 14493
replace byhand_manipadrsHP = "KR 26C1 # 94 - 58" in 14494
replace byhand_manipadrsHP = "KR 26A # 108A - 18" in 14497
replace byhand_manipadrsHP = "CL 91 # 26B3 - 33" in 14510

replace byhand_manipadrsHP = "CL 80 E1 # 26 - 30" in 14520
replace byhand_manipadrsHP = "KR 26A # 108A - 22" in 14532
replace byhand_manipadrsHP = "KR 26A # 108A - 22" in 14533
replace byhand_manipadrsHP = "KR 26M # 72W - 109" in 14535
replace byhand_manipadrsHP = "KR 26C1 # 97 - 09" in 14536
replace byhand_manipadrsHP = "CL 98 # 26B1 - 100" in 14538
replace byhand_manipadrsHP = "KR 26B2 # 91 - 35" in 14541
replace byhand_manipadrsHP = "CL 87 # 26B - 53" in 14542
replace byhand_manipadrsHP = "CL 89 # 26B - 14" in 14550
replace byhand_manipadrsHP = "CL 91 # 26 - 15 - 09" in 14556
replace byhand_manipadrsHP = "CL 90 # 26D - 13X" in 14557
replace byhand_manipadrsHP = "CL 78 # 8A - 25" in 14568
replace byhand_manipadrsHP = "DG 26K # 87 - 18" in 14576
replace byhand_manipadrsHP = "CL 78 # 8A - 23" in 14577
replace byhand_manipadrsHP = "CL 76 # 8C - 17" in 14579
replace byhand_manipadrsHP = "KR 6A # 71D - 57" in 14610
replace byhand_manipadrsHP = "KR 6B # 71D - 33" in 14621
replace byhand_manipadrsHP = "CL 5 11 # 10 - 97" in 14623
replace byhand_manipadrsHP = "CL 5 # 11 - 10 - 97" in 14623
replace byhand_manipadrsHP = "DG 23 # 30 - 35" in 14624
replace byhand_manipadrsHP = "DG 21 # 29 - 60" in 14625
replace byhand_manipadrsHP = "DG 21 # 29 - 60" in 14626
replace byhand_manipadrsHP = "DG 22 # 30 - 37" in 14627
replace byhand_manipadrsHP = "DG 22 # 30 - 37" in 14628
replace byhand_manipadrsHP = "DG 22 # 30 - 37" in 14629
replace byhand_manipadrsHP = "DG 22 # 30 - 42" in 14633
replace byhand_manipadrsHP = "TV 31 # 21 - 09" in 14634
replace byhand_manipadrsHP = "KR 17C # 33D - 14" in 14636
replace byhand_manipadrsHP = "KR 17C # 21 - 24" in 14641
replace byhand_manipadrsHP = "DG 22 # 30 - 42" in 14644
replace byhand_manipadrsHP = "KR 44 # 37 - 63" in 14700
replace byhand_manipadrsHP = "CL 43 # 43A - 17" in 14763
replace byhand_manipadrsHP = "KR 41A # 43 - 54B" in 14773
replace byhand_manipadrsHP = "KR 41A # 43 - 54B" in 14774
replace byhand_manipadrsHP = "CL 43 # 43A - 18" in 14781
replace byhand_manipadrsHP = "CL 93A # 42b - 09" in 14786
replace byhand_manipadrsHP = "KR 39A # 42B - 09" in 14787
replace byhand_manipadrsHP = "CL 93A # 42B - 09" in 14786
replace byhand_manipadrsHP = "KR 42 # 38 - 49" in 14814
replace byhand_manipadrsHP = "KR 26K # 71B1 - 09" in 14821
replace byhand_manipadrsHP = "" in 14822
replace byhand_manipadrsHP = "DG 71C1 # 26J - 51" in 14823
replace byhand_manipadrsHP = "DG 71C1 # 2B1 - 51" in 14824
replace byhand_manipadrsHP = "DG 72C # 26J - 55" in 14825
replace byhand_manipadrsHP = "KR 26J # 72A - 28" in 14827
replace byhand_manipadrsHP = "KR 26M # 72 - 09" in 14831
replace byhand_manipadrsHP = "KR 26M # 72 - 21" in 14835
replace byhand_manipadrsHP = "TV 26J # 70 - 56" in 14838
replace byhand_manipadrsHP = "KR 26 I2 # 72C - 22" in 14839
replace byhand_manipadrsHP = "TV 26J # 70 - 122" in 14840
replace byhand_manipadrsHP = "KR 26U # 71A1 - 26" in 14842
replace byhand_manipadrsHP = "KR 26L # 72E Bis - 35" in 14849

replace byhand_manipadrsHP = "KR 26K # 71B1 - 09" in 14850
replace byhand_manipadrsHP = "KR 26L # 71C - 20" in 14851
replace byhand_manipadrsHP = "KR 26D 70 # 70 - 12" in 14852
replace byhand_manipadrsHP = "KR 26 KD # 71A - 121" in 14853
replace byhand_manipadrsHP = "KR 26M # 71 - 15" in 14857
replace byhand_manipadrsHP = "DG 72 # 26 2 - 83" in 14858
replace byhand_manipadrsHP = "KR 26I # 71B1 - 10" in 14862
replace byhand_manipadrsHP = "DG 28C # 42A - 37" in 14867
replace byhand_manipadrsHP = "DG 28C # 42A - 27" in 14868
replace byhand_manipadrsHP = "KR 26M # 71A - 21" in 14869
replace byhand_manipadrsHP = "KR 26B # 71B1 - 26" in 14874
replace byhand_manipadrsHP = "KR 26K # 71A1 - 15" in 14875
replace byhand_manipadrsHP = "KR 26L # 70 - 32" in 14877
replace byhand_manipadrsHP = "CL 74 # 26C1 - 19" in 14878
replace byhand_manipadrsHP = "CL 17C # 29 - 31" in 14909
replace byhand_manipadrsHP = "KR 17 # 29T - 17" in 14910
replace byhand_manipadrsHP = "KR 17CT # 30 - 67" in 14913
replace byhand_manipadrsHP = "KR 17V # 27B - 50" in 14914
replace byhand_manipadrsHP = "KR 17C # 31 - 22" in 14916
replace byhand_manipadrsHP = "DG 20 # 17K - 19" in 14917
replace byhand_manipadrsHP = "KR 17C # 29 - 31" in 14922
replace byhand_manipadrsHP = "KR 20 # 33C - 178" in 14923
replace byhand_manipadrsHP = "KR 17F # 29 - 39" in 14928
replace byhand_manipadrsHP = "KR 17F # 29 - 39" in 14929
replace byhand_manipadrsHP = "KR 17F # 29 - 39" in 14930
replace byhand_manipadrsHP = "KR 17F # 29 - 39" in 14931
replace byhand_manipadrsHP = "KR 17F # 29 - 39" in 14932
replace byhand_manipadrsHP = "TV 30 # 17F - 68" in 14945
replace byhand_manipadrsHP = "KR 17D # 30 - 38" in 14950
replace byhand_manipadrsHP = "CL 47 # 2B1 - 17" in 14956
replace byhand_manipadrsHP = "KR 4N # 44AN - 23" in 14957
replace byhand_manipadrsHP = "CL 54 # 11D - 54" in 14960
replace byhand_manipadrsHP = "KR 4 E # 46A - 47" in 14962
replace byhand_manipadrsHP = "KR 2 # 45C - 03" in 14967
replace byhand_manipadrsHP = "KR 1D # 46C - 27" in 14969

replace byhand_manipadrsHP = "KR 2 C111 # 45 2A - 27" in 14973
replace byhand_manipadrsHP = "CL 56 # 4B - 145" in 14974
replace byhand_manipadrsHP = "KR 1H # 46C - 57" in 14977

rename NOMBRE barrio

replace byhand_manipadrsHP = "KR 2 C111 # 45 2A - 27" in 14973
replace byhand_manipadrsHP = "CL 56 # 4B - 145" in 14974
replace byhand_manipadrsHP = "KR 1H # 46C - 57" in 14977
replace byhand_manipadrsHP = "CL 76A # 1 E - 19" in 14986
replace byhand_manipadrsHP = "KR 4D # 52A - 29" in 14988
replace byhand_manipadrsHP = "KR 2B1 # 47 - 30" in 14993
replace byhand_manipadrsHP = "KR 1G # 46E - 16" in 14995
replace byhand_manipadrsHP = "CL 45C # 1D2 - 03" in 14997
replace byhand_manipadrsHP = "KR 1H # 4C - 15" in 15001
replace byhand_manipadrsHP = "CL 71 # 1A1 - 44" in 15004
replace byhand_manipadrsHP = "CL 46 # 2C - 37" in 15005
replace byhand_manipadrsHP = "CL 84 # 1KN - 04" in 15025

replace byhand_manipadrsHP = "CL 56 # 31C - 2 Bis 08" in 15029
replace byhand_manipadrsHP = "CL 58A # 1B1 - 11" in 15034
replace byhand_manipadrsHP = "KR 1E # 46 - 54" in 15036
replace byhand_manipadrsHP = "CL 56 # 1C2B - 08" in 15044
replace byhand_manipadrsHP = "CL 2A O # 4A - 10" in 15082
replace byhand_manipadrsHP = "KR 5 # 3 1 - 38" in 15087
replace byhand_manipadrsHP = "CL 34A # 27 - 08" in 15096
replace byhand_manipadrsHP = "CL 34 # 27 - 52" in 15100
replace byhand_manipadrsHP = "KR 29 # 28B - 01" in 15101
replace byhand_manipadrsHP = "CL 26 # 32A - 22" in 15102
replace byhand_manipadrsHP = "KR 29D # 28B2 - 5" in 15104
replace byhand_manipadrsHP = "KR 26 # 32A - 22" in 15107
replace byhand_manipadrsHP = "CL 34A # 27 - 44" in 15108
replace byhand_manipadrsHP = "CL 34A # 27 - 44" in 15109
replace byhand_manipadrsHP = "TV 26 # 28C - 42" in 15112
replace byhand_manipadrsHP = "KR 27 # 33H - 34" in 15121

replace byhand_manipadrsHP = "KR 33A # 45 - 05" in 15136
replace byhand_manipadrsHP = "KR 32 # 32 - 13" in 15171
replace byhand_manipadrsHP = "KR 36A # 30 - 50" in 15178
replace byhand_manipadrsHP = "KR 32 3 # 32 - 22" in 15188
replace byhand_manipadrsHP = "KR 35 # 31A - 66" in 15194
replace byhand_manipadrsHP = "KR 35 # 31A - 66" in 15196
replace byhand_manipadrsHP = "KR 33B # 30 - 72" in 15198
replace byhand_manipadrsHP = "CL 3A # 18 - 16" in 15234
replace byhand_manipadrsHP = "KR 13 # 2 - 20" in 15243
replace byhand_manipadrsHP = "CL 1A # 121 - 33" in 15244
replace byhand_manipadrsHP = "KR 13# 2 - 22" in 15247
replace byhand_manipadrsHP = "KR 12 O # 219" in 15249
replace byhand_manipadrsHP = "CL 23M2 # 28 - C27" in 15267
replace byhand_manipadrsHP = "CL 23M2 # 28C - 27" in 15267
replace byhand_manipadrsHP = "KR 24 # 24 - 30" in 15273
replace byhand_manipadrsHP = "KR 36A N # 5B 1 - 38" in 15282
replace byhand_manipadrsHP = "KR 30 3# 5C - 21" in 15288
replace byhand_manipadrsHP = "KR 30 # 5B1 - 70" in 15293
replace byhand_manipadrsHP = "KR 36C # 5B1 - 39" in 15294
replace byhand_manipadrsHP = "AV 6 # 38 - 32" in 15300
replace byhand_manipadrsHP = "AV 6 # 38 - 32" in 15301
replace byhand_manipadrsHP = "KR 37 # 5B1 - 37" in 15302
replace byhand_manipadrsHP = "KR 36B5B # 3 - 78" in 15306
replace byhand_manipadrsHP = "KR 36B # 5B 3 - 78" in 15306
replace byhand_manipadrsHP = "CL 5B3 # 38 - 20" in 15315
replace byhand_manipadrsHP = "CL 4C # 38D - 22" in 15325
replace byhand_manipadrsHP = "KR 24CB # 2 - 150" in 15329
replace byhand_manipadrsHP = "CL 5B3 # 37 - 35" in 15331
replace byhand_manipadrsHP = "KR 9 # 5A - 60" in 15334
replace byhand_manipadrsHP = "KR 89 # 18 - 72 - CS - 11" in 15339
replace byhand_manipadrsHP = "KR 89 # 18 - 72 CS 11" in 15339
replace byhand_manipadrsHP = "KR 89 # 18 - 72 CS 11" in 15340
replace byhand_manipadrsHP = "CL 94A Bis # 19" in 15346
replace byhand_manipadrsHP = "CL 23 KR # 50" in 15362
replace byhand_manipadrsHP = "CL 23 # 50" in 15362
replace byhand_manipadrsHP = "CL 23" in 15363
replace byhand_manipadrsHP = "KR 14 # 05" in 15368
replace byhand_manipadrsHP = "KR 13 # 12A - 14" in 15388
replace byhand_manipadrsHP = "CL 33B # 26B - 18" in 15394
replace byhand_manipadrsHP = "CL 18 # 41C - 68" in 15442
replace byhand_manipadrsHP = "CL 20B # 46A S - 15" in 15445
replace byhand_manipadrsHP = "KR 48C # 23I - 89" in 15458
replace byhand_manipadrsHP = "CL 23 # 46A - 19" in 15497
replace byhand_manipadrsHP = "KR 47A # 17A - 15" in 15507
replace byhand_manipadrsHP = "CL 43 # 34" in 15517
replace byhand_manipadrsHP = "KR 41C # 18 - 45" in 15533
replace byhand_manipadrsHP = "CL 23 # 49A - 39" in 15535
replace byhand_manipadrsHP = "CL 23 # 10B - 55" in 15536
replace byhand_manipadrsHP = "KR 1C1 # 71 - 14" in 15538
replace byhand_manipadrsHP = "CL 72A # 1A3 - 60" in 15540
replace byhand_manipadrsHP = "CL 72A # 1AZ - 24" in 15542
replace byhand_manipadrsHP = "CL 72A # 1A2 - 24" in 15542
replace byhand_manipadrsHP = "KR 1A # 73 Bis - 08" in 15553
replace byhand_manipadrsHP = "KR 1A12 # 73 - 09" in 15555
replace byhand_manipadrsHP = "KR N 72A # 20" in 15560
replace byhand_manipadrsHP = "" in 15560
replace byhand_manipadrsHP = "KR 1A 10 # 73 - 39" in 15561
replace byhand_manipadrsHP = "KR 1B 1 # 72 - 61" in 15563
replace byhand_manipadrsHP = "KR 1 9 # 72 - 21" in 15571
replace byhand_manipadrsHP = "CL 70 # 1A9 - 25" in 15573
replace byhand_manipadrsHP = "CL 72A # 1A 1 - 02" in 15577
replace byhand_manipadrsHP = "KR 1A13 # 70 - 81" in 15579
replace byhand_manipadrsHP = "KR 1A13 # 70 - 104" in 15583
replace byhand_manipadrsHP = "KR 1C1 # 71 - 14" in 15590
replace byhand_manipadrsHP = "KR 26B2 # 73A - 23" in 15596
replace byhand_manipadrsHP = "KR 1A14 # 71 - 46" in 15597
replace byhand_manipadrsHP = "CL 72A # 1A3 - 25B" in 15608
replace byhand_manipadrsHP = "CL 73 # 1C - 12" in 15610
replace byhand_manipadrsHP = "CL 73 # 1C1 - 81" in 15611
replace byhand_manipadrsHP = "CL 73 # 1C1 - 81" in 15612
replace byhand_manipadrsHP = "All 72A # 1 - 28" in 15614
replace byhand_manipadrsHP = "KR 1A 2C # 73 - 37" in 15615
replace byhand_manipadrsHP = "KR 1A11 # 72 - 22" in 15618
replace byhand_manipadrsHP = "KR 1A9 # 73 - 39" in 15624
replace byhand_manipadrsHP = "KR 1A8 # 73 - 41" in 15626
replace byhand_manipadrsHP = "KR 1 10 # 72 - 18" in 15632
replace byhand_manipadrsHP = "CL 72C # 1A 4 - 20" in 15633
replace byhand_manipadrsHP = "KR 1C2 # 72 - 49" in 15634
replace byhand_manipadrsHP = "KR 1B2 # 70 - 76" in 15635
replace byhand_manipadrsHP = "KR 1A7 # 71 - 106" in 15642
replace byhand_manipadrsHP = "DG 14 # 72A - 01" in 15644
replace byhand_manipadrsHP = "KR 1A2B # 73 - 08" in 15646
replace byhand_manipadrsHP = "CL 73A # 1E - 20" in 15652
replace byhand_manipadrsHP = "KR 1 Bis # 56 - 161 A 1036" in 15653
replace byhand_manipadrsHP = "CL 73 # 1A 10 - 35" in 15656
replace byhand_manipadrsHP = "KR 1AB1 # 72 - 81" in 15659
replace byhand_manipadrsHP = "KR 1A8 # 72 - 69" in 15664
replace byhand_manipadrsHP = "KR 731A # 10 - 35" in 15665
replace byhand_manipadrsHP = "KR 1A8 - # 72 - 32" in 15666
replace byhand_manipadrsHP = "KR 1A 14 # 72 - 100" in 15671
replace byhand_manipadrsHP = "KR 1A 14 # 72 - 100" in 15672
replace byhand_manipadrsHP = "CL 72C # 1A 2 - 62" in 15675
replace byhand_manipadrsHP = "KR 1AB # 70 - 69" in 15676
replace byhand_manipadrsHP = "KR 1A6 # 71 - 74" in 15677
replace byhand_manipadrsHP = "KR 1A4A # 7 3 - 42" in 15686
replace byhand_manipadrsHP = "KR 1A4A # 73 - 42" in 15686
replace byhand_manipadrsHP = "CL 72D1 # A1 - 44" in 15689
replace byhand_manipadrsHP = "CL 73A # 1C1 - 04" in 15690
replace byhand_manipadrsHP = "KR 7C Bis # 72B - 12" in 15691
replace byhand_manipadrsHP = "CL 72 # 1A3 - 89" in 15698
replace byhand_manipadrsHP = "KR 1A # 70C - 25" in 15699
replace byhand_manipadrsHP = "CL 72B # 1A 4B - 71" in 15700
replace byhand_manipadrsHP = "CL 72C # 1A2 - 86" in 15701
replace byhand_manipadrsHP = "CL 72D # 1A 1 - 68" in 15705
replace byhand_manipadrsHP = "CL 72D # 1A1 - 68" in 15705
replace byhand_manipadrsHP = "CL 70 # 31A9 - 15" in 15710
replace byhand_manipadrsHP = "CL 70 # 31A9 - 15" in 15711
replace byhand_manipadrsHP = "KR 1A7 # 72 - 13" in 15712
replace byhand_manipadrsHP = "CL 72A # 1A4B - 37" in 15713
replace byhand_manipadrsHP = "CL 73 Bis # 1A - 05" in 15714
replace byhand_manipadrsHP = "KR 1 14 # 70 - 104" in 15716
replace byhand_manipadrsHP = "KR 1A4 # 54 - 73 - 42" in 15718
replace byhand_manipadrsHP = "KR 1A4 # 54 - 73 - 42" in 15719
replace byhand_manipadrsHP = "KR 7C Bis # 63 - 20" in 15724
replace byhand_manipadrsHP = "KR 7C Bis # 63 - 20" in 15725
replace byhand_manipadrsHP = "KR 7 E Bis # 61 - 18" in 15727
replace byhand_manipadrsHP = "KR 7CB # 65 - 20" in 15730
replace byhand_manipadrsHP = "CL 22 # 7A - 35" in 15747
replace byhand_manipadrsHP = "KR 7 # 197 - 29" in 15749
replace byhand_manipadrsHP = "KR 3 # 19" in 15750
replace byhand_manipadrsHP = "KR 2A # 19 - 63B" in 15765
replace byhand_manipadrsHP = "CL 22 # 7A - 20B" in 15771
replace byhand_manipadrsHP = "KR 2 # 19 - 76" in 15792
replace byhand_manipadrsHP = "KR 13 # 14A - 25" in 15815
replace byhand_manipadrsHP = "KR 1 N # 10 CN - 60" in 15827
replace byhand_manipadrsHP = "DG 30A # 30A - 09" in 15828
replace byhand_manipadrsHP = "CL 14 # 4A - 20" in 15839
replace byhand_manipadrsHP = "DG 32 # 32C - 02" in 15841
replace byhand_manipadrsHP = "KR 31 # 32 - 37" in 15856
replace byhand_manipadrsHP = "CL 26 # 5B - 79" in 15857
replace byhand_manipadrsHP = "KR 29A # 31 - 40" in 15859
replace byhand_manipadrsHP = "KR 29A # 31 - 40" in 15860
replace byhand_manipadrsHP = "CL 36 # 29A - 40" in 15862
replace byhand_manipadrsHP = "KR 2A # 31 - 06" in 15864
replace byhand_manipadrsHP = "DG 31 # 31A - 19" in 15868
replace byhand_manipadrsHP = "KR 30 # 32 - 23" in 15869
replace byhand_manipadrsHP = "DG 28B # 28 - 39" in 15872
replace byhand_manipadrsHP = "DG 28B # 28 - 39" in 15873
replace byhand_manipadrsHP = "KR 29B # 30A - 25" in 15877
replace byhand_manipadrsHP = "KR 29 # 31 - 21" in 15894
replace byhand_manipadrsHP = "KR 31 # 32 - 37" in 15897
replace byhand_manipadrsHP = "DG 30 # 29A - 125" in 15898
replace byhand_manipadrsHP = "CL 35 G2 # 29A - 11" in 15899
replace byhand_manipadrsHP = "KR 31 # 33 - 12" in 15906
replace byhand_manipadrsHP = "KR 29 # 31 - 87" in 15907
replace byhand_manipadrsHP = "KR 31A # 31 - 26" in 15912
replace byhand_manipadrsHP = "CL 44 # 29 - 19" in 15914
replace byhand_manipadrsHP = "CL 25 N # 2 Bis N - 20" in 15916
replace byhand_manipadrsHP = "KR 37 3 # 25 - 16" in 15918
replace byhand_manipadrsHP = "CL 31N # 2A - 25" in 15922

replace byhand_manipadrsHP = "KR 59A3 # 11 - 57" in 15929
replace byhand_manipadrsHP = "KR 29B # 17 - 35" in 15960
replace byhand_manipadrsHP = "CL 19A # 32A - 71" in 15963
replace byhand_manipadrsHP = "CL 19 # 18 - 05" in 15987
replace byhand_manipadrsHP = "CL 14 # 29B - 21" in 16043
replace byhand_manipadrsHP = "CL 18 # 29A - 27" in 16049
replace byhand_manipadrsHP = "KR 31 # 23B" in 16063
replace byhand_manipadrsHP = "KR 31 # 23B" in 16064
replace byhand_manipadrsHP = "CL 23 # 33 - 19" in 16065
replace byhand_manipadrsHP = "KR 19 # 33F - 19" in 16076
replace byhand_manipadrsHP = "KR 20 # 33T - 57" in 16088
replace byhand_manipadrsHP = "KR 22 # 36 - 78" in 16094
replace byhand_manipadrsHP = "KR 38B # 3 - 95" in 16131
replace byhand_manipadrsHP = "KR 37 # 1 O - 82" in 16143
replace byhand_manipadrsHP = "DG 23 # 31 - 29" in 16145
replace byhand_manipadrsHP = "DG 23 # 31 - 29" in 16146
replace byhand_manipadrsHP = "KR 23 # 33F - 44" in 16151
replace byhand_manipadrsHP = "DG 19 # 25 - 22" in 16153
replace byhand_manipadrsHP = "DG 23 # 31 - 15" in 16168
replace byhand_manipadrsHP = "KR 24A # 33C - 184" in 16171
replace byhand_manipadrsHP = "KR 24A # 29 - 85" in 16172
replace byhand_manipadrsHP = "KR 24A # 29 - 85" in 16173
replace byhand_manipadrsHP = "KR 20 # 33C - 72" in 16175
replace byhand_manipadrsHP = "KR 23 # 29 - 118" in 16180
replace byhand_manipadrsHP = "TV 29 # 20 - 50" in 16183
replace byhand_manipadrsHP = "KR 19 # 33C - 33" in 16185
replace byhand_manipadrsHP = "KR 23 # 29 - 118" in 16187
replace byhand_manipadrsHP = "KR 23 # 29 - 118" in 16188
replace byhand_manipadrsHP = "KR 22 # 33 E - 83" in 16200
replace byhand_manipadrsHP = "KR 17C # 23 - 18" in 16201
replace byhand_manipadrsHP = "KR 24B # 29 - 63" in 16203
replace byhand_manipadrsHP = "DG 24A # 25 - 63" in 16205
replace byhand_manipadrsHP = "KR 20 # 33C - 107" in 16210
replace byhand_manipadrsHP = "KR 24C # 33C - 165" in 16214
replace byhand_manipadrsHP = "KR 24C # 33C - 17" in 16218
replace byhand_manipadrsHP = "DG 19 # 25 - 22" in 16220
replace byhand_manipadrsHP = "AV 4 O # 21A - 57" in 16222
replace byhand_manipadrsHP = "DG 22 # 17C - 63" in 16231
replace byhand_manipadrsHP = "AV 4 O # 9 - 43" in 16253
replace byhand_manipadrsHP = "KR 1 # 26" in 16261
replace byhand_manipadrsHP = "KR 1 # 26" in 16262
replace byhand_manipadrsHP = "KR 2 # 36A - 58" in 16266
replace byhand_manipadrsHP = "CL 33 # 1A - 22" in 16269
replace byhand_manipadrsHP = "KR 46 # 13A - 47" in 16274
replace byhand_manipadrsHP = "KR 13B # 21" in 16283
replace byhand_manipadrsHP = "KR 47 3 # 13A - 52" in 16293
replace byhand_manipadrsHP = "KR 44 N # 13A - 67" in 16305

replace byhand_manipadrsHP = "KR 46A # 13B - 66" in 16310
replace byhand_manipadrsHP = "KR 16B O # 2C3 - 08" in 16317
replace byhand_manipadrsHP = "CL 3 O # 73B - 46" in 16318
replace byhand_manipadrsHP = "CL 3 O # 73B - 46" in 16319
replace byhand_manipadrsHP = "CL 28 O # 73A" in 16321
replace byhand_manipadrsHP = "CL 2B O # 73D - 16" in 16323
replace byhand_manipadrsHP = "KR 94 # 1B - 28" in 16331
replace byhand_manipadrsHP = "KR 94 # 1B - 46" in 16341
replace byhand_manipadrsHP = "KR 94A # 1A - 11" in 16342
replace byhand_manipadrsHP = "KR 94 2 O # 2 Bis - 18" in 16349
replace byhand_manipadrsHP = "KR 82 O # 3D - 23" in 16350
replace byhand_manipadrsHP = "KR 94 # 2B - 43" in 16351
replace byhand_manipadrsHP = "KR 9A # 1 - 122" in 16365
replace byhand_manipadrsHP = "KR 9A A1 # 122" in 16365
replace byhand_manipadrsHP = "" in 16365
replace byhand_manipadrsHP = "KR 9A A1 # 122" in 16365
replace byhand_manipadrsHP = "" in 16365
replace byhand_manipadrsHP = "CL 1 # 94A Bis - 53" in 16367
replace byhand_manipadrsHP = "CL 1 # 94A - 53" in 16368
replace byhand_manipadrsHP = "CL 1 # 91A Bis - 53" in 16369
replace byhand_manipadrsHP = "CL 1 # 94A Bis - 53" in 16368
replace byhand_manipadrsHP = "CL 1 # 94A Bis - 53" in 16369
replace byhand_manipadrsHP = "KR 94 O # 1A - 89" in 16388
replace byhand_manipadrsHP = "CL 2 # 94 - 23" in 16403

replace byhand_manipadrsHP = "KR 37 # 1 O - 45" in 16410
replace byhand_manipadrsHP = "CL 54 N # 9N - 12" in 16421
replace byhand_manipadrsHP = "CL 22A O" in 16422
replace byhand_manipadrsHP = "CL 16B" in 16425
replace byhand_manipadrsHP = "KR 93 # 2C - 126" in 16428
replace byhand_manipadrsHP = "KR 93 # 2C - 126" in 16429
replace byhand_manipadrsHP = "KR 93 # 2C - 126" in 16430
replace byhand_manipadrsHP = "KR 93 # 2C - 126" in 16431
replace byhand_manipadrsHP = "KR 93 # 2C - 126" in 16432
replace byhand_manipadrsHP = "KR 93 # 2C - 126" in 16433
replace byhand_manipadrsHP = "KR 95 # 2B - 59" in 16436
replace byhand_manipadrsHP = "KR 97 # 20 - 29" in 16437
replace byhand_manipadrsHP = "AV 5 E # 42 - 26" in 16439
replace byhand_manipadrsHP = "KR 1IN # 77 - 05" in 16440
replace byhand_manipadrsHP = "CL 72C # 1 - 76" in 16441
replace byhand_manipadrsHP = "CL 84 # 14 - 32B" in 16444
replace byhand_manipadrsHP = "KR 1JN # 81 - 20" in 16445
replace byhand_manipadrsHP = "KR 1 LN # 81 - 89" in 16446
replace byhand_manipadrsHP = "KR 1F # 82 - 75" in 16449
replace byhand_manipadrsHP = "KR 1IN # 82 - 44" in 16451
replace byhand_manipadrsHP = "CL 71I1 # 3EN - 22" in 16454
replace byhand_manipadrsHP = "KR 1 JN # 82 - 16" in 16456
replace byhand_manipadrsHP = "CL 72C # 28 - 11" in 16475
replace byhand_manipadrsHP = "DG 18 # 71A - 66" in 16484
replace byhand_manipadrsHP = "KR 9 # 72B - 58" in 16491
replace byhand_manipadrsHP = "DG 14 # 71A - 45" in 16494
replace byhand_manipadrsHP = "DG 13 # 71AG - 6" in 16497
replace byhand_manipadrsHP = "KR 22 # 72 1 - 06" in 16500
replace byhand_manipadrsHP = "DG 18B # 17F1 - 28" in 16503
replace byhand_manipadrsHP = "DG 19 # 71A - 11" in 16507
replace byhand_manipadrsHP = "CL 72B # 8D - 09" in 16511
replace byhand_manipadrsHP = "TV 72 S # 26G9 - 26" in 16512
replace byhand_manipadrsHP = "TV 72 # 166 9 - 26" in 16513
replace byhand_manipadrsHP = "DG 14 # 71A - 122" in 16523
replace byhand_manipadrsHP = "KR 107 # 2B - 45" in 16525
replace byhand_manipadrsHP = "KR 24 E # 11A - 24" in 16529
replace byhand_manipadrsHP = "C 37 # 17A - 40" in 16531
replace byhand_manipadrsHP = "DG 19 # 72A - 57" in 16538
replace byhand_manipadrsHP = "KR 197 # 72 - 13A3" in 16544
replace byhand_manipadrsHP = "DG 13 # 71 - 48" in 16545
replace byhand_manipadrsHP = "DG 16 # 71A - 122" in 16552
replace byhand_manipadrsHP = "KR 8C # 72B - 59" in 16554
replace byhand_manipadrsHP = "DG 14 # 71A - 21" in 16557
replace byhand_manipadrsHP = "DG 19 # 72A - 51" in 16560
replace byhand_manipadrsHP = "DG 13 # 71B - 17" in 16568
replace byhand_manipadrsHP = "KR 74D O # 2 - 34" in 16569
replace byhand_manipadrsHP = "CL 6G # 51B - 33" in 16574
replace byhand_manipadrsHP = "CL 11 # 11 - 66" in 16575
replace byhand_manipadrsHP = "CL 6AE # 40C - 17" in 16581
replace byhand_manipadrsHP = "CL 6H O # 50C - 30" in 16586
replace byhand_manipadrsHP = "KR 50FN # 13B - 29" in 16592
replace byhand_manipadrsHP = "KR 50 # 8 Bis - 64 O" in 16593
replace byhand_manipadrsHP = "KR 50 # 8 Bis - 64 O" in 16594
replace byhand_manipadrsHP = "KR 40B O # 5B - 45" in 16595
replace byhand_manipadrsHP = "CL 13 # 46A - 25" in 16601
replace byhand_manipadrsHP = "KR 53 # 2" in 16603
replace byhand_manipadrsHP = "CL 123A # 28 E1 - 27" in 16607
replace byhand_manipadrsHP = "CL 18 O # 50D - 14" in 16612
replace byhand_manipadrsHP = "KR 52A # 34 - 10A" in 16613
replace byhand_manipadrsHP = "CL 2 O # 51 - 118" in 16631
replace byhand_manipadrsHP = "CL 6 # 49 - 70" in 16635
replace byhand_manipadrsHP = "KR 42 6 O # 3 - 63" in 16647
replace byhand_manipadrsHP = "KR 42 # 6 O 3 - 63" in 16647
replace byhand_manipadrsHP = "CL 9B O # 50 - 13" in 16651
replace byhand_manipadrsHP = "CL 3 O # 42A - 03" in 16653
replace byhand_manipadrsHP = "CL 6B # 52 - 99" in 16673
replace byhand_manipadrsHP = "CL 10 # 52 - 83" in 16676
replace byhand_manipadrsHP = "CL 5 O # 51 - 15" in 16678
replace byhand_manipadrsHP = "KR 53 # 12 13 - 23" in 16680
replace byhand_manipadrsHP = "KR 50 # 1 - 42 O" in 16695
replace byhand_manipadrsHP = "KR 54A # 47 - 07" in 16710
replace byhand_manipadrsHP = "CL 11 O # 50 - 25" in 16711
replace byhand_manipadrsHP = "CL 3 O # 3A - 45" in 16718
replace byhand_manipadrsHP = "CL 18 # 49B1 - 47" in 16722
replace byhand_manipadrsHP = "" in 16727
replace byhand_manipadrsHP = "CL 6A # 11C" in 16745
replace byhand_manipadrsHP = "KR 43 O # 8B - 30" in 16752
replace byhand_manipadrsHP = "KR 17F # 28A - 23" in 16762
replace byhand_manipadrsHP = "KR 17B # 28A - 57" in 16767
replace byhand_manipadrsHP = "KR 3 O" in 16774
replace byhand_manipadrsHP = "CL 99 # 27D - 130" in 16784
replace byhand_manipadrsHP = "KR 42 # 5B - 17" in 16790
replace byhand_manipadrsHP = "KR 1A6 # 73 - 73" in 16792
replace byhand_manipadrsHP = "CL 3 # 140" in 16815
replace byhand_manipadrsHP = "" in 16821
replace byhand_manipadrsHP = "" in 16822
replace byhand_manipadrsHP = "" in 16823
replace byhand_manipadrsHP = "" in 16824
replace byhand_manipadrsHP = "" in 16825
replace byhand_manipadrsHP = "KR 28B # 28C - 43" in 16830
replace byhand_manipadrsHP = "KR 28C # 28C - 36" in 16863
replace byhand_manipadrsHP = "CL 55A # 28G - 32" in 16871
replace byhand_manipadrsHP = "KR 28 AD # 28 - 56" in 16873
replace byhand_manipadrsHP = "CL 44 # 28F - 33" in 16890
replace byhand_manipadrsHP = "CL 123A # 28D 10 - 13" in 16896
replace byhand_manipadrsHP = "CL 123A3 # 28E3 - 19" in 16897
replace byhand_manipadrsHP = "CL 16 # 12A - 13" in 16912
replace byhand_manipadrsHP = "KR 9 # 16 - 140" in 16915
replace byhand_manipadrsHP = "KR 10 # 18" in 16921
replace byhand_manipadrsHP = "CL 16 # 11B - 15" in 16927
replace byhand_manipadrsHP = "KR 8 # 16C - 44" in 16936
replace byhand_manipadrsHP = "CL 11 32 # 6B1 - 23" in 16938
replace byhand_manipadrsHP = "CL 16B # 12B - 05" in 16945
replace byhand_manipadrsHP = "CL 125C # 28F - 49" in 16954
replace byhand_manipadrsHP = "CL 31 # 2BW - 40" in 16960
replace byhand_manipadrsHP = "KR 3N # 32N - 21" in 16962
replace byhand_manipadrsHP = "KR 1 1C # 34 - 58" in 16963
replace byhand_manipadrsHP = "KR 1 EN FN # 73 - 10" in 16965
replace byhand_manipadrsHP = "KR 28E2 # 122D - 34" in 16967
replace byhand_manipadrsHP = "CL 123 # 28B - 14" in 16970
replace byhand_manipadrsHP = "CL 123 # 28B - 14" in 16971
replace byhand_manipadrsHP = "CL 123 # 28B - 14" in 16972
replace byhand_manipadrsHP = "KR 28D 8 # 122D - 38" in 16975
replace byhand_manipadrsHP = "CL 122 # 28D7 - 49" in 16976
replace byhand_manipadrsHP = "CL 125 # 26 14 - 60" in 16978
replace byhand_manipadrsHP = "CL 122E # 28D 10 - 39" in 16979
replace byhand_manipadrsHP = "AV 7A O # 22A - 11" in 16987
replace byhand_manipadrsHP = "AV 5B O # 33A - 03" in 16996
replace byhand_manipadrsHP = "AV 5B O # 33A - 03" in 16997
replace byhand_manipadrsHP = "AV A Bis # 16 - 156" in 17000
replace byhand_manipadrsHP = "CL 30 O # 8C 05" in 17009
replace byhand_manipadrsHP = "CL 24 O # 8 - 35" in 17032
replace byhand_manipadrsHP = "AV 8 O # 19 E - 30" in 17033
replace byhand_manipadrsHP = "CL 21 O # 4 Bis 2 - 35" in 17046
replace byhand_manipadrsHP = "AV 12 O # 40 - 00" in 17047
replace byhand_manipadrsHP = "AV 8B # 31 - 71" in 17049
replace byhand_manipadrsHP = "AV 8 # 8A - 52" in 17059
replace byhand_manipadrsHP = "CL 20O # 4 - 58" in 17064
replace byhand_manipadrsHP = "CL 20O # 4 - 58" in 17065
replace byhand_manipadrsHP = "CL 30A O # 6 - 69" in 17066
replace byhand_manipadrsHP = "TV 27 # 28C - 41" in 17082
replace byhand_manipadrsHP = "AV 6 # 23" in 17084
replace byhand_manipadrsHP = "AV 6 # 23" in 17085
replace byhand_manipadrsHP = "CL 9 O N # 4B 43 - 49" in 17086
replace byhand_manipadrsHP = "AV 5 # 22 - 90" in 17087
replace byhand_manipadrsHP = "AV 6A O # 25 - 35" in 17090
replace byhand_manipadrsHP = "AV 8 O # 29N - 8B - 20" in 17093
replace byhand_manipadrsHP = "AV 5C Bis # 47B - 03" in 17096
replace byhand_manipadrsHP = "AV 4 O # 21B - 51" in 17107
replace byhand_manipadrsHP = "AV 8 O # 24 - 06" in 17108
replace byhand_manipadrsHP = "AV 8 O # 29 - 8B - 20" in 17093
replace byhand_manipadrsHP = "AV 6 O # 22A - 60" in 17112
replace byhand_manipadrsHP = "AV 8 O # 22 Bis - 18" in 17122
replace byhand_manipadrsHP = "AV 4 1 Bis O # 10 - 57" in 17127
replace byhand_manipadrsHP = "AV 70E # 3 19 - 60" in 17132
replace byhand_manipadrsHP = "AV 70E3 # 19 - 60" in 17132
replace byhand_manipadrsHP = "CL 12B O # 4 Bis 1 - 26" in 17135
replace byhand_manipadrsHP = "AV 15 O # 9A - 290" in 17140
replace byhand_manipadrsHP = "AV 5 O # 11 - 04" in 17142
replace byhand_manipadrsHP = "CL 19 O # 8A - 122" in 17143
replace byhand_manipadrsHP = "CL 30 O # 6 - 98" in 17153
replace byhand_manipadrsHP = "AV 6 O # 22 - 34" in 17154
replace byhand_manipadrsHP = "CL 72A # 4 - 108 C24" in 17160
replace byhand_manipadrsHP = "CL 54 # 1B1 - 12" in 17167
replace byhand_manipadrsHP = "CL 59 # 1C - 125" in 17174
replace byhand_manipadrsHP = "KR Bis # 46 - 50" in 17182
replace byhand_manipadrsHP = "CL 54 # 1A - 67" in 17183
replace byhand_manipadrsHP = "KR 1C3 # 58 - 30" in 17204
replace byhand_manipadrsHP = "KR 1 Bis # 59 - 15" in 17207
replace byhand_manipadrsHP = "CL 59 # 1 Bis - 35" in 17212
replace byhand_manipadrsHP = "CL 1 # 56 - 70" in 17213
replace byhand_manipadrsHP = "KR 1B # 57 - 102" in 17218
replace byhand_manipadrsHP = "CL 59 # 1 Bis - 30" in 17219
replace byhand_manipadrsHP = "KR 1AB # 57 - 102" in 17221
replace byhand_manipadrsHP = "CL 54 # 1B2 - 24" in 17228
replace byhand_manipadrsHP = "CL 59 # 1C - 73" in 17237
replace byhand_manipadrsHP = "KR 1 A 14 # 54A - 110" in 17238
replace byhand_manipadrsHP = "KR 1A # 55 - 70 - 50" in 17252
replace byhand_manipadrsHP = "KR 1A 55 # 70 - 50" in 17252
replace byhand_manipadrsHP = "KR 24D3 # 21 - 28" in 17271
replace byhand_manipadrsHP = "KR 26 # 70B - 23" in 17276
replace byhand_manipadrsHP = "KR 23C # 72B - 35" in 17281
replace byhand_manipadrsHP = "DG 70C3 # 24B1 - 45" in 17290
replace byhand_manipadrsHP = "KR 23A # 72B - 91" in 17291
replace byhand_manipadrsHP = "CL 70 # 25B - 49" in 17296
replace byhand_manipadrsHP = "KR 25C # 71 - 20" in 17306
replace byhand_manipadrsHP = "KR 28B # 72F - 55" in 17329
replace byhand_manipadrsHP = "CL 71 # 26C - 24" in 17335
replace byhand_manipadrsHP = "KR 24D # 72 - 63" in 17340
replace byhand_manipadrsHP = "KR 26H2 # 71 - 14" in 17355
replace byhand_manipadrsHP = "KR 89 10 # 80 - 222 - T11" in 17368
replace byhand_manipadrsHP = "KR 89 10 # 80 - 222" in 17368
replace byhand_manipadrsHP = "KR 42 3 # 39A - 25" in 17374
replace byhand_manipadrsHP = "KR 42A1 # 43 - 18" in 17378
replace byhand_manipadrsHP = "KR 42A1 # 42 - 72" in 17401
replace byhand_manipadrsHP = "KR 42A1 # 42 - 72" in 17426
replace byhand_manipadrsHP = "CL 36 # 41E - 69" in 17436
replace byhand_manipadrsHP = "KR 1A4C # 73 - 10" in 17441
replace byhand_manipadrsHP = "KR 8N # 46AN - 09" in 17450
replace byhand_manipadrsHP = "KR 42 # 40 - 56" in 17457
replace byhand_manipadrsHP = "KR 42A1 # 45 - 03" in 17459
replace byhand_manipadrsHP = "CL 42 # 42A1 - 06" in 17462

replace byhand_manipadrsHP = "CL 41 # 42C - 39" in 17477
replace byhand_manipadrsHP = "KR 24A # 33C - 84" in 17504
replace byhand_manipadrsHP = "CL 37 # 41G - 72" in 17505
replace byhand_manipadrsHP = "KR 41 E # 38 - 80" in 17530
replace byhand_manipadrsHP = "KR 41 # 53" in 17534
replace byhand_manipadrsHP = "KR 39 # 35A - 91" in 17585
replace byhand_manipadrsHP = "CL 45A # 5A - 150" in 17591
replace byhand_manipadrsHP = "DG 22 # 29 - 61" in 17609
replace byhand_manipadrsHP = "CL 10C # 46 - 12" in 17619
replace byhand_manipadrsHP = "KR 33 # 10A - 133" in 17624
replace byhand_manipadrsHP = "KR 33 # 10A - 133" in 17625
replace byhand_manipadrsHP = "CL 12B # 29A1 - 20" in 17628
replace byhand_manipadrsHP = "KR 32 # 10A - 130" in 17629
replace byhand_manipadrsHP = "CL 29 # 11B - 40" in 17632
replace byhand_manipadrsHP = "DG 23 # 10B - 137" in 17635
replace byhand_manipadrsHP = "DG 12C # 27" in 17636
replace byhand_manipadrsHP = "CL 66 # 12BI5 - 64" in 17649
replace byhand_manipadrsHP = "CL 54 N # 11A - 35" in 17653
replace byhand_manipadrsHP = "CL 63 3 # 12B - 28" in 17655
replace byhand_manipadrsHP = "CL 63 3 # 12B - 28" in 17656
replace byhand_manipadrsHP = "CL 63 3 # 12B - 28" in 17657
replace byhand_manipadrsHP = "KR 21B # 80C - 199" in 17674
replace byhand_manipadrsHP = "CL 88" in 17680
replace byhand_manipadrsHP = "CL 83D # 24F - 29" in 17694
replace byhand_manipadrsHP = "KR 49A # 56H - 03" in 17699
replace byhand_manipadrsHP = "TV 00 # 94" in 17702
replace byhand_manipadrsHP = "CL 101C # 22B - 110" in 17722
replace byhand_manipadrsHP = "CL 82 # 24A - 63" in 17744
replace byhand_manipadrsHP = "KR 28C # 122A - 10" in 17758
replace byhand_manipadrsHP = "CL 116 # 20 - 26" in 17763
replace byhand_manipadrsHP = "CL 84A # 20A - 02" in 17767
replace byhand_manipadrsHP = "CL 83D # 22 - 06" in 17775
replace byhand_manipadrsHP = "KR 21H # 80C - 135" in 17781
replace byhand_manipadrsHP = "CL 82D3 # 23 - 65" in 17786
replace byhand_manipadrsHP = "KR 24F4 # 82 - 12" in 17792
replace byhand_manipadrsHP = "KR 24F4 # 82 - 5" in 17793
replace byhand_manipadrsHP = "CL 80 E # 23A - 12" in 17796
replace byhand_manipadrsHP = "CL 79A # 23 - 38" in 17800
replace byhand_manipadrsHP = "KR 24F3 # 82 - 10" in 17802
replace byhand_manipadrsHP = "KR 21B # 80C - 128" in 17808
replace byhand_manipadrsHP = "CL 8C # 23A - 79" in 17813
replace byhand_manipadrsHP = "CL 89 # 20A - 33" in 17822
replace byhand_manipadrsHP = "KR 21 # 80C - 104" in 17823
replace byhand_manipadrsHP = "CL 109 # 14 - 99" in 17828
replace byhand_manipadrsHP = "DG 26 G 8 # 1 - 17" in 17834
replace byhand_manipadrsHP = "CL 82D # 20 - 41" in 17837
replace byhand_manipadrsHP = "KR 28F E # 128 - 64" in 17867
replace byhand_manipadrsHP = "KR 28F E # 128 - 64" in 17868
replace byhand_manipadrsHP = "KR 28F E # 128 - 64" in 17869
replace byhand_manipadrsHP = "KR 28F E # 128 - 64" in 17870
replace byhand_manipadrsHP = "CL 83D # 20A - 103" in 17880
replace byhand_manipadrsHP = "CL 82 # 23A - 82" in 17891
replace byhand_manipadrsHP = "CL 85 # 20A" in 17894
replace byhand_manipadrsHP = "AV 3 N # 20N - 52" in 17905
replace byhand_manipadrsHP = "CL 53 # 10A - 15" in 17919
replace byhand_manipadrsHP = "KR 11 # 48 - 33" in 17928
replace byhand_manipadrsHP = "KR 10 3 # 54 - 31" in 17934
replace byhand_manipadrsHP = "CL 50 # 12C - 57" in 17942

replace byhand_manipadrsHP = "KR 8 # 54 - 28" in 17945
replace byhand_manipadrsHP = "KR 12 # 49 - 30" in 17946
replace byhand_manipadrsHP = "CL 48 # 12A - 26" in 17953
replace byhand_manipadrsHP = "CL 53 N # 8B - 56" in 17960
replace byhand_manipadrsHP = "CL 49 # 12A - 60" in 17974
replace byhand_manipadrsHP = "KR 1B Bis # 59 - 94" in 17982
replace byhand_manipadrsHP = "KR 9 N # 52 Bis - 25" in 17983
replace byhand_manipadrsHP = "KR 9 N # 52 Bis - 25" in 17984
replace byhand_manipadrsHP = "KR 1C Bis # 58A1 - 24" in 17990
replace byhand_manipadrsHP = "KR 1 P2 # 60AB - 112P" in 17993
replace byhand_manipadrsHP = "KR 1C Bis # 58A 1 - 17" in 17999
replace byhand_manipadrsHP = "KR 1D2 # 6A - 14" in 18000
replace byhand_manipadrsHP = "CL 4 58A # 01 - 02" in 18001
replace byhand_manipadrsHP = "CL 4 58A # 01 - 02" in 18002
replace byhand_manipadrsHP = "KR 25F # 70B - 70" in 18004
replace byhand_manipadrsHP = "KR 28B2 # 70A1 - 76" in 18005
replace byhand_manipadrsHP = "DG 7BA2 # 24 - 11" in 18007
replace byhand_manipadrsHP = "DG 7BA2 # 24 - 11" in 18008
replace byhand_manipadrsHP = "DG 7BA2 # 24 - 11" in 18009
replace byhand_manipadrsHP = "DG 7BA2 # 24 - 11" in 18010
replace byhand_manipadrsHP = "DG 7BA2 # 24 - 11" in 18011
replace byhand_manipadrsHP = "KR 28B3 # 70E - 110" in 18013
replace byhand_manipadrsHP = "KR 26H # 70D - 39" in 18014
replace byhand_manipadrsHP = "DG 70A32 # 24 - 155" in 18020
replace byhand_manipadrsHP = "DG 70A32 # 24 - 155" in 18021
replace byhand_manipadrsHP = "DG 70A32 # 24 - 155" in 18022
replace byhand_manipadrsHP = "DG 70A32 # 24 - 155" in 18023
replace byhand_manipadrsHP = "DG 70A32 # 24 - 155" in 18024
replace byhand_manipadrsHP = "DG 70A32 # 24 - 155" in 18025
replace byhand_manipadrsHP = "DG 70A32 # 24 - 155" in 18026
replace byhand_manipadrsHP = "KR 24A1B # 70 - 73" in 18030
replace byhand_manipadrsHP = "KR 26D # 70A - 35" in 18032
replace byhand_manipadrsHP = "KR 26G # 70 - 23" in 18035
replace byhand_manipadrsHP = "DG 70 # 23A - 138" in 18036
replace byhand_manipadrsHP = "DG 71A1 # 24B1 - 10" in 18037
replace byhand_manipadrsHP = "DG 70E # 24D - 103" in 18038
replace byhand_manipadrsHP = "KR 24B # 70A1 - 85" in 18039
replace byhand_manipadrsHP = "KR 24D # 70 E - 47" in 18040
replace byhand_manipadrsHP = "KR 24D # 70 E - 47" in 18041
replace byhand_manipadrsHP = "KR 25A # 70B - 40" in 18042
replace byhand_manipadrsHP = "KR 24A # 70 - 90" in 18043
replace byhand_manipadrsHP = "KR 24D # 70C - 83" in 18047
replace byhand_manipadrsHP = "CL 24F # 70B - 28" in 18048
replace byhand_manipadrsHP = "KR 26 E # 70 - 35" in 18050
replace byhand_manipadrsHP = "KR 24 A1 # 70 - 13" in 18052
replace byhand_manipadrsHP = "KR 24E # 70B - 74" in 18053
replace byhand_manipadrsHP = "KR 25B # 70A - 58" in 18054
replace byhand_manipadrsHP = "KR 25B # 70A - 46" in 18055
replace byhand_manipadrsHP = "KR 24E # 70A - 40" in 18058
replace byhand_manipadrsHP = "KR 24E # 70A - 40" in 18059
replace byhand_manipadrsHP = "KR 24F # 70B - 35" in 18060
replace byhand_manipadrsHP = "DG 72C" in 18065
replace byhand_manipadrsHP = "KR 24 # 70E - 19" in 18071
replace byhand_manipadrsHP = "DG 70 # 25C - 18" in 18072
replace byhand_manipadrsHP = "KR 26A # 70A - 73" in 18075
replace byhand_manipadrsHP = "KR 26 # 70D - 68" in 18076
replace byhand_manipadrsHP = "DG 70G # 24D - 62" in 18077
replace byhand_manipadrsHP = "KR 25C # 70B - 35" in 18084
replace byhand_manipadrsHP = "KR 26 # 70B - 23" in 18085
replace byhand_manipadrsHP = "KR 25F # 70A - 23" in 18095
replace byhand_manipadrsHP = "KR 24 Bis # 70 - 11" in 18096
replace byhand_manipadrsHP = "KR 24 # 70 E - 68" in 18098
replace byhand_manipadrsHP = "KR 25 # 70A - 52" in 18100
replace byhand_manipadrsHP = "KR 25B # 70B - 71" in 18104
replace byhand_manipadrsHP = "KR 25B # 70B - 41" in 18105
replace byhand_manipadrsHP = "KR 26 1 # 72 - 15" in 18110
replace byhand_manipadrsHP = "KR 24 # 70 - 17" in 18111
replace byhand_manipadrsHP = "KR 24 # 70 - 17" in 18112
replace byhand_manipadrsHP = "DG 70F # 25D - 91" in 18114
replace byhand_manipadrsHP = "KR 26D # 70A - 35" in 18118
replace byhand_manipadrsHP = "KR 25D # 70A - 70" in 18119
replace byhand_manipadrsHP = "KR 25D # 70A - 70" in 18120
replace byhand_manipadrsHP = "KR 26G # 70B - 65" in 18121
replace byhand_manipadrsHP = "KR 25A # 70 - 11" in 18123
replace byhand_manipadrsHP = "DG 72B # 26 - 24" in 18124
replace byhand_manipadrsHP = "KR 24 F # 70B - 35" in 18126
replace byhand_manipadrsHP = "KR 24B3 # 70 E - 109" in 18127
replace byhand_manipadrsHP = "KR 24A1 # 70E - 109" in 18130
replace byhand_manipadrsHP = "KR 324C # 70 - 59" in 18132
replace byhand_manipadrsHP = "KR 324C # 70 - 59" in 18133
replace byhand_manipadrsHP = "KR 324C # 70 - 59" in 18134
replace byhand_manipadrsHP = "KR 24C # 70 - B54" in 18135
replace byhand_manipadrsHP = "KR 24C # 70B - 54" in 18135
replace byhand_manipadrsHP = "KR 24B2 # 70E - 30" in 18136
replace byhand_manipadrsHP = "CL 73 # 25T - 22" in 18138
replace byhand_manipadrsHP = "KR 26 # 70D6 - 7" in 18139
replace byhand_manipadrsHP = "KR 26 # 70D6 - 7" in 18140
replace byhand_manipadrsHP = "KR 24A1 # 70 - 98" in 18141
replace byhand_manipadrsHP = "KR 25C # 70B - 10" in 18142
replace byhand_manipadrsHP = "KR 24B4 # 70E - 130" in 18143
replace byhand_manipadrsHP = "KR 24 B4 # 70 - 35" in 18145
replace byhand_manipadrsHP = "DG 70 # 26 3 - 42" in 18146
replace byhand_manipadrsHP = "KR 24B4 # 70 - 65" in 18150

replace byhand_manipadrsHP = "KR 24B1 # 70 - 16" in 18151
replace byhand_manipadrsHP = "DG 28C # 42C - 13" in 18171
replace byhand_manipadrsHP = "KR 42B # 28B - 18" in 18185
replace byhand_manipadrsHP = "KR 43A # 28B - 19" in 18193
replace byhand_manipadrsHP = "KR 42 # 26D - 32" in 18200
replace byhand_manipadrsHP = "KR 45 # 26B - 74" in 18204
replace byhand_manipadrsHP = "CL 70 # 26G6 - 16" in 18217
replace byhand_manipadrsHP = "CL 98 # 26G - 41" in 18220
replace byhand_manipadrsHP = "CL 78N # 28D4 - 76" in 18222
replace byhand_manipadrsHP = "KR 26P2 # 94 - 17" in 18225
replace byhand_manipadrsHP = "CL 98 # 26G2 - 37" in 18228
replace byhand_manipadrsHP = "CL 38 # 13N - 76" in 18243
replace byhand_manipadrsHP = "KR 26G1 # 94 - 28" in 18249
replace byhand_manipadrsHP = "CL 96 # 26G - 49" in 18251
replace byhand_manipadrsHP = "CL 98A # 26G - 79" in 18253
replace byhand_manipadrsHP = "CL 97 # 26G5 - 15" in 18259
replace byhand_manipadrsHP = "CL 26H # 92 - 14" in 18264
replace byhand_manipadrsHP = "CL 90C # 26H - 08" in 18270
replace byhand_manipadrsHP = "TV 103 # 95" in 18273
replace byhand_manipadrsHP = "TV 103 # 26 86 - 16" in 18274
replace byhand_manipadrsHP = "CL 98 # 26G5 - 14" in 18276
replace byhand_manipadrsHP = "KR 28B 3 # 72A - 59" in 18282
replace byhand_manipadrsHP = "CL 72F5 # 3 28 E - 12" in 18294
replace byhand_manipadrsHP = "CL 72F 53 # 28 E - 12" in 18294
replace byhand_manipadrsHP = "DG 22 # 26L - 101" in 18312
replace byhand_manipadrsHP = "KR 26L # 72 E Bis - 05" in 18313
replace byhand_manipadrsHP = "DG 29A # 27 - 111" in 18316
replace byhand_manipadrsHP = "DG 28C # 28 - 06" in 18318
replace byhand_manipadrsHP = "DG 28D # 28 - 60" in 18322
replace byhand_manipadrsHP = "TV 28B3 # 28A - 22" in 18326
replace byhand_manipadrsHP = "CL 32 HT # 27 - 60" in 18327
replace byhand_manipadrsHP = "KR 27 # 28B - 16" in 18334
replace byhand_manipadrsHP = "TV 33E # 28 - 29" in 18335
replace byhand_manipadrsHP = "TV 28 # 28 - 48" in 18336
replace byhand_manipadrsHP = "TV 28 # 28 - 48" in 18337
replace byhand_manipadrsHP = "TV 27 # 28C - 23" in 18340
replace byhand_manipadrsHP = "DG 29 # 33E - 38" in 18343
replace byhand_manipadrsHP = "DG 26P9 # 10 - 52" in 18344
replace byhand_manipadrsHP = "DG 28D # 28 - 60" in 18346
replace byhand_manipadrsHP = "TV 26D # 28C - 31" in 18358
replace byhand_manipadrsHP = "DG 28D # 27 - 33" in 18361
replace byhand_manipadrsHP = "DG 28D # 27 - 33" in 18362
replace byhand_manipadrsHP = "DG 28D # 27 - 33" in 18363
replace byhand_manipadrsHP = "DG 28D # 27 - 33" in 18364
replace byhand_manipadrsHP = "DG 28DF # 28D3 - 18" in 18365
replace byhand_manipadrsHP = "TV 27D2 # 8C - 12" in 18366
replace byhand_manipadrsHP = "DG 28A # 28 - 45" in 18367
replace byhand_manipadrsHP = "TV 27" in 18370
replace byhand_manipadrsHP = "DG 28 # 28 - 44" in 18371
replace byhand_manipadrsHP = "TV 27 3 # 28 - 25" in 18372
replace byhand_manipadrsHP = "TV 28 # 28C - 20" in 18373
replace byhand_manipadrsHP = "TV 29 # 28 - 62" in 18374
replace byhand_manipadrsHP = "TV 29D # 28T - 38" in 18380
replace byhand_manipadrsHP = "TV 25 3 # 32 - 19" in 18385
replace byhand_manipadrsHP = "TV 25 # 32 - 19" in 18385
replace byhand_manipadrsHP = "DG 28 # 28 - 14" in 18391
replace byhand_manipadrsHP = "CL 47C # 3EN - 131" in 18392
replace byhand_manipadrsHP = "CL 41 N # 3C - 71" in 18403
replace byhand_manipadrsHP = "CL 47BN # 3CN - 45" in 18410
replace byhand_manipadrsHP = "CL 47BN # 3CN - 45" in 18411
replace byhand_manipadrsHP = "CL 47BN # 3CN - 45" in 18412
replace byhand_manipadrsHP = "AV 3B # 40 - 143" in 18428
replace byhand_manipadrsHP = "AV 3CN # 42 N - 73" in 18429
replace byhand_manipadrsHP = "CL 41 N # 3N - 37" in 18430
replace byhand_manipadrsHP = "AV 3FN # 45N - 30" in 18432
replace byhand_manipadrsHP = "AV 3 CM # 40 - 20" in 18433
replace byhand_manipadrsHP = "CL 5 O # 34 - 8A - 27" in 18443
replace byhand_manipadrsHP = "CL 5 O 34 # 8A - 27" in 18443
replace byhand_manipadrsHP = "CL 47A O # 5C Bis - 23" in 18445
replace byhand_manipadrsHP = "CL 47A O # 5C Bis - 23" in 18446
replace byhand_manipadrsHP = "DG 28D3 # 72F - 38" in 18453
replace byhand_manipadrsHP = "DG 28B3 # 72F4 - 18" in 18454
replace byhand_manipadrsHP = "DG 28D5 # 2F3 - 18" in 18456
replace byhand_manipadrsHP = "DG 28D" in 18457
replace byhand_manipadrsHP = "TV 72 # 4D 28 - 07" in 18458
replace byhand_manipadrsHP = "TV 72F3 # 28D3 - 53" in 18463
replace byhand_manipadrsHP = "DG 28D 3T # 72FA - 52" in 18465
replace byhand_manipadrsHP = "DG 28D1 # 72B - 10" in 18466
replace byhand_manipadrsHP = "TV 72F # 28D1 - 38" in 18467
replace byhand_manipadrsHP = "TV 72F # 28 01 - 38" in 18468
replace byhand_manipadrsHP = "CL 72 IT # 28F - 66" in 18470
replace byhand_manipadrsHP = "DG 28D3 # 72A1 - 04" in 18476
replace byhand_manipadrsHP = "DG 28D5 # 72F2 - 03" in 18478
replace byhand_manipadrsHP = "DG 28D2 # 71A - 17" in 18486
replace byhand_manipadrsHP = "DG 28D5 # 72F3 - 18" in 18487
replace byhand_manipadrsHP = "DG 28D4 # 72F - 25" in 18489
replace byhand_manipadrsHP = "DG 28D4 # 28D - 317" in 18491
replace byhand_manipadrsHP = "DG 28D4 # 28D - 317" in 18492
replace byhand_manipadrsHP = "DG 28D6 # 72F - 41" in 18494
replace byhand_manipadrsHP = "CL 71A # 28E - 32" in 18496
replace byhand_manipadrsHP = "DG 28D2 # 72A - 60" in 18498
replace byhand_manipadrsHP = "DG 28D1 # 72B - 10" in 18500

replace byhand_manipadrsHP = "DG 28D2 # 72A - 62" in 18507
replace byhand_manipadrsHP = "KR 28G3 # 72T - 32" in 18513
replace byhand_manipadrsHP = "DG 28D4 # 72F1 - 03" in 18516
replace byhand_manipadrsHP = "CL 72I # 28F - 50" in 18521
replace byhand_manipadrsHP = "CL 72I # 28F - 50" in 18522
replace byhand_manipadrsHP = "DG 28D4 # 72F2 - 03" in 18528
replace byhand_manipadrsHP = "DG 28D5 # 74F - 04" in 18530

*list multiple with same num_ide_
*list multiples by fecha, num_id_, and NOMBRE, semana 

drop if byhand_manipadrsHP  ==""

*export text file for geocoding 
rename byhand_manipadrsHP direcion
outfile ID_CODE direcion using "krystosik_homeaddress_dengue_chikv.txt", noquote replace

order ID_CODE direcion dir_res_
drop manipadrsHP- manipadrsH pound- pound1space_origionalB5 address_complete suffix2b- suffix5 variabl_merge drop_ suffix freq_COD_BARRIO
rename _count count
rename _pos1 pos1
rename _pos2 pos2
rename _pos3 pos3
rename _pos4 pos4
rename _pos5 pos5
rename _pos6 pos6
rename _pos7 pos7
rename _pos8 pos8
rename _pos9 pos9
*rename ID_BARRIO id_barrio
rename COD_BARRIO cod_barrio
rename ESTRATO_MO estrato_mo

save temp.dta, replace
*/

*From HERE
/*********************************
 *Amy Krystosik                  *
 *chikv and dengue in cali       *
 *dissertation                   *
 *last updated January 3, 2016  *
 *********************************/

cd "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data"
capture log close 
log using "dissertation_fromHERE.smcl", text replace 
set scrollbufsize 100000
set more 1
use temp.dta, clear



*data cleaning
bysort  num_ide_  fec_not cod_eve: gen freq_cedula = _N

sort num_ide_   fec_not direcion clasfinal cod_eve
quietly by num_ide_  fec_not direcion clasfinal cod_eve:  gen dup = cond(_N==1,0,_n)
tabulate dup
export excel num_ide_ cod_eve direcion clasfinal barrio dir_res_  fec_not freq_cedula dup using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\freq_cedula.xls", firstrow(variables) replace
drop if dup>1
bysort  num_ide_  fec_not cod_eve: gen freq_cedula2 = _N

order direcion clasfinal num_ide_  dir_res_ freq_cedula2 dup cod_eve barrio
gsort  - freq_cedula2 num_ide_  

*manual changes based on searching for address and using the most common clasfinal.
replace direcion = "DG 28 E # 29 - 48" in 3
replace direcion = "DG 28 E # 29 - 48" in 2
replace direcion = "DG 28 E # 29 - 48" in 1
replace direcion = "CL 72K # 3N - 31" in 5
replace direcion = "CL 72K # 3N - 31" in 4
replace direcion = "AV 2IN # 45N - 83" in 6
replace direcion = "KR 29B3 # 27 - 56" in 8
replace direcion = "KR 13 # 46 - 13" in 10
replace direcion = "KR 75 Bis # 72 - 116" in 14
replace direcion = "DG 71C1 # 26J - 51" in 17
replace direcion = "CL 77B # 23 - 25" in 19
replace clasfinal = "2" in 21
replace direcion = "CL 3C # 70 - 67" in 22
replace direcion = "KR 95 # 2B - 80" in 24
replace direcion = "AV 4 # 32 - 44 - 158" in 26
replace direcion = "AV 4 # 32 - 44 - 158" in 27
replace direcion = "AV 4 32 # 44 - 158" in 26
replace direcion = "AV 4 # 32 - 44 - 158" in 26
replace direcion = "KR 94 # 3W O" in 28
replace direcion = "CL 125 # 28F - 55" in 31
replace direcion = "CL 2A # 9 Bis" in 33
replace direcion = "KR 26 I3 # 95 - 24" in 35
replace direcion = "KR 24G # 85 - 101" in 36
replace direcion = "KR 1AB Bis # 73A - 70" in 38
replace direcion = "CL 36 # 30 - 44" in 40
replace direcion = "CL 43B # 32B - 29" in 43
replace direcion = "KR 26C1 # 94 - 58" in 44
replace direcion = "CL 45 # 83B - 4N" in 46
replace clasfinal = "2" in 46
replace direcion = "KR 44A # 40 - 22" in 49
replace direcion = "DG 71AN # 22 - 74 " in 50
replace direcion = "DG 71AN # 22 - 74 " in 51
replace clasfinal = "2" in 51
replace clasfinal = "2" in 52
replace direcion = "CL 71" in 55
replace direcion = "CL 15 # 36B" in 57
replace direcion = "KR 1 9 # 72 - 21" in 58
replace direcion = "KR 62B # 14 3 - 65" in 61
replace direcion = "CL 23 # 13F - 21" in 62
replace direcion = "KR 48C # 23I - 89" in 65
replace clasfinal = "2" in 64
replace direcion = "CL 15 # 121 - 66" in 66
replace direcion = "KR 27AT # 29 - 33" in 68
replace direcion = "CL 13E # 53 - 34" in 71
replace direcion = "CL 123 # 28B - 14" in 73
replace direcion = "KR 92 O # 2C2- 06" in 75
replace direcion = "CL 56J # 47D - 38" in 77
replace direcion = "KR 40M # 30C - 71" in 79

replace direcion = "KR 24 # 28 - 40" in 81
replace direcion = "KR 1C3 # 64 - 12" in 85
replace direcion = "AV 8N3 # 52B - 34" in 86
replace direcion = "KR 42 # 55B - 93" in 88
replace direcion = "KR 42 # 55B - 93" in 89
replace direcion = "CL 83A # 3AN - 32" in 91

replace direcion = "CL 55A # 28G - 48" in 92
replace direcion = "KR 7B Bis # 70 - 100" in 95
replace clasfinal = "2" in 94
replace direcion = "KR 42A # 38 - 79" in 97
replace direcion = "CL 13A3 # 50 - 57" in 99
replace clasfinal = "2" in 100
replace direcion = "KR 7 RB # 72 - 31" in 103
replace direcion = "KR 7 RB # 72 - 31" in 102
replace direcion = "KR 90 # 28 - 64" in 105
replace direcion = "KR 17F # 29 - 39" in 107
replace direcion = "CL 47A N # 5AN - 60" in 108
replace direcion = "KR 25E # 26B - 52" in 111
replace clasfinal = "2" in 109
replace direcion = "KR 49C1 # 7 - 26" in 112
replace direcion = "KR 87 O # 97" in 114
replace direcion = "KR 26I # 123 - 56" in 116
replace clasfinal = "2" in 119

replace direcion = "KR 28D # 100" in 118
replace clasfinal = "2" in 120
replace direcion = "KR 27F # 121 - 22" in 123

replace direcion = "CL 2 O # 24E - 46" in 125
replace direcion = "KR 39 E # 51 - 11" in 126
replace direcion = "KR 7M1 # 92 - 33" in 128
replace direcion = "KR 83CE # 46 - 24" in 131
replace direcion = "KR 18 # 71A - 118" in 132
replace direcion = "KR 43 # 14C - 35" in 135
replace direcion = "KR 17F1 # 18 - 35" in 137
replace direcion = "CL 44 # 28B - 25" in 138
replace direcion = "CL 42 O # 5A - 33" in 141
replace direcion = "KR 35 # 31A - 66" in 142
replace direcion = "CL 37A # 3CN - 31" in 144
replace direcion = "KR 64A # 14C - 71" in 146
replace direcion = "KR 14 # 6 - 54B" in 148

replace direcion = "KR 40A # 12B - 77" in 151
replace direcion = "KR 39C # 55A - 26" in 153

replace clasfinal = "2" in 155
replace clasfinal = "2" in 156
replace direcion = "KR 1DN # 77 - 33" in 158
replace direcion = "KR 41E2 # 49 - 23" in 160
replace direcion = "KR 94 # 1A - 70" in 163
replace direcion = "CL 70 N # 2AN - 121" in 164
replace direcion = "KR 95 # 1 Bis - 97" in 167
replace direcion = "KR 32 # 34 - 17" in 169
replace direcion = "CL 45 # 83D - 37" in 170
replace direcion = "CL 45 # 83D - 37" in 171
replace direcion = "KR 40A # 2C - 92" in 172
replace direcion = "KR 39A # 42B - 09" in 174
replace direcion = "KR 39A # 42B - 09" in 175
replace direcion = "KR 1 # 66 - 42" in 177
replace direcion = "KR 1B2 # 64 - 21" in 178
replace direcion = "KR 324C # 70 - 59" in 180
replace direcion = "KR 24C # 70 - 59" in 180
replace direcion = "KR 24C # 70 - 59" in 181
replace direcion = "AV 2HN # 52A - 05" in 183
replace direcion = "KR 1C5 # 63 - 80" in 185
replace direcion = "KR 41E3 # 55B - 93" in 186
replace direcion = "KR 7M1 # 92 - 46" in 188
replace direcion = "KR 1A10 # 73A - 53" in 190
replace direcion = "KR 5 N # 38 - 30" in 192
replace direcion = "KR 5 N # 38 - 30" in 193
replace direcion = "KR 1D # 46A - 36" in 194
replace direcion = "CL 70 # 2AN 1S1N - 203" in 197
replace direcion = "KR 46C # 40 - 16" in 199
replace direcion = "KR 7T Bis # 72 - 131" in 200

/*
*data cleaning
bysort  num_ide_  fec_not cod_eve: gen freq_cedula = _N

sort num_ide_   fec_not direcion clasfinal cod_eve
quietly by num_ide_  fec_not direcion clasfinal cod_eve:  gen dup = cond(_N==1,0,_n)
tabulate dup
export excel num_ide_ cod_eve direcion clasfinal barrio dir_res_  fec_not freq_cedula dup using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\freq_cedula.xls", firstrow(variables) replace
drop if dup>1

bysort  num_ide_  fec_not cod_eve: gen freq_cedula2 = _N
order direcion clasfinal num_ide_  dir_res_ freq_cedula2 dup cod_eve barrio
gsort  - freq_cedula2 num_ide_  
*/

*rerun dups by num_ide_   fec_not direcion clasfinal cod_eve
sort num_ide_   fec_not direcion clasfinal cod_eve
quietly by num_ide_  fec_not direcion clasfinal cod_eve:  gen dup2 = cond(_N==1,0,_n)
tabulate dup2
drop if dup2>1

*rerun dups by num_ide_  semana cod_eve 
sort num_ide_  semana cod_eve 
quietly by num_ide_  semana cod_eve:  gen dup4 = cond(_N==1,0,_n)
tabulate dup4
drop if dup4>1

bysort  num_ide_  semana cod_eve: gen freq_cedula4 = _N
order direcion clasfinal num_ide_  dir_res_ freq_cedula4 freq_cedula2 dup cod_eve barrio
gsort  - freq_cedula4 num_ide_  

replace direcion = trim( direcion)
replace direcion = itrim( direcion)

*remove prisoners
tab gp_carcela
drop if gp_carcela == "1" 

*check dates
tab semana
tab year

*check formats for each collum
*id
list num_ide_ if regexm(num_ide_, "[0-9]+")==1 

*edad
list edad if regexm(edad, "[0-9]+")==0 
destring edad, replace
order num_ide_
list num_ide_  pri_nom_ seg_nom_ pri_ape_ seg_ape_ edad if edad >= 100

*sex
tab sexo

*ethnicity
tab per_etn_

tab gp_discapa
tab gp_desplaz
tab gp_migrant
tab gp_carcela
tab gp_gestan
tab gp_indigen
tab gp_pobicbf
tab gp_mad_com
tab gp_desmovi
tab gp_psiquia
tab gp_vic_vio
tab desplazami
tab famantdngu
tab clasfinal
tab nom_eve
tab clasfinal nom_eve
drop count -  dup4
/*
*outsheet using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\redcap.csv", comma replace
outsheet using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\alldata.csv", comma replace
outsheet using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\redcap_2000.csv" in 1/2000, comma replace
outsheet using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\redcap_4000.csv" in 2001/4000, comma replace
outsheet using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\redcap_6000.csv" in 4001/6000, comma replace
outsheet using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\redcap_8000.csv" in 6001/8000, comma replace
outsheet using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\redcap_10000.csv" in 8001/10000, comma replace
outsheet using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\redcap_12000.csv" in 10001/12000, comma replace
outsheet using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\redcap_14000.csv" in 12001/14000, comma replace
outsheet using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\redcap_16000.csv" in 14001/15712, comma replace
*/

*export for secretary of healtlh geocoding
rename direcion direccion
export excel ID_CODE direccion barrio ID_BARRIO using "direcciones_krystosik_2febrero2016", firstrow(variables) replace

tostring ID_CODE, replace
save "temp.dta", replace
save "2014-2015.dta", replace

/*
*merge based on those that didn't georeference to include the neighborhood
import excel "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\sin_georreferenciar.xls", sheet("sin_georreferenciar") firstrow clear
save "sin_georreferenciar.dta", replace

use "temp.dta", clear
tostring ID_CODE, replace
merge m:1 ID_CODE direccion using "sin_georreferenciar.dta"
export excel ID_CODE  dir_res_ direccion barrio ID_BARRIO using "sin_georreferenciar_barrio.xls" if _merge == 3, firstrow(variables) replace 
list ID_CODE if _merge == 2
*drop _merge
*/



*upload the new addresses from javier
import excel "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\singeoreferenciar\sin_georreferenciar_javier.xls", sheet("Sheet1") firstrow clear
save "sin_georreferenciar_javier.dta", replace
drop if ID_CODE =="."
drop if ID_CODE ==" "
drop if ID_CODE ==""
merge 1:1 ID_CODE using "2014-2015.dta" 
replace direccion = direcionjavier if direcionjavier!="" & _merge == 3
save "2014-2015.dta", replace

/*
*********************epi analysis********************
destring edad sexo ocupacion_ per_etn_ gp_discapa gp_desplaz gp_migrant gp_gestan gp_indigen gp_pobicbf gp_mad_com gp_desmovi gp_psiquia gp_otros gp_vic_vio, replace
replace  gp_discapa = 0 if  gp_discapa == 2
replace  gp_desplaz= 0 if  gp_desplaz== 2
replace  gp_migrant= 0 if  gp_migrant== 2
replace  gp_gestan = 0 if  gp_gestan == 2
replace  gp_pobicbf = 0 if  gp_pobicbf == 2
replace  gp_mad_com = 0 if  gp_mad_com == 2
replace  gp_desmovi= 0 if  gp_desmovi== 2
replace  gp_psiquia = 0 if  gp_psiquia == 2
replace  gp_vic_vio = 0 if  gp_vic_vio == 2
replace  gp_otros = 0 if  gp_otros == 2


tab sexo_, gen (sex)
gen female = .
replace female = 1 if sex1 ==1
replace female = 0 if sex2 ==1

describe 
sum 

*uniqe identifer
isid Z_ID_CODE

/*Statistical analysis: For the descriptive analysis, the cases will be stratified by severity and described according to age, sex, ethnicity, occupation, and 
social risk group (pregnant, displaced, migrant). 
*/
tab nom_eve
tab clasfinal

*create outcome category of chikv and dengue without and with severity and grave and death. 
gen outcome = .
destring clasfinal, replace

*outcome = 0 for chikungunya 
replace outcome = 0 if dengue_death1 == 1
*outcome = 1 for dengue without warning
replace outcome =1 if clasfinal == 1
*outcome = 2 for dengue with warning signs
replace outcome =2 if clasfinal == 2
*outcome = 3 for dengue grave
replace outcome = 3 if dengue_death3 == 1
*outcome = 4 for dengue death
replace outcome = 4 if dengue_death4 == 1
*outcome = 5 for zika
replace outcome = 5 if cod_eve == 895

*sum the factors by dengue severity
tab outcome 
by outcome, sort : summarize edad sexo ocupacion_ per_etn_ gp_discapa gp_desplaz gp_migrant gp_gestan gp_indigen gp_pobicbf gp_mad_com gp_desmovi gp_psiquia gp_otros gp_vic_vio

/*An exploratory analysis of the data will be made to check for and correct outliers and missing data. Univariate analysis will be performed to determine the 
behavior of the numeric variables and the normality of the variables will be determined through a test of Shapiro Wilk where those with p > 0.05 will be 
considered normally distributed and a mean and standard deviation calculated. For non-normal variables, median and interquartile ranges will be presented. 
Categorical variables will be presented as proportions and strata will be compared with chi-squared tests with Fisherís exact test used for tables with 
values less than five in any cell.
*/

*shapiro wilk test
swilk edad sexo ocupacion_ per_etn_ gp_discapa gp_desplaz gp_migrant gp_gestan gp_pobicbf gp_mad_com gp_desmovi gp_psiquia gp_otros gp_vic_vio
*all variables are normally distrubted with p>.05
*mean and stddev
summarize edad

*non-normal variables, median and interquartile ranges
*none

*categorical variables
tab outcome
tab sexo 

*categorize ocupacion_ 


*table 1 for all cases by outcome where 0 is chkv, 1 is dengue without warning signs, 2 is dengue with warning signs, 3 is denuge grave, 4 is dengue death
table1, vars(edad contn \ sexo cat \ per_etn_ cat \ gp_discapa bin \ gp_desplaz bin \gp_migrant bin \ gp_gestan bin \ gp_pobicbf bin \ gp_mad_com bin \ gp_desmovi bin \ gp_psiquia bin \ gp_otros bin \ gp_vic_vio bin) by(outcome) saving(table1.xls, replace)

/*The cumulative incidence will be calculated as a ratio taking as the numerator the number of cases diagnosed with serologic testing during the time period 
of interest and the denominator as the population of Cali for the year. An incidence trend line will be estimated over time.
*/
cs outcome female
cs outcome female, by(outcome)
cs outcome gp_discapa
cs outcome gp_desplaz 
cs outcome gp_migrant 
cs outcome gp_gestan 
cs outcome gp_mad_com 
cs outcome gp_desmovi 
cs outcome gp_psiquia 
cs outcome gp_otros 
cs outcome gp_vic_vio
cs outcome gp_pobicbf 

/*The disease specific mortality rate will be calculated as the ratio between the number of dengue or chikungunya - related deaths during the study period and the 
denominator of the population of Cali for the year. 
*/


/*The case-fatality rate will be calculated as the ratio between the number of dengue or chikungunya -related deaths during the study period and the denominator of 
all patients with positive serological test for dengue or chikungunya.
*/

/*For the regression analysis, a geographically weighted Poisson regression will be used to predict disease incidence according to Formula 4 (Nakaya et al., 2005). 
*/
mlogit outcome edad female gp_gestan gp_otros

/*Sample Size: All eligible dengue and chikungunya cases with will be included in the epidemiological analysis. 
*/

/*The geographically weighted semiparametric Poisson regression will require a minimum sample size of 355 cases of chikungunya or dengue based on the parameters 
listed in Table 2 using an A-priori Sample Size Calculator for Multiple Regression (Soper, 2015). The minimal detectable effect size was determined to be 0.028 
assuming 44,877 cases, alpha = 0.05, and power = 0.80 assuming single level experiment with individual level outcome using Optimal Design Software. Based on previous 
research, the minimum expected effect size is xxx. 
*/
mlogit outcome edad female gp_gestan  gp_otros

*send to davalos
save "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\dengue_chikv_oct2014-oct2015_cali.dta", replace
export excel using "dengue_chikv_oct2014-oct2015_cali", firstrow(variables) replace

*export the new addresses for javier/*export for secretary of healtlh geocoding
export excel ID_CODE Z_ID_CODE direccion dir_res_ barrio ID_BARRIO using "direcciones_krystosik_28abril2016", firstrow(variables) replace
*/
*/

/****************************************
 *Amy Krystosik                         *
 *chikv, dengue, and zika in cali       *
 *dissertation                          *
 *last updated May 4, 2016              *
 ****************************************/
cd "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data"
capture log close 
log using "dissertation.smcl", text replace 
set scrollbufsize 100000
set more 1

/**import origional datasets and merge the dengue 2014 and 2015 and chikungunya 2015 data
import excel "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\DENGUE_OCT_DIC_2014_PARA_ICESI.xls", sheet("Hoja1") firstrow clear
tostring fec_not fec_arc_xl fec_aju_, replace 
save "DENGUE_OCT_DIC_2014_PARA_ICESI.dta", replace
import excel "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\D_DG_M_CALI_2015.xls", sheet("Hoja1") firstrow clear
tostring fec_exa, replace
tostring fec_rec, replace
tostring fec_not, replace
tostring fec_arc_xl fec_aju_, replace 

append using "DENGUE_OCT_DIC_2014_PARA_ICESI.dta", generate(append20142015)
save "dengue_20142015_cali.dta", replace

insheet using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\Chik _ind2015.csv", comma clear 
tostring cod_eve, replace
tostring fec_not, replace
tostring semana, replace
tostring ao, replace
tostring cod_sub edad_ cod_pre uni_med_ cod_pais_o cod_dpto_o cod_mun_o area_ localidad_ ocupacion_ per_etn_ gp_discapa gp_desplaz gp_migrant gp_carcela gp_gestan gp_indigen  gp_pobicbf gp_mad_com gp_desmovi gp_psiquia gp_vic_vio gp_otros cod_dpto_r cod_mun_r tip_cas_ pac_hos_ , replace
drop nit_upgd 
tostring  con_fin_ cer_def_ fec_arc_xl fec_aju_ fm_fuerza fm_unidad fm_grado , replace 
append using "dengue_20142015_cali.dta", generate(chikv2015)
save "dengue_chkv_20142015_cali.dta", replace
*/
*merge based on COD_BARRIO 
import excel "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\barrios.xls", sheet("barrios") firstrow clear
*add 9999 and 900 to barrios
set obs `=_N+1'
replace COD_BARRIO = "900 " in 339
replace NOMBRE = "FUERA DE CALI" in 339
set obs `=_N+1'
replace COD_BARRIO = "9999" in 340
replace NOMBRE = "Sin dato" in 340
save "barrios.dta", replace

/*
use "dengue_chkv_20142015_cali.dta", clear
gen COD_BARRIO = substr(bar_ver,1,4)
gen NOMBRE = ""
replace NOMBRE = substr(bar_ver, 5, 64)
merge m:1 COD_BARRIO using "barrios.dta"
tabdisp COD_BARRIO, c(NOMBRE), if _merge==2
drop if _merge==2

save "chkvdenguebarriosmerged.dta", replace

cd "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data"
capture log close 
log using "dissertation.smcl", text replace 
set scrollbufsize 100000
set more 1
use "chkvdenguebarriosmerged.dta", clear
*keep cod_eve fec_not semana ao num_ide_ edad_ sexo_ bar_ver_ dir_res_ ocupacion_ NOMBRE ajuste_ resultado  tip_cas_ clasfinal nom_eve COD_BARRIO _merge ID_BARRIO nmun_resi ndep_resi ESTRATO_MO
sort num_ide_, stable
gen ID_CODE = _n
save "chkvdenguebarriosmerged.dta", replace
*/

*now add the zika data and create a second Z_ID_CODE to maintain the origional ID_CODE integrity and have a new one to match
import excel "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\d_ch_z_SEPT_2015_2016_ICESI.xls", sheet("Hoja1") firstrow clear
save "d_ch_z_SEPT_2015_2016_ICESI.dta", replace
tostring fec_not, replace
/*append using "chkvdenguebarriosmerged.dta"
save "dengue_zika_chkv_201420152016_cali.dta", replace
*/

*zika id_code
sort num_ide_, stable
gen ID_CODE = _n
save "dengue_zika_chkv_201420152016_cali.dta", replace

*re-run the merge on the neighborhood.
*merge based on COD_BARRIO 
merge m:1 COD_BARRIO using "barrios.dta", gen(zikabarrio)
tabdisp COD_BARRIO, c(NOMBRE), if zikabarrio==2
drop if zikabarrio==2
save "chkvdenguezikabarriosmerged.dta", replace


*generate dengue status as suspected = 1, confirmed = 2, or dead = 3
destring cod_eve , replace
gen dengue = .
replace dengue = 1 if cod_eve == 210 |cod_eve == 220 |cod_eve == 580
replace dengue = 0 if cod_eve == 217

*replace ajuste_ = "8" if ajuste_ == "D"
*destring ajuste_, generate (adjustment_num)
*recast int adjustment_num, force
*destring resultado, generate (resultado_num)
*recast int resultado_num, force
*destring tip_cas_ , generate (tip_cas_num)
*recast int tip_cas_num, force
*destring clasfinal, gen (classfinal_num)
*recast int classfinal_num, force

gen dengue_status = . 
tab cod_eve, gen (dengue_death)

/*replace dengue_status = . 
replace dengue_status = 1 if tip_cas_num == 1|tip_cas_num == 2 & dengue == 1  
replace dengue_status = 2 if resultado_num == 1 & dengue == 1
replace dengue_status = 2 if tip_cas_num == 3|tip_cas_num == 4|tip_cas_num == 5 & dengue ==1
replace dengue_status = 2 if adjustment_num == 3|4|5 & dengue == 1
replace dengue_status = 2 if classfinal_num == 1|2|3|4|5|6|7 & dengue ==1
replace dengue_status = 3 if  dengue_death3 == 1 & dengue ==1
*/

*generate chkv status as suspected = 1, confirmed = 2, or dead = 3
gen chkv_status = . 
replace chkv_status = . if dengue == 0

*replacing neighborhoods not in shapefile with nearby neighborhoods
replace COD_BARRIO = "0101" if COD_BARRIO == "0198"
replace COD_BARRIO = "1312" if COD_BARRIO == "1298"
replace COD_BARRIO = "1495" if COD_BARRIO == "1452"
replace COD_BARRIO = "1119" if COD_BARRIO == "1597"
replace COD_BARRIO = "1781" if COD_BARRIO == "1798"
replace COD_BARRIO = "1404" if COD_BARRIO == "2110"
replace COD_BARRIO = "1495" if COD_BARRIO == "5100"

list COD_BARRIO NOMBRE bar_ver_ in 1/10 if zikabarrio == 1
rename zikabarrio variabl_zikabarrio

*export number of cases by barrio
bysort COD_BARRIO: gen freq_COD_BARRIO = _N
tabdisp COD_BARRIO, c(freq_COD_BARRIO NOMBRE ESTRATO_MO)
export excel freq_COD_BARRIO NOMBRE COD_BARRIO using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\diseasefreq_Barrio.xls", firstrow(variables) replace

*standardize home addresses
gen manipadrsH = " "
replace dir_res_ = proper(dir_res_)
replace dir_res_ = itrim(dir_res_)
replace dir_res_ = trim(dir_res_)
replace manipadrsH = dir_res_ 
/*
gen length_manipadrsH_b = length(manipadrsH)
gsort -length_manipadrsH_b 
*/
replace NOMBRE = proper(NOMBRE)
replace NOMBRE = trim(NOMBRE)
gen drop_ = ""

foreach x in "Palmira" "Yumbo" "Hormigero" "Florida" "Jamundi" "Candelaria" "La Buitrera"{ 
replace drop_= "`x'" if regexm(manipadrsH, "`x'") ==1
replace drop_= "`x'" if regexm(NOMBRE, "`x'") ==1
}
list in 1/10 if drop_ != ""
drop if drop_ != "" 
list NOMBRE manipadrsH if regexm(NOMBRE, "Fuera De Cali")==1 
drop if regexm(NOMBRE, "Fuera De Cali")==1 

*remove all barrios names + misspellings I added "LLA# VERDE" "Felida" "Alferez Real" "Sorrento" "PORTALES DE ALAMEDA" "Portales De" "Caldas" "Lobo Guerrero" "Valle Lili" "Colserguros" "Vereda Altos Los Mangos" "Tequendama" "# Recuerda" "Capri" "Villa Del Sur" "Alto Napoles" "Alto" "Lla# Verde" "Valle Del Lili" "Golondrinas" "Floralia*"
*remove other suffixes with parse key words apt*, block*, piso*, manzana*
gen suffix = ""
split manipadrsH, parse("Esquina" "Alemeda" "Villa" "Dse" "Inv" "Conjunto" "Cristobal Colon" "Guabal" "Pance" "Sin" "No Dato" "No Sabe" "Sd" "No Se" "No Recuerda" "No Consignada" "Parques" "Oasis" "Camino" "S Arraya" "Tprres De" "1 Mayo" "Mayo" "Brisas" "St" "Meledez" "Marroquin" "Comuneros" "Por" "Bochalema" "Rep" "Cidudad" "Sna" "Cortijo" "Villas" "Cortijo" "Llsno" "San" "Nueva" "Brisasa" "Dos" "Libe" "Depar" "Aotop" "Villamercedes" "Refugio" "Agrupacion" "Comfandi" "Antonio" "El Castillo" "Republica" "Asen" "Comuneros" "Quin" "Bario" "Barrio" "Cuiudadela" "Morichal" "Ssin" "Por" "Quin" "Acen" "Centro" "Alonso" "Naples" "La" "Polvorines" "Quintas" "Portal" "Snata" "Portada" "Acentamiento" "Santa Fe" "B Gaitan" "Santa" "Nuena" "Asentamiento" "Talanga" "Alonso Lopez Ii" "Ciudadela Floralia" "Brisas de Los Alamos" "Menga" "Paso del Comercio" "Los Guaduales" "Area en desarrollo - Parque del Amor" "Urb. La Flora" "Altos de Menga" "Urb. Calimio" "San Luis II" "Sect. Puente del Comercio" "Los Alcazares" "Ciudad Los Alamos" "La Flora" "Calima" "El Bosque" "Fonaviemcali" "Metropolitano del Norte" "La Campina" "Vipasa" "San Luis" "Flora Industrial" "Villa del Sol" "Urb. La Merced" "La Paz" "Petecuy II" "Los Parques - Barranquilla" "Chiminangos II" "Olaya Herrera" "Chipichape" "Torres de Confandi" "Chiminangos I" "Petecuy III" "Evaristo Garcia" "La Isla" "Jorge Eliser Gaitan" "Prados del Norte" "La Rivera I" "Los Guayacanes" "Petecuy I" "La Alianza" "Guillermo Valencia" "Marco Fidel Suares" "Paseo de Los Almendros" "Santa Monica" "San Vicente" "Los Andes" "Ignacio Rengifo" "El Sena" "Popular" "Bolivariano" "Los Andes B - La Rivera - El Saman" "Villa del Prado - El Guabito" "Manzanares" "Unid. Residencial Bueno Madrid" "Salomia" "Sultana - Berlina" "Alfonso Lopez I" "Sect. Patio Bonito" "Santander" "Sect. Altos de Normandia - Bataclan" "Fepicol" "Fatima" "Las Delicas" "Industria de Licores" "Base Aerea" "Versalles" "Aguacatal" "Granada" "El Piloto" "Alfonso Lopez II" "Porvenir" "San Marino" "La Esmeralda" "Jorge Isaacs" "San Nicolas" "Los Pinos" "Vista Hermosa" "Las Ceibas" "El Hoyo" "Juanambu" "Parque de la Cana" "Puerto Nuevo" "Industrial" "Alfonso Lopez III" "San Pedro" "Normandia" "Terron Colorado" "Centenario" "Santa Rita" "Santa Teresita" "El Troncal" "La Merced" "Obrero" "Villacolombia" "Urb. La Base" "La Base" "Siete de Agosto" "Arboledas" "Sucre" "El Penon" "Puerto Mallarino" "Urb. El Angel del Hogar" "El Calvario" "Sect. Bosque Municipal" "Municipal" "San Antonio" "Las Americas" "Benjamin Herrera" "Planta de Tratamiento" "Santa Rosa" "Acueducto San Antonio" "Atanasio Giraldo" "Bellavista" "La Floresta" "Chapinero" "San Cayetano" "El Trebol" "San Pascual" "San Juan Bosco" "Saavedra Galindo" "Belalcazar" "Simon Bolivar" "El Nacional" "Ulpiano Lloreda" "Navarro - La chanca" "Charco Azul" "Nueva Floresta" "El Mortinal" "Santafe" "Los Libertadores" "Santa Barbara" "Lleras Restrepo II" "Guayaquil" "Bretana" "Miraflores" "Tejares - Cristales" "San Fernando Viejo" "Alameda" "Jose Manuel Marroquin II" "Rafael Uribe Uribe" "Manuel Maria Buenaventura" "Alirio Mora Beltran" "Valle Grande" "Primitivo Crespo" "Villa del Lago" "Santa Monica Polpular" "Sect. Laguna del Pondaje" "Fenalco Kennedy" "Asturias" "El Rodeo" "Santa Monica Belalcazar" "Aranjuez" "Lleras Restrepo" "El Cedro" "3 de Julio" "Ciudad Talanga" "20 de Julio" "Los Naranjos II" "El Prado" "Junin" "Alfonso Barberena A." "Ricardo Balcazar" "Sect. Altos de Santa Isabel" "Las Acaicas" "Los Naranjos" "San Cristobal" "Aguablanca" "Prados de Oriente" "Santa Isabel" "Marroquin III" "Champagnat" "Puerta del Sol" "Bello Horizonte" "Villanueva" "El Pondaje" "Urb. Colseguros" "El Paraiso" "Compartir" "Santa Elena" "Sindical" "San Fernando Nuevo" "Los Lagos" "Colseguros Andes" "Villablanca" "El Recuerdo" "Eduardo Santos" "San Benito" "Promociones Populares B" "Ciudadela del Rio" "Doce de Octubre" "Desepaz Invicali" "Belen" "El Jardin" "Julio Rincon" "Rodrigo Lara Bonilla" "Yira Castro" "Los Comuneros II" "Siloe" "La Fortaleza" "Eucaristico" "Cristobal Colon" "Leon XIII" "Los Conquistadores" "Omar Torrijos" "Jose Manuel Marroquin I" "Calipso" "San Pedro Claver" "Alfonzo Bonilla Aragon" "La Sultana" "Lleras Camargo" "Urb. Boyaca" "Manuela Beltran" "Urb. Nueva Granada" "San Carlos" "La Libertad" "Sect. Asprosocial - Diamante" "Olimpico" "Jose Maria Cordoba" "El Diamante" "Primavera" "Urb. Tequendama" "El Poblado II" "Los Robles" "El Lido" "La Gran Colombia" "El Dorado" "El Poblado I" "Los Cambulos" "Tierra Blanca" "Los Lideres" "La Esperanza" "Antonio Narino" "Departamental" "Brisas de Mayo" "El Remanso" "Pasoancho" "Los Sauces" "Maracaibo" "La Independencia" "El Vergel" "El Guabal" "Calimio Decepaz" "Mojica" "Cementerio - Carabineros" "Unid. Residencial Santiago de Cali" "El Cortijo" "Pueblo Joven" "Las Orquideas" "Nueva Tequendama" "Panamericano" "Belisario Caicedo" "Los Comuneros I" "Urb. Militar" "LLA# VERDE" "Felida" "Alferez Real" "Sorrento" "PORTALES DE ALAMEDA" "Portales De" "Caldas" "Lobo Guerrero" "Valle Lili" "Colserguros" "Vereda Altos Los Mangos" "Tequendama" "# Recuerda" "Capri" "Villa Del Sur" "Alto Napoles" "Alto" "Lla# Verde" "Valle Del Lili" "Golondrinas" "Floralia" "Melendez" "Alfonso Lopez" "Felidia" "LLA# VERDE" "Felida" "Alferez Real" "Sorrento" "PORTALES DE ALAMEDA" "Portales De" "Caldas" "Lobo Guerrero" "Valle Lili" "Colserguros" "Vereda Altos Los Mangos" "Tequendama" "# Recuerda" "Capri" "Villa Del Sur" "Alto Napoles" "Alto" "Lla# Verde" "Valle Del Lili" "Golondrinas" "Floralia" "Apt" "Apto" "Apartamento" "Casa" "Manzana" "1Er" "2Ndo" "3Er" "Piso" "Bloque" "Torre" "La Buitrera" "Ciudad Del Campo" "Sarrento" "Hacienda ElCastillo" "Sep Gbis" "Arboleda Campestre" "Via CaliJamundi" "Napoles" "12 De Octubre" "Mario Correa" "Unidad ResidenciasHorizonte" "Los Chorros" "Corregimiento" "Lourdes" "Sector Fincas" "NuevaIndependencia" "Limonar" "Antigua" "Las Palmas" "Pampas" "Primero" "Valle" "Entrada Via" "Montebello" "Prados" "Corregimiento" "El CarmeloLl" "Ciudad" "Conjunto C" "Barrio" "Miranda" "Dapa" "Vereda" "Via Cavasa" "Callejon" "Floralia" "El Vallado" "Urbanizacion" "Ap" "Torre " "Sector" "Unidad" "Aprt" "Manazana" "Coregimiento" "Ciudad" "Lote" "Fincas" "Plaza" "Invasion" "Callejon" "Estacion" "Ciudad Modelo" "La Rivera" "La Selva" "Seguros Patria" "Tejares" "Templete" "Villa Del Mar" "Villa Del Prad" "El Angel Del H" "Guadalupe" "Los Andes" "Los Samanes" "Nuevo Rey" "Pizamos Iii" "Sector  Altos" "Villa Luz" "20 De Julio" "3 De Julio" "3 Villamercedes" "Acueducto San" "Aguablanca" "Aguacatal" "Alameda" "Alferez Real" "Alfonso Barber" "Alfonso Bonill" "Alfonso Lopez" "Alirio Mora Be" "Alto Melendez" "Alto Napoles" "Altos De Menga" "Andres Sanin" "Antonio Nari•O" "Aranjuez" "Arboledas" "Asturias" "Atanasio Girar" "Bajo Cristo Re" "Bajos Ciudad C" "Barrio Obrero" "Base Aerea" "Batallon Pichi" "Belalcazar" "Belen" "Belisario Caic" "Bella Suiza" "Bellavista" "Bello Horizont" "Benjamin Herre" "Bolivariano" "Bosques Del Li" "Boyaca" "Breta•A" "Brisas De Los" "Brisas De Mayo" "Brisas Del Lim" "Bueno Madrid" "Buenos Aires" "Caldas" "Calima" "Calima - La 14" "Calimio Desepa" "Calimio Norte" "Calipso" "Camino Real -" "Caney" "Cascajal" "Ca•Averal" "Ca•Averalejo" "Ca•Averales" "Centenario" "Cerro Cristo R" "Champanagt" "Chapinero" "Charco Azul" "Chiminangos  S" "Chiminangos Pr" "Chipichape" "Cinta Belisari" "Ciudad 2000" "Ciudad Campest" "Ciudad Capri" "Ciudad Cordoba" "Ciudad Jardin" "Ciudad Los Ala" "Ciudad Talanga" "Ciudad Univers" "Ciudadela Comf" "Ciudadela Del" "Ciudadela Flor" "Club Campestre" "Colinas Del Su" "Colseguros And" "Compartir" "Corregimiento" "Cristales" "Cristobal Colo" "Cto.Los Andes" "Cto.Pance" "Cuarto De Legu" "Departamental" "Desepaz - Invi" "Doce De Octubr" "Eduardo Santos" "El  Pilar" "El Bosque" "El Calvario" "El Cedro" "El Cortijo" "El Diamante" "El Dorado" "El Gran Limona" "El Guabal" "El Guabito" "El Hormiguero" "El Hoyo" "El Ingenio" "El Jardin" "El Jordan" "El Lido" "El Limonar" "El Morichal De" "El Morti•Al" "El Nacional" "El Paraiso" "El Pe•On" "El Piloto" "El Poblado I" "El Poblado Ii" "El Pondaje" "El Prado" "El Recuerdo" "El Refugio" "El Remanso" "El Retiro" "El Rodeo" "El Sena" "El Trebol" "El Troncal" "El Vallado" "El Vergel" "Eucaristico" "Evaristo Garci" "Fatima" "Fenalco Kenned" "Fepicol" "Flora Industri" "Fonaviemcali" "Fuera De Cali" "Golondrinas" "Granada" "Gualanday" "Guayaquil" "Guillermo Vale" "Horizontes" "Ignacio Rengif" "Industria De L" "Industrial" "Inv. Brisas De" "Inv. Calibella" "Inv. Camilo To" "Inv. Las Palma" "Inv. Nueva Ilu" "Inv. Valladito" "Inv. Villa Del" "Invasion  La F" "Jorge Eliecer" "Jorge Isaacs" "Jorge Zawadsky" "Jose  Holguin" "Jose Manuel Ma" "Jose Maria Cor" "Juanambu" "Julio Rincon" "Junin" "La Alborada" "La Alianza" "La Base" "La Buitrera" "La Campi•A" "La Cascada" "La Elvira" "La Esmeralda" "La Esperanza" "La Flora" "La Floresta" "La Fortaleza" "La Gran Colomb" "La Hacienda" "La Independenc" "La Isla" "La Libertad" "La Merced" "La Paz" "La Playa" "La Reforma" "La Rivera 1" "La Selva" "Las Acacias" "Las Americas" "Las Ceibas" "Las Delicias" "Las Garzas" "Las Granjas" "Las Naranjos I" "Las Orquideas" "Las Quintas De" "Las Veraneras" "Laureano Gomez" "Leon Xiii" "Lili" "Lleras Camargo" "Lleras Restrep" "Los Alcazares" "Los Andes" "Los Cambulos" "Los Chorros" "Los Comuneros" "Los Conquistad" "Los Farallones" "Los Guaduales" "Los Guayacanes" "Los Lagos" "Los Libertador" "Los Lideres" "Los Naranjos I" "Los Parques Ba" "Los Pinos" "Los Portales" "Los Robles" "Los Sauces" "Lourdes" "Manuel Maria B" "Manuela Beltra" "Manzanares" "Maracaibo" "Marco Fidel Su" "Mariano Ramos" "Mario Correa R" "Marroquin Iii" "Mayapan Las Ve" "Melendez" "Menga" "Metropolitano" "Miraflores" "Mojica" "Montebello" "Multicentro" "Municipal" "Napoles" "Navarro" "Navarro La Cha" "Normandia" "Villa Gorgona" "Altos" "Quintas" "Barrio" "Coregimiento" "Alfonso" "Ca—Averales" "Mario Correa" "Los Geranios" "Pacara" "Conputo" "Acentamiento Brisas De Comunero" "Unidad" "Pampas Del Mirado" "Sec" "Llano Verde" "Via La Buitrera" "Quintas Don Simon" "Libertadores" "Ap" "No Sabe" "Manz" "Etapa" "Blq" "Bl" "Sin Informacion" "Conjun" "Colinas Del Sur" "Calicanto" "Jordan" "Caney" "El Portal" "Alfonso L”Pez I" "Segundo" "Buenos Aires" "Etapa" "Brisas De La Chorrera" "Sin Informacion" "Bosques Del" "Trabajo" "Sta Anita" "Ingenio" "Bella Suiza" "Brisas De Mayo" "Llano Grande" "Mariano Ramos" "Las Granjas" "Tercer" "Republica De Israel" "Atp" "Cali" "Vallado" "Esquina" "Urbanizaci”N Boyaca" "Urbanizaci”N" "Colseguros" "Col" "Laurano" "Oasis De" "2Do" "Pi" "Libertadores" "Bugalagrandes" "Uribe" "Palmeras" "Porton De Cali" "Villa Del Lago" "Jordan" "Caney" "La Caba—A" "Normania" "Sect" "Solares La Morada Et2" "Sirena Alta Los Mangos" "Sect 4 Agrup 6" "Sec 6 Agr 5" "Sardi L 165" "PJ De— Castillo Cs 12" "No Sabe" "Manzana")
list  dir_res_ manipadrsH1 manipadrsH2 if manipadrsH2!="" 
rename manipadrsH1 manipadrsH_origional
rename manipadrsH2 suffix2
rename manipadrsH3 suffix3
rename manipadrsH4 suffix4 
rename manipadrsH5 suffix5
order manipadrsH manipadrsH_origional suffix2 suffix3 suffix4 suffix5 NOMBRE dir_res_
gsort -manipadrsH_origional 
replace manipadrsH = manipadrsH_origional if suffix2!="" | manipadrsH_origional!=""
list manipadrsH manipadrsH_origional suffix2 suffix3 suffix4 suffix5 in 1/10 if suffix2!=""
drop manipadrsH_origional 

list manipadrsH  dir_res_ if regexm(manipadrsH, "Ta")==1 
list manipadrsH  NOMBRE if regexm(manipadrsH, "ta")==1 
replace manipadrsH = subinstr(manipadrsH, "Sexta", " ",. )
replace manipadrsH = subinstr(manipadrsH, "Ta", " ",. )
replace manipadrsH = subinstr(manipadrsH, "ta", " ",. )

list manipadrsH  dir_res_ if regexm(manipadrsH, "Na")==1 
list manipadrsH  NOMBRE if regexm(manipadrsH, "na")==1 
replace manipadrsH = subinstr(manipadrsH, "Na", " ",. )
replace manipadrsH = subinstr(manipadrsH, "na", " ",. )

replace manipadrsH = "" if manipadrsH == "CLinica Farallones"
replace manipadrsH = "" if manipadrsH == "El Reten"

replace manipadrsH ="999" if regexm(manipadrsH, "Sin Dato")==1 
replace manipadrsH ="999" if regexm(manipadrsH, "No Dato")==1 
replace manipadrsH ="999" if regexm(manipadrsH, "No Sabe")==1 
replace manipadrsH ="999" if regexm(manipadrsH, "Sd")==1 
replace manipadrsH ="999" if regexm(manipadrsH, "Sin Informacion")==1 
replace manipadrsH ="999" if regexm(manipadrsH, "No Se")==1 
replace manipadrsH ="999" if regexm(manipadrsH, "No Recuerda")==1 
replace manipadrsH ="999" if regexm(manipadrsH, "No Consignada")==1 
 
list manipadrsH if regexm(manipadrsH, "Sec")==1 
replace manipadrsH ="999" if regexm(manipadrsH, "Sec")==1 
gen homeless = ""
replace homeless ="1" if regexm(manipadrsH, "Habitante De La CL")==1 
replace manipadrsH ="999" if regexm(manipadrsH, "Habitante De La CL")==1 
drop if manipadrsH=="999"
drop if manipadrsH==""

rename ao year
order dir_res_ manipadrsH NOMBRE 

/*gen manipadrsH_l =length(manipadrsH) 
order manipadrsH_l
gsort -manipadrsH_l
*/

*streets dictionary 

replace manipadrsH = subinword(manipadrsH,"Cranorte"," KR Norte ",.)
replace manipadrsH = subinword(manipadrsH,"Carrrera"," KR ",.)
replace manipadrsH = subinword(manipadrsH,"Caarrea"," KR ",.)
replace manipadrsH = subinword(manipadrsH,"Karrera"," KR ",.)
replace manipadrsH = subinword(manipadrsH,"Caarrea"," KR ",.)
replace manipadrsH = subinword(manipadrsH,"Carreara"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Carerara"," K R",.)
replace manipadrsH = subinstr(manipadrsH,"Carera"," KR ",.)
replace manipadrsH = subinword(manipadrsH,"Karrera"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Carrear"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Carrera"," KR ",.)
replace manipadrsH = subinword(manipadrsH,"Carrea"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Carerra"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Cra"," KR ",.)
replace manipadrsH = subinword(manipadrsH,"Lr"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Carre"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Crr"," KR ",.)
replace manipadrsH = subinword(manipadrsH,"Lra"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Cara"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Carr"," KR ",.)
replace manipadrsH = subinword(manipadrsH,"Cra"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Cr"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Crra"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Crra"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Kra"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Crr"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Car"," KR ",.)
replace manipadrsH = subinword(manipadrsH,"Vr"," KR ",.)
replace manipadrsH = subinstr(manipadrsH,"Cr"," KR ",.)

replace manipadrsH = subinword(manipadrsH,"Caller#","CL #",.)
replace manipadrsH = subinword(manipadrsH,"Call E","CL",.)
replace manipadrsH = subinstr(manipadrsH,"Calle","CL",.)
replace manipadrsH = subinword(manipadrsH,"Clle","CL",.)
replace manipadrsH = subinword(manipadrsH,"Cll","CL",.)
replace manipadrsH = subinword(manipadrsH,"Cale","CL",.)
replace manipadrsH = subinword(manipadrsH,"Cal","CL",.)
replace manipadrsH = subinword(manipadrsH,"Call","CL",.)
replace manipadrsH = subinword(manipadrsH,"Cll E","CL",.)
replace manipadrsH = subinword(manipadrsH,"Xcll E","CL",.)
replace manipadrsH = subinword(manipadrsH,"Xcalle","CL",.)
replace manipadrsH = subinword(manipadrsH,"Xalle","CL",.)
replace manipadrsH = subinword(manipadrsH,"Cl","CL",.)

replace manipadrsH = subinword(manipadrsH,"Pasaje","PJ",.)
replace manipadrsH = subinword(manipadrsH,"Pasajes","PJ",.)
replace manipadrsH = subinword(manipadrsH,"Pas","PJ",.)
replace manipadrsH = subinword(manipadrsH,"Paisaje","PJ",.)

replace manipadrsH = subinword(manipadrsH,"Transversal","TV",.)
replace manipadrsH = subinword(manipadrsH,"Tran","TV",.)
replace manipadrsH = subinword(manipadrsH,"Tb","TV",.)
replace manipadrsH = subinword(manipadrsH,"Trasversal","TV",.)
replace manipadrsH = subinword(manipadrsH,"Trasv","TV",.)
replace manipadrsH = subinword(manipadrsH,"Transversal","TV",.)
replace manipadrsH = subinword(manipadrsH,"Trasnv","TV",.)
replace manipadrsH = subinword(manipadrsH,"Trv","TV",.)
replace manipadrsH = subinword(manipadrsH,"Trav","TV",.)
replace manipadrsH = subinword(manipadrsH,"Trsv","TV",.)
replace manipadrsH = subinword(manipadrsH,"Trn","TV",.)
replace manipadrsH = subinword(manipadrsH,"Trv","TV",.)
replace manipadrsH = subinword(manipadrsH,"Trasnversal","TV",.)
replace manipadrsH = subinword(manipadrsH,"Tasnv","TV",.)
replace manipadrsH = subinword(manipadrsH,"Trasn","TV",.)
replace manipadrsH = subinword(manipadrsH,"Tras","TV",.)
replace manipadrsH = subinword(manipadrsH,"Tranvesal","TV",.)
replace manipadrsH = subinword(manipadrsH,"Tranv","TV",.)
replace manipadrsH = subinword(manipadrsH,"Tranversal","TV",.)
replace manipadrsH = subinword(manipadrsH,"Trans","TV",.)
replace manipadrsH = subinword(manipadrsH,"Tr","TV",.)
replace manipadrsH = subinword(manipadrsH,"Tra","TV",.)
replace manipadrsH = subinword(manipadrsH,"Traaversal","TV",.)
replace manipadrsH = subinword(manipadrsH,"Tans","TV",.)
replace manipadrsH = subinword(manipadrsH,"Transv","TV",.)
replace manipadrsH = subinword(manipadrsH,"Trasv","TV",.)
replace manipadrsH = subinword(manipadrsH,"Trav","TV",.)

replace manipadrsH = subinword(manipadrsH,"Diagnonal"," DG ",.)
replace manipadrsH = subinword(manipadrsH,"Diagonal"," DG ",.)
replace manipadrsH = subinword(manipadrsH,"Diagonal"," DG ",.)
replace manipadrsH = subinword(manipadrsH,"Diganoal","DG",.)
replace manipadrsH = subinword(manipadrsH,"Diag","DG",.)
replace manipadrsH = subinword(manipadrsH,"Diga"," DG ",.)
replace manipadrsH = subinword(manipadrsH,"Dig"," DG ",.)
replace manipadrsH = subinword(manipadrsH,"Dg","DG",.)

replace manipadrsH = subinword(manipadrsH,"Conjuto","Conjunto",.)
replace manipadrsH = subinword(manipadrsH,"Conjuto","Conjunto",.)

replace manipadrsH = subinword(manipadrsH,"1 Era","1",.)
replace manipadrsH = subinword(manipadrsH,"-Calle","Cl",.)
replace manipadrsH = subinword(manipadrsH,"2 E pa"," ",.)


*deal with this one later. it is causing problems in other words. i can use a regular expression to find times when "No" comes by itself. 
*replace manipadrsH = subinword(manipadrsH,"No","#",.)
replace manipadrsH = subinword(manipadrsH,"N∫"," # ",.)
replace manipadrsH = subinword(manipadrsH,"Nuemro"," # ",.)
replace manipadrsH = subinword(manipadrsH,"Numero#"," # ",.)
replace manipadrsH = subinword(manipadrsH,"Numero"," # ",.)
replace manipadrsH = subinword(manipadrsH,"No"," # ",.)

replace manipadrsH = subinword(manipadrsH,"Avenida","AV",.)
replace manipadrsH = subinword(manipadrsH,"Ae","AV",.)
replace manipadrsH = subinword(manipadrsH,"Av","Avenida",.)
replace manipadrsH = subinword(manipadrsH,"Avenida","AV",.)
replace manipadrsH = subinword(manipadrsH,"Aveniida","AV",.)
replace manipadrsH = subinword(manipadrsH,"Ave","AV",.)
replace manipadrsH = subinstr(manipadrsH,"Avendad","AV",.)

replace manipadrsH = subinstr(manipadrsH,"--","-",.)
replace manipadrsH = subinstr(manipadrsH,"--","-",.)
replace manipadrsH = subinstr(manipadrsH,"- -","-",.)
replace manipadrsH = subinstr(manipadrsH,"ñ", "-", .)

replace manipadrsH = subinword(manipadrsH,"Mz","Manzana",.)
replace manipadrsH = subinword(manipadrsH,"Mn","Manzana",.)
replace manipadrsH = subinword(manipadrsH,"Manz","Manzana",.)
replace manipadrsH = subinword(manipadrsH,"Manza","Manzana",.)
replace manipadrsH = subinword(manipadrsH,"Mansana","Manzana",.)

*remove other suffixes with parse key words apt*, block*, piso*, manzana*
split manipadrsH, parse("Apt" "Conjunto" "Cristobal Colon" "Guabal" "Pance" "Sin" "No Dato" "No Sabe" "Sd" "No Se" "No Recuerda" "No Consignada" "Parques" "Oasis" "Camino" "S Arraya" "Tprres De" "1 Mayo" "Mayo" "Brisas" "St" "Meledez" "Marroquin" "Comuneros" "Por" "Bochalema" "Rep" "Cidudad" "Sna" "Cortijo" "Villas" "Cortijo" "Llsno" "San" "Nueva" "Brisasa" "Dos" "Libe" "Depar" "Aotop" "Villamercedes" "Refugio" "Agrupacion" "Comfandi" "Antonio" "El Castillo" "Republica" "Asen" "Comuneros" "Quin" "Bario" "Barrio" "Cuiudadela" "Morichal" "Ssin" "Por" "Quin" "Acen" "Centro" "Alonso" "Naples" "La" "Polvorines" "Quintas" "Portal" "Snata" "Portada" "Acentamiento" "Santa Fe" "B Gaitan" "Santa" "Nuena" "Asentamiento" "Talanga" "Alonso Lopez Ii" "Ciudadela Floralia" "Brisas de Los Alamos" "Menga" "Paso del Comercio" "Los Guaduales" "Area en desarrollo - Parque del Amor" "Urb. La Flora" "Altos de Menga" "Urb. Calimio" "San Luis II" "Sect. Puente del Comercio" "Los Alcazares" "Ciudad Los Alamos" "La Flora" "Calima" "El Bosque" "Fonaviemcali" "Metropolitano del Norte" "La Campina" "Vipasa" "San Luis" "Flora Industrial" "Villa del Sol" "Urb. La Merced" "La Paz" "Petecuy II" "Los Parques - Barranquilla" "Chiminangos II" "Olaya Herrera" "Chipichape" "Torres de Confandi" "Chiminangos I" "Petecuy III" "Evaristo Garcia" "La Isla" "Jorge Eliser Gaitan" "Prados del Norte" "La Rivera I" "Los Guayacanes" "Petecuy I" "La Alianza" "Guillermo Valencia" "Marco Fidel Suares" "Paseo de Los Almendros" "Santa Monica" "San Vicente" "Los Andes" "Ignacio Rengifo" "El Sena" "Popular" "Bolivariano" "Los Andes B - La Rivera - El Saman" "Villa del Prado - El Guabito" "Manzanares" "Unid. Residencial Bueno Madrid" "Salomia" "Sultana - Berlina" "Alfonso Lopez I" "Sect. Patio Bonito" "Santander" "Sect. Altos de Normandia - Bataclan" "Fepicol" "Fatima" "Las Delicas" "Industria de Licores" "Base Aerea" "Versalles" "Aguacatal" "Granada" "El Piloto" "Alfonso Lopez II" "Porvenir" "San Marino" "La Esmeralda" "Jorge Isaacs" "San Nicolas" "Los Pinos" "Vista Hermosa" "Las Ceibas" "El Hoyo" "Juanambu" "Parque de la Cana" "Puerto Nuevo" "Industrial" "Alfonso Lopez III" "San Pedro" "Normandia" "Terron Colorado" "Centenario" "Santa Rita" "Santa Teresita" "El Troncal" "La Merced" "Obrero" "Villacolombia" "Urb. La Base" "La Base" "Siete de Agosto" "Arboledas" "Sucre" "El Penon" "Puerto Mallarino" "Urb. El Angel del Hogar" "El Calvario" "Sect. Bosque Municipal" "Municipal" "San Antonio" "Las Americas" "Benjamin Herrera" "Planta de Tratamiento" "Santa Rosa" "Acueducto San Antonio" "Atanasio Giraldo" "Bellavista" "La Floresta" "Chapinero" "San Cayetano" "El Trebol" "San Pascual" "San Juan Bosco" "Saavedra Galindo" "Belalcazar" "Simon Bolivar" "El Nacional" "Ulpiano Lloreda" "Navarro - La chanca" "Charco Azul" "Nueva Floresta" "El Mortinal" "Santafe" "Los Libertadores" "Santa Barbara" "Lleras Restrepo II" "Guayaquil" "Bretana" "Miraflores" "Tejares - Cristales" "San Fernando Viejo" "Alameda" "Jose Manuel Marroquin II" "Rafael Uribe Uribe" "Manuel Maria Buenaventura" "Alirio Mora Beltran" "Valle Grande" "Primitivo Crespo" "Villa del Lago" "Santa Monica Polpular" "Sect. Laguna del Pondaje" "Fenalco Kennedy" "Asturias" "El Rodeo" "Santa Monica Belalcazar" "Aranjuez" "Lleras Restrepo" "El Cedro" "3 de Julio" "Ciudad Talanga" "20 de Julio" "Los Naranjos II" "El Prado" "Junin" "Alfonso Barberena A." "Ricardo Balcazar" "Sect. Altos de Santa Isabel" "Las Acaicas" "Los Naranjos" "San Cristobal" "Aguablanca" "Prados de Oriente" "Santa Isabel" "Marroquin III" "Champagnat" "Puerta del Sol" "Bello Horizonte" "Villanueva" "El Pondaje" "Urb. Colseguros" "El Paraiso" "Compartir" "Santa Elena" "Sindical" "San Fernando Nuevo" "Los Lagos" "Colseguros Andes" "Villablanca" "El Recuerdo" "Eduardo Santos" "San Benito" "Promociones Populares B" "Ciudadela del Rio" "Doce de Octubre" "Desepaz Invicali" "Belen" "El Jardin" "Julio Rincon" "Rodrigo Lara Bonilla" "Yira Castro" "Los Comuneros II" "Siloe" "La Fortaleza" "Eucaristico" "Cristobal Colon" "Leon XIII" "Los Conquistadores" "Omar Torrijos" "Jose Manuel Marroquin I" "Calipso" "San Pedro Claver" "Alfonzo Bonilla Aragon" "La Sultana" "Lleras Camargo" "Urb. Boyaca" "Manuela Beltran" "Urb. Nueva Granada" "San Carlos" "La Libertad" "Sect. Asprosocial - Diamante" "Olimpico" "Jose Maria Cordoba" "El Diamante" "Primavera" "Urb. Tequendama" "El Poblado II" "Los Robles" "El Lido" "La Gran Colombia" "El Dorado" "El Poblado I" "Los Cambulos" "Tierra Blanca" "Los Lideres" "La Esperanza" "Antonio Narino" "Departamental" "Brisas de Mayo" "El Remanso" "Pasoancho" "Los Sauces" "Maracaibo" "La Independencia" "El Vergel" "El Guabal" "Calimio Decepaz" "Mojica" "Cementerio - Carabineros" "Unid. Residencial Santiago de Cali" "El Cortijo" "Pueblo Joven" "Las Orquideas" "Nueva Tequendama" "Panamericano" "Belisario Caicedo" "Los Comuneros I" "Urb. Militar" "LLA# VERDE" "Felida" "Alferez Real" "Sorrento" "PORTALES DE ALAMEDA" "Portales De" "Caldas" "Lobo Guerrero" "Valle Lili" "Colserguros" "Vereda Altos Los Mangos" "Tequendama" "# Recuerda" "Capri" "Villa Del Sur" "Alto Napoles" "Alto" "Lla# Verde" "Valle Del Lili" "Golondrinas" "Floralia" "Melendez" "Alfonso Lopez" "Felidia" "LLA# VERDE" "Felida" "Alferez Real" "Sorrento" "PORTALES DE ALAMEDA" "Portales De" "Caldas" "Lobo Guerrero" "Valle Lili" "Colserguros" "Vereda Altos Los Mangos" "Tequendama" "# Recuerda" "Capri" "Villa Del Sur" "Alto Napoles" "Alto" "Lla# Verde" "Valle Del Lili" "Golondrinas" "Floralia" "Apt" "Apto" "Apartamento" "Casa" "Manzana" "1Er" "2Ndo" "3Er" "Piso" "Bloque" "Torre" "La Buitrera" "Ciudad Del Campo" "Sarrento" "Hacienda ElCastillo" "Sep Gbis" "Arboleda Campestre" "Via CaliJamundi" "Napoles" "12 De Octubre" "Mario Correa" "Unidad ResidenciasHorizonte" "Los Chorros" "Corregimiento" "Lourdes" "Sector Fincas" "NuevaIndependencia" "Limonar" "Antigua" "Las Palmas" "Pampas" "Primero" "Valle" "Entrada Via" "Montebello" "Prados" "Corregimiento" "El CarmeloLl" "Ciudad" "Conjunto C" "Barrio" "Miranda" "Dapa" "Vereda" "Via Cavasa" "Callejon" "Floralia" "El Vallado" "Urbanizacion" "Ap" "Torre " "Sector" "Unidad" "Aprt" "Manazana" "Coregimiento" "Ciudad" "Lote" "Fincas" "Plaza" "Invasion" "Callejon" "Estacion" "Ciudad Modelo" "La Rivera" "La Selva" "Seguros Patria" "Tejares" "Templete" "Villa Del Mar" "Villa Del Prad" "El Angel Del H" "Guadalupe" "Los Andes" "Los Samanes" "Nuevo Rey" "Pizamos Iii" "Sector  Altos" "Villa Luz" "20 De Julio" "3 De Julio" "3 Villamercedes" "Acueducto San" "Aguablanca" "Aguacatal" "Alameda" "Alferez Real" "Alfonso Barber" "Alfonso Bonill" "Alfonso Lopez" "Alirio Mora Be" "Alto Melendez" "Alto Napoles" "Altos De Menga" "Andres Sanin" "Antonio Nari•O" "Aranjuez" "Arboledas" "Asturias" "Atanasio Girar" "Bajo Cristo Re" "Bajos Ciudad C" "Barrio Obrero" "Base Aerea" "Batallon Pichi" "Belalcazar" "Belen" "Belisario Caic" "Bella Suiza" "Bellavista" "Bello Horizont" "Benjamin Herre" "Bolivariano" "Bosques Del Li" "Boyaca" "Breta•A" "Brisas De Los" "Brisas De Mayo" "Brisas Del Lim" "Bueno Madrid" "Buenos Aires" "Caldas" "Calima" "Calima - La 14" "Calimio Desepa" "Calimio Norte" "Calipso" "Camino Real -" "Caney" "Cascajal" "Ca•Averal" "Ca•Averalejo" "Ca•Averales" "Centenario" "Cerro Cristo R" "Champanagt" "Chapinero" "Charco Azul" "Chiminangos  S" "Chiminangos Pr" "Chipichape" "Cinta Belisari" "Ciudad 2000" "Ciudad Campest" "Ciudad Capri" "Ciudad Cordoba" "Ciudad Jardin" "Ciudad Los Ala" "Ciudad Talanga" "Ciudad Univers" "Ciudadela Comf" "Ciudadela Del" "Ciudadela Flor" "Club Campestre" "Colinas Del Su" "Colseguros And" "Compartir" "Corregimiento" "Cristales" "Cristobal Colo" "Cto.Los Andes" "Cto.Pance" "Cuarto De Legu" "Departamental" "Desepaz - Invi" "Doce De Octubr" "Eduardo Santos" "El  Pilar" "El Bosque" "El Calvario" "El Cedro" "El Cortijo" "El Diamante" "El Dorado" "El Gran Limona" "El Guabal" "El Guabito" "El Hormiguero" "El Hoyo" "El Ingenio" "El Jardin" "El Jordan" "El Lido" "El Limonar" "El Morichal De" "El Morti•Al" "El Nacional" "El Paraiso" "El Pe•On" "El Piloto" "El Poblado I" "El Poblado Ii" "El Pondaje" "El Prado" "El Recuerdo" "El Refugio" "El Remanso" "El Retiro" "El Rodeo" "El Sena" "El Trebol" "El Troncal" "El Vallado" "El Vergel" "Eucaristico" "Evaristo Garci" "Fatima" "Fenalco Kenned" "Fepicol" "Flora Industri" "Fonaviemcali" "Fuera De Cali" "Golondrinas" "Granada" "Gualanday" "Guayaquil" "Guillermo Vale" "Horizontes" "Ignacio Rengif" "Industria De L" "Industrial" "Inv. Brisas De" "Inv. Calibella" "Inv. Camilo To" "Inv. Las Palma" "Inv. Nueva Ilu" "Inv. Valladito" "Inv. Villa Del" "Invasion  La F" "Jorge Eliecer" "Jorge Isaacs" "Jorge Zawadsky" "Jose  Holguin" "Jose Manuel Ma" "Jose Maria Cor" "Juanambu" "Julio Rincon" "Junin" "La Alborada" "La Alianza" "La Base" "La Buitrera" "La Campi•A" "La Cascada" "La Elvira" "La Esmeralda" "La Esperanza" "La Flora" "La Floresta" "La Fortaleza" "La Gran Colomb" "La Hacienda" "La Independenc" "La Isla" "La Libertad" "La Merced" "La Paz" "La Playa" "La Reforma" "La Rivera 1" "La Selva" "Las Acacias" "Las Americas" "Las Ceibas" "Las Delicias" "Las Garzas" "Las Granjas" "Las Naranjos I" "Las Orquideas" "Las Quintas De" "Las Veraneras" "Laureano Gomez" "Leon Xiii" "Lili" "Lleras Camargo" "Lleras Restrep" "Los Alcazares" "Los Andes" "Los Cambulos" "Los Chorros" "Los Comuneros" "Los Conquistad" "Los Farallones" "Los Guaduales" "Los Guayacanes" "Los Lagos" "Los Libertador" "Los Lideres" "Los Naranjos I" "Los Parques Ba" "Los Pinos" "Los Portales" "Los Robles" "Los Sauces" "Lourdes" "Manuel Maria B" "Manuela Beltra" "Manzanares" "Maracaibo" "Marco Fidel Su" "Mariano Ramos" "Mario Correa R" "Marroquin Iii" "Mayapan Las Ve" "Melendez" "Menga" "Metropolitano" "Miraflores" "Mojica" "Montebello" "Multicentro" "Municipal" "Napoles" "Navarro" "Navarro La Cha" "Normandia" "Villa Gorgona" "Altos" "Quintas" "Barrio" "Coregimiento" "Alfonso" "Ca—Averales" "Mario Correa" "Los Geranios" "Pacara" "Conputo" "Acentamiento Brisas De Comunero" "Unidad" "Pampas Del Mirado" "Sec" "Llano Verde" "Via La Buitrera" "Quintas Don Simon" "Libertadores" "Ap" "No Sabe" "Manz" "Etapa" "Blq" "Bl" "Sin Informacion" "Conjun" "Colinas Del Sur" "Calicanto" "Jordan" "Caney" "El Portal" "Alfonso L”Pez I" "Segundo" "Buenos Aires" "Etapa" "Brisas De La Chorrera" "Sin Informacion" "Bosques Del" "Trabajo" "Sta Anita" "Ingenio" "Bella Suiza" "Brisas De Mayo" "Llano Grande" "Mariano Ramos" "Las Granjas" "Tercer" "Republica De Israel" "Atp" "Cali" "Vallado" "Esquina" "Urbanizaci”N Boyaca" "Urbanizaci”N" "Colseguros" "Col" "Laurano" "Oasis De" "2Do" "Pi" "Libertadores" "Bugalagrandes" "Uribe" "Palmeras" "Porton De Cali" "Villa Del Lago" "Jordan" "Caney" "La Caba—A" "Normania" "Sect" "Solares La Morada Et2" "Sirena Alta Los Mangos" "Sect 4 Agrup 6" "Sec 6 Agr 5" "Sardi L 165" "PJ De— Castillo Cs 12" "No Sabe" "Manzana")
list  dir_res_ manipadrsH1 manipadrsH2 if manipadrsH2!="" 
rename manipadrsH1 manipadrsH_origional
rename manipadrsH2 suffix2b
order manipadrsH manipadrsH_origional suffix2b NOMBRE dir_res_
gsort -manipadrsH_origional 
replace manipadrsH = manipadrsH_origional if suffix2b!="" | manipadrsH_origional!=""
list manipadrsH manipadrsH_origional suffix2b in 1/10 if suffix2b!=""
drop manipadrsH_origional 


replace manipadrsH = subinword(manipadrsH,"Ktr","Carratera",.)

 
replace manipadrsH = subinword(manipadrsH,"Kilometro","KM",.)
replace manipadrsH = subinword(manipadrsH,"Ke","KM",.)

replace manipadrsH = subinword(manipadrsH,"Inv","Invasion",.)
replace manipadrsH = subinword(manipadrsH,"Invacion","Invasion",.)
replace manipadrsH = subinword(manipadrsH,"Con","-",.)

replace manipadrsH = subinword(manipadrsH,"Oeste N ","Oeste #",.)
replace manipadrsH = subinword(manipadrsH,"Oes N ","Oeste #",.)
replace manipadrsH = subinword(manipadrsH,"Oest N ","Oeste #",.)
replace manipadrsH = subinword(manipadrsH,"O N ","Oeste #",.)


replace manipadrsH = subinstr(manipadrsH, "Xcll", "Cl",. )
replace manipadrsH = subinstr(manipadrsH, "Union De Vivienda", "",. )
replace manipadrsH = subinstr(manipadrsH, "DIAGNONAL", "Dg",. )
replace manipadrsH = subinstr(manipadrsH, "Poblado Campestre", "",. )
replace manipadrsH = subinstr(manipadrsH, "con", " # ",. )
replace manipadrsH = subinstr(manipadrsH, "Cada", "CL",. )
replace manipadrsH = subinstr(manipadrsH, "Kcra", "KR",. )
replace manipadrsH = subinstr(manipadrsH, "via al mar", "Av 4 Oeste",. )
replace manipadrsH = subinstr(manipadrsH, "DIAGNONAL", "dg",. )
replace manipadrsH = subinstr(manipadrsH, "}", " # ",. )
replace manipadrsH = subinstr(manipadrsH, "Diagonal", "Dg",. )
replace manipadrsH = subinstr(manipadrsH, "Diagonal", "Dg",. )
replace manipadrsH = subinstr(manipadrsH, "Diagona", "Dg",. )
replace manipadrsH = subinstr(manipadrsH, "Diagon", "Dg",. )
replace manipadrsH = subinstr(manipadrsH, "1∫", "1",. )
replace manipadrsH = subinstr(manipadrsH, "1Ra", "1",. )
replace manipadrsH = subinstr(manipadrsH, "Diagon", "Dg",. )
replace manipadrsH = subinstr(manipadrsH, "Diago", "Dg",. )
replace manipadrsH = subinstr(manipadrsH, "DGna", "Dg",. )
replace manipadrsH = subinstr(manipadrsH, "Scarrera", "KR",. )


/*replace manipadrsH = subinstr(manipadrsH, "KR MANZANA", "KR M", .)
replace manipadrsH = subinstr(manipadrsH, "CL MANZANA", "Cl M", .)
replace manipadrsH = subinstr(manipadrsH, "AV MANZANA", "Av M", .)
replace manipadrsH = subinstr(manipadrsH, "TV MANZANA", "Tv M", .)
replace manipadrsH = subinstr(manipadrsH, "PJ MANZANA", "Pj M", .)*/



*remove those without any numbers in manipadrsH
list dir_res_ if regexm(manipadrsH, "[0-9]+")==0 
drop if regexm(manipadrsH, "[0-9]+")==0 
list dir_res_ if regexm(manipadrsH, "[ a-zA-Z ]+")==0 
drop if regexm(manipadrsH, "[ a-zA-Z ]+")==0 
drop if regexm(manipadrsH, "9999")==1 
drop if regexm(manipadrsH, "Sd")==1 
drop if regexm(manipadrsH, "No Dato")==1 

*Km is a rural address outside of cali. remove from observations
list dir_res_ if regexm(manipadrsH, "Km")==1 
drop if regexm(manipadrsH, "Km")==1 
list dir_res_ if regexm(manipadrsH, "KM")==1 
drop if regexm(manipadrsH, "KM")==1 
list dir_res_ if regexm(manipadrsH, "km")==1 
drop if regexm(manipadrsH, "km")==1 

*change common street names to numbers
replace manipadrsH = subinstr(manipadrsH, "Avenida Las Americas", "Av 3 Norte",. )
replace manipadrsH = subinstr(manipadrsH, "Las Americas", "Av 3 Norte",. )
replace manipadrsH = subinstr(manipadrsH, "Americas", "Av 3 Norte",. )
replace manipadrsH = subinstr(manipadrsH, "America", "Av 3 Norte",. )
replace manipadrsH = subinstr(manipadrsH, "AV Americas", "Av 3 Norte",. )

list manipadrsH dir_res_ if regexm(manipadrsH, "Los Libertadores")==1 
list manipadrsH dir_res_ if regexm(manipadrsH, "Libertadores")==1 
list manipadrsH dir_res_ if regexm(manipadrsH, "El Simon Bolivar")==1 
list manipadrsH dir_res_ if regexm(manipadrsH, "Simon Bolivar")==1 
list manipadrsH dir_res_ if regexm(manipadrsH, "La Roosevelt")==1 
list manipadrsH dir_res_ if regexm(manipadrsH, "El Roosevelt")==1 
list manipadrsH dir_res_ if regexm(manipadrsH, "Roosevelt")==1 
list manipadrsH dir_res_ if regexm(manipadrsH, "La Quinta")==1 
list manipadrsH dir_res_ if regexm(manipadrsH, "Quinta")==1 
list manipadrsH dir_res_ if regexm(manipadrsH, "La Novena")==1 
list manipadrsH dir_res_ if regexm(manipadrsH, "Novena")==1 
list manipadrsH dir_res_ if regexm(manipadrsH, "La Pasoancho")==1 
list manipadrsH dir_res_ if regexm(manipadrsH, "Pasoancho")==1 
list manipadrsH dir_res_ if regexm(manipadrsH, "La Carolina")==1 
list manipadrsH dir_res_ if regexm(manipadrsH, "Carolina")==1 


list manipadrsH  dir_res_ if regexm(manipadrsH, "No Saber")==1 
list manipadrsH  dir_res_ if regexm(manipadrsH, "No Sabe")==1 
list manipadrsH  dir_res_ if regexm(manipadrsH, "NS")==1 
list manipadrsH  dir_res_ if regexm(manipadrsH, "Ns")==1 
list manipadrsH  dir_res_ if regexm(manipadrsH, "Sin Informacion")==1 
list manipadrsH  dir_res_ if regexm(manipadrsH, "No Informacion")==1 
list manipadrsH  dir_res_ if regexm(manipadrsH, "Sin Dato")==1 
list manipadrsH  dir_res_ if regexm(manipadrsH, "SD")==1 

list manipadrsH  dir_res_ if regexm(manipadrsH, "∑")==1 
replace manipadrsH = subinstr(manipadrsH, "∑", " # ",. )

list manipadrsH  dir_res_ if regexm(manipadrsH, "]")==1 
replace manipadrsH = subinstr(manipadrsH, "]", " # ",. )

replace manipadrsH = subinstr(manipadrsH, "5 Ta", " 5 ",. )
replace manipadrsH = subinstr(manipadrsH, "5Ta", " 5 ",. )
replace manipadrsH = subinstr(manipadrsH, "Sexta", " 6 ",. )
replace manipadrsH = subinstr(manipadrsH, "Portada De Comfandi", "  ",. )
replace manipadrsH = subinstr(manipadrsH, "Alle", " Cl ",. )
replace manipadrsH = subinstr(manipadrsH, "N∞", " # ",. )
replace manipadrsH = subinstr(manipadrsH, "Diagnoal", " DG ",. )
replace manipadrsH = subinstr(manipadrsH, "Acenida", " AV ",. )
replace manipadrsH = subinstr(manipadrsH, "Avenidad", " AV ",. )
replace manipadrsH = subinstr(manipadrsH, "A Venidad", " AV ",. )
replace manipadrsH = subinstr(manipadrsH, "Ato", " Apt ",. )
replace manipadrsH = subinstr(manipadrsH, "Jarillon De Lopez", " ",. )
replace manipadrsH = subinstr(manipadrsH, "ø", " ",. )


/*exports to excel
*export suspected dengue- none
*export confirmed dengue
export excel using "dengue_confirmed.xls" if dengue_status == 2|3, sheet("dengue_confirmed") sheetreplace firstrow(variables)
*export dengue deaths
export excel using "dengue_death.xls" if dengue_status == 3, sheet("dengue_deaths") sheetreplace firstrow(variables)
*export full data set
export excel using "all_dengue.xls", sheet("dengue_all") sheetreplace firstrow(variables)
*/

/**export test google api 100
export excel using "testgoogleapi100" in 1/100, firstrow(variables) replace
*import google refine data
import excel "all_dengue_googlerefine_nov 14.xls", sheet("all_dengue xls") firstrow clear
drop ID_BARRIO ini_sin_ control fec_rec muestra prueba agente resultado resultado_num fec_exp valor cod_pre cod_sub tip_ide_ edad_ uni_med_ sexo_ cod_pais_o cod_dpto_o cod_mun_o area_ localidad_ cen_pobla_ vereda_ bar_ver_ ocupacion_ tip_ss_ cod_ase_ per_etn_ gp_discapa gp_desplaz gp_migrant gp_carcela gp_gestan gp_indigen gp_pobicbf gp_mad_com gp_desmovi gp_psiquia gp_vic_vio gp_otros cod_dpto_r cod_mun_r fec_con_ tip_cas_ tip_cas_num pac_hos_ fec_hos_ con_fin_ fec_def_ ajuste_ adjustment_num telefono_ fecha_nto_ cer_def_ cbmte_ nuni_modif fec_arc_xl nom_dil_f_ tel_dil_f_ fec_aju_ nit_upgd fm_fuerza fm_unidad fm_grado desplazami cod_mun_d famantdngu direclabor fiebre cefalea dolrretroo malgias artralgia erupcionr dolor_abdo vomito diarrea somnolenci hipotensio hepatomeg hem_mucosa hipotermia caida_plaq acum_liqui aum_hemato extravasac hemorr_hem choque dao_organ muesttejid mueshigado muesbazo muespulmon muescerebr muesmiocar muesmedula muesrion clasfinal classfinal_num conducta nom_upgd ndep_proce nmun_proce  nmun_notif ndep_notif nreg append20142015 COD_BARRIO COD_COMUNA AREA PERIMETRO ESTRATO_MO ACUERDO LIMITES variabl_merge direccion_work
*/



*remake the address variable with updated addreses 
gen country = "Colombia"
egen address_complete = concat(manipadrsH NOMBRE nmun_resi ndep_resi country), punct(, " ")
order address_complete 
replace address_complete  = proper(address_complete)
order num_ide_ ID_CODE address_complete manipadrsH NOMBRE ID_BARRIO fec_not semana year

*export back to google api for geocoding
*ëhttps://maps.google.com/maps/api/geocode/json?key= AIzaSyAKegm2d1GFwrycpXosp3CovJ_jng50a0k&sensor=false&address=í+ escape(value, ëurlí)
*3rd attempt succesfull: 


/*geocode using mapquest
geocodeopen,  key("SiJaN36FLhrzDlMbvEV6LgaArtTR6fF2")  fulladdr( address_complete)   
writekml, filename(kmlout_mapquest) plcategory(nom_eve) pldesc(address_complete)
rename latitude latitude_mq
rename longitude longitude_mq

*geocode using google api
geocode3, address(address_complete)
rename g_lat latitude
rename g_lon longitude
writekml, filename(kmlout_google) plcategory(nom_eve) pldesc(address_complete)

*next step in arcgis 10.3- project lat/long
*/
*import shortened excel files from arcgis from openrefine
*import excel "all_dengue_googlerefine_nov-16C_short.xls", sheet("all_dengue_googlerefine_nov 14B") firstrow clear
*save all_dengue_googlerefine_nov-16_C.dta, replace 

*creating regular expressions and subexpresions
*create regular expression to parse the words after the numbers that are not a single letter. 
*e.g. KR 1 a 120 b O 17 ciudad jardin = KR 1a 120b O 17
*e.g. KR 1 a 120 b O 17 ciudad jardin apto 4 manzana 4 = KR 1a 120b O 17

/*
gen clipped_homeaddress = gen home_address_cali  firstpart minus words at end of expression
replace clipped_homeaddress = gen home_address_cali  first part minus words at begining of expression that are not KR or CL or PJ or TV or DG. */

*create expression to put together numbers and letters that are not "N" or "O" 
*e.g. KR 1 a 120 b O 17 = KR 1a 120b O 17
*number always goes with number after it
*remove space between number and following single letters that are not "O"s or "N"s or E's

replace manipadrsH = "." if manipadrsH == "999" 

*split stndadrsH into various variables number of segments seperated by length. 
*split manipadrsH, parse(" ")

*local numbers "0 1 2 3 4 5 6 7 8 9" 
*local streets "Kr Cl Av Pj Tv Dg"
/*foreach number in "0" "1" "2" "3" "4" "5" "6" "7" "8" "9" {
	foreach street in "Kr" "Cl" "Av" "Pj" "Tv" "Dg"{
		display("`street'`number'")
	}
}
foreach number in "0" "1" "2" "3" "4" "5" "6" "7" "8" "9" {
	foreach street in "Kr" "Cl" "Av" "Pj" "Tv" "Dg"{
		display("`street' `number'")
	}
}*/

*cleaning
replace manipadrsH = subinword(manipadrsH,"#"," # ",.)

replace manipadrsH = subinword(manipadrsH,"Kr"," KR ",.)
replace manipadrsH = subinstr(manipadrsH, "Cl", " CL ",.)
replace manipadrsH = subinstr(manipadrsH, "Av", " AV ",.)
replace manipadrsH = subinstr(manipadrsH, "Pj", " PJ ",.)
replace manipadrsH = subinstr(manipadrsH, "Tv", " TV ",.)
replace manipadrsH = subinstr(manipadrsH, "Dg", " DG ",.)

replace manipadrsH = subinword(manipadrsH,"kr"," KR ",.)
replace manipadrsH = subinstr(manipadrsH, "cl", " CL ",.)
replace manipadrsH = subinstr(manipadrsH, "av", " AV ",.)
replace manipadrsH = subinstr(manipadrsH, "pj", " PJ ",.)
replace manipadrsH = subinstr(manipadrsH, "tv", " TV ",.)
replace manipadrsH = subinstr(manipadrsH, "dg", " DG ",.)

replace manipadrsH = trim(manipadrsH)
replace manipadrsH = itrim(manipadrsH)


foreach number in "0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "-" {
	foreach street in "KR" "CL" "AV" "PJ" "TV" "DG"{
		replace manipadrsH = subinstr(manipadrsH, ("`street'`number'"), "`street' `number'", .)
	}
}
/*foreach n in "([ 0-9]*)"{
	foreach x in "Kr"`n' "Cl"`n' "Av"`n' "Pj"`n' "Tv"`n' "Dg"`n'{
	replace manipadrsH = subinstr(manipadrsH, "`x'", "#", .)
	}
}
foreach x in "Kr[ 0-9]*" "Cl`n'" "Av`n'" "Pj`n'" "Tv`n'" "Dg`n'"{
	replace manipadrsH = subinstr(manipadrsH, "`x'", "#", .)
	}*/

*remove second street keyword
*"Kr" = dog "Cl" = cat "Av" = bird "Pj" = fish "Tv" = hat "Dg" = doug
replace manipadrsH = subinword(manipadrsH,"KR","dog",1)
replace manipadrsH = subinstr(manipadrsH, "CL", "cat",1)
replace manipadrsH = subinstr(manipadrsH, "AV", "bird",1)
replace manipadrsH = subinstr(manipadrsH, "PJ", "fish",1)
replace manipadrsH = subinstr(manipadrsH, "TV", "hat",1)
replace manipadrsH = subinstr(manipadrsH, "DG", "doug",1)

foreach x in "KR" "Cl" "AV" "PJ" "TV" "DG"{
	replace manipadrsH = subinstr(manipadrsH, "`x'", " # ", .)
	}
*"Kr" = dog "Cl" = cat "Av" = bird "Pj" = fish "Tv" = hat "Dg" = doug
replace manipadrsH = subinstr(manipadrsH, "dog", "KR", .)
replace manipadrsH = subinstr(manipadrsH, "cat", "CL", .)
replace manipadrsH = subinstr(manipadrsH, "bird", "AV", .)
replace manipadrsH = subinstr(manipadrsH, "fish", "PJ", .)
replace manipadrsH = subinstr(manipadrsH, "hat", "TV", .)
replace manipadrsH = subinstr(manipadrsH, "doug", "DG", .)

*split into with or without # sign
replace manipadrsH = subinstr(manipadrsH, "s #Rmania","", .)
replace manipadrsH = subinstr(manipadrsH, "Transv","Tv", .)
replace manipadrsH = subinstr(manipadrsH, "Bue#S Aires","", .)
replace manipadrsH = subinstr(manipadrsH, "9#Rte","9N", .)
replace manipadrsH = subinstr(manipadrsH, "Cra#Rte  # 72 - A  - 20","KR 72A N #20", .)
replace manipadrsH = subinstr(manipadrsH, "# Recueda","", .)
replace manipadrsH = subinstr(manipadrsH, "Diga#Al 49 O # 13 ‚Äì 26","Dg 49 O # 13 - 26", .)
replace manipadrsH = subinstr(manipadrsH, "Cl 4#Rte #2An-26","Cl 4 N # 2An - 26", .)
replace manipadrsH = subinstr(manipadrsH, "Av 5 #Re # 44N-65","Av 5 N # 44N - 65", .)
replace manipadrsH = subinstr(manipadrsH, "Diag#Al 26G 7 # Tv 72 T - 53","Dg 26G7 # 72T - 53", .)
replace manipadrsH = subinstr(manipadrsH, "Kr 26 N # Diag#Al 28 B- 20", "KR 26 N # 28B - 20", .)
replace manipadrsH = trim(manipadrsH) 
foreach x in "KR" "CL" "AV" "PJ" "TV" "DG"{
replace manipadrsH = subinstr(manipadrsH, "`x'", strupper("`x'"), .)
}

*I have to treat each second pound differently. 
*use regular expressions to identify those which are street # or street# from other
* for each x in "Kr" "Av" "Pj" "Dg" "Tv"
*if `x['0-9]*[#]" then `x'[0-9]*[]"

*replace all other second "#" with with "-"
*# = pound
replace manipadrsH = subinword(manipadrsH,"#","pound",1)
replace manipadrsH = subinstr(manipadrsH, "#", " - ", .)
replace manipadrsH = subinstr(manipadrsH, "pound", " # ", .)

save temp.dta, replace

*From HERE
/*********************************
 *Amy Krystosik                  *
 *chikv and dengue in cali       *
 *dissertation                   *
 *last updated December 1, 2015  *
 *********************************/

cd "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data"
capture log close 
log using "dissertation_fromHERE.smcl", text replace 
set scrollbufsize 100000
set more 1
use temp.dta, clear
sort ID_CODE
order ID_CODE


*those without "#"
gen nopound = ""
replace nopound = manipadrsH if strpos(manipadrsH, "#")==0
order nopound dir_res manipadrsH NOMBRE
gsort -nopound 

*consider the "Bis" in the cleaning here too
replace manipadrsH = subinstr(manipadrsH, "Biss", " Bis ", .)
replace manipadrsH = subinstr(manipadrsH, "bis", " Bis ", .)
replace manipadrsH = subinstr(manipadrsH, "Bos", " Bis ", .)
replace manipadrsH = subinstr(manipadrsH, "bos", " Bis ", .)
replace manipadrsH = trim(manipadrsH)
replace manipadrsH = itrim(manipadrsH)
split manipadrsH, parse("Bis")
rename manipadrsH manipadrsH_origional
order manipadrsH_origional manipadrsH1 manipadrsH2 manipadrsH3
gsort -manipadrsH2
replace manipadrsH_origional = trim(manipadrsH1) + " Bis " + trim(manipadrsH2) if manipadrsH2!=""
replace manipadrsH_origional = trim(manipadrsH1) + " Bis " + trim(manipadrsH2)+ " Bis " + trim(manipadrsH3) if manipadrsH3!=""
drop manipadrsH1 manipadrsH2 manipadrsH3
rename manipadrsH_origional manipadrsH 
replace manipadrsH = trim(manipadrsH)
replace manipadrsH = itrim(manipadrsH)

split manipadrsH, parse("-")
rename manipadrsH manipadrsH_origional
order manipadrsH_origional manipadrsH1 manipadrsH2 manipadrsH3 manipadrsH4
gsort -manipadrsH2
replace manipadrsH_origional = trim(manipadrsH1) + " - " + trim(manipadrsH2) if manipadrsH2!=""
replace manipadrsH_origional = trim(manipadrsH1) + " - " + trim(manipadrsH2)+ " - " + trim(manipadrsH3) if manipadrsH3!=""
replace manipadrsH_origional = trim(manipadrsH1) + " - " + trim(manipadrsH2)+ " - " + trim(manipadrsH3)+ " - " + trim(manipadrsH4) if manipadrsH4!=""
drop manipadrsH1 manipadrsH2 manipadrsH3 manipadrsH4
rename manipadrsH_origional manipadrsH 
replace manipadrsH  = trim(manipadrsH)
replace manipadrsH  = itrim(manipadrsH)


*sort based on number of [ ] in string nopound so we can select better the before and after pound variables
replace nopound = trim(nopound)
replace nopound = itrim(nopound)
replace nopound = subinstr(nopound, "-", " - ", .)
foreach street in "KR" "CL" "AV" "PJ" "TV" "DG"{
	display("`street'")
	replace nopound = subinstr(nopound, "`street'", " `street' ", .)
}
replace nopound = trim(nopound)
replace nopound = itrim(nopound)

moss nopound, match(" ")
foreach number in "1" "2" "3" "4" "5" "6" "7" "8" "9" "10"{
	gen nopound`number' = nopound if _count==`number'
}

**take a break to eat. when i get back, i can use each category to do next step given below. 
**add a "#" for those in nopound
*select part that should come before the pound so we can put a pound at the end. 
*drop beforepound_np 
replace nopound = trim(nopound)
replace nopound = itrim(nopound)

foreach number in "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" {
	gen beforepound_np`number'= ""
}
*select part that should come after the pound so we can put reconstruct nopound. 
foreach number in "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" {
	gen afterpound_np`number'= ""
}
*now select using regex based on number of spaces
*np1
replace beforepound_np1= regexs(0) if regexm(nopound1, "^[a-zA-Z]+[ ]?[0-9]*[ ]?[a-zA-Z]*")==1 & nopound1!=""
replace afterpound_np1 = regexs(0) if regexm(nopound1, "[0-9]*$")==1 & nopound1!=""
drop if strpos(nopound1, "Km")!=0 
drop if strpos(nopound1, "KM")!=0 
list beforepound_np1 afterpound_np1 manipadrsH if nopound1!=""
*np1 has problems. i have to clean manipadrsH  better first. 

*np2
replace beforepound_np2= regexs(0) if regexm(nopound2, "^[a-zA-Z]+[ ]?[0-9]*[ ]?[a-zA-Z]*")==1 & nopound2!=""
replace afterpound_np2 = regexs(0) if regexm(nopound2, "[0-9]+[a-zA-Z]*[ ]?[-]?[ ]?[0-9]*[ ]?[a-zA-Z]*$")==1 & nopound2!="" 
drop if strpos(nopound2, "Km")!=0 
drop if strpos(nopound2, "KM")!=0 
list beforepound_np2 afterpound_np2 manipadrsH if nopound2!=""
*this one  has problems too. maybe i will have to seperate by size and then select multiple before and after pounds. 

*np3
replace beforepound_np3= regexs(0) if regexm(nopound3, "^[a-zA-Z]+[ ]?[0-9]*[ ]?[a-zA-Z]*[ ]?[a-zA-Z]*")==1 & nopound3!=""
replace afterpound_np3 = regexs(0) if regexm(nopound3, "[0-9]+[ ]?[a-zA-Z]*[-]?[ ]?[0-9]*$")==1 & nopound3!="" 
list beforepound_np3 afterpound_np3 manipadrsH if nopound3!=""

*np4
replace beforepound_np4= regexs(0) if regexm(nopound4, "^[a-zA-Z]+[ ]?[0-9]*[ ]?[a-zA-Z]*[ ]?[a-zA-Z]*")==1 & nopound4!=""
replace afterpound_np4 = regexs(0) if regexm(nopound4, "[0-9]+[a-zA-Z]*[ ]?[-]?[ ]?[0-9]*[ ]?[a-zA-Z]*[ ]?[0-9]*$")==1 & nopound4!=""
list beforepound_np4 afterpound_np4 manipadrsH if nopound4!=""

*np5
replace beforepound_np5= regexs(0) if regexm(nopound5, "^[a-zA-Z]+[ ]?[0-9]*[ ]?[a-zA-Z]*[ ]?[a-zA-Z]*")==1 & nopound5!=""
replace afterpound_np5 = regexs(0) if regexm(nopound5, "[0-9]+[a-zA-Z]*[ ]?[-]?[ ]?[0-9]*[ ]?[a-zA-Z]*[ ]?[0-9]*$")==1 & nopound5!=""
list beforepound_np5 afterpound_np5 manipadrsH if nopound5!=""

*np6
replace beforepound_np6= regexs(0) if regexm(nopound6, "^[a-zA-Z]+[ ]?[0-9]*[ ]?[a-zA-Z]*[ ]?[a-zA-Z]*")==1 & nopound6!=""
replace afterpound_np6 = regexs(0) if regexm(nopound6, "[0-9]+[a-zA-Z]*[ ]?[-]?[ ]?[0-9]*[ ]?[a-zA-Z]*[ ]?[0-9]*$")==1 & nopound6!="" 
list beforepound_np6 afterpound_np6 manipadrsH if nopound6!=""

*np7
replace beforepound_np7= regexs(0) if regexm(nopound7, "^[a-zA-Z]+[ ]?[0-9]*[ ]?[a-zA-Z]*[ ]?[a-zA-Z]*")==1  & nopound7!=""
replace afterpound_np7 = regexs(0) if regexm(nopound7, "[0-9]+[a-zA-Z]*[ ]?[-]?[ ]?[0-9]*[ ]?[a-zA-Z]*[ ]?[0-9]*$")==1  & nopound7!=""
list beforepound_np7 afterpound_np7 manipadrsH if nopound7!=""

*np8
replace beforepound_np8= regexs(0) if regexm(nopound8, "^[a-zA-Z]+[ ]?[0-9]*[ ]?[a-zA-Z]*[ ]?[a-zA-Z]*")==1 & nopound8!=""
replace afterpound_np8 = regexs(0) if regexm(nopound8, "[0-9]+[a-zA-Z]*[ ]?[-]?[ ]?[0-9]*[ ]?[a-zA-Z]*[ ]?[0-9]*$")==1 & nopound8!="" 
list beforepound_np8 afterpound_np8 manipadrsH if nopound8!=""

*np9
replace beforepound_np9= regexs(0) if regexm(nopound9, "^[a-zA-Z]+[ ]?[0-9]*[ ]?[a-zA-Z]*[ ]?[a-zA-Z]*")==1 & nopound9!=""
replace afterpound_np9 = regexs(0) if regexm(nopound9, "[0-9]+[a-zA-Z]*[ ]?[-]?[ ]?[0-9]*[ ]?[a-zA-Z]*[ ]?[0-9]*$")==1 & nopound9!="" 
list beforepound_np9 afterpound_np9 manipadrsH if nopound9!=""

*np10
list nopound nopound10 dir_res_ if nopound10!=""
replace beforepound_np10 = regexs(0) if regexm(nopound, "^[a-zA-Z]+[0-9]*[a-zA-Z]*")==1 & nopound10!="" 
replace afterpound_np10 = regexs(0) if regexm(nopound, "[0-9]+[a-zA-Z]*[ ]?[-]?[ ]?[0-9]*[ ]?[a-zA-Z]*[ ]?[0-9]*$")==1 & nopound10!=""
list beforepound_np10  afterpound_np10  nopound nopound10 dir_res_ if nopound10!=""

foreach number in "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" {
	order beforepound_np`number' 
	gsort -beforepound_np`number'
	order beforepound_np`number' afterpound_np`number'
	replace nopound`number'= beforepound_np`number'+" # " + afterpound_np`number' if nopound`number'!=""
	replace nopound = nopound`number' if nopound`number'!=""
	drop nopound`number' beforepound_np`number' afterpound_np`number'
}
order nopound manipadrsH dir_res_
replace manipadrsH = nopound if nopound!="" 
drop nopound 



*those with "#"
gen pound = ""
replace pound = manipadrsH if strpos(manipadrsH, "#")!=0
split pound, parse(pound, "#")
replace pound1=trim(pound1)
replace pound1=itrim(pound1)
replace pound2=itrim(pound2)
replace pound2=trim(pound2)
gen first_homeaddressP= "."
replace first_homeaddressP = pound1
gen last_homeaddressP= "."
replace last_homeaddressP= pound2

*standardize the pound2

*from here for the bis to put insdie the parse. 
*clean the bis 
*drop pound2bis 
gen pound2bis=""
*replace pound2spacenodash = pound2 if regexm(pound2, "[0-9]+[a-zA-Z]*[ ][0-9]+")==1
replace pound2 = proper(pound2)
replace pound2 = subinstr(pound2, "Biss", "Bis", .)
replace pound2 = subinstr(pound2, "bis", "Bis", .)
replace manipadrsH = subinstr(manipadrsH, "Bos", "Bis", .)
replace manipadrsH = subinstr(manipadrsH, "bos", "Bis", .)

replace pound2bis= pound2 if strpos(pound2, "Bis")!=0
replace pound2bis= pound2 if strpos(pound2, "bis")!=0

*find instances with Bis and suffix of oeste, norte, or este
*drop bissuffix 
gen bissuffix=""
replace bissuffix= regexs(0) if regexm(pound2bis, "Bis Oe|Bis Oeste|Bis Norte|Bis N|Bis No|Bis Este|Bis E")==1
order bissuffix pound2bis
gsort -bissuffix
*drop these suffixes
replace pound2bis = subinstr(pound2bis, "Bis Oe", "Bis", .)
replace pound2bis = subinstr(pound2bis, "Bis N", "Bis", .)
*add this bissuffix back later when i reconstruct the bis. 

*nuisance characters to remove. 
replace pound2bis= subinstr(pound2bis, "s De", "", .)

order pound2bis
gsort -pound2bis
split pound2bis, parse(Bis)
rename pound2bis pound2bis_origional
order pound2bis_origional pound2bis1 pound2bis2 pound2 dir_res_ 
gsort -pound2bis_origional

*for each side of the bis, run the " "parse

*from here pound2bis1 
*from here for the parse on space section. to use on each side of the bis
*select pound2 cases with "[0-9] [a-Z]"
*drop pound2bis1space
gen pound2bis1space=""
order pound2bis1space pound2bis1 pound2
replace pound2bis1 = itrim(pound2bis1)
replace pound2bis1 = trim(pound2bis1)
*
replace pound2bis1space=regexs(0) if regexm(trim(pound2bis1), "[0-9]*[ ][a-d]?[A-D]?[f-m]?[F-M]?[p-z]?[P-Z]?")==1
*this one is excluded because it has an extra DG. This DG is a mistake and shoudl be dealt with later. "pound2bis1 = DG 72 E"
replace pound2bis1space= trim(pound2bis1space)
replace pound2bis1space= itrim(pound2bis1space)
gsort -pound2bis1space
*parse on " " those with "[0-9] [a-Z]"
split pound2bis1space, parse(" ") 
replace pound2bis1space= trim(pound2bis1space1) 
replace pound2bis1space= itrim(pound2bis1space1) 
replace pound2bis1space= trim(pound2bis1space2) 
replace pound2bis1space= itrim(pound2bis1space2) 
order pound2bis1space pound2bis1space1 pound2bis1space2
gsort -pound2bis1space1
rename pound2bis1space pound2bis1space_origional 
replace pound2bis1space_origional = pound2bis1space1+pound2bis1space2 if pound2bis1space_origional !=""

*gen pound2bis1spacebeforedash = pound2bis1space_origional if pound2bis1space_origional !=""
*drop  pound2bis1space1 pound2bis1space2
rename pound2bis1space_origional pound2bis1space
*to here. 
*to here pound2bis1

*add the dashes on either side of the bis if pound2bis1space!=""
gsort - pound2bis1space 
replace pound2bis1space = subinstr(trim(pound2bis1space), " ", "-", .) if pound2bis1space!=""
replace pound2bis1space= subinstr(trim(pound2bis1space), "--", "-", .) if pound2bis1space!=""
replace pound2bis1space = subinstr(trim(pound2bis1space), "---", "-", .) if pound2bis1space!=""
replace pound2bis1 = pound2bis1space if pound2bis1space!=""
order pound2bis_origional pound2bis1 
gsort -pound2bis_origional  
drop pound2bis1space pound2bis1space1 pound2bis1space2
*to here


*from here pound2bis2
*from here for the parse on space section. to use on each side of the bis
*select pound2 cases with "[0-9] [a-Z]"
*drop pound2bis2space
*select those with a space
gen pound2bis2space=""
order pound2bis2space pound2bis2 pound2
replace pound2bis2 = itrim(pound2bis2)
replace pound2bis2 = trim(pound2bis2)
replace pound2bis2space=regexs(0) if regexm(trim(pound2bis2), "[ - ]*[ 0-9]*[ - ]*[ 0-9]*[ ]*[a-d]?[A-D]?[f-m]?[F-M]?[p-z]?[P-Z]?[-]?[ 0-9 ]*")==1
gsort -pound2bis2space
replace pound2bis2space= trim(pound2bis2space)
replace pound2bis2space= itrim(pound2bis2space)
gsort -pound2bis2space
*parse on " "|"-" those with "[0-9] [a-Z]"
split pound2bis2space, parse(" " "-" " -" "- "" - ") 
rename pound2bis2space pound2bis2space_origional 
order pound2bis2space_origional pound2bis2space1 pound2bis2space2 
replace pound2bis2space1 = trim(pound2bis2space1) if pound2bis2space1 !=""
replace pound2bis2space1 = itrim(pound2bis2space1) if pound2bis2space1 !="" 
replace pound2bis2space2 = trim(pound2bis2space2) if pound2bis2space2 !=""
replace pound2bis2space2 = itrim(pound2bis2space2) if pound2bis2space2 !="" 
*replace pound2bis2space3 = trim(pound2bis2space3) if pound2bis2space3 !=""
*replace pound2bis2space3 = itrim(pound2bis2space3) if pound2bis2space3 !="" 
replace pound2bis2space_origional = " - " + pound2bis2space1 if pound2bis2space1!=""
replace pound2bis2space_origional = " - " + pound2bis2space1 + " - " + pound2bis2space2 if pound2bis2space1!="" & pound2bis2space2!=""
*replace pound2bis2space_origional = " - " + pound2bis2space1 + " - " + pound2bis2space2 + " - " + pound2bis2space3 if pound2bis2space1!="" & pound2bis2space2!="" & pound2bis2space3!=""
*replace pound2bis2space_origional = " - " + pound2bis2space1 + " - " + pound2bis2space2 + " - " + pound2bis2space3 + " - " + pound2bis2space4 if pound2bis2space1!="" & pound2bis2space2!="" & pound2bis2space3!="" & pound2bis2space4!=""
rename pound2bis2space_origional pound2bis2space
drop pound2bis2space1  - pound2bis2space2 
replace pound2bis2space = itrim(pound2bis2space)
replace pound2bis2space = trim(pound2bis2space)
replace pound2bis2space= subinstr(trim(pound2bis2space), "---", " - ", .) if pound2bis2space!=""
replace pound2bis2space= subinstr(trim(pound2bis2space), "--", " - ", .) if pound2bis2space!=""
replace pound2bis2space= subinstr(trim(pound2bis2space), "- -", " - ", .) if pound2bis2space!=""
replace pound2bis2space= subinstr(trim(pound2bis2space), "-", " - ", .) if pound2bis2space!=""
replace pound2bis2space= itrim(pound2bis2space)
replace pound2bis2space= trim(pound2bis2space)
order pound2bis2space pound2bis2 
gsort -pound2bis2space

/**select those with Oe|Oeste|O
drop pound2bis2spaceoeste 
gen pound2bis2spaceoeste=""
replace pound2bis2 = itrim(pound2bis2)
replace pound2bis2 = trim(pound2bis2)
order pound2bis2spaceoeste pound2bis2 pound2
replace pound2bis2spaceoeste= pound2bis2 if strpos(pound2bis2, "O")!=0
replace pound2bis2spaceoeste= pound2bis2 if strpos(pound2bis2, "Oe")!=0
replace pound2bis2spaceoeste= pound2bis2 if strpos(pound2bis2, "Oeste")!=0
replace pound2bis2spaceoeste= pound2bis2 if strpos(pound2bis2, "Norte")!=0
replace pound2bis2spaceoeste= pound2bis2 if strpos(pound2bis2, "N")!=0
replace pound2bis2spaceoeste= pound2bis2 if strpos(pound2bis2, "E")!=0
order pound2bis2spaceoeste
gsort -pound2bis2spaceoeste
drop pound2bis2spaceoeste
*there are none. good. I don't have to do anythign else with this variable. */
*to here. 
*to here pound2bis2

*add the dashes on either side of the bis if pound2bis1space!=""
*to here
replace pound2bis2 = pound2bis2space if pound2bis2space!=""
drop pound2bis2space
*reconstruct the variable pound2bis
replace pound2bis_origional=  pound2bis1 + " Bis " + pound2bis2 if pound2bis_origional!=""
*add this bissuffix back later when i reconstruct the bis. 
replace pound2bis_origional=  pound2bis1 + " Bis " + bissuffix + pound2bis2 if pound2bis_origional!="" & bissuffix !=""
rename pound2bis_origional pound2bis 
drop pound2bis1 pound2bis2
order pound2bis pound2 dir_res_ 
gsort -pound2bis 
replace pound2 = pound2bis if pound2bis!=""
 
*
order last_homeaddressP pound2
gsort -pound2
replace last_homeaddressP = pound2 if pound2!=""

*standardize pound1, first part if has #
*First step, standardize the "Bis" so I can parse on "Bis"
*drop pound1bis 
gen pound1bis=""	
order pound1bis
replace pound1bis= pound1 if strpos(pound1, "Bis")!=0
replace pound1bis= pound1 if strpos(pound1, "bis")!=0
replace pound1bis= pound1 if strpos(pound1, "BIS")!=0
replace pound1bis = subinstr(pound1bis, "bis", "Bis", .)
replace pound1bis= subinstr(pound1bis, "bis", "Bis", .)
replace pound1bis= subinstr(pound1bis, "BIS", "Bis", .)
replace pound1bis= subinstr(pound1bis, "bIS", "Bis", .)
replace pound1bis= subinstr(pound1bis, "BIs", "Bis", .)
replace pound1bis= subinstr(pound1bis, "bIs", "Bis", .)
replace pound1bis = subinstr(pound1bis, "biS", "Bis", .)
replace pound1bis = subinstr(pound1bis, "Bist", "Bis", .)
*those with "Bis" in the peice before pound, parse on "Bis"
split pound1bis, parse(Bis)
rename pound1bis pound1bis_origional
order pound1bis_origional pound1bis1 pound1bis2 pound1 dir_res_ 
gsort -pound1bis1
*drop pound1space
replace pound1bis1=trim(pound1bis1)
*here we are making a second variable for the peice before the pound before the bis so we can find those with [0-9][ ][a-zA-Z]. 
*first we will remove the first section by using a parse and reconstructing it without the first peice (KR, CL...).
gen pound1bis1space = pound1bis1 if pound1bis1!=""
order pound1bis1 
gsort - pound1bis1 
split pound1bis1space, parse("")
rename pound1bis1space pound1bis1space_origional
order pound1bis1space_origional dir_res_
gsort -pound1bis1space_origional   
*here we reconstruct pound1bis1space_origional wihtout the KR|CL... 
replace pound1bis1space_origional = pound1bis1space2 + " " + pound1bis1space3 + " " + pound1bis1space4 + " " + pound1bis1space5

*drop pound1bis1spaceB
*here we create a second variable where we search for those pound1bis1space_origional with [0-9][ ][a-zA-Z].  
gen pound1bis1spaceB = ""
order pound1bis1spaceB 
replace pound1bis1spaceB= regexs(0) if regexm(trim(pound1bis1space_origional), "[0-9]+[ ][a-zA-Z]*[ ]?[a-zA-Z]*[0-9]?[-]?")==1
*remove the "-" here and repalce with " "
replace pound1bis1spaceB = subinstr(itrim(pound1bis1spaceB), "-", " ", .) if pound1bis1spaceB !=""
*here we parse on " " those those pound1bis1space_origional with [0-9][ ][][a-zA-Z].  
replace pound1bis1spaceB = itrim(pound1bis1spaceB)
split pound1bis1spaceB, parse(" ")
rename pound1bis1spaceB pound1bis1spaceB_origional 
*here we reconstruct those those pound1bis1space_origional with [0-9][ ][][a-zA-Z] so that [0-9][a-zA-Z]
replace pound1bis1space_origional = pound1bis1space1 + " " + pound1bis1spaceB1 + pound1bis1spaceB2+ pound1bis1spaceB3 if pound1bis1spaceB_origional !=""
replace pound1bis1space_origional = subinstr(pound1bis1space_origional, "KR 7MaPJ","KR 7Map",.) 
gsort -pound1bis1space_origional 
replace pound1bis1space_origional = pound1bis1space1 +" "+ pound1bis1space2 + " " + pound1bis1space3 + " " + pound1bis1space4 + " " + pound1bis1space5 if pound1bis1spaceB_origional ==""
drop pound1bis1space1 - pound1bis1space5 
drop pound1bis1spaceB1 - pound1bis1spaceB3 
drop pound1bis1spaceB_origional
rename pound1bis1space_origional pound1bis1space
replace pound1bis1space = trim(pound1bis1space)
order pound1bis1 pound1bis1space 
*pound1bis1space will be the first part of pound 1 before the bis
replace pound1bis1 = pound1bis1space if pound1bis1space !=""
drop pound1bis1space 

*now put the before and after bis together
order pound1bis_origional  pound1bis1 pound1bis2 
gsort -pound1bis2 
replace pound1bis_origional = trim(pound1bis1) + " Bis " + trim(pound1bis2) if pound1bis_origional !=""
order pound1bis_origional pound1   
gsort -pound1bis_origional
replace pound1 = pound1bis_origional if pound1bis_origional!=""
drop pound1bis1 pound1bis2 

*now deal with those without bis: if pound1bis_origional!=""
*drop pound1space_origional 
gen pound1space = pound1
split pound1space, parse(" ")
rename pound1space pound1space_origional 
*in this step we remove the KR|CL so we can select without it. we will add it back later to the pound1space_origional + pound1space1
replace pound1space_origional = pound1space2 + " " + pound1space3 + " " + pound1space4 + " " + pound1space5 + " " + pound1space6
drop pound1space2-pound1space6  
*drop pound1space_origionalB 
gen pound1space_origionalB =""
replace pound1space_origional = trim(pound1space_origional)
replace pound1space_origional = itrim(pound1space_origional)
replace pound1space_origionalB=pound1space_origional if regexm(trim(pound1space_origional), "[0-9]+[ ]+[a-d]?[A-D]?[f-m]?[F-M]?[p-z]?[P-Z]?[ 0-9]*")==1 & pound1bis_origional==""
order pound1space_origional pound1space_origionalB dir_res_
*parse those with "[0-9][ ][a-Z]"
replace pound1space_origionalB= trim(pound1space_origionalB)
split pound1space_origionalB, parse(" ") 
rename pound1space_origionalB pound1space_origionalB_A
*put the peices back together without space
replace pound1space_origionalB_A= pound1space_origionalB1+pound1space_origionalB2+pound1space_origionalB3+pound1space_origionalB4+pound1space_origionalB5 if pound1space_origionalB_A!=""
*replace pound1 with  pound1space_origionalB_A + pound1space1 for street 
replace pound1 = pound1space1 + " " + pound1space_origionalB_A  if pound1space_origionalB_A !=""
order pound1 pound1space_origionalB_A pound1space_origionalB1 pound1space_origionalB2 
gsort -pound1space_origionalB_A


/*
*select last two numbers and add a hyphen and cut two hyphens into two
gen lasttwo = "."
replace lasttwo = last_homeaddressP 
*turn over the last homeaddress and select the first two

replace lasttwo = split(last_homeaddressP), parse(" ") 
*/

*reconstruct manipadrsHP from first_homeaddressP last_homeaddressP
gen manipadrsHP="."
replace first_homeaddressP = trim(first_homeaddressP)
replace last_homeaddressP = trim(last_homeaddressP)
replace manipadrsHP = trim(first_homeaddressP + " # " + last_homeaddressP)
replace manipadrsHP = subinstr(manipadrsHP, "--", " - ", .)
replace manipadrsHP = subinstr(manipadrsHP, "- -", " - ", .)
replace manipadrsHP = subinstr(manipadrsHP, "-", " - ", .)
replace manipadrsHP = trim(manipadrsHP)
replace manipadrsHP = itrim(manipadrsHP)
order dir_res_ manipadrsHP last_homeaddressP
gsort -pound

*consider the "Bis" in the cleaning here too
replace manipadrsHP = subinstr(manipadrsHP, "Biss", " Bis ", .)
replace manipadrsHP = subinstr(manipadrsHP, "bis", " Bis ", .)
replace manipadrsHP = subinstr(manipadrsHP, "Bos", " Bis ", .)
replace manipadrsHP = subinstr(manipadrsHP, "bos", " Bis ", .)
replace manipadrsHP = trim(manipadrsHP)
replace manipadrsHP = itrim(manipadrsHP)

/*
split manipadrsHP, parse("Bis")
rename manipadrsHP manipadrsHP_origional
replace manipadrsHP_origional = trim(manipadrsHP1) + " Bis " + trim(manipadrsHP2) if manipadrsH2!=""
replace manipadrsH_origional = trim(manipadrsH1) + " Bis " + trim(manipadrsH2)+ " Bis " + trim(manipadrsH3) if manipadrsH3!=""
drop manipadrsH1 manipadrsH2 manipadrsH3
rename manipadrsH_origional manipadrsH 
replace manipadrsH = trim(manipadrsH)
replace manipadrsH = itrim(manipadrsH)
*/


list manipadrsHP dir_res_ if regexm(manipadrsHP , "Ta")==1 
list manipadrsHP NOMBRE if regexm(manipadrsHP , "ta")==1 
replace manipadrsHP  = subinstr(manipadrsHP , "Ta", " ",. )
replace manipadrsHP = subinstr(manipadrsHP , "ta", " ",. )

list manipadrsHP dir_res_ if regexm(manipadrsHP , "Na")==1 
list manipadrsHP NOMBRE if regexm(manipadrsHP , "na")==1 
replace manipadrsHP  = subinstr(manipadrsHP , "Na", " ",. )
replace manipadrsHP  = subinstr(manipadrsHP , "na", " ",. )

list manipadrsHP dir_res_ if regexm(manipadrsHP , "ma")==1 
list manipadrsHP NOMBRE if regexm(manipadrsHP , "Ma")==1 
replace manipadrsHP  = subinstr(manipadrsHP , "Ma", " ",. )
replace manipadrsHP = subinstr(manipadrsHP , "Ma", " ",. )

list manipadrsHP dir_res_ if regexm(manipadrsHP , "Ra")==1 
list manipadrsHP NOMBRE if regexm(manipadrsHP , "ra")==1 
replace manipadrsHP  = subinstr(manipadrsHP , "Ra", " ",. )
replace manipadrsHP  = subinstr(manipadrsHP , "ra", " ",. )

list manipadrsHP dir_res_ if regexm(manipadrsHP , "Va")==1 
list manipadrsHP NOMBRE if regexm(manipadrsHP , "va")==1 
replace manipadrsHP  = subinstr(manipadrsHP , "Va", " ",. )
replace manipadrsHP  = subinstr(manipadrsHP , "va", " ",. )

*remove space between all letters and numbers unless it is a N, E, O, S
*replace N, O, E, S, KR, AV, PJ, TV, DG to other symbols
foreach x in "A" "B" "C" "D" "F" "G" "H" "I" "J" "K" "L" "M" "P" "Q" "R" "T" "U" "V" "W" "X" "Y" "Z"{
	replace manipadrsHP = subinstr(manipadrsHP, " `x' ", "`x'", .)
	}

*once all of the directions are cleaned, replace each the oeste, norte, este, with " O ", " E " " N " then itrim and trim the variable 
replace manipadrsHP = subinstr(manipadrsHP, "Norte", " N ", .)
replace manipadrsHP = subinstr(manipadrsHP, "Nte", " N ", .)
replace manipadrsHP = subinstr(manipadrsHP, "Oeste", " O ", .)
replace manipadrsHP = subinstr(manipadrsHP, "Oste", " O ", .)
replace manipadrsHP = subinstr(manipadrsHP, "Oes", " O ", .)
replace manipadrsHP = subinstr(manipadrsHP, "Oest", " O ", .)
replace manipadrsHP = subinstr(manipadrsHP, "Ose", " O ", .)
replace manipadrsHP = subinstr(manipadrsHP, "Oe", " O ", .)
replace manipadrsHP = subinstr(manipadrsHP, "Este", " E ", .)
replace manipadrsHP = subinstr(manipadrsHP, "Sur", " S ", .)


/*replace manipadrsHP = subinstr(manipadrsHP, "O", " O ", .)
replace manipadrsHP = subinstr(manipadrsHP, "E", " E ", .)
replace manipadrsHP = subinstr(manipadrsHP, "N", " N ", .)*/

replace manipadrsHP = subinstr(manipadrsHP, "Bis", " Bis ", .)
replace manipadrsHP = subinstr(manipadrsHP, "Bis Bis", " Bis ", .)
replace manipadrsHP = subinstr(manipadrsHP, "#", " # ", .)
replace manipadrsHP = subinstr(manipadrsHP, "- Bis", "Bis", .)
replace manipadrsHP = subinstr(manipadrsHP, "-", " - ", .)


*remove missing
replace manipadrsHP = "." if manipadrsHP==""  
list if manipadrsHP=="."  
drop if manipadrsHP=="."  

/**we have to remove strings like "Polverines" "La Luisa" "La Choclona" "Acentamiento Brisas De Comunero" "municipal En Candelaria" "Brisas De Los Alamos" 
gen manipadrsHP_l =length(manipadrsHP) 
order manipadrsHP
gsort -manipadrsHP_l
*/

replace manipadrsHP = trim(manipadrsHP)
replace manipadrsHP = itrim(manipadrsHP)
replace manipadrsHP = proper(manipadrsHP)


replace manipadrsHP = subinword(manipadrsHP,"Kr","KR",.)
replace manipadrsHP = subinstr(manipadrsHP, "Cl", "CL",.)
replace manipadrsHP = subinstr(manipadrsHP, "Av", "AV",.)
replace manipadrsHP = subinstr(manipadrsHP, "Pj", "PJ",.)
replace manipadrsHP = subinstr(manipadrsHP, "Tv", "TV",.)
replace manipadrsHP = subinstr(manipadrsHP, "Dg", "DG",.)

replace manipadrsHP = subinword(manipadrsHP,"kr","KR",.)
replace manipadrsHP = subinstr(manipadrsHP, "cl", "CL",.)
replace manipadrsHP = subinstr(manipadrsHP, "av", "AV",.)
replace manipadrsHP = subinstr(manipadrsHP, "pj", "PJ",.)
replace manipadrsHP = subinstr(manipadrsHP, "tv", "TV",.)
replace manipadrsHP = subinstr(manipadrsHP, "dg", "DG",.)


*split on pound sign and replace the spaces with dashes. 
split manipadrsHP, parse("#")
rename manipadrsHP manipadrsHP_origional
replace manipadrsHP2 = subinstr(trim(manipadrsHP2), " ", " - ", .) if manipadrsHP2!=""
replace manipadrsHP2 = subinstr(trim(manipadrsHP2), " - - - - ", " - ", .) if manipadrsHP2!=""
replace manipadrsHP2 = subinstr(trim(manipadrsHP2), " - - - ", " - ", .) if manipadrsHP2!=""
replace manipadrsHP2 = subinstr(trim(manipadrsHP2), " - - ", " - ", .) if manipadrsHP2!=""
replace manipadrsHP2 = subinstr(trim(manipadrsHP2), "-  -", " - ", .) if manipadrsHP2!=""
replace manipadrsHP2 = subinstr(trim(manipadrsHP2), "- Bis", " Bis ", .) if manipadrsHP2!=""

replace manipadrsHP2 = subinstr(trim(manipadrsHP2), " - E ", " E ", .) if manipadrsHP2!=""
replace manipadrsHP2 = subinstr(trim(manipadrsHP2), " - O ", " O ", .) if manipadrsHP2!=""
replace manipadrsHP2 = subinstr(trim(manipadrsHP2), " - S ", " S ", .) if manipadrsHP2!=""
replace manipadrsHP2 = subinstr(trim(manipadrsHP2), " - N ", " N ", .) if manipadrsHP2!=""

replace manipadrsHP2 = trim(manipadrsHP2) if manipadrsHP2!=""
replace manipadrsHP2 = itrim(manipadrsHP2) if manipadrsHP2!=""
replace manipadrsHP_origional = trim(manipadrsHP1) + " # " + trim(manipadrsHP2) if manipadrsHP2!=""
rename manipadrsHP_origional manipadrsHP  
drop manipadrsHP1 manipadrsHP2 

*order
order manipadrsHP dir_res

*make variable I will edit by hand
gen byhand_manipadrsHP = "."
replace byhand_manipadrsHP = manipadrsHP
order dir_res_ byhand_manipadrsHP NOMBRE manipadrsHP 

*stable sort so that the observations stay in the right order for hand edits
sort ID_CODE, stable
sort NOMBRE, stable

*export to excel a coopy
export excel using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\byhand.xls", firstrow(variables) replace

/*
*manual edits in stata edit window
replace byhand_manipadrsHP = "KR 40 # 31A - 49" in 1
replace byhand_manipadrsHP = "KR 41 # 30A - 56" in 8
replace byhand_manipadrsHP = "KR 39A # 30A - 42" in 20
replace byhand_manipadrsHP = "KR 41A # 30C - 30" in 47
replace byhand_manipadrsHP = "KR 41A # 30C - 93" in 46
replace byhand_manipadrsHP = "KR 41 # 30A - 56" in 39
replace byhand_manipadrsHP = "KR 41 # 30A - 56" in 40
replace byhand_manipadrsHP = "KR 41 # 30A - 56" in 41
replace byhand_manipadrsHP = "KR 2 # 64A - 22" in 71
replace byhand_manipadrsHP = "KR 13 # 62 - 36" in 73
replace byhand_manipadrsHP = "CL 59 # 59 - 2F38" in 74
replace byhand_manipadrsHP = "KR 1H Bis # 64 - 22" in 90
replace byhand_manipadrsHP = "KR 1H # 62 - 70" in 91
replace byhand_manipadrsHP = "CL 62 # 1B - 90" in 92
replace byhand_manipadrsHP = "KR 1 # 1 - 68 - 52" in 98
replace byhand_manipadrsHP = "KR 1D # 70C - 18" in 99
replace byhand_manipadrsHP = "KR 1D # 70C - 18" in 100
replace byhand_manipadrsHP = "KR 1F # 71 - 77" in 102
replace byhand_manipadrsHP = "KR 1J # 62A - 28" in 113
replace byhand_manipadrsHP = "CL 71A # 9D - 35" in 114
replace byhand_manipadrsHP = "KR 1H # 64A - 48" in 115
replace byhand_manipadrsHP = "KR 35 O # 7 - 13" in 125
replace byhand_manipadrsHP = "CL 7 O # 25 - 153" in 126
replace byhand_manipadrsHP = "KR 4 E # 62B - 40" in 133
replace byhand_manipadrsHP = "KR 3A # 62A - 47" in 136
replace byhand_manipadrsHP = "CL 59 # 4D - 59" in 137
replace byhand_manipadrsHP = "CL 60D # 4D - 65" in 145
replace byhand_manipadrsHP = "KR 5 # 28A - 99" in 146
replace byhand_manipadrsHP = "CL 60C # 4D B - 15 - 46" in 149

replace byhand_manipadrsHP = "KR 4C1 # 62B - 53" in 152
replace byhand_manipadrsHP = "KR 4C1 # 62B - 53" in 153
replace byhand_manipadrsHP = "KR 3 # 63 - 70" in 154
replace byhand_manipadrsHP = "KR 3 # 63 - 70" in 155
replace byhand_manipadrsHP = "CL 59D # 3 Bis - 10" in 159
replace byhand_manipadrsHP = "KR 4B # 58 - 28" in 160
replace byhand_manipadrsHP = "KR 4 # 63 - 13 - 05" in 161
replace byhand_manipadrsHP = "KR 4C1 # 59C Bis - 04" in 165
replace byhand_manipadrsHP = "CL 92 # 8A - 10" in 170
replace byhand_manipadrsHP = "CL 95 # 19 - 91" in 173
replace byhand_manipadrsHP = "CL 18A # 55 - 105" in 177
replace byhand_manipadrsHP = "CL 18 Bis # 52A - 11" in 178
replace byhand_manipadrsHP = "CL 14B # 14 N - 86" in 180
replace byhand_manipadrsHP = "CL 18 # 35 - 40" in 181
replace byhand_manipadrsHP = "CL 18 # 35 - 40" in 182
replace byhand_manipadrsHP = "CL 18 # 35 - 40" in 183
replace byhand_manipadrsHP = "CL 18 # 35 - 40" in 184
replace byhand_manipadrsHP = "CL 18 # 50 - 97" in 185
replace byhand_manipadrsHP = "CL 57 # 1G - 06" in 194
replace byhand_manipadrsHP = "KR 52A # 16 - 65" in 200
replace byhand_manipadrsHP = "CL 18 # 53A  - 88" in 204
replace byhand_manipadrsHP = "CL 13 Cn # 15 - 22" in 227
replace byhand_manipadrsHP = "CL 13 Cn # 20 - 15" in 228
replace byhand_manipadrsHP = "CL 122 # 28F - 1 - 53" in 231
replace byhand_manipadrsHP = "CL 110 # 29 - 48" in 232
replace byhand_manipadrsHP = "KR 28D # 5 - 120A - 57B" in 235
replace byhand_manipadrsHP = "KR 28C # 120B - 58" in 237
replace byhand_manipadrsHP = "KR 28D4 # 120A - 127" in 239
replace byhand_manipadrsHP = "KR 28D4 # 120A - 127" in 240
replace byhand_manipadrsHP = "CL 18 # 28 E - 51" in 241
replace byhand_manipadrsHP = "KR 28 # 120B - 63" in 242
replace byhand_manipadrsHP = "KR 28D6 # 120A - 27" in 243
replace byhand_manipadrsHP = "KR 28D4 # 120B - 58" in 244
replace byhand_manipadrsHP = "CL 5 O" in 245
replace byhand_manipadrsHP = "CL 2 O N" in 246
replace byhand_manipadrsHP = "CL 26B # 27 - 24" in 250
replace byhand_manipadrsHP = "CL 26B # 27 - 24" in 251
replace byhand_manipadrsHP = "CL 26B # 27 - 24" in 252
replace byhand_manipadrsHP = "CL 26B # 27 - 24" in 253
replace byhand_manipadrsHP = "DG l # 25 - 17" in 254
replace byhand_manipadrsHP = "TV 29 # 26 - 30" in 255
replace byhand_manipadrsHP = "TV 29 # 26 - 30" in 256
replace byhand_manipadrsHP = "TV 29 # 26 - 30" in 257
replace byhand_manipadrsHP = "TV 29 # 26 - 30" in 258
replace byhand_manipadrsHP = "KR 45 # 45 - 96C - 79" in 259
replace byhand_manipadrsHP = "DG 24A # T25 - 104" in 260
replace byhand_manipadrsHP = "KR 33 # 96A - 98" in 263
replace byhand_manipadrsHP = "TV 25 # D24 - B11" in 264
replace byhand_manipadrsHP = "DG 18 # 17F1 - 07" in 265
replace byhand_manipadrsHP = "DG 24B # 25 - 102" in 271

replace byhand_manipadrsHP = "DG 24B # 25 - 102" in 272
replace byhand_manipadrsHP = "KR 7 # 74 - 38" in 273
replace byhand_manipadrsHP = "DG 24B # 25 - 66" in 276
replace byhand_manipadrsHP = "DG 23 # 25 - 68" in 277
replace byhand_manipadrsHP = "KR 11E # 39 - 04" in 278
replace byhand_manipadrsHP = "CL 40 N # 3 N - 2D" in 281
replace byhand_manipadrsHP = "TV 29 # 26 - 36" in 282
replace byhand_manipadrsHP = "TV 29 # 26 - 36" in 283
replace byhand_manipadrsHP = "TV 29 # 26 - 36" in 284
replace byhand_manipadrsHP = "TV 29 # 26 - 36" in 285
replace byhand_manipadrsHP = "TV 2 # 26 - 104" in 289
replace byhand_manipadrsHP = "KR 30 # 26B - 91" in 290
replace byhand_manipadrsHP = "CL 57An # 2An - 51" in 292
replace byhand_manipadrsHP = "KR 7U # 69 - 05" in 293
replace byhand_manipadrsHP = "DG 24C # T25 - 80" in 295
replace byhand_manipadrsHP = "DG 24C # T25 - 80" in 296
replace byhand_manipadrsHP = "CL 57A N # 2A N - 51" in 292

replace byhand_manipadrsHP = "AV 7B #" in 299
replace byhand_manipadrsHP = "CL 4 # 39 - 58" in 303
replace byhand_manipadrsHP = "DG 24A # 25 - 44" in 305
replace byhand_manipadrsHP = "KR 46 # 44 - 48" in 306
replace byhand_manipadrsHP = "CL 23 # 17B - 24" in 308
replace byhand_manipadrsHP = "TV 29D # 24D - 26" in 314
replace byhand_manipadrsHP = "CL 23A # 9 E - 111" in 317
replace byhand_manipadrsHP = "CL 72 # 3 N - 06" in 319
replace byhand_manipadrsHP = "KR 34 # 54A - 38" in 320
replace byhand_manipadrsHP = "KR 29 # 28H - 21" in 325
replace byhand_manipadrsHP = "CL 117 # 28E - 04 - 60" in 327
replace byhand_manipadrsHP = "CL 115 # 28E4 - 42" in 328
replace byhand_manipadrsHP = "CL 115 # 28E4 - 42" in 329
replace byhand_manipadrsHP = "CL 117 # 28E4 - 36" in 330
replace byhand_manipadrsHP = "CL 118 # 28E - 97" in 331
replace byhand_manipadrsHP = "KR 25 # 26B - 80" in 336
replace byhand_manipadrsHP = "CL 27 # 24A - 40" in 351
replace byhand_manipadrsHP = "KR 24B # 26B - 05" in 352
replace byhand_manipadrsHP = "KR 25B # 26B - 111" in 355
replace byhand_manipadrsHP = "KR 25B # 26B - 25" in 357
replace byhand_manipadrsHP = "KR 26Q # 72T - 03" in 358
replace byhand_manipadrsHP = "KR 25B # 26B - 52" in 367
replace byhand_manipadrsHP = "KR 25E # 26B - 52" in 368
replace byhand_manipadrsHP = "KR 26B # 26B - 126" in 369
replace byhand_manipadrsHP = "KR 25B # 26B - 85" in 373
replace byhand_manipadrsHP = "KR 25A # 25 - 120" in 374
replace byhand_manipadrsHP = "KR 25 # 25 - 48" in 378
replace byhand_manipadrsHP = "CL 26B # 27 - 26" in 380
replace byhand_manipadrsHP = "DG 24 # 25 - 104" in 386
replace byhand_manipadrsHP = "DG 24 # 25 102" in 387
replace byhand_manipadrsHP = "DG 24CT # 25 - 104" in 386
replace byhand_manipadrsHP = "DG 24C # 25 - 102" in 387
replace byhand_manipadrsHP = "KR 28 # 26B - 86" in 399
replace byhand_manipadrsHP = "CL 26C # 29A - 27" in 400
replace byhand_manipadrsHP = "KR 26H - 2 N # 72U - 49" in 401
replace byhand_manipadrsHP = "A4 N # 32 - 44 - 158" in 402
replace byhand_manipadrsHP = "AV 4 N # 32 - 44 - 158" in 402
replace byhand_manipadrsHP = "CL 22 O # 2A - 124" in 412
replace byhand_manipadrsHP = "CL 2C # 92A - 11" in 419
replace byhand_manipadrsHP = "AV 6 O # 6B - 26" in 420
replace byhand_manipadrsHP = "CL 13 O # 6 Bis O - 31" in 421
replace byhand_manipadrsHP = "CL 90 O # 15 - 96" in 422

replace byhand_manipadrsHP = "CL 9 O # 15 - 80" in 436
replace byhand_manipadrsHP = "KR 23B # 9B - 30" in 440
replace byhand_manipadrsHP = "CL 7G # 25L - 27" in 441
replace byhand_manipadrsHP = "CL 12 # 24 - 90" in 442
replace byhand_manipadrsHP = "CL 9B # 19 - 28" in 450
replace byhand_manipadrsHP = "CL 19 # 37" in 461
replace byhand_manipadrsHP = "CL 9F # 23C - 98" in 470
replace byhand_manipadrsHP = "DG 7 TA1 # 20 - H3 - 50" in 472
replace byhand_manipadrsHP = "DG 24B # 25 - 102" in 475
replace byhand_manipadrsHP = "KR 2 O # 9 E - 63" in 483
replace byhand_manipadrsHP = "KR 23A # 13 - 90" in 484
replace byhand_manipadrsHP = "KR 23A # 13 - 90" in 485
replace byhand_manipadrsHP = "CL 7A # 17C - 21" in 487
replace byhand_manipadrsHP = "CL 8 # 22 - 53" in 488
replace byhand_manipadrsHP = "KR 23 # 8 07" in 490
replace byhand_manipadrsHP = "KR 23 # 8 - 07" in 490
replace byhand_manipadrsHP = "CL 9 E # 18 - 49" in 492
replace byhand_manipadrsHP = "KR 23C # 23C 84 - 24" in 493
replace byhand_manipadrsHP = "KR 23C # 84 - 24" in 493
replace byhand_manipadrsHP = "KR 23 # 5A - 47" in 500
replace byhand_manipadrsHP = "CL 9 # 23 - 65" in 501
replace byhand_manipadrsHP = "CL 7A # 19 - 28" in 504
replace byhand_manipadrsHP = "CL 23A # 7A - 39" in 506
replace byhand_manipadrsHP = "KR 23 # 15B - 38" in 512
replace byhand_manipadrsHP = "KR 75 # 3P - 32" in 521
replace byhand_manipadrsHP = "KR 33 E # 46" in 545
replace byhand_manipadrsHP = "KR 28D # 99 - 27D - 60" in 558
replace byhand_manipadrsHP = "CL 79 # 02 - 8D" in 566
replace byhand_manipadrsHP = "KR 28 # 99 - 28 - 32" in 567


replace byhand_manipadrsHP = "CL 80 N # 26P - 46" in 569
replace byhand_manipadrsHP = "CL 81 # 26P - 40" in 570
replace byhand_manipadrsHP = "CL 93 N # 27D - 136" in 573
replace byhand_manipadrsHP = "CL 84 # 26P - 10" in 574
replace byhand_manipadrsHP = "KR 26C # 80C - 10" in 578
replace byhand_manipadrsHP = "CL 93M N # 27D - 95" in 581
replace byhand_manipadrsHP = "CL 92 # 28A- 04" in 583
replace byhand_manipadrsHP = "CL 78 # 26 - P18" in 584
replace byhand_manipadrsHP = "DG 26H5 # 72U - 74" in 601
replace byhand_manipadrsHP = "CL 89 # 28 - 24" in 603

replace byhand_manipadrsHP = "KR 25F # 70A - 41" in 609
replace byhand_manipadrsHP = "CL 17 # 26I - 3 - 11" in 614
replace byhand_manipadrsHP = "CL 85 # 27 - 112" in 623
replace byhand_manipadrsHP = "KR 27 # 27 - 23" in 626
replace byhand_manipadrsHP = "KR 28 - 3 # 95 - 52" in 630
replace byhand_manipadrsHP = "KR 26I - 3 # 72 - 69" in 631
replace byhand_manipadrsHP = "CL 85 # 28 - E3 - 41" in 632
replace byhand_manipadrsHP = "CL 91 N # 27D - 101" in 636
replace byhand_manipadrsHP = "KR 28 # 88A - 18" in 637
replace byhand_manipadrsHP = "KR 26U # 76 - 32" in 639
replace byhand_manipadrsHP = "CL 83 # 28C1 - 34" in 642
replace byhand_manipadrsHP = "KR 26R # 73A - 81" in 666
replace byhand_manipadrsHP = "KR 28 # 81 - 26P - 54" in 671
replace byhand_manipadrsHP = "CL 78 # 27C - 10" in 674
replace byhand_manipadrsHP = "CL 79 # 26P - 109" in 675
replace byhand_manipadrsHP = "CL 78 # 26P - 03" in 676
replace byhand_manipadrsHP = "CL 82 # 28D - 151" in 686
replace byhand_manipadrsHP = "CL 90 # 28E3 - 71" in 700
replace byhand_manipadrsHP = "CL 91A # 26P - 47" in 701
replace byhand_manipadrsHP = "CL 88A N # 28 - 38" in 704
replace byhand_manipadrsHP = "CL 83A # 28E3 - 83" in 712
replace byhand_manipadrsHP = "KR 27 # 78A - 59" in 714
replace byhand_manipadrsHP = "KR 28C # 2 - 88 - 10" in 716
replace byhand_manipadrsHP = "CL 90 # 27D - 107" in 718
replace byhand_manipadrsHP = "KR 84 # 36" in 720
replace byhand_manipadrsHP = "CL 85 # 26P - 121" in 737
replace byhand_manipadrsHP = "KR 7 S Bis # 72 - 44" in 741

replace byhand_manipadrsHP = "KR 7R # 73 - 34" in 744
replace byhand_manipadrsHP = "KR 7T Bis # 72 - 104" in 749
replace byhand_manipadrsHP = "KR 7 E # 70 - 107" in 750
replace byhand_manipadrsHP = "CL 7A # 76 Bis - 03" in 757
replace byhand_manipadrsHP = "KR 7B Bis # 86 - 29" in 765
replace byhand_manipadrsHP = "CL 7D # 1 - 82 - 30" in 773
replace byhand_manipadrsHP = "CL 7D 1 # 82 - 30" in 773
replace byhand_manipadrsHP = "KR 1AB # 76 - 08" in 774
replace byhand_manipadrsHP = "KR 7CB # 14 - 84 - 43" in 775
replace byhand_manipadrsHP = "KR 7R Bis # 76 - 87" in 776

replace byhand_manipadrsHP = "KR 75 # 77 - 87" in 784
replace byhand_manipadrsHP = "KR 7L Bis # 70 - 28" in 785
replace byhand_manipadrsHP = "KR 7L Bis # 76 - 103" in 786
replace byhand_manipadrsHP = "CL 82 # 7H Bis - 48" in 794
replace byhand_manipadrsHP = "KR 7T # 74 - 75" in 795
replace byhand_manipadrsHP = "CL 81 # 7 N - 35" in 803
replace byhand_manipadrsHP = "CL 81 # 7 N - 35" in 804
replace byhand_manipadrsHP = "CL 72A # 3 N - 87" in 807
replace byhand_manipadrsHP = "KR 7L Bis # 70 - 39" in 819
replace byhand_manipadrsHP = "KR 7T Bis # 72 - 124" in 821
replace byhand_manipadrsHP = "KR 7 S Bis # Z2 - 44" in 822
replace byhand_manipadrsHP = "KR 7S Bis # 72 - 44" in 822
replace byhand_manipadrsHP = "KR 7L3 # 81 - 45" in 824
replace byhand_manipadrsHP = "KR 7T Bis # 77 - 137" in 825
replace byhand_manipadrsHP = "KR 7 Bis # 72 - 85" in 832
replace byhand_manipadrsHP = "KR 7D1 # 82 - 98" in 835
replace byhand_manipadrsHP = "CL 70 # 74 Bis - 29" in 842
replace byhand_manipadrsHP = "KR 7E # 81 - 70" in 860
replace byhand_manipadrsHP = "CL 88 # 7HI - 13" in 864
replace byhand_manipadrsHP = "KR 7P Bis # 72 - 48" in 870
replace byhand_manipadrsHP = "KR 7 Bis # 86 - 04" in 871
replace byhand_manipadrsHP = "KR 7T1 # 76 - 22" in 873

replace byhand_manipadrsHP = "KR 7H # 70 - 97" in 875
replace byhand_manipadrsHP = "KR 7H # 70 - 97" in 876
replace byhand_manipadrsHP = "KR 76 # 92 - 04" in 878
replace byhand_manipadrsHP = "CL 72 # 7T Bis - 22" in 887
replace byhand_manipadrsHP = "CL 88 # 88 73BN - 13" in 895
replace byhand_manipadrsHP = "KR 7D Bis # 3 - 81 - 28" in 900
replace byhand_manipadrsHP = "KR 7D Bis # 81 - 28" in 900
replace byhand_manipadrsHP = "KR 7T # 10 - 73 - 53" in 907
replace byhand_manipadrsHP = "KR 32 # 19 - 11" in 910
replace byhand_manipadrsHP = "CL 41 # 7 E - 20" in 918
replace byhand_manipadrsHP = "KR 7U # 72 - 21" in 922
replace byhand_manipadrsHP = "KR 7L Bis # 76 - 11B" in 923
replace byhand_manipadrsHP = "KR 7P Bis # 78 - 48" in 924
replace byhand_manipadrsHP = "CL 74 # 7T Bis - 36" in 927
replace byhand_manipadrsHP = "CL 72 Bis # 7 - 72" in 932
replace byhand_manipadrsHP = "CL 72 Bis # 7 - 72" in 933
replace byhand_manipadrsHP = "CL 72 Bis # 7 - 72" in 934
replace byhand_manipadrsHP = "KR 7 Bis # 72 - 93" in 939
replace byhand_manipadrsHP = "CL 88 # 7 - 19" in 940
replace byhand_manipadrsHP = "KR 7U # 76 - 50" in 944
replace byhand_manipadrsHP = "KR 7P Bis # 81 - 05" in 947
replace byhand_manipadrsHP = "KR 7P Bis # 81 - 05" in 948
replace byhand_manipadrsHP = "KR 7M Bis # 74 - 03" in 951
replace byhand_manipadrsHP = "CL 70 # 7C Bis - 18" in 952
replace byhand_manipadrsHP = "CL 70 # 7E Bis - 14" in 955
replace byhand_manipadrsHP = "KR 7B Bis # 70 - 100" in 958
replace byhand_manipadrsHP = "KR 7D # 70 - 113" in 959
replace byhand_manipadrsHP = "KR 7 E Bis # 73 - 62" in 962
replace byhand_manipadrsHP = "KR 7D Bis # 76 - 61" in 963
replace byhand_manipadrsHP = "KR 7C # 81 - 116" in 976
replace byhand_manipadrsHP = "KR 7C # 81 - 116" in 977
replace byhand_manipadrsHP = "KR 7WB # 64 - 77" in 980
replace byhand_manipadrsHP = "KR 7L # 76 - 86" in 988
replace byhand_manipadrsHP = "KR 7 R Bis # 72 - 31" in 991
replace byhand_manipadrsHP = "KR T Bis # 76 - 11" in 995
replace byhand_manipadrsHP = "CL 70 # 70 7B - 16" in 999
replace byhand_manipadrsHP = "KR 7MR Bis # 73 - 77" in 1005

replace byhand_manipadrsHP = "KR 7B Bis # 70 - 125" in 1010
replace byhand_manipadrsHP = "KR 7 # 77 - 80" in 1012
replace byhand_manipadrsHP = "KR 7L Bis # 76 - 109" in 1013
replace byhand_manipadrsHP = "KR 7L Bis # 76 - 109" in 1014
replace byhand_manipadrsHP = "KR 7A # 84 - 95" in 1018
replace byhand_manipadrsHP = "KR 7A Bis # 72A - 30" in 1023
replace byhand_manipadrsHP = "CL 71 # 7R Bis - 56" in 1024
replace byhand_manipadrsHP = "KR 70 Bis # 70 - 99" in 1028

replace byhand_manipadrsHP = "KR 7P # 72 - 72" in 1030

replace byhand_manipadrsHP = "CL 72 # 7 Bis - 10" in 1134
replace byhand_manipadrsHP = "KR 7 E Bis # 73 - 93" in 1137
replace byhand_manipadrsHP = "KR 7 E Bis # 73 - 93 " in 1138
replace byhand_manipadrsHP = "KR 7 E Bis # 73 - 93" in 1138
replace byhand_manipadrsHP = "CL 81 # 7 Bis - 65" in 1140
replace byhand_manipadrsHP = "KR 7D 3 # 81 - 31" in 1141
replace byhand_manipadrsHP = "KR 7D3 # 81 - 31" in 1141
replace byhand_manipadrsHP = "CL 86 # 3 - 7A - 02" in 1142
replace byhand_manipadrsHP = "CL 86 # 37A - 02" in 1143
replace byhand_manipadrsHP = "CL 86 # 37A - 02" in 1142
replace byhand_manipadrsHP = "CL 88 # 7G Bis - 01" in 1149
replace byhand_manipadrsHP = "KR 7E # 66 - 19" in 1152
replace byhand_manipadrsHP = "CL 84A Bis # 86A - 24" in 1168
replace byhand_manipadrsHP = "CL 72FR # 7C - 100" in 1170
replace byhand_manipadrsHP = "KR 7Tb1 # 76 - 54" in 1186
replace byhand_manipadrsHP = "KR 28 # 36A - 37" in 1189


replace byhand_manipadrsHP = "CL 88 # 7E Bis - 17" in 1191
replace byhand_manipadrsHP = "CL 70 # 7A Bis - 29" in 1195
replace byhand_manipadrsHP = "KR 26A1 # 78 - 40" in 1215
replace byhand_manipadrsHP = "KR 26C 62 # 64 - 19" in 1216
replace byhand_manipadrsHP = "TV 103 # 26B3 - 29" in 1217
replace byhand_manipadrsHP = "KR 26A2 # 75 - 34" in 1230
replace byhand_manipadrsHP = "CL 76 # 26E - 12" in 1231
replace byhand_manipadrsHP = "CL 78AN # 26G - 27" in 1237
replace byhand_manipadrsHP = "KR 7 E # 72A - 69" in 1053

replace byhand_manipadrsHP = "KR 26C2 # 74 - 88" in 1238
replace byhand_manipadrsHP = "KR 26C1 # 74 - 27" in 1239
replace byhand_manipadrsHP = "CL 78 # 26A - 229" in 1241
replace byhand_manipadrsHP = "CL 79 # 26B3 - 21" in 1242
replace byhand_manipadrsHP = "CL 79 # 26 - B3 - 21" in 1242
replace byhand_manipadrsHP = "KR 26 # 107 - 03" in 1251

replace byhand_manipadrsHP = "CL 11A #  33" in 1257
replace byhand_manipadrsHP = "KR 26B2 # 75 - 61" in 1265
replace byhand_manipadrsHP = "CL 77 # 26A - 20" in 1266
replace byhand_manipadrsHP = "CL 78 # 26A - 12" in 1274
replace byhand_manipadrsHP = "KR 27C # 72B - 16" in 1275
replace byhand_manipadrsHP = "CL 78 # 26A - 12" in 1277
replace byhand_manipadrsHP = "KR 26A # 77 - 56" in 1279

replace byhand_manipadrsHP = "KR 26C2 # 74 - 53" in 1281
replace byhand_manipadrsHP = "KR 26F1 # 75 - 19" in 1304
replace byhand_manipadrsHP = "CL 76 # 26E - 04" in 1311
replace byhand_manipadrsHP = "KR 26B1 # 75 - 39" in 1313
replace byhand_manipadrsHP = "KR 26A1 # 78 - 76" in 1319
replace byhand_manipadrsHP = "CL 77 # 26B33 - 26" in 1322
replace byhand_manipadrsHP = "CL 77 # 26B3 - 26" in 1322
replace byhand_manipadrsHP = "KR 26B1 # 77 - 75" in 1323
replace byhand_manipadrsHP = "CL 80F # 26G3 - 34" in 1325
replace byhand_manipadrsHP = "CL 77 # 26B2 - 04" in 1326
replace byhand_manipadrsHP = "CL 80 # 80R8 - 04" in 1328
replace byhand_manipadrsHP = "CL 77 # 26A3 - 13" in 1329
replace byhand_manipadrsHP = "KR 76A # 26 -" in 1331
replace byhand_manipadrsHP = "KR 76A # 26" in 1331
replace byhand_manipadrsHP = "KR 26U # 3 - 88 - 12" in 1332
replace byhand_manipadrsHP = "KR 26B2 # 78 - 32" in 1335
replace byhand_manipadrsHP = "CL 5" in 1343
replace byhand_manipadrsHP = "KR 94B O # 3 - 17" in 1344
replace byhand_manipadrsHP = "KR 85 # 29 - 35" in 1345
replace byhand_manipadrsHP = "KR 94 # 3W O" in 1350
replace byhand_manipadrsHP = "AV 46 # 96 - 46" in 1358
replace byhand_manipadrsHP = "KR 96 # 1 - 53 O" in 1359
replace byhand_manipadrsHP = "KR 93 # 2 - 35" in 1365

replace byhand_manipadrsHP = "KR 90C O # 4 - 37" in 1366
replace byhand_manipadrsHP = "KR 96 O # 2B - 08" in 1382
replace byhand_manipadrsHP = "CL 3C # 94A - 51" in 1387
replace byhand_manipadrsHP = "CL 1Ba # 94B - 09" in 1390
replace byhand_manipadrsHP = "KR 95 # 1 Bis - 97" in 1391
replace byhand_manipadrsHP = "CL 5 O # 81B - 08" in 1397
replace byhand_manipadrsHP = "CL 3C O # 94A - 14" in 1408
replace byhand_manipadrsHP = "CL 5" in 1415
replace byhand_manipadrsHP = "" in 1415

replace byhand_manipadrsHP = "CL 1C O # 94C - 50" in 1419
replace byhand_manipadrsHP = "CL 2B O # 83B - 16" in 1433
replace byhand_manipadrsHP = "KR 80 # 1B - 34" in 1441
replace byhand_manipadrsHP = "KR 80A Bis O # 2 - 23" in 1445
replace byhand_manipadrsHP = "CL 1B O # 78A - 10" in 1454
replace byhand_manipadrsHP = "CL 1B O # 78A - 10" in 1455

drop if byhand_manipadrsHP  ==""


replace byhand_manipadrsHP = "KR 79A # 1 - 15 O" in 1487
replace byhand_manipadrsHP = "KR 83 # 1 O - 24" in 1490
replace byhand_manipadrsHP = "AV 8A1N # 53B - 09" in 1507
replace byhand_manipadrsHP = "AV 7C1 # 53A - 02" in 1509
replace byhand_manipadrsHP = "CL 53 # 7C1 - 48" in 1510
replace byhand_manipadrsHP = "CL 2A # 9 Bis" in 1511
replace byhand_manipadrsHP = "AV 6F # 53BN - 09" in 1515
replace byhand_manipadrsHP = "CL 53 N # 8AN - 90" in 1518
replace byhand_manipadrsHP = "CL 53 AN # 7C - 119" in 1524
replace byhand_manipadrsHP = "AV 8N3 # 52B - 34" in 1526
replace byhand_manipadrsHP = "AV 8N3 # 52B - 34" in 1527
replace byhand_manipadrsHP = "AV 8A1 # 50 - 190" in 1529
replace byhand_manipadrsHP = "CL 53AN # 8 - 163" in 1530
replace byhand_manipadrsHP = "AV 22 # 53A - 11" in 1535
replace byhand_manipadrsHP = "CL 53AN # 7A - 142" in 1536
replace byhand_manipadrsHP = "CL 53 # 91 - 32" in 1539
replace byhand_manipadrsHP = "AV 7C1 # 53 - 19" in 1541
replace byhand_manipadrsHP = "AV 7CN # 53 - 133" in 1542
replace byhand_manipadrsHP = "AV 8 N # 52B - 66" in 1545
replace byhand_manipadrsHP = "CL 52NA # 181 - 35" in 1546
replace byhand_manipadrsHP = "AV 7 CN # 52 - 157" in 1548
replace byhand_manipadrsHP = "AV 7C1 # 52 - 164" in 1550
replace byhand_manipadrsHP = "CL 5 # 9BN - 14" in 1551
replace byhand_manipadrsHP = "CL 52N #  7C1 - 34" in 1556
replace byhand_manipadrsHP = "CL 13 # 16" in 1559
replace byhand_manipadrsHP = "KR 8AB # 73A - 05" in 1574
replace byhand_manipadrsHP = "CL 63NA # 23" in 1591
replace byhand_manipadrsHP = "KR 39E # 48 - 48" in 1625
replace byhand_manipadrsHP = "KR 39E # 48 - 48" in 1626

replace byhand_manipadrsHP = "CL 43A # 34 - 16" in 1648
replace byhand_manipadrsHP = "CL 47 # 39A - 45" in 1699
replace byhand_manipadrsHP = "CL 37 # 39E - 52" in 1711
replace byhand_manipadrsHP = "CL 42 # 39E - 11" in 1714
replace byhand_manipadrsHP = "KR 33 # 30 - 19" in 1780

replace byhand_manipadrsHP = "CL 40 # 41D - 08" in 1855
replace byhand_manipadrsHP = "KR 41F # 41E - 39" in 1867
replace byhand_manipadrsHP = "CL 46D # 39A - 100" in 1875
replace byhand_manipadrsHP = "KR 42 # 40 - 15" in 1877
replace byhand_manipadrsHP = "CL 47 # 39G - 15" in 1882
replace byhand_manipadrsHP = "CL 37 # 39C - 12" in 1916
replace byhand_manipadrsHP = "CL 15A # 23B - 07" in 1960
replace byhand_manipadrsHP = "CL 16A # 19A - 03" in 1986
replace byhand_manipadrsHP = "CL 61" in 2022

replace byhand_manipadrsHP = "CL 61" in 2022
replace byhand_manipadrsHP = "CL 36A # 25A - 87" in 2053
replace byhand_manipadrsHP = "CL 41 # 24B - 10" in 2063
replace byhand_manipadrsHP = "CL 36 # 11F - 80" in 2066
replace byhand_manipadrsHP = "KR 1D1 # 52 - 88" in 2069
replace byhand_manipadrsHP = "CL # 13 - 12" in 2080
replace byhand_manipadrsHP = "KR 14A3 # 35 - 78" in 2084
replace byhand_manipadrsHP = "CL 41 # 17B - 27" in 2087
replace byhand_manipadrsHP = "KR 17 # 33F - 25" in 2098
replace byhand_manipadrsHP = "CL 34 # 17B - 06" in 2103
replace byhand_manipadrsHP = "KR 12 # 33A - 33" in 2115
replace byhand_manipadrsHP = "KR 17B # 33F - 124" in 2123
replace byhand_manipadrsHP = "KR 1D # 46A - 36" in 2128
replace byhand_manipadrsHP = "KR 15 # 33B - 55" in 2131
replace byhand_manipadrsHP = "CL 56F1 # 48B - 17" in 2137
replace byhand_manipadrsHP = "CL 46A # 49A - 48" in 2138
replace byhand_manipadrsHP = "KR 42A # 54C - 74" in 2149
replace byhand_manipadrsHP = "KR 42 Bis N # 54C - 83" in 2150
replace byhand_manipadrsHP = "KR 46B # 56F1 - 16" in 2154
replace byhand_manipadrsHP = "KR 46B # 56F - 120" in 2158
replace byhand_manipadrsHP = "KR 50 # 56B - 15" in 2162
replace byhand_manipadrsHP = "CL 47A # 49A - 36" in 2167
replace byhand_manipadrsHP = "CL 55N # 47C - 64" in 2172
replace byhand_manipadrsHP = "CL 56 # 49G - 78" in 2173
replace byhand_manipadrsHP = "CL 56 # 49G - 78" in 2174
replace byhand_manipadrsHP = "CL 56A # 49F - 19" in 2181
replace byhand_manipadrsHP = "CL 56D # 42C2 - 86" in 2187
replace byhand_manipadrsHP = "KR 44A # 55C - 55" in 2197
replace byhand_manipadrsHP = "CL 22" in 2201
replace byhand_manipadrsHP = "KR 11D # 22A - 35" in 2206
replace byhand_manipadrsHP = "KR 10 Bis # 18 - 70" in 2214
replace byhand_manipadrsHP = "CL 22 # 8A - 59" in 2222
replace byhand_manipadrsHP = "CL 10" in 2225
replace byhand_manipadrsHP = "CL 18 # 17 - 36" in 2230
replace byhand_manipadrsHP = "KR 26CN # 97 - 30" in 2235
replace byhand_manipadrsHP = "KR 10 # 19 - 20" in 2241
replace byhand_manipadrsHP = "KR 9 # 6 - 04" in 2243
replace byhand_manipadrsHP = "CL 22A # 8 - 58" in 2245
replace byhand_manipadrsHP = "CL 22A # 8A - 34" in 2258
replace byhand_manipadrsHP = "KR 27D # 72F - 70" in 2270
replace byhand_manipadrsHP = "CL 23 # 19A - 49" in 2275
replace byhand_manipadrsHP = "CL 21 # 17B - 61" in 2287
replace byhand_manipadrsHP = "CL 23 # 13F - 21" in 2294
replace byhand_manipadrsHP = "KR 18B # 17 - 26" in 2310
replace byhand_manipadrsHP = "CL 23 # 17F - 33" in 2316
replace byhand_manipadrsHP = "KR 28J # 72T - 116" in 2329
replace byhand_manipadrsHP = "KR 40 # 1A - 14 O" in 2342
replace byhand_manipadrsHP = "AV 12 O # 39 - 05" in 2349
replace byhand_manipadrsHP = "KR 40N # 1A - 96" in 2352
replace byhand_manipadrsHP = "CL 1F # 38B - 83" in 2354
replace byhand_manipadrsHP = "CR 39 O # 14 - 15" in 2355
replace byhand_manipadrsHP = "KR 38B # 1D - 02" in 2356
replace byhand_manipadrsHP = "CL O # 38 - C28" in 2357
replace byhand_manipadrsHP = "" in 2357
replace byhand_manipadrsHP = "DG 72C" in 2362
replace byhand_manipadrsHP = "DG 72C N" in 2366
replace byhand_manipadrsHP = "DG 72C" in 2373
replace byhand_manipadrsHP = "CL 3 O # 51 - 81" in 2375
replace byhand_manipadrsHP = "KR 55 O # 1A - 75" in 2388
replace byhand_manipadrsHP = "KR 9 # 8 O - 30" in 2397
replace byhand_manipadrsHP = "CL 13B # 4A - 11" in 2400
replace byhand_manipadrsHP = "CL 14 O # 4A - 04" in 2401
replace byhand_manipadrsHP = "KR 2 O # 21 - 36" in 2402
replace byhand_manipadrsHP = "CL 82 # 28D4 - 10" in 2406
replace byhand_manipadrsHP = "CL 82 # 28D4 - 10" in 2407
replace byhand_manipadrsHP = "KR 22A # 7A O - 84" in 2410
replace byhand_manipadrsHP = "KR 4 O # 312A - 67" in 2411
replace byhand_manipadrsHP = "KR 4 O # 312A - 67" in 2412
replace byhand_manipadrsHP = "KR 12A # 2A - 37 O" in 2415
replace byhand_manipadrsHP = "CL 23 O # 33A - 09" in 2416
replace byhand_manipadrsHP = "KR 2D # 12A - 45 O" in 2419
replace byhand_manipadrsHP = "KR 2A # 21 - 67" in 2422
replace byhand_manipadrsHP = "CL 72J # 28G - 141" in 2425
replace byhand_manipadrsHP = "CL 72J # 28G - 104" in 2428
replace byhand_manipadrsHP = "CL 72I # 28F - 98" in 2434
replace byhand_manipadrsHP = "KR 26 O # 28B - 28" in 2437
replace byhand_manipadrsHP = "CL 72K # 28H - 72" in 2439
replace byhand_manipadrsHP = "CL 30A # 11D - 12" in 2445
replace byhand_manipadrsHP = "KR 13A # 27B - 22" in 2453
replace byhand_manipadrsHP = "CL 29 # 11B - 22" in 2456
replace byhand_manipadrsHP = "CL 30 # 11G - 53" in 2461
replace byhand_manipadrsHP = "CL 38N3 # 2N - 50" in 2470
replace byhand_manipadrsHP = "KR 5 AN # 38AN - 133" in 2471
replace byhand_manipadrsHP = "KR 2N # 38N - 35" in 2474
replace byhand_manipadrsHP = "KR 69A # 13B2 - 56" in 2485
replace byhand_manipadrsHP = "CL 11C # 24D - 20" in 2494
replace byhand_manipadrsHP = "KR 23B # 9B - 63" in 2495
replace byhand_manipadrsHP = "CL 9F # 23A - 10" in 2504
replace byhand_manipadrsHP = "KR 23C # 13B - 90" in 2508
replace byhand_manipadrsHP = "KR 209E # 63" in 2517
replace byhand_manipadrsHP = "CL 9E # 23B - 41" in 2518
replace byhand_manipadrsHP = "KR 20 # 09 - 12" in 2521
replace byhand_manipadrsHP = "KR 23 # 9C - 2A" in 2523
replace byhand_manipadrsHP = "KR 18 # 10 - 44" in 2529
replace byhand_manipadrsHP = "CL 9 # 23A - 54" in 2534
replace byhand_manipadrsHP = "CL 9 # 23A - 54" in 2535
replace byhand_manipadrsHP = "CL 11 # 15 - 17" in 2536
replace byhand_manipadrsHP = "CL 55AN # 2AN - 107" in 2540
replace byhand_manipadrsHP = "KR 8BN # 72B - 17" in 2545
replace byhand_manipadrsHP = "AV 2A5 # 75EN - 06" in 2547
replace byhand_manipadrsHP = "AV 2A # 75HN - 89" in 2548
replace byhand_manipadrsHP = "CL 57BN # 2BN - 69" in 2550
replace byhand_manipadrsHP = "CL 83A # 3AN - 38" in 2552
replace byhand_manipadrsHP = "AV 2B2 # 72N Bis - 99" in 2554
replace byhand_manipadrsHP = "AV 2B2N # 74N - 34" in 2555
replace byhand_manipadrsHP = "AV 2B2 # 73N Bis - 98" in 2556
replace byhand_manipadrsHP = "AV 2B2 # 73N Bis - 99" in 2557
replace byhand_manipadrsHP = "CL 77A # 3BN - 36" in 2558
replace byhand_manipadrsHP = "CL 73CN # 2 - 82" in 2559
replace byhand_manipadrsHP = "AV 2B3 # 72N - 43" in 2562
replace byhand_manipadrsHP = "AV 2B2 # 73N Bis - 57" in 2564
replace byhand_manipadrsHP = "CL 67N # 2A - 50" in 2566
replace byhand_manipadrsHP = "KR 3DN # 71F - 12" in 2569
replace byhand_manipadrsHP = "KR 3 FN # 70 - 50" in 2571
replace byhand_manipadrsHP = "CL 59AN # 2DN - 60" in 2572
replace byhand_manipadrsHP = "CL 73 BN # 2A - 87" in 2573
replace byhand_manipadrsHP = "CL 55 AN # 2AN - 20" in 2575
replace byhand_manipadrsHP = "CL 71I # 3BN - 64" in 2577
replace byhand_manipadrsHP = "CL 74CN # 2 - 24" in 2578
replace byhand_manipadrsHP = "AV 2B2 # 73N Bis - 98" in 2582
replace byhand_manipadrsHP = "AV 2B2 # 73N Bis - 98" in 2583
replace byhand_manipadrsHP = "AV 2B1 # 73 - 65" in 2584
replace byhand_manipadrsHP = "AV 2BN # 74N - 35" in 2586
replace byhand_manipadrsHP = "CL 73AN # 2A - 50" in 2588
replace byhand_manipadrsHP = "AV 2B5 # 72N - 51" in 2589

replace byhand_manipadrsHP = "CL 73CN # 2 - 27" in 2590
replace byhand_manipadrsHP = "CL 62N # 2F - 09" in 2592
replace byhand_manipadrsHP = "AV 2A5N # 75EN - 12" in 2593
replace byhand_manipadrsHP = "AV 2A5N # 75E - 12" in 2593
replace byhand_manipadrsHP = "AV 2N # 75N - 28" in 2594
replace byhand_manipadrsHP = "AV 2B2 # 73N Bis - 59" in 2595
replace byhand_manipadrsHP = "CL 84 # 3BN - 32E" in 2596
replace byhand_manipadrsHP = "CL 60 # 2DN - 95" in 2598
replace byhand_manipadrsHP = "CL 83 # 3BN - 90" in 2599
replace byhand_manipadrsHP = "CL 72JN # 8N - 34" in 2600
replace byhand_manipadrsHP = "AV 2 # 75NE - 35" in 2601
replace byhand_manipadrsHP = "CL 75CN # 2A Bis - 63" in 2602
replace byhand_manipadrsHP = "AV 2AN # 75H - 35" in 2603
replace byhand_manipadrsHP = "AV 2B1 # 73N Bis 4 - 65" in 2604
replace byhand_manipadrsHP = "AV 2B1 # 73N Bis 4 - 65" in 2605
replace byhand_manipadrsHP = "AV 2BN # 73N Bis - 59" in 2607
replace byhand_manipadrsHP = "CL 72AN # 3 - 50" in 2611
replace byhand_manipadrsHP = "KR 3AN # 71C - 26" in 2612
replace byhand_manipadrsHP = "AV 2BL # 73 Bis - 65" in 2613
replace byhand_manipadrsHP = "AV 2B2 # 74 - 34" in 2615
replace byhand_manipadrsHP = "AV 2N # 74AN - 27" in 2619
replace byhand_manipadrsHP = "CL 11 Bis O # S2B - 09" in 2620
replace byhand_manipadrsHP = "CL 11 Bis O # 52B - 09" in 2620
replace byhand_manipadrsHP = "KR 52 E O # 9A - 56" in 2628
replace byhand_manipadrsHP = "KR 52C # 9A - 42 O" in 2630
replace byhand_manipadrsHP = "CL 38 # 5 N" in 2662
replace byhand_manipadrsHP = "KR 3AN # 34N - 146" in 2663
replace byhand_manipadrsHP = "KR 3 N # 33N - 45B8 " in 2668
replace byhand_manipadrsHP = "KR 5 N # 38 - 30B1" in 2669
replace byhand_manipadrsHP = "KR 76 # 2A - 31" in 2685

replace byhand_manipadrsHP = "KR 73 # 3C - 08" in 2702
replace byhand_manipadrsHP = "KR 69 # 2C - 15" in 2718
replace byhand_manipadrsHP = "KR 73 # 2B - 35" in 2721
replace byhand_manipadrsHP = "CL 72B # 1A4 - 52" in 2734
replace byhand_manipadrsHP = "KR 73A # 1J - 82" in 2743
replace byhand_manipadrsHP = "CL 62AN # 2N - 68" in 2748
replace byhand_manipadrsHP = "CL 69 # 4AN - 52" in 2755
replace byhand_manipadrsHP = "CL 60 # 5N - 45" in 2756
replace byhand_manipadrsHP = "CL 62 # 4AN - 24" in 2757
replace byhand_manipadrsHP = "CL 71D # 3A1N - 08" in 2760
replace byhand_manipadrsHP = "CL 71D # 3A 1N - 08" in 2760
replace byhand_manipadrsHP = "CL 69 # 4AN - 60" in 2762
replace byhand_manipadrsHP = "CL 67 # 4AN - 74" in 2764
replace byhand_manipadrsHP = "CL 68 # 4AN - 26" in 2767
replace byhand_manipadrsHP = "KR 1 # 66 - 42" in 2770
replace byhand_manipadrsHP = "CL 71L # 3DN - 13" in 2779
replace byhand_manipadrsHP = "" in 2795
replace byhand_manipadrsHP = "CL 88 # 28E6 - 90" in 2796
replace byhand_manipadrsHP = "CL 125 # 28F - 55" in 2799
replace byhand_manipadrsHP = "KR 26D # 125 - CVC - 018" in 2803
replace byhand_manipadrsHP = "KR 26PN # 124 - 156" in 2810
replace byhand_manipadrsHP = "KR 26PN # 124 - 156" in 2811
replace byhand_manipadrsHP = "KR 27 DN # 122 - 70" in 2827
replace byhand_manipadrsHP = "KR 27BN # 123 - 75" in 2836
replace byhand_manipadrsHP = "KR 26R1 # 124 - 13" in 2837
replace byhand_manipadrsHP = "KR 26M4 # 124 - 60" in 2838
replace byhand_manipadrsHP = "KR 26I2 # 123 - 83" in 2847
replace byhand_manipadrsHP = "KR 27F # 1 - 23" in 2860
replace byhand_manipadrsHP = "KR 26M1 # 121 - 88" in 2867
replace byhand_manipadrsHP = "KR 26U # 123 - 27" in 2892
replace byhand_manipadrsHP = "CL 84N # 3BN - 45" in 2906
replace byhand_manipadrsHP = "CL 8H # 104" in 2925
replace byhand_manipadrsHP = "CL 84A # 1C5 Bis - 56" in 2927
replace byhand_manipadrsHP = "KR 14A Bis # 76 - 06" in 2931
replace byhand_manipadrsHP = "CL 72L # 3BN - 51" in 2934
replace byhand_manipadrsHP = "CL 84 # 1A5 Bis - 57" in 2937
replace byhand_manipadrsHP = "CL 84N # 1H - 16" in 2938
replace byhand_manipadrsHP = "KR 1A5 Bis # 83 - 39" in 2940
replace byhand_manipadrsHP = "CL 84 # 1KN - 04" in 2943
replace byhand_manipadrsHP = "KR 19 # 4B - 73A - 10" in 2944
replace byhand_manipadrsHP = "KR 1A8 # 73A - 88" in 2945
replace byhand_manipadrsHP = "KR 1A6 # 73 - 16" in 2946
replace byhand_manipadrsHP = "DG 1 # 77 - 52" in 2947
replace byhand_manipadrsHP = "KR 1B Bis # 76 - 11" in 2949
replace byhand_manipadrsHP = "CL 84 # 1CN - 72" in 2951
replace byhand_manipadrsHP = "CL 84 # 1 LN - 72" in 2952
replace byhand_manipadrsHP = "KR 1A 8 Bis # 76 - 77" in 2953
replace byhand_manipadrsHP = "KR 5 1A # 5A - 73 - 14" in 2954
replace byhand_manipadrsHP = "KR 1A 5A # 73 - 14" in 2954
replace byhand_manipadrsHP = "CL 85 # 1A 11 - 89" in 2955
replace byhand_manipadrsHP = "KR 1A 9 Bis # 76 - 28" in 2956
replace byhand_manipadrsHP = "KR 1 A 10 # 76 - 46" in 2957
replace byhand_manipadrsHP = "KR 1A 7 Bis # 73 - A" in 2958
replace byhand_manipadrsHP = "CL 73 2 N # 1A - 46" in 2960
replace byhand_manipadrsHP = "KR 2 Bis # 23A - 36" in 2961
replace byhand_manipadrsHP = "KR 1A8 Bis # 76 - 77" in 2953
replace byhand_manipadrsHP = "KR 1A5A # 73 - 14" in 2954
replace byhand_manipadrsHP = "CL 84 # 1KN - 04" in 2972
replace byhand_manipadrsHP = "CL 84 # 1LN - 26" in 2973
replace byhand_manipadrsHP = "KR 1A4D # 76 - 06" in 2975
replace byhand_manipadrsHP = "KR 1A4D Bis # 76 - 40" in 2976
replace byhand_manipadrsHP = "CL 841D # 83 - 05" in 2980
replace byhand_manipadrsHP = "KR 10 # 73A - 53" in 2981
replace byhand_manipadrsHP = "KR 1ASF # 73A - 04" in 2983
replace byhand_manipadrsHP = "KR 14 5F # 73A - 04" in 2984
replace byhand_manipadrsHP = "CL 72B # 28E - 34" in 2988
replace byhand_manipadrsHP = "DG 71B # 26 - 40" in 3002
replace byhand_manipadrsHP = "KR 284 # 72Z3 - 21" in 3005
replace byhand_manipadrsHP = "CL 72I # 28J - 72" in 3008
replace byhand_manipadrsHP = "CR 25A # 124 - 45" in 3009
replace byhand_manipadrsHP = "CL 72B # 28D3 - 39" in 3010

replace byhand_manipadrsHP = "TV 72F # 28D1 - 24" in 3018
replace byhand_manipadrsHP = "CL 72B # 28D3 - 91" in 3025
replace byhand_manipadrsHP = "KR 28A # 1 - 72W - 52" in 3028
replace byhand_manipadrsHP = "KR 72C # 28D3 - 15" in 3038
replace byhand_manipadrsHP = "CL 72F5 # 28D3 - 22" in 3041
replace byhand_manipadrsHP = "CL 72 # 28D - 315" in 3047
replace byhand_manipadrsHP = "DG 28ND1 # 72F - 24" in 3048
replace byhand_manipadrsHP = "CL 71BN # 28D3 - 119" in 3053
replace byhand_manipadrsHP = "CL 72C # 28D3 - 99" in 3054
replace byhand_manipadrsHP = "CL 72F6 # 28EJ - 5" in 3055
replace byhand_manipadrsHP = "KR 28D4 # 72 - 22" in 3065
replace byhand_manipadrsHP = "CL 73B1 # 26A - 28" in 3078
replace byhand_manipadrsHP = "CL 72G # 28D3 - 47" in 3079
replace byhand_manipadrsHP = "CL 72F3 # 28E - 84" in 3090
replace byhand_manipadrsHP = "KR 28D2 # 73P - 73" in 3104
replace byhand_manipadrsHP = "CL 72F3 # 28D3 - 35" in 3111
replace byhand_manipadrsHP = "CL 72F5 # 28E - 44" in 3114
replace byhand_manipadrsHP = "CL 72F # 28E - 65" in 3118
replace byhand_manipadrsHP = "CL 72F2 # 28F - 29" in 3119
replace byhand_manipadrsHP = "CL 72F3 # 28D3 - 03" in 3128
replace byhand_manipadrsHP = "KR 26I # 70 - 49" in 3132
replace byhand_manipadrsHP = "CL 28 # 3 - 35" in 3133
replace byhand_manipadrsHP = "CL 72F4 # 28E - 12" in 3135
replace byhand_manipadrsHP = "CL 72F4 N # 28E - 44" in 3136
replace byhand_manipadrsHP = "KR 28C3 # 129A - 20" in 3143
replace byhand_manipadrsHP = "KR 54 O # 12 - 07" in 3155
replace byhand_manipadrsHP = "CL 70 # 28D - 60" in 3156
replace byhand_manipadrsHP = "DG 28D2 # 72A - 60" in 3164
replace byhand_manipadrsHP = "CL 70" in 3166
replace byhand_manipadrsHP = "KR 72U # 42 - 14" in 3176
replace byhand_manipadrsHP = "CL 72H Bis # 28E - 26" in 3199
replace byhand_manipadrsHP = "CL 72H Bis # 28E - 54" in 3200
replace byhand_manipadrsHP = "TV 28 # 72E2 - 50" in 3203
replace byhand_manipadrsHP = "CL 72F4 # 28E - 29" in 3207
replace byhand_manipadrsHP = "KR 28D # 71A - 57" in 3210
replace byhand_manipadrsHP = "CL 71 3 # 11 - 101" in 3211
replace byhand_manipadrsHP = "DG 26P8 # 83 - 25" in 3212
replace byhand_manipadrsHP = "CL 71 - 3 # 11 - 101" in 3211
replace byhand_manipadrsHP = "CL 72F1 # 28E - 42" in 3216
replace byhand_manipadrsHP = "CL 3 # 80 - 46" in 3221
replace byhand_manipadrsHP = "CL 72 # 28 - B70" in 3222
replace byhand_manipadrsHP = "KR 28B # 72 - 48" in 3225
replace byhand_manipadrsHP = "CL 72F2 # 28D3 - 69" in 3227
replace byhand_manipadrsHP = "CL 72U # 26I2 - 44" in 3250
replace byhand_manipadrsHP = "KR 28D1 # 72W" in 3251
replace byhand_manipadrsHP = "CL 72F2 # 28D3 - 02" in 3258
replace byhand_manipadrsHP = "CL 72 Bis # 28 - 21" in 3262
replace byhand_manipadrsHP = "CL 72F2 # 28D3 - 22" in 3263
replace byhand_manipadrsHP = "CL 70 # 26D - 10" in 3265
replace byhand_manipadrsHP = "CL 70 # 26D - 10" in 3266
replace byhand_manipadrsHP = "DG 26P6 # 87 - 17" in 3282
replace byhand_manipadrsHP = "CL 72F1 # 28 E - 16" in 3283
replace byhand_manipadrsHP = "CL 72F1 # 28D3 - 17" in 3284
replace byhand_manipadrsHP = "KR 28D6 # 72 - 35" in 3298
replace byhand_manipadrsHP = "CL 72F # 28E - 25" in 3302
replace byhand_manipadrsHP = "CL 72F # 28E - 25" in 3303
replace byhand_manipadrsHP = "KR 28E Bis # 72F4 - 21" in 3305
replace byhand_manipadrsHP = "CL 9C NR # 143 - 41" in 3312
replace byhand_manipadrsHP = "KR 50 # 5 - 173" in 3326
replace byhand_manipadrsHP = "KR 81AN # 42 - 25" in 3352
replace byhand_manipadrsHP = "KR 83B2 # 42A - 40" in 3354
replace byhand_manipadrsHP = "CL 48 Bis" in 3364

replace byhand_manipadrsHP = "KR 85C1 # 54B - 27" in 3374
replace byhand_manipadrsHP = "KR 51 O # 8D - 34" in 3377
replace byhand_manipadrsHP = "KR 85AnN# 45 - 31" in 3392
replace byhand_manipadrsHP = "KR 85AN# 45 - 31" in 3392
replace byhand_manipadrsHP = "KR 85E # 4B - 86" in 3395
replace byhand_manipadrsHP = "KR 82AN # 45 - 59" in 3426
replace byhand_manipadrsHP = "KR 85C1 # 55B - 27" in 3440
replace byhand_manipadrsHP = "KR 83CE # 46 - 24" in 3441
replace byhand_manipadrsHP = "KR 83E # 42 - 71" in 3446
replace byhand_manipadrsHP = "KR 85B # 43" in 3447
replace byhand_manipadrsHP = "CL 28 # 85C - 30" in 3449
replace byhand_manipadrsHP = "KR 82A # 45 - 01" in 3450
replace byhand_manipadrsHP = "KR 83B3 # 45 - 87" in 3458

replace byhand_manipadrsHP = "KR 83B3 # 45 - 87" in 3458
replace byhand_manipadrsHP = "KR 83A # 45 - 23" in 3469
replace byhand_manipadrsHP = "CL 42 # 95A - 15" in 3471
replace byhand_manipadrsHP = "CL 45 # 45 - 83D - 37" in 3480
replace byhand_manipadrsHP = "CL 95 # 83D - 37" in 3482
replace byhand_manipadrsHP = "CL 46 # 83B1 - 30" in 3485
replace byhand_manipadrsHP = "KR 83B1 # 48A - 23" in 3504
replace byhand_manipadrsHP = "KR 83B1 # 48A - 23" in 3505
replace byhand_manipadrsHP = "KR 83B2 # 42A - 40" in 3509
replace byhand_manipadrsHP = "KR 143 #" in 3531
*/
replace byhand_manipadrsHP = "DG 51 # 11 - 77" in 3540
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, "DG L", " DG ",. )
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, "- O", " O ",. )
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, "An", "AN",. )
replace byhand_manipadrsHP = trim(byhand_manipadrsHP)
replace byhand_manipadrsHP = itrim(byhand_manipadrsHP)
/*
replace byhand_manipadrsHP = "DG 51 # 11 - 77" in 3540
replace byhand_manipadrsHP = "KR 56 # 7 - 96 O" in 3544
replace byhand_manipadrsHP = "CL 18 # 61 - 29" in 3552
replace byhand_manipadrsHP = "CL 18AN # 55 - 96" in 3555
replace byhand_manipadrsHP = "KR 1A9n # 3A - 76" in 3568
replace byhand_manipadrsHP = "DG 51 # 9 - 46" in 3577
replace byhand_manipadrsHP = "CL 12C # 29A5 - 09" in 3583
replace byhand_manipadrsHP = "CL 9B # 29A - 22" in 3587
replace byhand_manipadrsHP = "KR 31 # 9B - 25" in 3594
replace byhand_manipadrsHP = "CL 49 # 13A - 23" in 3600
replace byhand_manipadrsHP = "KR 23 # 70C - 09" in 3647
replace byhand_manipadrsHP = "KR 23 # 70B - 03" in 3648

replace byhand_manipadrsHP = "KR 23 # 70B - 09" in 3656
replace byhand_manipadrsHP = "KR 25P # 72U - 22" in 3657

replace byhand_manipadrsHP = "DG 71AN" in 3659
replace byhand_manipadrsHP = "KR 25Q # 72U - 33" in 3661
replace byhand_manipadrsHP = "DG 71A # 23A" in 3662
replace byhand_manipadrsHP = "KR 23 # 70C - 09" in 3663
replace byhand_manipadrsHP = "KR 24 # 70 - 93" in 3665
replace byhand_manipadrsHP = "DG 70 # 23A - 41" in 3669
replace byhand_manipadrsHP = "" in 3671
replace byhand_manipadrsHP = "" in 3681

replace byhand_manipadrsHP = "KR 25 # 72U - 20" in 3683
replace byhand_manipadrsHP = "CL 2B14 # 61 - 85" in 3692
replace byhand_manipadrsHP = "CL 62B # 1A61 - 85" in 3693
replace byhand_manipadrsHP = "CL 62B # 1A - 98" in 3697
replace byhand_manipadrsHP = "CL 23 # 1A9 - 9 - 205" in 3698
replace byhand_manipadrsHP = "CL 62B # 1A9 - 205" in 3699
replace byhand_manipadrsHP = "CL 62B # 1A9 - 275" in 3701
replace byhand_manipadrsHP = "KR 1C1 # 68 - 11" in 3700
replace byhand_manipadrsHP = "CL 62B # 1A9 - 365 - 2B2" in 3702
replace byhand_manipadrsHP = "KR 1C3 # 64 - 12" in 3703
replace byhand_manipadrsHP = "CL 62B # 19 - 9 - 205" in 3705
replace byhand_manipadrsHP = "KR 1A # 1 - 24" in 3712
replace byhand_manipadrsHP = "CL 62B # 1A9 - 36" in 3714
replace byhand_manipadrsHP = "CL 62B # 1A9 - 205" in 3716
replace byhand_manipadrsHP = "CL 11 # 64C - 35" in 3720
replace byhand_manipadrsHP = "CL 62B # 1A9 - 80" in 3721
replace byhand_manipadrsHP = "CL 66 # 1A6 - 33" in 3722
replace byhand_manipadrsHP = "CL 62B # 1A9 - 80" in 3723
replace byhand_manipadrsHP = "KR 1B3 # 63 - 28" in 3724
replace byhand_manipadrsHP = "CL 62 # 1A6 - 185" in 3734
replace byhand_manipadrsHP = "CL 62B # 1-9 - 275" in 3741
replace byhand_manipadrsHP = "CL 62B # 1A - 27" in 3742
replace byhand_manipadrsHP = "CL 62 # 1A9 - 250" in 3748
replace byhand_manipadrsHP = "" in 3751
replace byhand_manipadrsHP = "CL 62B # 1A9 - 80" in 3755
replace byhand_manipadrsHP = "KR 1B2 # 64 - 21" in 3757
replace byhand_manipadrsHP = "KR 1C5 # 63 - 80" in 3759
replace byhand_manipadrsHP = "CL 62B # 1A9 - 75" in 3767
replace byhand_manipadrsHP = "CL 59 # 1 Bis - 35" in 3770
replace byhand_manipadrsHP = "AV 6B N # 35 - 34" in 3773
replace byhand_manipadrsHP = "" in 3774
replace byhand_manipadrsHP = "AV 6BN # 35 - 35" in 3776
replace byhand_manipadrsHP = "KR 26JTL # 351" in 3780
replace byhand_manipadrsHP = "KR 54 N # 32A - 81" in 3832
replace byhand_manipadrsHP = "KR 25 - 4 # 45 - 79" in 3834
replace byhand_manipadrsHP = "CL 59 # 58 - 17" in 3844
replace byhand_manipadrsHP = "CL 92 # 28D - 94" in 3845
replace byhand_manipadrsHP = "DG 66 # 33B - 35" in 3873
replace byhand_manipadrsHP = "KR 60 # 33B - 28" in 3874
replace byhand_manipadrsHP = "KR 71 # 45A - 172" in 3880
replace byhand_manipadrsHP = "KR 40A # 32A - 10" in 3890
replace byhand_manipadrsHP = "KR 101 # 12A Bis - 15" in 3898
replace byhand_manipadrsHP = "KR 7M1 # 92 - 46" in 3900
replace byhand_manipadrsHP = "KR 70 # 210" in 3925
replace byhand_manipadrsHP = "CL 54C # 41E3 - 54" in 3958

replace byhand_manipadrsHP = "KR 41BN # 45 - 81" in 3968
replace byhand_manipadrsHP = "KR 49B N # 56D - 37" in 3982

replace byhand_manipadrsHP = "CL 54 # 42C - 23" in 4000
replace byhand_manipadrsHP = "CL 47 # 49a - 89" in 4002
replace byhand_manipadrsHP = "KR 42A1 # 51 - 101" in 4007
replace byhand_manipadrsHP = "KR 45 # 48 - 47C" in 4013

replace byhand_manipadrsHP = "CL 57 # 47D - 14" in 4017
replace byhand_manipadrsHP = "KR 47 # 55C - 14" in 4019
replace byhand_manipadrsHP = "CL 56FI # 46B - 76" in 4024
replace byhand_manipadrsHP = "KR 49D # 56D - 58" in 4028
replace byhand_manipadrsHP = "KR 43 # 53 - 51" in 4046
replace byhand_manipadrsHP = "KR 48B # 51 - 40" in 4057
replace byhand_manipadrsHP = "KR 43B # 48A - 102" in 4070
replace byhand_manipadrsHP = "KR 47A # 56D - 60" in 4072
replace byhand_manipadrsHP = "CL 56J # 47D - 38" in 4078
replace byhand_manipadrsHP = "CL 47A N # 48C - 35" in 4083
replace byhand_manipadrsHP = "CL 56C # 43A - 75" in 4084

replace byhand_manipadrsHP = "CL 56C # 43A - 75" in 4085
replace byhand_manipadrsHP = "CL 56D N # 49A - 07" in 4090
replace byhand_manipadrsHP = "KR E2 # 55B - 93" in 4092
replace byhand_manipadrsHP = "CL 53 # 47D - 73" in 4095
replace byhand_manipadrsHP = "KR 52 # 49 - 54" in 4120
replace byhand_manipadrsHP = "KR 41E2 # 49 - 65" in 4121
replace byhand_manipadrsHP = "KR 43 # 48A - 28" in 4125
replace byhand_manipadrsHP = "KR 47 - 3 # 51 - 70" in 4130
replace byhand_manipadrsHP = "KR 42D1 # 49 - 42" in 4132
replace byhand_manipadrsHP = "CL 41 # 41E3 - 18" in 4136
replace byhand_manipadrsHP = "CL 54C # 49G - 06" in 4154
replace byhand_manipadrsHP = "KR 41E2 # 49 - 23" in 4158
replace byhand_manipadrsHP = "KR 41E27 # 48 - 76" in 4165
replace byhand_manipadrsHP = "KR 41E2 # 48 - 76" in 4165
replace byhand_manipadrsHP = "CL 56C # 47D - 97" in 4172
replace byhand_manipadrsHP = "CL 51 # 49 - 05" in 4179
replace byhand_manipadrsHP = "KR 42D1 # 48 - 48" in 4187
replace byhand_manipadrsHP = "KR 41E3 # 55B - 93" in 4198
replace byhand_manipadrsHP = "CL 55 # 41D2 - 8DL" in 4200
replace byhand_manipadrsHP = "KR 49 # 56 - 50" in 4212
replace byhand_manipadrsHP = "KR 41E3 # 52 - 16" in 4217
replace byhand_manipadrsHP = "KR 115 # 20 - 61" in 4224

replace byhand_manipadrsHP = "KR 103 # 12B - 106" in 4232
replace byhand_manipadrsHP = "KR 106 # 12B - 155" in 4261
replace byhand_manipadrsHP = "CL 73A2 # 3 N - 78" in 4277

replace byhand_manipadrsHP = "CL 60 # 2FN - 29" in 4278
replace byhand_manipadrsHP = "CL 7C # 2AN - 121" in 4281
replace byhand_manipadrsHP = "CL 59A N # 2AN - 29" in 4282
replace byhand_manipadrsHP = "CL 61AN # 2AN - 97" in 4283
replace byhand_manipadrsHP = "CL 70 # 2AN - 51" in 4284
replace byhand_manipadrsHP = "AV 66 # 2AN - 50" in 4285
replace byhand_manipadrsHP = "KR 23A # 101D - 12" in 4286
replace byhand_manipadrsHP = "KR 23A # 101D - 12" in 4287
replace byhand_manipadrsHP = "KR 23A # 101D - 12" in 4288
replace byhand_manipadrsHP = "CL 56 N # 2HN - 89" in 4290
replace byhand_manipadrsHP = "CL 73BN # 2A - 87" in 4292
replace byhand_manipadrsHP = "CL 62A # 2BN - 93" in 4293
replace byhand_manipadrsHP = "CL 52AN # 2EN - 95" in 4294
replace byhand_manipadrsHP = "CL 52AN # 2N - 95" in 4297
replace byhand_manipadrsHP = "AV 2A N # 75HN - 89" in 4298
replace byhand_manipadrsHP = "AV 2AN # 52 N - 75" in 4299
replace byhand_manipadrsHP = "CL 55BN # 2EN - 64" in 4305
replace byhand_manipadrsHP = "CL 61N # 2AN - 21" in 4306
replace byhand_manipadrsHP = "CL 70N # 2AN - 121" in 4307
replace byhand_manipadrsHP = "CL 55AN # 2AN - 107" in 4309
replace byhand_manipadrsHP = "CL 58 N # 2GN - 69" in 4313
replace byhand_manipadrsHP = "AV 2TN # 53DN - 05" in 4314
replace byhand_manipadrsHP = "AV 2E N # 53AN - 05" in 4315
replace byhand_manipadrsHP = "AV 2HN # 52A - 05" in 4317
replace byhand_manipadrsHP = "CL 74AN # 2A - 63" in 4319
replace byhand_manipadrsHP = "CL 59 # 2DN - 31" in 4321
replace byhand_manipadrsHP = "AV 2B1 # 73 N Bis - 65" in 4322
replace byhand_manipadrsHP = "AV 2B1 # 73N Bis - 65" in 4322
replace byhand_manipadrsHP = "CL 100C # 22B - 85" in 4323

replace byhand_manipadrsHP = "CL 106D # 20 - 85" in 4344

replace byhand_manipadrsHP = "CL 106D # 20 - 85" in 4344
replace byhand_manipadrsHP = "CL 100B # 22B - 31" in 4353
replace byhand_manipadrsHP = "CL 24M # 86 - 34" in 4364
replace byhand_manipadrsHP = "KR 24M # 86 - 34" in 4364
replace byhand_manipadrsHP = "CL 94A # 22A - 14" in 4368
replace byhand_manipadrsHP = "KR 83B1 # 45 - 87" in 4386
replace byhand_manipadrsHP = "CL 45 # 83B - 4N" in 4402
replace byhand_manipadrsHP = "CL 85 # 43B - 4N" in 4404
replace byhand_manipadrsHP = "KR 83C1 # 45 - 36" in 4418

replace byhand_manipadrsHP = "CL 30 # 3 - 75 - 59" in 4420
replace byhand_manipadrsHP = "CL 30 # 75 - 59" in 4420
replace byhand_manipadrsHP = "CL 26 # 83C - 40" in 4431
replace byhand_manipadrsHP = "CL 26 # 83C - 40" in 4432
replace byhand_manipadrsHP = "KR 83B1 # 45 - 60" in 4436

replace byhand_manipadrsHP = "CL 45 - 3 # 83D - 37" in 4441
replace byhand_manipadrsHP = "KR 26H5 # 125 - 28" in 4446
replace byhand_manipadrsHP = "CL 11 # 23 - 139" in 4475
replace byhand_manipadrsHP = "KR 26G2 # 122 - 40" in 4476
replace byhand_manipadrsHP = "KR 26G2 # 122 - 40" in 4477
replace byhand_manipadrsHP = "KR 26G2 # 122 - 04" in 4488
replace byhand_manipadrsHP = "KR 26G2 # 122 - 39" in 4492
replace byhand_manipadrsHP = "CL 103A # 23 Bis - 60" in 4500
replace byhand_manipadrsHP = "KR 26FB # 12 - 09" in 4506
replace byhand_manipadrsHP = "KR 26A Bis # 122R - 21" in 4512
replace byhand_manipadrsHP = "KR 26K1 # 122 - 94" in 4516
replace byhand_manipadrsHP = "CL 72K # 3N - 31" in 4524
replace byhand_manipadrsHP = "CL 72 # 3BN - 15" in 4527
replace byhand_manipadrsHP = "CL 72H # 2BN - 63" in 4528
replace byhand_manipadrsHP = "CL 75 # 3BN - 08" in 4529
replace byhand_manipadrsHP = "CL 77 # 3N - 42" in 4533
replace byhand_manipadrsHP = "CL 84 # 1IN - 22" in 4536
replace byhand_manipadrsHP = "KR 9 # 83F - 63" in 4537
replace byhand_manipadrsHP = "CL 72 E # 3BN - 91" in 4544
replace byhand_manipadrsHP = "CL 72 E # 3BN - 91" in 4545
replace byhand_manipadrsHP = "CL 72K # 3N - 27" in 4548
replace byhand_manipadrsHP = "CL 83A # 2 Bis N - 26" in 4551
replace byhand_manipadrsHP = "CL 82 # 2 Bis N - 26" in 4552
replace byhand_manipadrsHP = "CL 84 # 2A - 52B" in 4553
replace byhand_manipadrsHP = "CL 73 # 3BN - 39" in 4554
replace byhand_manipadrsHP = "CL 72K # 3AN - 19" in 4558
replace byhand_manipadrsHP = "CL 78 # 3BN - 20" in 4564
replace byhand_manipadrsHP = "CL 77 # 3N - 03" in 4566
*/
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, "- Bn", "BN",. )
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, " Bn", "BN",. )

/*
replace byhand_manipadrsHP = "KR 1AB Bis # 73A - 70" in 4569
replace byhand_manipadrsHP = "KR 2 BN # 72J - 10" in 4571
replace byhand_manipadrsHP = "CL 76 # 2BN - 25" in 4573
replace byhand_manipadrsHP = "CL 76 # 2BN - 34" in 4574
replace byhand_manipadrsHP = "CL 72K # 3BN - 62" in 4575
replace byhand_manipadrsHP = "CL 72F # 2BN - 58" in 4576
replace byhand_manipadrsHP = "CL 72F # 2BN - 58" in 4577
replace byhand_manipadrsHP = "CL 72F # 2BN - 58" in 4578
replace byhand_manipadrsHP = "CL 7A # 2BN - 37" in 4579
replace byhand_manipadrsHP = "CL 7A # 2BN - 37" in 4580
replace byhand_manipadrsHP = "CL 70 # 3BN - 68" in 4583
replace byhand_manipadrsHP = "CL 82 # 2BN - 55" in 4585
replace byhand_manipadrsHP = "CL 73 # 8N - 31" in 4588
replace byhand_manipadrsHP = "CL 75 # 5N - 83" in 4589
replace byhand_manipadrsHP = "CL 72J # 8GN - 38" in 4590
replace byhand_manipadrsHP = "CL 72A2 # 03AN - 90" in 4594
replace byhand_manipadrsHP = "CL 75 # 2BN - 05" in 4595
replace byhand_manipadrsHP = "CL 71I # 2 - 33" in 4599
replace byhand_manipadrsHP = "CL 71I2 # 3 - 3" in 4599
replace byhand_manipadrsHP = "CL 72F # 3BN - 15" in 4601
replace byhand_manipadrsHP = "CL 72C # C3BN - 86" in 4602
replace byhand_manipadrsHP = "CL 75 # 2BN - 20" in 4605
replace byhand_manipadrsHP = "CL 84 # 3BN - 42" in 4606
replace byhand_manipadrsHP = "CL 72G # 2BN - 75" in 4607
replace byhand_manipadrsHP = "KR 3FN # 70 - 50" in 4608
replace byhand_manipadrsHP = "CL 83A # 3B - 16" in 4609
replace byhand_manipadrsHP = "CL 83A # 3B - 16" in 4610
replace byhand_manipadrsHP = "CL 72C # 14N - 18" in 4611
replace byhand_manipadrsHP = "CL 79 # 2BN - 37" in 4614
replace byhand_manipadrsHP = "CL 79 # 2BN - 37" in 4616
replace byhand_manipadrsHP = "CL 75 # 3BN - 83" in 4618
replace byhand_manipadrsHP = "CL 7 - 2DN # 4N - 27" in 4621
replace byhand_manipadrsHP = "CL 73 # 3BN - 78" in 4631
replace byhand_manipadrsHP = "CL 81 # 2AN - 08" in 4634
replace byhand_manipadrsHP = "CL 72I # 3BN - 31" in 4638
replace byhand_manipadrsHP = "CL 72L # 2BN - 55" in 4640

replace byhand_manipadrsHP = "CL 74 # 2BN - 72" in 4646
replace byhand_manipadrsHP = "CL 76 # 3N - 28" in 4647
replace byhand_manipadrsHP = "CL 71I1 # 3AN - 29" in 4650
replace byhand_manipadrsHP = "CL 71H # 3EN - 10" in 4651

replace byhand_manipadrsHP = "CL 79 # 3BN - 22" in 4656
replace byhand_manipadrsHP = "CL 74 # 8N - 36" in 4658
replace byhand_manipadrsHP = "CL 72F # 3AN - 35" in 4660
replace byhand_manipadrsHP = "CL 71C # 3C N - 48" in 4663
replace byhand_manipadrsHP = "CL 83A # 3AN - 32" in 4664
replace byhand_manipadrsHP = "CL 72F # 3BN - 47" in 4667
replace byhand_manipadrsHP = "CL 84B # 3BN - 45" in 4669
replace byhand_manipadrsHP = "CL 84B # 12" in 4670
replace byhand_manipadrsHP = "CL 78 # 3BN - 50" in 4672
replace byhand_manipadrsHP = "CL 72 # 3N - 60" in 4676
replace byhand_manipadrsHP = "CL 46 # 3BN - 38" in 4681
replace byhand_manipadrsHP = "CL 72C # 4N - 34" in 4682
replace byhand_manipadrsHP = "CL 70A # 4CN - 24" in 4684
replace byhand_manipadrsHP = "CL 80 # 3BN - 27" in 4685
replace byhand_manipadrsHP = "CL 82 # 8 N - 56" in 4686
replace byhand_manipadrsHP = "CL 83A # 4N - 19" in 4687
replace byhand_manipadrsHP = "CL 78 # 3BN - 32" in 4691

replace byhand_manipadrsHP = "CL 78 # 3BN - 32" in 4692
replace byhand_manipadrsHP = "KR 3 EN # 70 - 90" in 4693
replace byhand_manipadrsHP = "CL 72 E # 2BN - 74" in 4694
replace byhand_manipadrsHP = "CL 72 E # 2BN - 74" in 4695
replace byhand_manipadrsHP = "CL 72 # 2BN - 79" in 4698
replace byhand_manipadrsHP = "CL 72C # 13BN - 43" in 4699
replace byhand_manipadrsHP = "CL 84 # 2BN - 45" in 4700
replace byhand_manipadrsHP = "KR 83 # 3AN - 15" in 4704
replace byhand_manipadrsHP = "CL 71 E # 3BN - 17" in 4708
replace byhand_manipadrsHP = "KR 1H N # 82 - 58" in 4713
replace byhand_manipadrsHP = "CL 72F # 3BN - 39" in 4715
replace byhand_manipadrsHP = "CL 79 # 4 N - 75" in 4725
replace byhand_manipadrsHP = "CL 72L # 3AN - 54" in 4728
replace byhand_manipadrsHP = "CL 83A # 3BN - 05" in 4735
replace byhand_manipadrsHP = "CL 74CN # 2 - 55" in 4736
replace byhand_manipadrsHP = "CL 75 # 3BN - 32" in 4738
replace byhand_manipadrsHP = "CL 72J # 3BN - 91" in 4739
replace byhand_manipadrsHP = "CL 77 # 3AN - 63" in 4742
replace byhand_manipadrsHP = "CL 82 # 5N - 02" in 4743
replace byhand_manipadrsHP = "CL 72 E # 2BN - 87" in 4747
replace byhand_manipadrsHP = "CL 70 # 3BN - 68" in 4755
replace byhand_manipadrsHP = "CL 70 # 3BN - 68" in 4756
replace byhand_manipadrsHP = "CL 72A2 # 3AN - 72" in 4758
replace byhand_manipadrsHP = "CL 84 # 4 N - 10" in 4759
replace byhand_manipadrsHP = "CL 73 N # 2B - 03" in 4763

replace byhand_manipadrsHP = "CL 82 # 2AN - 05" in 4764
replace byhand_manipadrsHP = "CL 72K # 3BN - 67" in 4767
replace byhand_manipadrsHP = "CL 79 # 3BN - 40" in 4768
replace byhand_manipadrsHP = "CL 76 # 3AN - 25" in 4769
replace byhand_manipadrsHP = "CL 83 CN # 4N - 55" in 4774
replace byhand_manipadrsHP = "CL 83A # 3BN - 89" in 4784
replace byhand_manipadrsHP = "CL 72 # 2BN - 51" in 4789
replace byhand_manipadrsHP = "CL 72 # 2BN - 51" in 4790
replace byhand_manipadrsHP = "CL 38A # 3BN - 71" in 4793
replace byhand_manipadrsHP = "CL 83D # 8N - 45" in 4798
replace byhand_manipadrsHP = "CL 72AN # 03 - 62" in 4800
replace byhand_manipadrsHP = "CL 72J # 3BN - 74" in 4802
replace byhand_manipadrsHP = "CL 80 # 3BN - 45" in 4803
replace byhand_manipadrsHP = "CL 72 # 3BN - 43" in 4805
replace byhand_manipadrsHP = "KR 73 # 2C - 90" in 4806
replace byhand_manipadrsHP = "CL 82 # 3BN - 76" in 4807
replace byhand_manipadrsHP = "AV 2A3 # 75C - 115" in 4809
replace byhand_manipadrsHP = "CL 84 # 3AN - 42" in 4810
replace byhand_manipadrsHP = "CL 75 # 2BN - 56" in 4813
replace byhand_manipadrsHP = "CL 83F1 # 9 - 133" in 4815
replace byhand_manipadrsHP = "CL 79 # 2BN - 25" in 4819
replace byhand_manipadrsHP = "CL 76 # 4 N - 65" in 4821
replace byhand_manipadrsHP = "CL 77 # 3A - 39" in 4824
replace byhand_manipadrsHP = "KR 3A1 N # 71D - 17" in 4827
replace byhand_manipadrsHP = "CL 84N # 2AN - 46" in 4828
replace byhand_manipadrsHP = "CL 70 N # 5N - 43" in 4830
replace byhand_manipadrsHP = "CL 72 N # 8N - 38" in 4831
replace byhand_manipadrsHP = "CL 80 # 2BN - 09" in 4834
replace byhand_manipadrsHP = "CL 72B # 3AN - 53" in 4839
replace byhand_manipadrsHP = "KR 28A # 10A - 27" in 4870
replace byhand_manipadrsHP = "CL 10N # 29A - 09" in 4871
replace byhand_manipadrsHP = "C 32 # 13 - 50" in 4873
replace byhand_manipadrsHP = "KR 32 # 13 - 50" in 4873
replace byhand_manipadrsHP = "KR 12C # 3 - 29B - 115" in 4874
replace byhand_manipadrsHP = "CL 12B # 42A - 32" in 4875
replace byhand_manipadrsHP = "KR 25 # 14 - 38" in 4878
replace byhand_manipadrsHP = "KR 29A5 # 12B - 41" in 4879
replace byhand_manipadrsHP = "CL 12 # 29B - 72" in 4880
replace byhand_manipadrsHP = "KR 33A # 10A - 60" in 4885

replace byhand_manipadrsHP = "CL 102 # 23B - 10" in 4923
replace byhand_manipadrsHP = "CL 102E # 23B - 57" in 4927
replace byhand_manipadrsHP = "CL 101D # 24B - 51" in 4933
replace byhand_manipadrsHP = "KR 4C N # 72B - 18" in 4947
replace byhand_manipadrsHP = "CL 102H24 # 13 - 19" in 4950
replace byhand_manipadrsHP = "CL 102B # 22B - 69" in 4964
replace byhand_manipadrsHP = "CL 124 # 26I3 - 40" in 4973
replace byhand_manipadrsHP = "CL 101B # 22B - 10" in 4988
replace byhand_manipadrsHP = "CL 101B # 22B - 10" in 4989
replace byhand_manipadrsHP = "" in 4995
replace byhand_manipadrsHP = "" in 4996
replace byhand_manipadrsHP = "CL 10 O # 24C - 100" in 5002
replace byhand_manipadrsHP = "KR 31A # 14C - 47" in 5016
replace byhand_manipadrsHP = "CL 15 # 36B" in 5029
replace byhand_manipadrsHP = "CL 15A # 39A - 61" in 5032
replace byhand_manipadrsHP = "KR 3 # 13B - 96" in 5050
replace byhand_manipadrsHP = "CL 18 # 38A - 26" in 5084

replace byhand_manipadrsHP = "CL 18 # 38A - 26" in 5085
replace byhand_manipadrsHP = "KR 38 # 18 - 36" in 5093
replace byhand_manipadrsHP = "CL 14 # 37A - 49" in 5094
replace byhand_manipadrsHP = "CL 35AN # 2AN - 107" in 5095
replace byhand_manipadrsHP = "CL 7 # 31 - 41 - 180" in 5137
replace byhand_manipadrsHP = "KR 1D # 56 - 123" in 5140
replace byhand_manipadrsHP = "KR 53 # 11A - 47" in 5194

replace byhand_manipadrsHP = "KR 40A # 12B - 77" in 5196
replace byhand_manipadrsHP = "KR 102 # 24B - 28" in 5215
replace byhand_manipadrsHP = "CL 122A # 26I3" in 5267
replace byhand_manipadrsHP = "KR 26K2 # 124 - 39" in 5273
replace byhand_manipadrsHP = "KR 26S3 # 124 - 47" in 5281
replace byhand_manipadrsHP = "CL 101C N # 22B - 62" in 5286
replace byhand_manipadrsHP = "KR 26I2 # 122 - 04" in 5293
replace byhand_manipadrsHP = "CL 94 # 20A - 98" in 5300
replace byhand_manipadrsHP = "KR 26 IG # 124 - 40" in 5304
replace byhand_manipadrsHP = "CL 23 # 114" in 5316
replace byhand_manipadrsHP = "KR 26M1 # 122 - 29" in 5317
replace byhand_manipadrsHP = "CL 120 # 26B - 210" in 5318
replace byhand_manipadrsHP = "CL 120 # 22 - 15" in 5325
replace byhand_manipadrsHP = "CL 122 # 2H - 06" in 5329
replace byhand_manipadrsHP = "KR 26G2 # 121 - 57" in 5331
replace byhand_manipadrsHP = "KR 26E # 124 - 52" in 5335
replace byhand_manipadrsHP = "KR 27D72 # 121 - 48" in 5342
replace byhand_manipadrsHP = "KR 27D # 121 - 48" in 5342
replace byhand_manipadrsHP = "CL 109Q # 79Q - 10" in 5345
replace byhand_manipadrsHP = "KR 28D3 # 120B - 33" in 5348
replace byhand_manipadrsHP = "CL 50 # 28F - 65" in 5363
replace byhand_manipadrsHP = "CL 46 # 28D - 113" in 5364
replace byhand_manipadrsHP = "CL 52 # 28E - 72" in 5365
replace byhand_manipadrsHP = "CL 48 # 28G - 50" in 5369
replace byhand_manipadrsHP = "" in 5392
replace byhand_manipadrsHP = "CL 52 # 28D - 45" in 5415
replace byhand_manipadrsHP = "CL 54 # 28 E - 66" in 5433
replace byhand_manipadrsHP = "DG 28D # 33 - 645" in 5438
replace byhand_manipadrsHP = "CL 44 # 29 - 69" in 5439
replace byhand_manipadrsHP = "TV 33 E # 29 - 35" in 5440
replace byhand_manipadrsHP = "TV 33 # 28 E - 39" in 5441


replace byhand_manipadrsHP = "TV 29 # 28D - 09" in 5442
replace byhand_manipadrsHP = "DG 29B # 33G - 51" in 5444
replace byhand_manipadrsHP = "DG 28D # 33G - 54" in 5445
replace byhand_manipadrsHP = "DG 28D # 33 - E79" in 5448
replace byhand_manipadrsHP = "DG 28D # 33E - 79" in 5448
replace byhand_manipadrsHP = "DG 28E # 29 - 42" in 5449
replace byhand_manipadrsHP = "CL 44 # 33G - 64" in 5450
replace byhand_manipadrsHP = "DG 29A # 30 - 18" in 5451
replace byhand_manipadrsHP = "DG 28E # 33 - E09" in 5452
replace byhand_manipadrsHP = "DG 28E # 33E - 09" in 5452
replace byhand_manipadrsHP = "TV 33E # 28B - 04" in 5458
replace byhand_manipadrsHP = "DG 29 # 30 - 35" in 5459
replace byhand_manipadrsHP = "DG 29 # 30 - 33" in 5460
replace byhand_manipadrsHP = "DG 29B # 50 - 44" in 5461
replace byhand_manipadrsHP = "DG 29 # 30 - 33" in 5462
replace byhand_manipadrsHP = "TV 33G # 28D - 33" in 5463
replace byhand_manipadrsHP = "DG 29B # 33E - 12" in 5466
replace byhand_manipadrsHP = "DG 28 # 33E - 24" in 5467
replace byhand_manipadrsHP = "CL 44 # 33E - 49" in 5468
replace byhand_manipadrsHP = "TV 33E # 28D - 34" in 5470
replace byhand_manipadrsHP = "DG 29 # 33E - 25" in 5472
replace byhand_manipadrsHP = "DG 29 # 33E - 25" in 5473
replace byhand_manipadrsHP = "TV 33E # 28 - 29" in 5475
replace byhand_manipadrsHP = "DG 28 E # 29 - 48" in 5476
replace byhand_manipadrsHP = "DG 28E  # 29 - 48" in 5477
replace byhand_manipadrsHP = "AV 10 N # 54 - 136" in 5480
replace byhand_manipadrsHP = "AV 8N # 52 - 81 - 85" in 5484
replace byhand_manipadrsHP = "CL 51N # 9N - 18" in 5489
replace byhand_manipadrsHP = "AV 10 N # 54 N - 134" in 5491
replace byhand_manipadrsHP = "CL 51 N # 9N - 18" in 5489
replace byhand_manipadrsHP = "AV 9 N # 46N -  20" in 5497
replace byhand_manipadrsHP = "AV 9 N # 46N - 20" in 5497
replace byhand_manipadrsHP = "CL 46C # 7N - 66" in 5499
replace byhand_manipadrsHP = "KR 4C # 65B - 13" in 5500
replace byhand_manipadrsHP = "CL 49 N # 8AN - 52" in 5504
replace byhand_manipadrsHP = "AV 9 N # 51 - 76" in 5507
replace dir_res_ = "AV 6 # 29 - 71" in 5527
replace dir_res_ = "CL 6 # 29 - 71" in 5527
replace byhand_manipadrsHP = "KR 29 # 28D - D07" in 5542
replace byhand_manipadrsHP = "KR 29 # 28D - 07" in 5542
replace byhand_manipadrsHP = "DG 65 # 8 - 28" in 5552
replace byhand_manipadrsHP = "CL 9 O # 51A - 19" in 5557
replace byhand_manipadrsHP = "CL 29 # 39A - 28" in 5571
replace byhand_manipadrsHP = "KR 29 # 75 - 36" in 5606
replace byhand_manipadrsHP = "KR 29 # 36 - 75" in 5606
replace byhand_manipadrsHP = "CL 42 # 42 - 33A - 12" in 5629
replace byhand_manipadrsHP = "KR 30A # 39 - 11" in 5631

replace byhand_manipadrsHP = "KR 28-1 # 72W - 27" in 5654
replace byhand_manipadrsHP = "CL 42B # 32B - 14" in 5664
replace byhand_manipadrsHP = "CL 36 # 30 - 25" in 5667
replace byhand_manipadrsHP = "DG # 72B - 31" in 5674
replace byhand_manipadrsHP = "CL 72F2 Bis # 28F - 40" in 5676
replace byhand_manipadrsHP = "Cl 41 # 33 - 19" in 5700
replace byhand_manipadrsHP = "KR 33B # 41 - 27" in 5701
replace byhand_manipadrsHP = "KR 29 # 39" in 5702
replace byhand_manipadrsHP = "KR 29A # 38 - 89" in 5709
replace byhand_manipadrsHP = "KR 28 # 72T - 122" in 5750

replace byhand_manipadrsHP = "" in 5753
replace byhand_manipadrsHP = "CL 37 # 34 - 58" in 5754
replace byhand_manipadrsHP = "KR 33A # 38 - 83" in 5762
replace byhand_manipadrsHP = "KR 16A # 13A - 04" in 5797
replace byhand_manipadrsHP = "KR 28C # 4 - 28 - 48" in 5808
replace byhand_manipadrsHP = "KR 1A11 # 71 - 51" in 5832
replace byhand_manipadrsHP = "KR 40B # 13A - 34A" in 5839

replace byhand_manipadrsHP = "CL 16 # 42A - 29" in 5840
replace byhand_manipadrsHP = "KR 43 # 14A - 12" in 5851
replace byhand_manipadrsHP = "KR 43A # 13C - 80" in 5854
replace byhand_manipadrsHP = "CL 15B # 41B - 49" in 5896
replace byhand_manipadrsHP = "KR 40 # 13C - 88" in 5915
replace byhand_manipadrsHP = "KR 43A # 13B - 46" in 5928
replace byhand_manipadrsHP = "CL 16 # 41C - 24" in 5931
replace byhand_manipadrsHP = "CL 15A # 41A - 24" in 5937
replace byhand_manipadrsHP = "KR 1 # 43 - 14 - 76" in 5941
replace byhand_manipadrsHP = "KR 43 # 14 - 76" in 5941
replace byhand_manipadrsHP = "KR 46B # 14A - 20" in 5951
replace byhand_manipadrsHP = "KR 46B # 14A - 20" in 5952
replace byhand_manipadrsHP = "KR 42A # 14B - 30" in 5959
replace byhand_manipadrsHP = "CL 60 # 4D Bis - 47" in 5963
replace byhand_manipadrsHP = "CL 62A # 2E1 - 26" in 5968
replace byhand_manipadrsHP = "CL 64 # 5B" in 5971
replace byhand_manipadrsHP = "CL 58B # 4D - 10" in 5978
replace byhand_manipadrsHP = "KR 4E # 52A - 65" in 5980
replace byhand_manipadrsHP = "CL 64 # 5B - 183" in 5982
replace byhand_manipadrsHP = "KR 1D1 # 61A - 55" in 5983
replace byhand_manipadrsHP = "KR 89 # 18 - 72" in 5985
replace byhand_manipadrsHP = "KR 89 # 18 - 72" in 5998
replace byhand_manipadrsHP = "KR 84 # 15 - 10" in 6011
replace byhand_manipadrsHP = "KR 29B3 # 27 - 56" in 6026

replace byhand_manipadrsHP = "KR 30 # 26B - 63" in 6038
replace byhand_manipadrsHP = "KR 29A # 26B - 108" in 6042
replace byhand_manipadrsHP = "KR 29A # 26B - 108" in 6043
replace byhand_manipadrsHP = "KR 29 # 26B - 87" in 6050
replace byhand_manipadrsHP = "CL 27 # 30 - 20" in 6054
replace byhand_manipadrsHP = "CL 29 # 36H - 18" in 6058
replace byhand_manipadrsHP = "KR 30 # 26B - 68" in 6059
replace byhand_manipadrsHP = "KR 32B # 26B - 89" in 6066
replace byhand_manipadrsHP = "KR 31A # 26B - 62" in 6079
replace byhand_manipadrsHP = "CL 5 # 1DN - 24" in 6081

replace byhand_manipadrsHP = "KR 35 # 27 - 87" in 6097
replace byhand_manipadrsHP = "CL 29 # 30A - 35" in 6106
replace byhand_manipadrsHP = "KR 33 N # 26B - 123" in 6116
replace byhand_manipadrsHP = "KR 32 # 26B - 49" in 6148
replace byhand_manipadrsHP = "CL 2 # 92A - 01" in 6165
replace byhand_manipadrsHP = "KR 28 # 26B - 19" in 6190
replace byhand_manipadrsHP = "KR 96 # 1A - 161" in 6204
replace byhand_manipadrsHP = "KR 94A1 # 1 - 94" in 6218
replace byhand_manipadrsHP = "CL 1A7C # 4 - 43" in 6221
replace byhand_manipadrsHP = "KR 94 # 2 O 1B - 03" in 6222
replace byhand_manipadrsHP = "KR 94 # 2 O - 1B - 03" in 6222
replace byhand_manipadrsHP = "KR 2B # 40A - 75" in 6235
replace byhand_manipadrsHP = "KR 39 # 1 - 24" in 6242
replace byhand_manipadrsHP = "KR 49C1 # 7 - 26" in 6251
replace byhand_manipadrsHP = "45 # 2 - 40" in 6262
replace byhand_manipadrsHP = "KR 45 # 2 - 40" in 6262
replace byhand_manipadrsHP = "CL 1A # 42 - 55" in 6265
replace byhand_manipadrsHP = "KR 40 -3  # 40 - 12" in 6280
replace byhand_manipadrsHP = "KR 47C" in 6284
replace byhand_manipadrsHP = "CL 66B # 404C" in 6285
replace byhand_manipadrsHP = "CL 13A # 66B - 60" in 6316
replace byhand_manipadrsHP = "KR 62B # 14 3 - 65" in 6317
replace byhand_manipadrsHP = "KR 64A # 14 - 28" in 6326
replace byhand_manipadrsHP = "KR 64A # 14C - 71" in 6369
replace byhand_manipadrsHP = "KR 64A # 14C - 71" in 6370
replace byhand_manipadrsHP = "CL 12 # 65A - 45" in 6378
replace byhand_manipadrsHP = "KR 64A # 14 - 75" in 6380

replace byhand_manipadrsHP = "KR 42B Bis # 54C - 94" in 6403
replace byhand_manipadrsHP = "KR 55C N # 49F - 21" in 6407
replace byhand_manipadrsHP = "KR 50 N # 55C - 03" in 6411
replace byhand_manipadrsHP = "KR 50 N # 55C - 03B" in 6412
replace byhand_manipadrsHP = "KR 56 E # 48B - 45" in 6414
replace byhand_manipadrsHP = "CL 56D # 49B - 30" in 6418
replace byhand_manipadrsHP = "KR 49H # 56I - 22" in 6423
replace byhand_manipadrsHP = "KR 42E1 # 54 - 53" in 6427
replace byhand_manipadrsHP = "KR 45 # 56E - 56" in 6421
replace byhand_manipadrsHP = "KR 45A # 56F1 - 30" in 6428
replace byhand_manipadrsHP = "CL 56I N # 49G - 08" in 6430
replace byhand_manipadrsHP = "CL 56I # 49G - 08" in 6430
replace byhand_manipadrsHP = "KR 47B # 56D - 1" in 6432
replace byhand_manipadrsHP = "KR 47A # 56D - 44" in 6439
replace byhand_manipadrsHP = "CL 56C # 49G50" in 6444
replace byhand_manipadrsHP = "CL 56C # 49G - 50" in 6444
replace byhand_manipadrsHP = "KR 42C2 # 56C - 16" in 6448
replace byhand_manipadrsHP = "KR 46A # 56G - 76" in 6450
replace byhand_manipadrsHP = "KR 49 # 55A - 73" in 6452
replace byhand_manipadrsHP = "CL 125 # 26H - 215" in 6453
replace byhand_manipadrsHP = "CL 56E # 42C2 - 56" in 6457
replace byhand_manipadrsHP = "CL 56C # 47B - 36" in 6461
replace byhand_manipadrsHP = "KR 43 # 56E - 46" in 6467
replace byhand_manipadrsHP = "CL 72 # 4N - 55" in 6475
replace byhand_manipadrsHP = "CL 56D N # 49D - 07" in 6476
replace byhand_manipadrsHP = "CL 56 # 49A - 02" in 6481
replace byhand_manipadrsHP = "CL 54 # 43C - 36" in 6490
replace byhand_manipadrsHP = "KR 50 # 55C - 03" in 6491
replace byhand_manipadrsHP = "CL 7W # 28A - 07" in 6492
replace byhand_manipadrsHP = "KR 48B # 56H - 16" in 6493
replace byhand_manipadrsHP = "KR 43 # 56E - 40" in 6494
replace byhand_manipadrsHP = "CL 56 N # 48B - 26" in 6495
replace byhand_manipadrsHP = "KR 48B N # 56I - 50" in 6497
replace byhand_manipadrsHP = "KR 56F1 # 47D - 61" in 6498
replace byhand_manipadrsHP = "CL 56CE # 49G - 42" in 6505
replace byhand_manipadrsHP = "KR 49F # 56D - 106" in 6513
replace byhand_manipadrsHP = "KR 42B Bis # 54C - 22" in 6521
replace byhand_manipadrsHP = "KR 46 # 56F1 - 31" in 6523
replace byhand_manipadrsHP = "KR 42D1 # 56E - 21" in 6525
replace byhand_manipadrsHP = "KR 42C2 # 54 - 94" in 6529

replace byhand_manipadrsHP = "CL 14C # 64B - 90" in 6540
replace byhand_manipadrsHP = "CL 12 O # 24C Bis - 51" in 6533
replace byhand_manipadrsHP = "KR 24C # 11C - 107" in 6548
replace byhand_manipadrsHP = "CL 5 O # 14 - 40" in 6549
replace byhand_manipadrsHP = "KR 27AT # 29 - 33" in 6563
replace byhand_manipadrsHP = "KR 27AT # 29 - 33" in 6564
replace byhand_manipadrsHP = "KR 27AT # 29 - 33" in 6565


replace byhand_manipadrsHP = "KR 28 # 29 - 10" in 6576
replace byhand_manipadrsHP = "KR 27 # 29 - 114" in 6583
replace byhand_manipadrsHP = "KR 3 # 01 - 03" in 6596
replace byhand_manipadrsHP = "CL 5B # 2" in 6602
replace byhand_manipadrsHP = "CL 3A # 1AB - 06" in 6603
replace byhand_manipadrsHP = "KR 1 # 26" in 6608
replace byhand_manipadrsHP = "CL 12A # 28 E - 267" in 6614
replace byhand_manipadrsHP = "CL 72Y # 28H - 29" in 6615
replace byhand_manipadrsHP = "KR 28J # 20 - 72" in 6617
replace byhand_manipadrsHP = "" in 6618
replace byhand_manipadrsHP = "KR 29B # 45A - 02" in 6623
replace byhand_manipadrsHP = "KR 28B1 # 72Y - 37" in 6625
replace byhand_manipadrsHP = "CL 76 # 28D6 - 22" in 6643
replace byhand_manipadrsHP = "KR 28-2 # 72F - 76" in 6636
replace byhand_manipadrsHP = "KR 28 - 2 # 72F - 76" in 6636
replace byhand_manipadrsHP = "KR 28 # 72T - 68" in 6651
replace byhand_manipadrsHP = "KR 29D # 43A - 18" in 6652
replace byhand_manipadrsHP = "KR 28E6W # 72U - 69" in 6671
replace byhand_manipadrsHP = "KR 28 - 2 # 72W - 22" in 6704
replace byhand_manipadrsHP = "KR 30A # 42A - 28" in 6707
replace byhand_manipadrsHP = "KR 28H N # 72J - 36" in 6732

replace byhand_manipadrsHP = "KR 28E6 # 72V - 51" in 6733
replace byhand_manipadrsHP = "KR 28EG # 72V - 31" in 6735
replace byhand_manipadrsHP = "KR 28DA # 72T - 47" in 6751
replace byhand_manipadrsHP = "KR 27G # 72W2 - 95" in 6752
replace byhand_manipadrsHP = "CL 72Z2 # 28A1 - 31" in 6765
replace byhand_manipadrsHP = "CL 72T2 # 28E - 13" in 6769
replace byhand_manipadrsHP = "KR 26I2 # 72W - 136" in 6771
replace byhand_manipadrsHP = "KR 28E3 # 72T - 16" in 6777
replace byhand_manipadrsHP = "KR 31 # 42A - 71" in 6783
replace byhand_manipadrsHP = "KR 28 - 1 # 72W - 27" in 6788
replace byhand_manipadrsHP = "KR 28 - 2 # 112 - 72" in 6803
replace byhand_manipadrsHP = "KR 28 # 72M - 18" in 6804
replace byhand_manipadrsHP = "KR 28D4 # 72 - 41" in 6809
replace byhand_manipadrsHP = "KR 28B2 # 72U - 14" in 6814
replace byhand_manipadrsHP = "KR 28G # 72ET - 98" in 6820
replace byhand_manipadrsHP = "KR 21A # 42A - 14" in 6821
replace byhand_manipadrsHP = "KR 28E3 # 72 - 77" in 6823
replace byhand_manipadrsHP = "KR 29A # 46 - 60" in 6829
replace byhand_manipadrsHP = "KR 28E2 # 72T2 - 02" in 6836
replace byhand_manipadrsHP = "KR 28E5 # 72T - 82" in 6837
replace byhand_manipadrsHP = "CL 73 # 28F - 66" in 6843
replace byhand_manipadrsHP = "CL 72U # 28 1 - 19" in 6844
replace byhand_manipadrsHP = "CL 72U # 28 - 1 - 19" in 6844
replace byhand_manipadrsHP = "CL 72D2 # 28E - 13" in 6846
replace byhand_manipadrsHP = "CL 72W # 28E1 - 01" in 6849
replace byhand_manipadrsHP = "KR 28E6 # 72D - 42" in 6850
replace byhand_manipadrsHP = "KR 28E6 # 72D - 42" in 6851
replace byhand_manipadrsHP = "CL 72 # 28E - 52" in 6858
replace byhand_manipadrsHP = "KR 28A # 72W - 18" in 6859
replace byhand_manipadrsHP = "KR 28D3 # 72W - 37" in 6864
replace byhand_manipadrsHP = "KR 283 N # 72Z - 41" in 6865
replace byhand_manipadrsHP = "CL 72 # 28E6 - 65" in 6870
replace byhand_manipadrsHP = "KR 28P3 # 72T - 39" in 6871
replace byhand_manipadrsHP = "CL 72U # 28E6 - 16" in 6872
replace byhand_manipadrsHP = "KR 28A1 # 72U - 31" in 6873
replace byhand_manipadrsHP = "KR 26B # 72B - 12" in 6877
replace byhand_manipadrsHP = "KR 28A # 72W - 01" in 6885
replace byhand_manipadrsHP = "KR 28E5 # 72TC - 32" in 6887
replace byhand_manipadrsHP = "KR 28E2 # 72V - 44" in 6892
replace byhand_manipadrsHP = "KR 28 N # 72S - 52" in 6896
replace byhand_manipadrsHP = "KR 28E1 # 72W - 30" in 6897
replace byhand_manipadrsHP = "KR 28EG # 72U - 59" in 6904
replace byhand_manipadrsHP = "TV 28F # 72L2 - 131" in 6907
replace byhand_manipadrsHP = "KR 28D4 # 72 - 22" in 6909

replace byhand_manipadrsHP = "CL 85E # 3 - 29" in 6913
replace byhand_manipadrsHP = "CL 85 # 43 - 29" in 6913
replace byhand_manipadrsHP = "CL 85 # E3 - 29" in 6913
replace byhand_manipadrsHP = "KR 28E4 # 72B - 27" in 6927
replace byhand_manipadrsHP = "KR 28 - 3 # 72Y - 67" in 6929
replace byhand_manipadrsHP = "CL 72U1 N # 28E - 52" in 6931
replace byhand_manipadrsHP = "CL 42A1 # 39E - 29" in 6932
replace byhand_manipadrsHP = "KR 28E3 # 72U - 32" in 6934
replace byhand_manipadrsHP = "KR 28 - 01 N  # 72T - 52" in 6942
replace byhand_manipadrsHP = "KR 28EG # 72V - 72" in 6944
replace byhand_manipadrsHP = "KR 28E7 # 72B - 51" in 6955

replace byhand_manipadrsHP = "KR 28E3 N # 72 - 06" in 6956
replace byhand_manipadrsHP = "KR 28A1 # 72Z - 101" in 6957
replace byhand_manipadrsHP = "KR 28F4 # 72B - 47" in 6961
replace byhand_manipadrsHP = "KR 28E7 # 72V - 37" in 6965
replace byhand_manipadrsHP = "KR 28F # 73L - 74" in 6966

replace byhand_manipadrsHP = "KR 28 - 1 # 72Z - 77" in 6969
replace byhand_manipadrsHP = "KR 28D4 # 72B - 01" in 6970
replace byhand_manipadrsHP = "CL 51 # 29A - 102" in 6980
replace byhand_manipadrsHP = "KR 28D2 # 72U - 06" in 6991
replace byhand_manipadrsHP = "KR 28E6 # 72U - 77" in 6998
replace byhand_manipadrsHP = "KR 28 E # 72U - 59" in 7004
replace byhand_manipadrsHP = "KR 28 - 4 # 2Y - 124" in 7005
replace byhand_manipadrsHP = "CL 53 # 304A - 40" in 7012
replace byhand_manipadrsHP = "CL 88 # 28G - 87" in 7020
replace byhand_manipadrsHP = "CL 72 # 28E - 94" in 7025

replace byhand_manipadrsHP = "KR 28D2 # 72U - 16" in 7027
replace byhand_manipadrsHP = "CL 72U # 282 - 07" in 7029
replace byhand_manipadrsHP = "KR 261 # 72U - 86" in 7032
replace byhand_manipadrsHP = "" in 7036
replace byhand_manipadrsHP = "CL 72T2 # 28E - 47" in 7047
replace byhand_manipadrsHP = "KR 26H1 # 8D - 80" in 7053
replace byhand_manipadrsHP = "KR 28 - 1 # 72Z - 62" in 7057
replace byhand_manipadrsHP = "KR 28 - 2 # 72Z - 27" in 7060

replace byhand_manipadrsHP = "KR 28 - 1 # 72Z - 02" in 7071
replace byhand_manipadrsHP = "KR 28 - A1 # 72W - 27" in 7074
replace byhand_manipadrsHP = "CL 72 # 28EA - 15" in 7076
replace byhand_manipadrsHP = "KR 28A1 # 72U - 31" in 7080
replace byhand_manipadrsHP = "KR 28D5 # 72Y - 52" in 7088
replace byhand_manipadrsHP = "KR 26H # 72C - 18B" in 7093
replace byhand_manipadrsHP = "CL 72A # 28B - 70" in 7094
replace byhand_manipadrsHP = "CL 72W1 # 27 - 87" in 7095
replace byhand_manipadrsHP = "KR 26H2 # 720 - 50" in 7097
replace byhand_manipadrsHP = "CL 72F2 # 28F - 64" in 7099
replace byhand_manipadrsHP = "DG 29B # 30 - 12" in 7109
replace byhand_manipadrsHP = "CL 72W1 # 27 - 32" in 7114
replace byhand_manipadrsHP = "CL 72P # 28J - 10" in 7116
replace byhand_manipadrsHP = "KR 28B # 72A - 28" in 7127
replace byhand_manipadrsHP = "CL 71A # 26 - 22" in 7130
replace byhand_manipadrsHP = "KR 28B # 72A - 11" in 7131
replace byhand_manipadrsHP = "CL 72 N # 28E - 6" in 7133
replace byhand_manipadrsHP = "KR 28 - 3 # 95 - 65" in 7136
replace byhand_manipadrsHP = "KR 28D # 72F4 - 60" in 7137
replace byhand_manipadrsHP = "KR 283 # 72 - 59" in 7143
replace byhand_manipadrsHP = "CL 72F3 # 28D3 - 80" in 7146
replace byhand_manipadrsHP = "KR 28 Bis # 72A - 52" in 7168
replace byhand_manipadrsHP = "CL 72B # 28D3 - 81" in 7177
replace byhand_manipadrsHP = "CL 72B # 28D3 - 81" in 7178
replace byhand_manipadrsHP = "KR 28E6 # 72T - 86" in 7179
replace byhand_manipadrsHP = "KR 28E6 # 72T - 86" in 7180

replace byhand_manipadrsHP = "KR 42A  N # 14 - 50" in 7219
replace byhand_manipadrsHP = "KR 42A N # 14 - 50" in 7219
replace byhand_manipadrsHP = "CL 1 # 67 - 68" in 7225
replace byhand_manipadrsHP = "CL 1 # 67 - 68" in 7226
replace byhand_manipadrsHP = "CL 1 # 67 - 68" in 7227

replace byhand_manipadrsHP = "CL 3D # 66B - 11" in 7243
replace byhand_manipadrsHP = "CL 1 # 67 - 56" in 7244
replace byhand_manipadrsHP = "CL 1A # 67 - 68B" in 7250
replace byhand_manipadrsHP = "CL 2C3 # 68 - 27" in 7252
replace byhand_manipadrsHP = "CL 2A # 66B - 120" in 7259
replace byhand_manipadrsHP = "CL 1A # 62A - 130" in 7274
replace byhand_manipadrsHP = "CL 3 # 65A - 16" in 7283
replace byhand_manipadrsHP = "KR 70 # 1 Bis 5 - 03" in 7287
replace byhand_manipadrsHP = "KR 26J1 # 123 - 38" in 7290
replace byhand_manipadrsHP = "CL 7 # 24I3 - 28" in 7292
replace byhand_manipadrsHP = "KR 26 - 14 # 124 - 21" in 7294
replace byhand_manipadrsHP = "KR 26H3 # 122 - 55" in 7295
replace byhand_manipadrsHP = "CL 123 # 26I - 336" in 7297
replace byhand_manipadrsHP = "CL 123 # 26I - 336" in 7298
replace byhand_manipadrsHP = "KR 26J1 # 124M - 51" in 7299
replace byhand_manipadrsHP = "CL 125 # 28A1 - 27" in 7300
replace byhand_manipadrsHP = "KR 26I2 # 125A - 28" in 7302
replace byhand_manipadrsHP = "CL 123 # 26H - 411" in 7303
replace byhand_manipadrsHP = "KR 26J3 # 121 - 23" in 7304
replace byhand_manipadrsHP = "KR 39 # 50A - 21" in 7308

replace byhand_manipadrsHP = "KR 38A # 52A - 21" in 7318
replace byhand_manipadrsHP = "CL 53 # 33 - 03" in 7355
replace byhand_manipadrsHP = "KR 41E1 # 52 - 53" in 7368
replace byhand_manipadrsHP = "KR 38A # 41A - 48" in 7371
replace byhand_manipadrsHP = "CL 39 # 24D - 50" in 7384
replace byhand_manipadrsHP = "KR 24D # 33F - 80" in 7387
replace byhand_manipadrsHP = "CL 34 # 24C - 16" in 7392
replace byhand_manipadrsHP = "KR 26 # 33E - 43" in 7405
replace byhand_manipadrsHP = "KR 26O # 28C - 04" in 7432

replace byhand_manipadrsHP = "CL 36A # 25A - 63" in 7433
replace byhand_manipadrsHP = "CL 36A # 25A - 63" in 7434
replace byhand_manipadrsHP = "KR 24 # 45B - 22" in 7437
replace byhand_manipadrsHP = "KR 26PD # 28C - 23" in 7440
replace byhand_manipadrsHP = "KR 26M # 2FB - 49" in 7442
replace byhand_manipadrsHP = "CL 39 # 24D - 60" in 7472
replace byhand_manipadrsHP = "CL 36 # 24D - 83" in 7475
replace byhand_manipadrsHP = "KR 26P # 28C - 27" in 7480
replace byhand_manipadrsHP = "KR 26P # 28C - 27" in 7481

replace byhand_manipadrsHP = "DG 30 # 42A - 05" in 7486
replace byhand_manipadrsHP = "DG 30 # 42A - 05" in 7487
replace byhand_manipadrsHP = "KR 26 O # 28C - 36" in 7489
replace byhand_manipadrsHP = "CL 33H # 24" in 7492
replace byhand_manipadrsHP = "KR 26 N # 28B - 20" in 7494

replace byhand_manipadrsHP = "KR 2DB1 # 47 - 57" in 7502
replace byhand_manipadrsHP = "CL 49 # 2B1 - 21" in 7503
replace byhand_manipadrsHP = "CL 49 # 2B1 - 21" in 7504
replace byhand_manipadrsHP = "CL 14" in 7508
replace byhand_manipadrsHP = "CL 49 N # 2IN - 15" in 7513
replace byhand_manipadrsHP = "CL 47 # 1D1 - 05" in 7514
replace byhand_manipadrsHP = "CL 47AN # 2G - 98" in 7515
replace byhand_manipadrsHP = "CL 52AN # 2EN - 95" in 7531
replace byhand_manipadrsHP = "KR 4D # 52A - 58" in 7532
replace byhand_manipadrsHP = "CL 54B # 47 - 76" in 7533
replace byhand_manipadrsHP = "CL 52 # 15 - 37" in 7559

replace byhand_manipadrsHP = "KR 24A # 56A - 35" in 7567
replace byhand_manipadrsHP = "KR 11 # 39 - 90" in 7583
replace byhand_manipadrsHP = "KR 41 # 10A - 16" in 7594
replace byhand_manipadrsHP = "CL 36 # 11C - 83" in 7600
replace byhand_manipadrsHP = "CL 42 " in 7607
replace byhand_manipadrsHP = "CL 42C" in 7607
replace byhand_manipadrsHP = "KR 11AF # 36 - 04" in 7615
replace byhand_manipadrsHP = "KR 11F # 36 - 04" in 7616

replace byhand_manipadrsHP = "KR 11F # 36 - 04" in 7615
replace byhand_manipadrsHP = "CL 35 # 11B - 08" in 7617
replace byhand_manipadrsHP = "CL 36 # 11C - 49" in 7621
replace byhand_manipadrsHP = "CL 44B # 10 - 26" in 7626

replace byhand_manipadrsHP = "KR 8A # 34A - 38B" in 7630
replace byhand_manipadrsHP = "CL 37 # 8A - 45" in 7636
replace byhand_manipadrsHP = " CL 35 # 8A - 12" in 7645
replace byhand_manipadrsHP = "KR 8 # 42AN - 25" in 7646
replace byhand_manipadrsHP = "KR 11C # 37 - 07" in 7654
replace byhand_manipadrsHP = "CL 46 # 11D - 49" in 7667
replace byhand_manipadrsHP = "KR 11B3 # 36 - 02" in 7672
replace byhand_manipadrsHP = "KR 11B3 # 36 - 02" in 7673
replace byhand_manipadrsHP = "KR 12AE # 36 - 17" in 7681
replace byhand_manipadrsHP = "KR 39G # 51A - 90" in 7686
replace byhand_manipadrsHP = "CL 53 # 39E - 44" in 7692
replace byhand_manipadrsHP = "KR 41A # 56 - 75" in 7701
replace byhand_manipadrsHP = "KR 38B # 55A - 68" in 7703
replace byhand_manipadrsHP = "CL 55B # 39C - 77" in 7712
replace byhand_manipadrsHP = "KR 39A # 56A - 74" in 7718
replace byhand_manipadrsHP = "CL 55 # 41E3 - 24" in 7733
replace byhand_manipadrsHP = "CL 76A # 28A - 33" in 7737
replace byhand_manipadrsHP = "KR 38B # 66A - 69" in 7739
replace byhand_manipadrsHP = "KR 46 # 49 - 14" in 7744
replace byhand_manipadrsHP = "KR 29 # 56I - 20" in 7755

replace byhand_manipadrsHP = "CL 36D # 48B - 57" in 7756
replace byhand_manipadrsHP = "KR 39B # 54B - 31" in 7760
replace byhand_manipadrsHP = "KR 39E" in 7761
replace byhand_manipadrsHP = "KR 40 # 49A - 22" in 7773
replace byhand_manipadrsHP = "KR 39A # 36A - 74" in 7776
replace byhand_manipadrsHP = "KR 39A # 56A - 74" in 7777
replace byhand_manipadrsHP = "CL 50 # 39G - 21" in 7802
replace byhand_manipadrsHP = "KR 38 # 56A - 65" in 7803
replace byhand_manipadrsHP = "KR 41b # 52 - 39" in 7807
replace byhand_manipadrsHP = "KR 41B # 52 - 39" in 7807
replace byhand_manipadrsHP = "KR 40B # 52A - 28" in 7839
replace byhand_manipadrsHP = "CL 55A # 32A - 95" in 7844
replace byhand_manipadrsHP = "CL 55A # 32A - 95" in 7845

replace byhand_manipadrsHP = "KR 32 Bis # 42C - 56" in 7881
replace byhand_manipadrsHP = "CL 46 # 33C - 04" in 7884
replace byhand_manipadrsHP = "CL 46 # 33C - 04" in 7885
replace byhand_manipadrsHP = "CL 43B # 32B - 29" in 7912
replace byhand_manipadrsHP = "CL 43B # 32B - 29" in 7913
replace byhand_manipadrsHP = "KR 33A # 42C - 40" in 7921
replace byhand_manipadrsHP = "KR 32A Bis # 42C - 103" in 7933
replace byhand_manipadrsHP = "KR 33B # 42B - 30" in 7934
replace byhand_manipadrsHP = "KR 34 N # 42B - 06" in 7940
replace byhand_manipadrsHP = "CL 43A # 73C - 26" in 7945
replace byhand_manipadrsHP = "KR 39M # 44A - 105" in 7947
replace byhand_manipadrsHP = "CL 43 # 31A - 25" in 7948
replace byhand_manipadrsHP = "CL 33C # 84C - 27" in 7954
replace byhand_manipadrsHP = "CL 48 # 34A - 28" in 7995
replace byhand_manipadrsHP = "KR 33B Bis # 46B - 22" in 8015
replace byhand_manipadrsHP = "CL 43B # 32B - 29" in 8024
replace byhand_manipadrsHP = "CL 4 Bis # 33BN - 83" in 8043

replace byhand_manipadrsHP = "CL 45 # 33B - 16" in 8059
replace byhand_manipadrsHP = "KR 42C # 33C - 14" in 8061
replace byhand_manipadrsHP = "KR 28E7  # 72 - 07" in 8086
replace byhand_manipadrsHP = "KR 33A # 33A - 15" in 8087
replace byhand_manipadrsHP = "KR 33 # 42 - 20" in 8094
replace byhand_manipadrsHP = "KR 32A Bis # 46 - 22" in 8095
replace byhand_manipadrsHP = "KR 32A # 44 - 51" in 8102
replace byhand_manipadrsHP = "CL 52 N # 4N - 27" in 8110

replace byhand_manipadrsHP = "KR 5 N # 49AN - 02" in 8111
replace byhand_manipadrsHP = "KR 20 # 13 - 08" in 8113
replace byhand_manipadrsHP = "KR 3 N # 30 N - 08" in 8116
replace byhand_manipadrsHP = "KR 2BN # 30N - 50" in 8117
replace byhand_manipadrsHP = "KR 2 # 7 - 32" in 8123
replace byhand_manipadrsHP = "KR 24 # 70A1 - 64" in 8132
replace byhand_manipadrsHP = "CL 52 # 8 N - 94T3" in 8143
replace byhand_manipadrsHP = "CL 52 # 8 N - 94T3" in 8144
replace byhand_manipadrsHP = "CL 60DN # 5N - 26" in 8147

replace byhand_manipadrsHP = "CL 70A # 1A5 - 207" in 8152
replace byhand_manipadrsHP = "KR 1A5 - 2 # 70 - 67" in 8159
replace byhand_manipadrsHP = "KR 1A5 - 2 # 70 - 67" in 8160
replace byhand_manipadrsHP = "CL 70A # 1A5 - 207" in 8161
replace byhand_manipadrsHP = "CL 70A # 1A5 - 4 - 11" in 8162
replace byhand_manipadrsHP = "CL 16 # 9AN - 37" in 8165
replace byhand_manipadrsHP = "AV 34 # 97" in 8173
replace byhand_manipadrsHP = "CL 98 # 23A - 21" in 8174
replace byhand_manipadrsHP = "CL 100 # 23A - 28" in 8178

replace byhand_manipadrsHP = "KR 19 # 12 - 53B" in 8193
replace byhand_manipadrsHP = "KR 16 # 13A - 54" in 8194
replace byhand_manipadrsHP = "CL 14 # 19 - 31B" in 8195
replace byhand_manipadrsHP = "CL 13 # 22B - 04" in 8199
replace byhand_manipadrsHP = "CL 13A # 22B - 04" in 8210
replace byhand_manipadrsHP = "KR 7 N # 46B - 08" in 8221

replace byhand_manipadrsHP = "CL 72F 3T # 28F - 56" in 8225
replace byhand_manipadrsHP = "KR 78H # 2B - 29" in 8227
replace byhand_manipadrsHP = "CL 35" in 8242
replace byhand_manipadrsHP = "KR 20" in 8250
replace byhand_manipadrsHP = "CL 88 # 7I - 27" in 8256
replace byhand_manipadrsHP = "KR 7A # 88G - 29" in 8257
replace byhand_manipadrsHP = "KR 7 B  Bis  # 66 - 22" in 8260
replace byhand_manipadrsHP = "CL 66  # 7B Bis - 56" in 8262
replace byhand_manipadrsHP = "KR 7 # 8 Bis 65 - 16" in 8263
replace byhand_manipadrsHP = "CL 69 # 7 Bis - 12" in 8267
replace byhand_manipadrsHP = "CL 66A # 7B Bis - 79" in 8268
replace byhand_manipadrsHP = "CL 69 # 7B Bis - 12" in 8269
replace byhand_manipadrsHP = "CL 69 # 7B Bis - 12" in 8270
replace byhand_manipadrsHP = "" in 8279
replace byhand_manipadrsHP = "CL 2 E O # 91 Bis - 1 - 12" in 8293
replace byhand_manipadrsHP = "CL 2 E O # 91 Bis - 1 - 12" in 8294
replace byhand_manipadrsHP = "KR 87 O #  97" in 8295
replace byhand_manipadrsHP = "KR 87 O # 97" in 8296
replace byhand_manipadrsHP = "KR 87 O # 97" in 8297
replace byhand_manipadrsHP = "KR 7A" in 8298
replace byhand_manipadrsHP = "CL 73 - 3 # 12 - 103" in 8306
replace byhand_manipadrsHP = "CL 71 # 2E - 18" in 8307
replace byhand_manipadrsHP = "CL 71F # 3EN - 11" in 8313

replace byhand_manipadrsHP = "CL 71F # 3EN - 11" in 8314
replace byhand_manipadrsHP = "KR 7AL # 76 - 85" in 8319
replace byhand_manipadrsHP = "KR 2C # 70A - 20" in 8320
replace byhand_manipadrsHP = "KR 2C # 70A - 20" in 8321
replace byhand_manipadrsHP = "KR 2C # 70A - 20" in 8322
replace byhand_manipadrsHP = "KR 2C # 70A - 20" in 8323
replace byhand_manipadrsHP = "KR 7 CN # 13BN - 21" in 8331
replace byhand_manipadrsHP = "KR 7CN # 13BN - 21" in 8331
replace byhand_manipadrsHP = "CL 73 # 2A - 21" in 8339
replace byhand_manipadrsHP = "CL 73IA # 42" in 8341
replace byhand_manipadrsHP = "CL 72 # 2C - 27" in 8347
replace byhand_manipadrsHP = "CL 73A # 1J - 82" in 8350
replace byhand_manipadrsHP = "CL 71 # 1 Bis - 2E 12" in 8355
replace byhand_manipadrsHP = "CL 71 # 1 Bis 2E - 12" in 8355

replace byhand_manipadrsHP = "CL 72 # 3AN - 16" in 8359
replace byhand_manipadrsHP = "CL 81 # 37T - 35" in 8365
replace byhand_manipadrsHP = "CL 13 # 44A - 32" in 8383
replace byhand_manipadrsHP = "KR 48A # 13A - 41" in 8384
replace byhand_manipadrsHP = "CL 13A # 49A - 20" in 8386
replace byhand_manipadrsHP = "KR 49A # 32A - 03" in 8390
replace byhand_manipadrsHP = "CL 86A # 26 - 65 - 51" in 8399
replace byhand_manipadrsHP = "KR 26H4 # 87 - 46" in 8400
replace byhand_manipadrsHP = "KR 26F1 # 77 - 46" in 8403
replace byhand_manipadrsHP = "DG 26P16 # 104 - 45" in 8406
replace byhand_manipadrsHP = "DG 26O # 87 - 66" in 8407
replace byhand_manipadrsHP = "DG 26O # 87 - 66" in 8408
replace byhand_manipadrsHP = "KR 26E # 73A - 17" in 8410
replace byhand_manipadrsHP = "DG 26G12 # 83 - 66" in 8411
replace byhand_manipadrsHP = "DG 26 O # 87 - 66" in 8412
replace byhand_manipadrsHP = "DG 26E6 # 72S - 138" in 8414
replace byhand_manipadrsHP = "DG 26P20 N # 105T - 20" in 8416
replace byhand_manipadrsHP = "DG 26B10 # 96 - 24" in 8417
replace byhand_manipadrsHP = "DG 26P6 # 96 - 59" in 8418
replace byhand_manipadrsHP = "TV 94 N # 26P16 - 25" in 8419
replace byhand_manipadrsHP = "DG 27G12 # 73 - 03" in 8420
replace byhand_manipadrsHP = "DG 27G12 # 73 - 03" in 8421
replace byhand_manipadrsHP = "DG 26H4 # 80 - 74" in 8423
replace byhand_manipadrsHP = "DG 26P11 # 96 - 11" in 8424
replace byhand_manipadrsHP = "KR 26P # 80" in 8426
replace byhand_manipadrsHP = "KR 26G6 # 73 - 67" in 8429
replace byhand_manipadrsHP = "DG 26P13 # 106 - 39" in 8430
replace byhand_manipadrsHP = "DG 26H4 # 83 - 80" in 8431
replace byhand_manipadrsHP = "DG 26P13 # 105A - 66" in 8432
replace byhand_manipadrsHP = "DG 26 N # 96 - 10" in 8433
replace byhand_manipadrsHP = "DG 26 # 96 - 10" in 8433
replace byhand_manipadrsHP = "DG 26G # 27T - 17" in 8434
replace byhand_manipadrsHP = "DG 26G8 # 27T - 17" in 8434
replace byhand_manipadrsHP = "DG 26P13 # 105 - 70" in 8439
replace byhand_manipadrsHP = "DG 26P2 # 96 - 52" in 8440
replace byhand_manipadrsHP = "DG 26G8 # 77 - 10" in 8442
replace byhand_manipadrsHP = "TV 94 # 26P16 - 25" in 8419
replace byhand_manipadrsHP = "DG 26P20 # 105T - 20" in 8416

replace byhand_manipadrsHP = "DG 26B # 93 - 20" in 8444
replace byhand_manipadrsHP = "DG 26P5 # 87 - 80" in 8445
replace byhand_manipadrsHP = "DG 26P4 # 87 - 38" in 8446
replace byhand_manipadrsHP = "DG 26B12 # 87 - 04" in 8448
replace byhand_manipadrsHP = "DG 26N # 96 - 10" in 8450
replace byhand_manipadrsHP = "DG 26I # 80 - 11" in 8451
replace byhand_manipadrsHP = "KR 26C2 # 73 - 16" in 8452
replace byhand_manipadrsHP = "DG 26B10 # 104 - 59" in 8454
replace byhand_manipadrsHP = "DG 26P16 # 105A - 45" in 8457
replace byhand_manipadrsHP = "DG 26P1 # 83 - 45" in 8459
replace byhand_manipadrsHP = "DG 26 # 80 - 75P4" in 8460
replace byhand_manipadrsHP = "DG 20P1 # 37A - 32" in 8463
replace byhand_manipadrsHP = "KR 26K # 10" in 8473
replace byhand_manipadrsHP = "DG 26H # 77 - 25" in 8476
replace byhand_manipadrsHP = "DG 26P18 # 105A - 17" in 8477


replace byhand_manipadrsHP = "CL 47 Bis # 40 - 68" in 8482
replace byhand_manipadrsHP = "CL 47 Bis N # 40 - 68" in 8482
replace byhand_manipadrsHP = "DG 28E # 54 - 51" in 8488
replace byhand_manipadrsHP = "CL 55A # 28G - 48" in 8491
replace byhand_manipadrsHP = "KR 25 # 26B - 70" in 8517
replace byhand_manipadrsHP = "KR 17 # 15A - 33" in 8528

replace byhand_manipadrsHP = "KR 23C # 12 - 02" in 8533
replace byhand_manipadrsHP = "CL 12 # 23D - 112" in 8534
replace byhand_manipadrsHP = "KR 29A # 26B - 41" in 8535
replace byhand_manipadrsHP = "CL 11 # 23C - 79" in 8538
replace byhand_manipadrsHP = "KR 23C # 13B - 92" in 8552
replace byhand_manipadrsHP = "CL 11 # 23D - 14" in 8553
replace byhand_manipadrsHP = "DG 58 # 25 - 26" in 8558
replace byhand_manipadrsHP = "KR 1B # 51 - 36" in 8563
replace byhand_manipadrsHP = "CL 45B # 1D - 82" in 8564
replace byhand_manipadrsHP = "KR 12A Bis # 62 - 20" in 8605

replace byhand_manipadrsHP = "CL 58 # 6A - 28" in 8630
replace byhand_manipadrsHP = "CL 64 # 71" in 8653
replace byhand_manipadrsHP = "CL 54 # 11A - 39" in 8658
replace byhand_manipadrsHP = "CL 49 # 8A - 32" in 8661
replace byhand_manipadrsHP = "CL 44 N " in 8663
replace byhand_manipadrsHP = "CL 42 N # 6A - 04" in 8666
replace byhand_manipadrsHP = "CL 44 - 3 # 7N - 22" in 8667
replace byhand_manipadrsHP = "AV 7CN1 # 42 - 153" in 8670
replace byhand_manipadrsHP = "CL 44 N  # 7CN1 - 48" in 8663
replace byhand_manipadrsHP = "CL 44 N " in 8663

replace byhand_manipadrsHP = "KR 65 # 1A - 93" in 8673
replace byhand_manipadrsHP = "CL 44 # 6A - 57" in 8685
replace byhand_manipadrsHP = "KR 6AC # 42 - 55" in 8686
replace byhand_manipadrsHP = "CL 41 # 6B - 00" in 8690
replace byhand_manipadrsHP = "KR 38 # 26A - 27" in 8707

replace byhand_manipadrsHP = "" in 8716
replace byhand_manipadrsHP = "" in 8717
replace byhand_manipadrsHP = "AV 2IN # 45N - 83" in 8718
replace byhand_manipadrsHP = "AV 2I # 45 - 83" in 8719
replace byhand_manipadrsHP = "AV 2IN # 45N - 83" in 8720
replace byhand_manipadrsHP = "AV 2IN # 45N - 83" in 8721
replace byhand_manipadrsHP = "CL 50 N # 3FN - 30" in 8723
replace byhand_manipadrsHP = "AV 6A # 42 - 05" in 8725
replace byhand_manipadrsHP = "AV 3 EN # 59 - 130" in 8732
replace byhand_manipadrsHP = "AV 2HN # 352 - 05" in 8734
replace byhand_manipadrsHP = "CL 50 N # 5AN - 52" in 8737
replace byhand_manipadrsHP = "CL 58 N # 2GN - 69" in 8741

replace byhand_manipadrsHP = "CL 54 # 3BN - 49" in 8748
replace byhand_manipadrsHP = "CL 47BN # 5AN - 45" in 8749
replace byhand_manipadrsHP = "CL 72 N # 3BN - 39" in 8750
replace byhand_manipadrsHP = "AV 3F N # 59 - 125" in 8753
replace byhand_manipadrsHP = "CL 52 # 4AN - 25" in 8756
*/

replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, "Bn", "BN",. )
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, " BN", "BN",. )
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, " Fn", "FN",. )

/*
replace byhand_manipadrsHP = "CL 47A N # 5AN - 60" in 8765
replace byhand_manipadrsHP = "AV 5 N # 44N - 65" in 8766
replace byhand_manipadrsHP = "CL 47BN # 5AN - 45" in 8767
replace byhand_manipadrsHP = "CL 47 N # 5CN - 23" in 8772
replace byhand_manipadrsHP = "KR 31 # 42A - 86" in 8776
replace byhand_manipadrsHP = "CL 62 # 3GN - 80" in 8777
replace byhand_manipadrsHP = "AV 4 # 47AN - 05" in 8781
replace byhand_manipadrsHP = "AV 9 N # 54 - 13" in 8787
replace byhand_manipadrsHP = "AV 9 N # 54 - 13" in 8788
replace byhand_manipadrsHP = "CL 49A # 4N - 23" in 8791
replace byhand_manipadrsHP = "AV 4BN # 47 - 64B" in 8792
replace byhand_manipadrsHP = "CL 52 N # 3FN - 131" in 8793
replace byhand_manipadrsHP = "CL 59 # 2AN - 88" in 8801
replace byhand_manipadrsHP = "AV 4B # 44N - 25" in 8811
replace byhand_manipadrsHP = "CL 44 N 3 # 3E - 07" in 8812
replace byhand_manipadrsHP = "AV 4 N # 47AN - 27" in 8813
replace byhand_manipadrsHP = "AV 6 O # 30B - 40" in 8814
replace byhand_manipadrsHP = "CL 33F # 11H - 28" in 8820
replace byhand_manipadrsHP = "KR 12 # 31A - 23" in 8838
replace byhand_manipadrsHP = "KR 15 # 33F - 23" in 8845
replace byhand_manipadrsHP = "KR 19 # 33F - 43" in 8846

replace byhand_manipadrsHP = "TV 30 # 33A - 30" in 8873
replace byhand_manipadrsHP = "KR 15 # 32B15 - 21" in 8882
replace byhand_manipadrsHP = "KR 28C # 28C - 66" in 8888
replace byhand_manipadrsHP = "KR 27A # 32 - 41P2" in 8896
replace byhand_manipadrsHP = "KR 29B # 30A - 20" in 8952
replace byhand_manipadrsHP = "CL 34B # 29B - 27" in 8962

replace byhand_manipadrsHP = "KR 31 - 3 # 32A - 31" in 8977
replace byhand_manipadrsHP = "DG 33 # 32A - 45" in 8992
replace byhand_manipadrsHP = "KR 32A # 30 - 49" in 8993
replace byhand_manipadrsHP = "KR 35D # 30 - 71" in 8994
replace byhand_manipadrsHP = "KR 32A # 30 - 85" in 8997
replace byhand_manipadrsHP = "KR 32B # 30 - 87" in 9000
replace byhand_manipadrsHP = "KR 32AD # 30 - 110" in 9006
replace byhand_manipadrsHP = "KR 34 # 30 - 53P3" in 9011
replace byhand_manipadrsHP = "KR 33B # 30 - 48" in 9013
replace byhand_manipadrsHP = "CL 13E # 68 - 90" in 9014
replace byhand_manipadrsHP = "CL 13E # 68 - 90" in 9020
replace byhand_manipadrsHP = "CL 15 # 69 - 31" in 9025
replace byhand_manipadrsHP = "" in 9045
replace byhand_manipadrsHP = "KR 41C # 30D - 95" in 9050
replace byhand_manipadrsHP = "KR 41C # 30D - 95" in 9051
replace byhand_manipadrsHP = "DG 28D7 # 28D3 - 59" in 9061
replace byhand_manipadrsHP = "DG 28D7 # 28D3 - 59" in 9062
replace byhand_manipadrsHP = "DG 28D7 # 28D3 - 59" in 9063
replace byhand_manipadrsHP = "DG 28D7 # 28D3 - 59" in 9064
replace byhand_manipadrsHP = "KR 42 # 26B - 27" in 9076
replace byhand_manipadrsHP = "CL 26 # 41B - 21" in 9094
*/

replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, "- Gn", "GN",. )
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, " Gn", "GN",. )
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, "Gn", "GN",. )
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, " GN", "GN",. )
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, "- AN", "AN",. )
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, " AN", "AN",. )

/*
replace byhand_manipadrsHP = "CL 26 # 41B - 21" in 9104
replace byhand_manipadrsHP = "CL 29 # 40B - 19" in 9106
replace byhand_manipadrsHP = "KR 41B # 26C - 2" in 9119
replace byhand_manipadrsHP = "KR 41 # 26C - 36" in 9120
replace byhand_manipadrsHP = "KR 7 # 42 N 7N - 17" in 9137
replace byhand_manipadrsHP = "KR 7 # 45N7N - 29" in 9139
replace byhand_manipadrsHP = "KR 6N # 40N - 39" in 9144
replace byhand_manipadrsHP = "KR 8 # 39 N - 16" in 9146
replace byhand_manipadrsHP = "CL 44 # 8N - 3" in 9147
replace byhand_manipadrsHP = "CL 48 N # 2GN - 21" in 9155
replace byhand_manipadrsHP = "CL 47 # 2EN - 05" in 9175
replace byhand_manipadrsHP = "AV 2 EN # 53AN - 05" in 9176

*/
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, " Fn", "FN",. )
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, "Fn", "FN",. )
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, "Am", "AM",. )
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, "- Hn", "HN",. )
replace byhand_manipadrsHP = subinstr(byhand_manipadrsHP, "Cn", "CN",. )
/*
replace byhand_manipadrsHP = "CL 58 N # 2FN - 29" in 9179
replace byhand_manipadrsHP = "CL 47B # 2AN - 52" in 9195

replace byhand_manipadrsHP = "CL 49 N # 2IN - 15" in 9197
replace byhand_manipadrsHP = "" in 9202
replace byhand_manipadrsHP = "KR 3 # 9C - 128" in 9207

replace byhand_manipadrsHP = "CL 47CN # 26N - 105" in 9209
replace byhand_manipadrsHP = "KR 1A6 # 72 - 04" in 9218
replace byhand_manipadrsHP = "KR 1A6 # 12 - 04" in 9219
replace byhand_manipadrsHP = "CL 72T1 # 27A - 80" in 9227
replace byhand_manipadrsHP = "CL 72T1 # 27A - 80" in 9228
replace byhand_manipadrsHP = "KR 72S # 27 - 59" in 9231
replace byhand_manipadrsHP = "CL 72P1 # 26N - 52" in 9232
replace byhand_manipadrsHP = "CL 72 - 11 # 27A - 66" in 9240
replace byhand_manipadrsHP = "CL 72P # 26IO1 - 79" in 9248
replace byhand_manipadrsHP = "CL 7A # 5 I Bis - 36" in 9265
replace byhand_manipadrsHP = "KR 1AD Bis # 76 - 40" in 9266
replace byhand_manipadrsHP = "KR 70B # 1C2 - 08" in 9267
replace byhand_manipadrsHP = "KR 70B # 1C2 - 08" in 9268
replace byhand_manipadrsHP = "KR 70B # 1C2 - 08" in 9269
replace byhand_manipadrsHP = "CL 71A # 2C - 87" in 9270
replace byhand_manipadrsHP = "KR 1A54 # 71 - 72" in 9279
replace byhand_manipadrsHP = "KR 1A5B # 73A - 16" in 9285
replace byhand_manipadrsHP = "CL 70A # 1I Bis - 37" in 9286
replace byhand_manipadrsHP = "CL 70C # 1J - 24" in 9288
replace byhand_manipadrsHP = "CL 15 # 48 - 21" in 9291
replace byhand_manipadrsHP = "KR 46B # 14A - 36" in 9297
replace byhand_manipadrsHP = "KR 43 # 14B - 62" in 9306
replace byhand_manipadrsHP = "KR 55 # 12A- 58" in 9307
replace byhand_manipadrsHP = "CL 15 # 45 - 18" in 9312
replace byhand_manipadrsHP = "KR 46 # 14B - 57" in 9319
replace byhand_manipadrsHP = "KR 25 # 426E - 36" in 9324
replace byhand_manipadrsHP = "CL 19A # 24B - 35" in 9356
replace byhand_manipadrsHP = "CL 44 # 13A - 19" in 9379
replace byhand_manipadrsHP = "KR 11F # 42 - 73" in 9381
replace byhand_manipadrsHP = "KR 11F # 42 - 73" in 9382
replace byhand_manipadrsHP = "KR 12BNC # 42 - 91" in 9389
replace byhand_manipadrsHP = "KR 12BNC # 42 - 91" in 9390

replace byhand_manipadrsHP = "KR 116 # 42 - 65B" in 9400
replace byhand_manipadrsHP = "PJ 7F1 # 64 - 11" in 9419
replace byhand_manipadrsHP = "CL 68 # 7A R Bis - 07" in 9433
replace byhand_manipadrsHP = "CL 7V Bis # 62 - 67" in 9448
replace byhand_manipadrsHP = "CL 64 PJ 7F # 64 - 40" in 9465
replace byhand_manipadrsHP = "CL 66 PJ 7" in 9466
replace byhand_manipadrsHP = "KR 14 # 6 - 54B" in 9469
replace byhand_manipadrsHP = "KR 7AJ # 60 - 67" in 9473
replace byhand_manipadrsHP = "KR 7T2 # 69 - 64" in 9482
replace byhand_manipadrsHP = "KR 7 - 3 # 69 -27" in 9501
replace byhand_manipadrsHP = "CL 43 # 4B - 50" in 9521

replace byhand_manipadrsHP = "CL 44A # 430" in 9530
replace byhand_manipadrsHP = "CL 16B # 49A - 57" in 9550
replace byhand_manipadrsHP = "CL 17 N # 46A - 45" in 9568

replace byhand_manipadrsHP = "CL 79 # 26G3 - 27" in 9593
replace byhand_manipadrsHP = "KR 26G2 # 73B - 11" in 9596
replace byhand_manipadrsHP = "KR 26D # 80c - 17" in 9597
replace byhand_manipadrsHP = "KR 26D # 80C - 17" in 9597
replace byhand_manipadrsHP = "CL 80B # 26D - 95" in 9600
replace byhand_manipadrsHP = "CL 80A # 26G2 - 58" in 9601
replace byhand_manipadrsHP = "CL 10R # 27D - 11" in 9604
replace byhand_manipadrsHP = "KR 284 # 103 - 55" in 9606
replace byhand_manipadrsHP = "KR 284 # 103 - 55" in 9607
replace byhand_manipadrsHP = "KR 27 # 82 - 26P - 61" in 9608
replace byhand_manipadrsHP = "CL 108 # 27G - 24" in 9617

replace byhand_manipadrsHP = "KR 96A # 26I1 - 27" in 9619
replace byhand_manipadrsHP = "CL 96A # 26 1 - 27" in 9620
replace byhand_manipadrsHP = "CL 83 # 27F - 24" in 9644
replace byhand_manipadrsHP = "CL 112 # 27F - 19" in 9648

replace byhand_manipadrsHP = "KR 28 # 72L - 06" in 9653
replace byhand_manipadrsHP = "KR 28E3 # 72T - 64" in 9656
replace byhand_manipadrsHP = "KR 28E3 # 72T - 64" in 9657
replace byhand_manipadrsHP = "CL 104 # 27C - 17" in 9658
replace byhand_manipadrsHP = "CL 80 # 28D4 - 04" in 9659
replace byhand_manipadrsHP = "CL 111 # 28  4 - 31" in 9664
replace byhand_manipadrsHP = "CL 105 # 27D - 87" in 9668

replace byhand_manipadrsHP = "KR 28 2 # 103 - 78" in 9692
replace byhand_manipadrsHP = "CL 72 # 7R - 28" in 9694
replace byhand_manipadrsHP = "CL 110 # 28 4 - 73" in 9696
replace byhand_manipadrsHP = "PJ 7F # 68A - 53" in 9725

replace byhand_manipadrsHP = "CL 49A N # 32A - 61" in 9729
replace byhand_manipadrsHP = "CL 50 # 32A - 27" in 9749
replace byhand_manipadrsHP = "CL 53 # 32A - 119" in 9768
replace byhand_manipadrsHP = "CL 50 # 32A - 116" in 9773

replace byhand_manipadrsHP = "CL 54 # 30B - 94" in 9778
replace byhand_manipadrsHP = "CL 48A # 30B - 05" in 9790
replace byhand_manipadrsHP = "C 49 # 24 - 25" in 9798
replace byhand_manipadrsHP = "CL 49 # 24 - 25" in 9798
replace byhand_manipadrsHP = "CL 50 # 33 - 32" in 9800
replace byhand_manipadrsHP = "CL 48A # 32A - 15" in 9808

replace byhand_manipadrsHP = "CL 32A # 30 - 39" in 9839
replace byhand_manipadrsHP = "DG 29A # 27 - 89" in 9860
replace byhand_manipadrsHP = "CL 34 # 29A - 40" in 9864
replace byhand_manipadrsHP = "CL 34C # 29D - 46" in 9873
replace byhand_manipadrsHP = "KR 32 # 34 - 105" in 9878
replace byhand_manipadrsHP = "TV 26 # 28A - 107" in 9886
replace byhand_manipadrsHP = "TV 26 # 28A - 107" in 9887
replace byhand_manipadrsHP = "CL 35D # 29B - 57" in 9888


replace byhand_manipadrsHP = "KR 93 # 102" in 9895
replace byhand_manipadrsHP = "CL 56 # 86CI - 72" in 9967
replace byhand_manipadrsHP = "CL 34 4 # 98B - 35" in 9980
replace byhand_manipadrsHP = "CL 34 4 # 98B - 35" in 9981
replace byhand_manipadrsHP = "KR 95 # 50B - 45" in 9986
replace byhand_manipadrsHP = "CL 28 # 96 - 161" in 9995


replace byhand_manipadrsHP = "CL 44A # 430" in 9530
replace byhand_manipadrsHP = "CL 16B # 49A - 57" in 9550
replace byhand_manipadrsHP = "CL 17 N # 46A - 45" in 9568
replace byhand_manipadrsHP = "CL 79 # 26G3 - 27" in 9593
replace byhand_manipadrsHP = "KR 26G2 # 73B - 11" in 9596
replace byhand_manipadrsHP = "KR 26D # 80c - 17" in 9597
replace byhand_manipadrsHP = "KR 26D # 80C - 17" in 9597
replace byhand_manipadrsHP = "CL 80B # 26D - 95" in 9600
replace byhand_manipadrsHP = "CL 80A # 26G2 - 58" in 9601
replace byhand_manipadrsHP = "CL 10R # 27D - 11" in 9604
replace byhand_manipadrsHP = "KR 284 # 103 - 55" in 9606
replace byhand_manipadrsHP = "KR 284 # 103 - 55" in 9607
replace byhand_manipadrsHP = "KR 27 # 82 - 26P - 61" in 9608
replace byhand_manipadrsHP = "CL 108 # 27G - 24" in 9617
replace byhand_manipadrsHP = "KR 96A # 26I1 - 27" in 9619
replace byhand_manipadrsHP = "CL 96A # 26 1 - 27" in 9620
replace byhand_manipadrsHP = "CL 83 # 27F - 24" in 9644
replace byhand_manipadrsHP = "CL 112 # 27F - 19" in 9648
replace byhand_manipadrsHP = "KR 28 # 72L - 06" in 9653
replace byhand_manipadrsHP = "KR 28E3 # 72T - 64" in 9656
replace byhand_manipadrsHP = "KR 28E3 # 72T - 64" in 9657
replace byhand_manipadrsHP = "CL 104 # 27C - 17" in 9658
replace byhand_manipadrsHP = "CL 80 # 28D4 - 04" in 9659
replace byhand_manipadrsHP = "CL 111 # 28  4 - 31" in 9664
replace byhand_manipadrsHP = "CL 105 # 27D - 87" in 9668
replace byhand_manipadrsHP = "KR 28 2 # 103 - 78" in 9692
replace byhand_manipadrsHP = "CL 72 # 7R - 28" in 9694
replace byhand_manipadrsHP = "CL 110 # 28 4 - 73" in 9696
replace byhand_manipadrsHP = "PJ 7F # 68A - 53" in 9725
replace byhand_manipadrsHP = "CL 49A N # 32A - 61" in 9729
replace byhand_manipadrsHP = "CL 50 # 32A - 27" in 9749
replace byhand_manipadrsHP = "CL 53 # 32A - 119" in 9768
replace byhand_manipadrsHP = "CL 50 # 32A - 116" in 9773
replace byhand_manipadrsHP = "CL 54 # 30B - 94" in 9778
replace byhand_manipadrsHP = "CL 48A # 30B - 05" in 9790
replace byhand_manipadrsHP = "C 49 # 24 - 25" in 9798
replace byhand_manipadrsHP = "CL 49 # 24 - 25" in 9798
replace byhand_manipadrsHP = "CL 50 # 33 - 32" in 9800
replace byhand_manipadrsHP = "CL 48A # 32A - 15" in 9808
replace byhand_manipadrsHP = "CL 32A # 30 - 39" in 9839
replace byhand_manipadrsHP = "DG 29A # 27 - 89" in 9860
replace byhand_manipadrsHP = "CL 34 # 29A - 40" in 9864
replace byhand_manipadrsHP = "CL 34C # 29D - 46" in 9873
replace byhand_manipadrsHP = "KR 32 # 34 - 105" in 9878
replace byhand_manipadrsHP = "TV 26 # 28A - 107" in 9886
replace byhand_manipadrsHP = "TV 26 # 28A - 107" in 9887
replace byhand_manipadrsHP = "CL 35D # 29B - 57" in 9888
replace byhand_manipadrsHP = "KR 93 # 102" in 9895
replace byhand_manipadrsHP = "CL 56 # 86CI - 72" in 9967
replace byhand_manipadrsHP = "CL 34 4 # 98B - 35" in 9980
replace byhand_manipadrsHP = "CL 34 4 # 98B - 35" in 9981
replace byhand_manipadrsHP = "KR 95 # 50B - 45" in 9986
replace byhand_manipadrsHP = "CL 28 # 96 - 161" in 9995
replace byhand_manipadrsHP = "CL 45 # 86 - 38" in 10024
replace byhand_manipadrsHP = "DG 22 # 30 - 90" in 10034
replace byhand_manipadrsHP = "CL 54D # 85C1 - 60" in 10057
replace byhand_manipadrsHP = "CL 54D # 85C1 - 60" in 10058
replace byhand_manipadrsHP = "CL 54D # 85C1 - 60" in 10059
replace byhand_manipadrsHP = "CL 54D # 85C1 - 60" in 10060
replace byhand_manipadrsHP = "CL 54D # 85C1 - 60" in 10061
replace byhand_manipadrsHP = "CL 54D # 85C1 - 60" in 10062
replace byhand_manipadrsHP = "KR 97 # 42 - 57" in 10072
replace byhand_manipadrsHP = "CL 19 # 50C - 36" in 10076
replace byhand_manipadrsHP = "CL 10 O # 50 - 16" in 10080
replace byhand_manipadrsHP = "KR 5AN # 6N - 41" in 10082
replace byhand_manipadrsHP = "CL 13 O # 49C - 14" in 10083
replace byhand_manipadrsHP = "CL 13 O # 49C - 14" in 10084
replace byhand_manipadrsHP = "CL 13 O # 46A - 59" in 10098
replace byhand_manipadrsHP = "KR 1AW # 10 - 60" in 10099
replace byhand_manipadrsHP = "KR 1AW # 10 - 60" in 10100
replace byhand_manipadrsHP = "CL 12 # 16B - 40" in 10111
replace byhand_manipadrsHP = "KR 26I # 72C - 45" in 10114
replace byhand_manipadrsHP = "KR 26 - 1 # 72W - 22" in 10116
replace byhand_manipadrsHP = "CL 72B # 24D - 05" in 10125
replace byhand_manipadrsHP = "KR 23 A # 13" in 10129
replace byhand_manipadrsHP = "CL 72B # 24D - 59" in 10135
replace byhand_manipadrsHP = "KR 1 # 7D - 102" in 10144
replace byhand_manipadrsHP = "KR 1A # 3A - 70C" in 10151
replace byhand_manipadrsHP = "KR 1A # 3A - 70C" in 10152
replace byhand_manipadrsHP = "KR 1A3 # 70B - 44" in 10155
replace byhand_manipadrsHP = "CL 1B # 73D - 36" in 10158
replace byhand_manipadrsHP = "CL 81 # 1J - 19" in 10159
replace byhand_manipadrsHP = "CL 70A # 13A - 49" in 10162
replace byhand_manipadrsHP = "CL 70A # 13A - 49" in 10163
replace byhand_manipadrsHP = "KR 1 # 70 - " in 10167
replace byhand_manipadrsHP = "KR 1 # 70A - 14 " in 10167
replace byhand_manipadrsHP = "CL 70B Bis # 1 3 - 26" in 10173
replace byhand_manipadrsHP = "CL 70B Bis # 1 3 - 26" in 10174
replace byhand_manipadrsHP = "KR 1A5" in 10175
replace byhand_manipadrsHP = "KR 1A # 70A - 72" in 10176
replace byhand_manipadrsHP = "KR 1AB Bis" in 10181
replace byhand_manipadrsHP = "KR 1A A1 # 70D - 11" in 10182
replace byhand_manipadrsHP = "CL 70A # 1A4B - 35" in 10183
replace byhand_manipadrsHP = "" in 10184
replace byhand_manipadrsHP = "KR 1LN # 82 - 34" in 10190
replace byhand_manipadrsHP = "CL 70A1A # 223B - 17" in 10192
replace byhand_manipadrsHP = "CL 70A # 1A - 304" in 10195
replace byhand_manipadrsHP = "KR 1A # 7A Bis - 33" in 10196
replace byhand_manipadrsHP = "CL 70 # 2AN 1S1N - 203" in 10199
replace byhand_manipadrsHP = "CL 70 # 2AN  1S1N - 203" in 10200
replace byhand_manipadrsHP = "CL 70C # 1A3 - 14" in 10201
replace byhand_manipadrsHP = "CL 60A # 2D - 14" in 10202
replace byhand_manipadrsHP = "KR 1D1BN # 57 - 154" in 10204
replace byhand_manipadrsHP = "KR 1D # 2A 57 - 26" in 10210
replace byhand_manipadrsHP = "KR 1AF # 57 - 63" in 10217
replace byhand_manipadrsHP = "KR 2 E # 59D - 53" in 10220
replace byhand_manipadrsHP = "KR 3 N # 71I - 206" in 10221
replace byhand_manipadrsHP = "CL 56 # 1E - 41B" in 10225
replace byhand_manipadrsHP = "KR 1C3 # 53B - 02" in 10226
replace byhand_manipadrsHP = "KR 1A Bis # 52 - 26" in 10228
replace byhand_manipadrsHP = "KR 2DB # 59D - 35" in 10231
replace byhand_manipadrsHP = "KR 1D Bis # 59C - 1B" in 10233
replace byhand_manipadrsHP = "KR 1D1 # 52 - 74" in 10237
replace byhand_manipadrsHP = "KR 1C4 # 53B - 05" in 10238
replace byhand_manipadrsHP = "KR 2AC # 57 - 93" in 10241
replace byhand_manipadrsHP = "KR 1D1 # 52 - 40" in 10244
replace byhand_manipadrsHP = "CL 52A # 1F - 90" in 10246
replace byhand_manipadrsHP = "KR 1D2A # 57 - 14" in 10247
replace byhand_manipadrsHP = "CL 61 # 1B - 90" in 10248
replace byhand_manipadrsHP = "KR 40 # 7 - 679" in 10262
replace byhand_manipadrsHP = "KR 39 # 9B - 56" in 10263
replace byhand_manipadrsHP = "CL 4B O # 73D Bis - 86" in 10279
replace byhand_manipadrsHP = "CL 2C 3 O # 76B - 76" in 10280

replace byhand_manipadrsHP = "CL 2C O # 74 E - 98" in 10292
replace byhand_manipadrsHP = "KR 67 O # 3 - 16" in 10299
replace byhand_manipadrsHP = "CL 3 O #71 Bis - 04" in 10300
replace byhand_manipadrsHP = "KR 76 BO # 2C - 316" in 10301
replace byhand_manipadrsHP = "KR 76 BO # 2C - 316" in 10302
replace byhand_manipadrsHP = "KR 76 BO # 2C - 316" in 10303	

replace byhand_manipadrsHP = "CL 3 O # 73B - 55" in 10335
replace byhand_manipadrsHP = "KR 73 O" in 10337
replace byhand_manipadrsHP = "CL 3 O # 74G - 33" in 10351
replace byhand_manipadrsHP = "CL 3 O # 74G - 33" in 10352
replace byhand_manipadrsHP = "KR 26I2 # 72U - 37" in 10353
replace byhand_manipadrsHP = "CL 2C O # 73C - 71" in 10358
replace byhand_manipadrsHP = "KR 69 # 3 O - 16" in 10370
replace byhand_manipadrsHP = "CL 3 # 66C - 12" in 10375
replace byhand_manipadrsHP = "CL 55 # 29A - 80" in 10386
replace byhand_manipadrsHP = "CL 72Z2 # 28F - 87" in 10387
replace byhand_manipadrsHP = "CL 55 # 32A - 49" in 10390
replace byhand_manipadrsHP = "CL 52 # 29B - 32" in 10398
replace byhand_manipadrsHP = "CL 54 # 29A - 24" in 10407

replace byhand_manipadrsHP = "KR 28D # 72F4 - 59" in 10409
replace byhand_manipadrsHP = "CL 72S # 28 1 - 77" in 10422
replace byhand_manipadrsHP = "CL 52 # 29B - 52" in 10436
replace byhand_manipadrsHP = "KR 28D1 # 72F4 - 94" in 10439
replace byhand_manipadrsHP = "CL 56A # 32A - 38" in 10445
replace byhand_manipadrsHP = "CL 72I # 27C - 61" in 10453
replace byhand_manipadrsHP = "CL 805 # 32" in 10463
replace byhand_manipadrsHP = "KR 28D2 # 72 N - 53" in 10480
replace byhand_manipadrsHP = "KR 28D # 72F4 - 115" in 10491
replace byhand_manipadrsHP = "KR 28D2 # 72F4 - 115" in 10491
replace byhand_manipadrsHP = "KR 28 2 # 72T - 87" in 10494
replace byhand_manipadrsHP = "CL 54 # 29A - 74" in 10499
replace byhand_manipadrsHP = "KR 28 1 # 72T - 114" in 10503
replace byhand_manipadrsHP = "CL 72P # 28 1 - 31" in 10512
replace byhand_manipadrsHP = "CL 84 # 3BN - 60" in 10526
replace byhand_manipadrsHP = "CL 56GN # 49A - 07" in 10536
replace byhand_manipadrsHP = "KR 28J # 72Z - 232" in 10541
replace byhand_manipadrsHP = "CL 52A # 30A - 52" in 10554
replace byhand_manipadrsHP = "CL 72P # 28I - 62" in 10560

replace byhand_manipadrsHP = "KR 28D2 # 72P - 45" in 10564
replace byhand_manipadrsHP = "CL 76 # 30B - 20" in 10565
replace byhand_manipadrsHP = "CL 72S # 28 1 - 125" in 10576
replace byhand_manipadrsHP = "KR 28D # 72P - 35" in 10580
replace byhand_manipadrsHP = "KR 28E # 72G - 66" in 10592
replace byhand_manipadrsHP = "CL 52AA # 30A - 94" in 10595
replace byhand_manipadrsHP = "CL 52A # 30A - 94" in 10595
replace byhand_manipadrsHP = "KR 28B # 72T - 38" in 10602
replace byhand_manipadrsHP = "CL 72S # 28 1 - 125" in 10608
replace byhand_manipadrsHP = "KR 33 #" in 10622
replace byhand_manipadrsHP = "CL 72 2Q # 28A - 102" in 10628
replace byhand_manipadrsHP = "CL 54B # 29A - 03" in 10633
replace byhand_manipadrsHP = "CL 54 4 # 30B - 87" in 10638
replace byhand_manipadrsHP = "CL 72S # 28 1 - 81" in 10642
replace byhand_manipadrsHP = "CL 5 # 30B - 19" in 10656
replace byhand_manipadrsHP = "CL 78 # 28F - 51" in 10662
replace byhand_manipadrsHP = "CL 72L2 # 28F - 82" in 10664

replace byhand_manipadrsHP = "CL 50 # 29A - 18" in 10670
replace byhand_manipadrsHP = "CL 72L # 28B - 46" in 10680
replace byhand_manipadrsHP = "CL 76 # 28F - 20" in 10706

replace byhand_manipadrsHP = "CL 35 # 29A - 49" in 10717
replace byhand_manipadrsHP = "KR 31 # 35B - 48" in 10726
replace byhand_manipadrsHP = "CL 35D # 29A - 27" in 10727
replace byhand_manipadrsHP = "DG 29B # 27 - 17" in 10730
replace byhand_manipadrsHP = "KR 33 # 33C - 133" in 10734
replace byhand_manipadrsHP = "DG 2 QB # 27 - 05" in 10735
replace byhand_manipadrsHP = "CL 35D # 29A - 27" in 10736
replace byhand_manipadrsHP = "KR 29 # 35 E - 17" in 10750
replace byhand_manipadrsHP = "DG 29A # 28 - 34" in 10762
replace byhand_manipadrsHP = "KR 29 3 # 35 - 10" in 10764
replace byhand_manipadrsHP = "KR 76C # 2B - 15" in 10770
replace byhand_manipadrsHP = "TV 2A # 1C - 140 - B" in 10771
replace byhand_manipadrsHP = "TV 2A # 1C - 140B" in 10771
replace byhand_manipadrsHP = "KR 72A 19 # 71A - 95" in 10778
replace byhand_manipadrsHP = "KR 72A # 71A - 95" in 10778
replace byhand_manipadrsHP = "CL 19 # 71A - 95" in 10778
replace byhand_manipadrsHP = "CL 79 # 4 N - 86" in 10782
replace byhand_manipadrsHP = "CL 72C # 4CN - 09" in 10783
replace byhand_manipadrsHP = "KR 8 N # 91J - 30" in 10785
replace byhand_manipadrsHP = "CL 71B # 8N - 41" in 10793
replace byhand_manipadrsHP = "CL 72C # 5N - 45" in 10794
replace byhand_manipadrsHP = "CL 72 CN # 4CN - 23" in 10796
replace byhand_manipadrsHP = "KR 4C # 71F - 59" in 10797
replace byhand_manipadrsHP = "CL 72A Bis # 8N - 49" in 10804
replace byhand_manipadrsHP = "CL 72A Bis # 8N - 49" in 10805
replace byhand_manipadrsHP = "CL 70 Bis # 4CN - 103" in 10808
replace byhand_manipadrsHP = "CL 71B N # 8N - 36" in 10809
replace byhand_manipadrsHP = "CL 71B N # 8N - 36" in 10810
replace byhand_manipadrsHP = "CL 71 # 4CN - 15" in 10815

replace byhand_manipadrsHP = "CL 62 # 2B - 32" in 10823
replace byhand_manipadrsHP = "KR 2B # 65A - 32" in 10825
replace byhand_manipadrsHP = "KR 26K # 72U - 28" in 10838
replace byhand_manipadrsHP = "DG 26G11 # 72U - 54" in 10841
replace byhand_manipadrsHP = "KR 26I # 72U - 79" in 10843
replace byhand_manipadrsHP = "CL 11A # 33" in 10848
replace byhand_manipadrsHP = "CL 72P # 26H3 - 23" in 10850
replace byhand_manipadrsHP = "CL 72E52 # 26K - 21" in 10851
replace byhand_manipadrsHP = "KR 26H2 # 72U - 49" in 10852
replace byhand_manipadrsHP = "KR 26H2 # 72U - 49" in 10853
replace byhand_manipadrsHP = "KR 26I1 # 72P1 - 87" in 10854
replace byhand_manipadrsHP = "KR 26 # 72WS - 31" in 10869
replace byhand_manipadrsHP = "" in 10871
replace byhand_manipadrsHP = "KR 26M # 72U - 85" in 10878
replace byhand_manipadrsHP = "KR 26I1 # 72N - 46" in 10881

replace byhand_manipadrsHP = "KR 26K # 72P1 - 16" in 10882
replace byhand_manipadrsHP = "KR 26H3 # 72W - 15" in 10883
replace byhand_manipadrsHP = "KR 26I # 72P - 1" in 10884
replace byhand_manipadrsHP = "CL 72P # 26 1 - 110" in 10885
replace byhand_manipadrsHP = "CL 72P # 26 1 - 110" in 10886
replace byhand_manipadrsHP = "CL 72P # 26 1 - 110" in 10887
replace byhand_manipadrsHP = "CL 72P # 26 1 - 110" in 10888
replace byhand_manipadrsHP = "KR 26I 1 # 72W - 03" in 10897
replace byhand_manipadrsHP = "KR 26H3 # 72P1 - 27" in 10898
replace byhand_manipadrsHP = "KR 26I2 # 72P - 16" in 10899
replace byhand_manipadrsHP = "KR 26I1 # 72P1 - 10" in 10901

replace byhand_manipadrsHP = "KR 26H # 72U - 82" in 10913
replace byhand_manipadrsHP = "KR 26K # 72U - 56" in 10919
replace byhand_manipadrsHP = "KR 26F N # 740 - 32" in 10940
replace byhand_manipadrsHP = "KR 26I2 # 72P1 - 52" in 10942
replace byhand_manipadrsHP = "CL 72P # 26L - 03" in 10948
replace byhand_manipadrsHP = "KR 26H3 # 72P - 10" in 10950
replace byhand_manipadrsHP = "CL 72 # 26G - 445" in 10963
replace byhand_manipadrsHP = "CL 2 # 22 - 47" in 10970

replace byhand_manipadrsHP = "KR 18 N # 3 - 02B" in 10986
replace byhand_manipadrsHP = "CL 2AB # 18 - 28" in 10987
replace byhand_manipadrsHP = "KR 26H9 # 123 - 10" in 11005
replace byhand_manipadrsHP = "KR 26G3 # 75 - 10" in 11012
replace byhand_manipadrsHP = "KR 26G3 # 75 - 10" in 11013
replace byhand_manipadrsHP = "KR 26G3 # 75 - 10" in 11014

replace byhand_manipadrsHP = "CL 78 # 26G - 94" in 11016
replace byhand_manipadrsHP = "CL 88 # 26B - 36" in 11033
replace byhand_manipadrsHP = "KR 80A # 26G2 - 47" in 11035
replace byhand_manipadrsHP = "CL 80AN # 26D - 11" in 11036
replace byhand_manipadrsHP = "CL 76 # 26B - 12" in 11039
replace byhand_manipadrsHP = "CL 80 Bis # 26C - 55" in 11044
replace byhand_manipadrsHP = "CL 80 # 26F - 05" in 11046
replace byhand_manipadrsHP = "CL 79 # 26G3 - 22" in 11056
replace byhand_manipadrsHP = "CL 80 # 103 - 28" in 11062
replace byhand_manipadrsHP = "CL 62B # 1A9 - 75" in 11066

replace byhand_manipadrsHP = "CL 58 # 1D - 56" in 11067
replace byhand_manipadrsHP = "CL 58 # 1D - 56" in 11068
replace byhand_manipadrsHP = "KR 1B3 # 61A - 26" in 11071
replace byhand_manipadrsHP = "KR 1B33 # 61A - 26" in 11071
replace byhand_manipadrsHP = "KR 1 # 66" in 11072

replace byhand_manipadrsHP = "KR 1F # 61A - 14" in 11076
replace byhand_manipadrsHP = "CL 62B # 1A9 - 365" in 11078
replace byhand_manipadrsHP = "CL 64 # 1" in 11082
replace byhand_manipadrsHP = "KR 1B1 # 61A - 25" in 11086
replace byhand_manipadrsHP = "KR 1 C2 # 61A - 69" in 11087
replace byhand_manipadrsHP = "KR 1C2 # 61A - 69" in 11088
replace byhand_manipadrsHP = "KR 2A1 # 59D - 25" in 11090
replace byhand_manipadrsHP = "CL 62B # 1A9 - 365" in 11111
replace byhand_manipadrsHP = "KR 1B2 # 59 - 126" in 11112

replace byhand_manipadrsHP = "KR 1D Bis # 61A - 32" in 11113
replace byhand_manipadrsHP = "CL 62A # 6 - 185" in 11118
replace byhand_manipadrsHP = "CL 62A # 1A - 6 - 185" in 11118
replace byhand_manipadrsHP = "KR 1E Bis # 61B - 34" in 11121
replace byhand_manipadrsHP = "KR 1B2 # 61 - 03" in 11122
replace byhand_manipadrsHP = "CL 59 # 1 Bis - 35" in 11123
replace byhand_manipadrsHP = "CL 59 # 1 Bis - 35" in 11124
replace byhand_manipadrsHP = "KR 1B2 # 61A - 57" in 11125
replace byhand_manipadrsHP = "CL 69A # 7ML Bis - 742" in 11127

replace byhand_manipadrsHP = "KR 7L Bis # 67 - 64" in 11129
replace byhand_manipadrsHP = "KR 7L Bis # 67 - 64" in 11130
replace byhand_manipadrsHP = "PJ 7F13 # 68A - 53" in 11132
replace byhand_manipadrsHP = "KR 7ME Bis # 78 - 72" in 11136
replace byhand_manipadrsHP = "CL 69A # 7B Bis - 70" in 11140
replace byhand_manipadrsHP = "PJ 7F # 68A - 64" in 11142
replace byhand_manipadrsHP = "CL 62A # 2E1 - 57" in 11147
replace byhand_manipadrsHP = "CL 72R # 25D5 - 10" in 11150
replace byhand_manipadrsHP = "CL 72 # 28BS - 28" in 11153
replace byhand_manipadrsHP = "CL 72L 32 # 8 E - 26" in 11160
replace byhand_manipadrsHP = "CL 72R # 28D5 - 59" in 11166
replace byhand_manipadrsHP = "CL 72L # 28D2 - 25" in 11167
replace byhand_manipadrsHP = "CL 72 L1 # 28G - 07" in 11170
replace byhand_manipadrsHP = "CL 72L 1 # 28I - 01" in 11172
replace byhand_manipadrsHP = "CL 72L 1 # 28I - 01" in 11173
replace byhand_manipadrsHP = "CL 72L 1 # 28I - 01" in 11174
replace byhand_manipadrsHP = "CL 72L 1 # 28I - 01" in 11175
replace byhand_manipadrsHP = "CL 72L2 # 28E3 - 74" in 11182
replace byhand_manipadrsHP = "CL 72S # 28E2 - 22" in 11201
replace byhand_manipadrsHP = "CL 72S # 28E2 - 22" in 11202

replace byhand_manipadrsHP = "CL 72Z2 # 28F - 27" in 11209
replace byhand_manipadrsHP = "CL 72L2 # 28F - 31" in 11210
replace byhand_manipadrsHP = "CL 72L1 # 28 - 27" in 11216
replace byhand_manipadrsHP = "CL 72L2 # 28F - 27" in 11217
replace byhand_manipadrsHP = "CL 72 # 28E - 82" in 11221
replace byhand_manipadrsHP = "CL 72L2 # 28F - 27" in 11222
replace byhand_manipadrsHP = "CL 72K # 28D4 - 35" in 11223
replace byhand_manipadrsHP = "KR 3 O E # 73B - 20" in 11234
replace byhand_manipadrsHP = "KR 3 O E # 73B - 20" in 11235
replace byhand_manipadrsHP = "KR 74 # 1A - 79" in 11236
replace byhand_manipadrsHP = "KR 75 # 1 Bis - 37" in 11247
replace byhand_manipadrsHP = "DG F1 # 73 - 53" in 11252
replace byhand_manipadrsHP = "KR 75A O # 2B - 13" in 11255
replace byhand_manipadrsHP = "DG 1 # 73 - 53" in 11252
replace byhand_manipadrsHP = "CL 3 DN # 75 - 21" in 11259

replace byhand_manipadrsHP = "KR 74B # 1B" in 11265
replace byhand_manipadrsHP = "KR 73B # 1B - 51" in 11274
replace byhand_manipadrsHP = "KR 72 # 1A - 77" in 11278
replace byhand_manipadrsHP = "TV 2 3 # 1 - 76" in 11282
replace byhand_manipadrsHP = "CL 1 Bis O # 73B - 53" in 11283
replace byhand_manipadrsHP = "KR 74A3 # 98 - 103" in 11285
replace byhand_manipadrsHP = "CL 3 O # 66C - 31" in 11291
replace byhand_manipadrsHP = "CL 3 O # 66C - 31" in 11292
replace byhand_manipadrsHP = "CL 99 N # 26G - 04" in 11298
replace byhand_manipadrsHP = "CL 117 # 26H - 130" in 11310

replace byhand_manipadrsHP = "CL 35 # 7A - 102" in 11311
replace byhand_manipadrsHP = "CL 111 # 26Q" in 11312
replace byhand_manipadrsHP = "CL 108 # 26H1 - 24" in 11314
replace byhand_manipadrsHP = "CL 108 # 26H1 - 24" in 11315
replace byhand_manipadrsHP = "CL 106 # 26 O - 10" in 11321
replace byhand_manipadrsHP = "CL 120 # 26I - 52" in 11322
replace byhand_manipadrsHP = "CL 107 # 26P - 45" in 11340
replace byhand_manipadrsHP = "CL 117 # 26H - 18" in 11346
replace byhand_manipadrsHP = "KR 26H3 # 112 - 162" in 11358
replace byhand_manipadrsHP = "CL 99 N # 26I2 - 04" in 11377

replace byhand_manipadrsHP = "KR 26 # 8 112 - 148" in 11385
replace byhand_manipadrsHP = "CL 114 3 # 26I - 68" in 11393
replace byhand_manipadrsHP = "KR 26I # 123 - 56" in 11394
replace byhand_manipadrsHP = "CL 107 # 26L " in 11400
replace byhand_manipadrsHP = "CL 116 # 26I - 24" in 11409
replace byhand_manipadrsHP = "CL 104 # 26I - 10" in 11425
replace byhand_manipadrsHP = "CL 104 # 26I - 10" in 11426
replace byhand_manipadrsHP = "CL 26 # 117I - 13 - 11B" in 11434
replace byhand_manipadrsHP = "CL 112 # 26I - 66" in 11437
replace byhand_manipadrsHP = "KR 26I # 103A - 16" in 11438
replace byhand_manipadrsHP = "CL 115 # 26Q - 120" in 11447
replace byhand_manipadrsHP = "CL 40 # 1A - 18" in 11455

replace byhand_manipadrsHP = "KR 40M # 30C - 71" in 11476
replace byhand_manipadrsHP = "KR 43 # 24" in 11478
replace byhand_manipadrsHP = "CL 39A # 47C - 16" in 11502

replace byhand_manipadrsHP = "KR 46A # 38A - 55" in 11540
replace byhand_manipadrsHP = "KR 46C # 38A - 49" in 11542
replace byhand_manipadrsHP = "KR 46B  # 46 - 73" in 11543
replace byhand_manipadrsHP = "KR 47 # 42A - 43" in 11584
replace byhand_manipadrsHP = "KR 49A # 42 - 76" in 11590
replace byhand_manipadrsHP = "KR 48A # 44 - 97" in 11619

replace byhand_manipadrsHP = "KR 47 # 46 - 29" in 11663
replace byhand_manipadrsHP = "CL 39A # 46A - 13" in 11672
replace byhand_manipadrsHP = "CL 42 N # 46A - 18" in 11675
replace byhand_manipadrsHP = "KR 46 # 41A - 26" in 11724
replace byhand_manipadrsHP = "KR 47 # 36H - 113" in 11736
replace byhand_manipadrsHP = "CL 2A # 74B - 15" in 11761
replace byhand_manipadrsHP = "CL 2A # 74B - 15" in 11762
replace byhand_manipadrsHP = "DG 26P # 86 - 60" in 11763

replace byhand_manipadrsHP = "DG 26P1 # 83 - 32" in 11768
replace byhand_manipadrsHP = "DG P2 # 93 - 74" in 11769
replace byhand_manipadrsHP = "DG 26N # 96 - 17" in 11772

replace byhand_manipadrsHP = "TV 103 # 26P4 - 20" in 11775
replace byhand_manipadrsHP = "TV 103 # 26P4 - 20" in 11776
replace byhand_manipadrsHP = "KR 26H3H # 72W - 33" in 11780
replace byhand_manipadrsHP = "DG 26 G5 # 72T - 17" in 11783
replace byhand_manipadrsHP = "DG 26 G5 # 72T - 17" in 11784
replace byhand_manipadrsHP = "DG 26 G5 # 72T - 17" in 11785
replace byhand_manipadrsHP = "DG 26 G5 # 72T - 17" in 11786
replace byhand_manipadrsHP = "DG 26P2 # 92 - 123" in 11789
replace byhand_manipadrsHP = "DG 26G4 # 72T - 74" in 11790
replace byhand_manipadrsHP = "DG 26P 19 # 105 - 15" in 11796
replace byhand_manipadrsHP = "DG 26I # 96 - 81" in 11797
replace byhand_manipadrsHP = "DG 26G10 # 72U - 70" in 11802
replace byhand_manipadrsHP = "DG 26G5 # 72U - 46" in 11804
replace byhand_manipadrsHP = "DG 26G8 # 1N2T - 66" in 11806
replace byhand_manipadrsHP = "DG 26G10 # 62T - 18" in 11810
replace byhand_manipadrsHP = "CL 71" in 11815
replace byhand_manipadrsHP = "CL 71" in 11816
replace byhand_manipadrsHP = "CL 26I3 # 105 - 155" in 11818
replace byhand_manipadrsHP = "KR 26H4 # 96 - 63" in 11819
replace byhand_manipadrsHP = "DG 26I2 # 87 - 54" in 11822
replace byhand_manipadrsHP = "DG 26P5 # 80 - 74" in 11823
replace byhand_manipadrsHP = "DG 26H4 # 73 - 67" in 11824
replace byhand_manipadrsHP = "DG 26BP2 # 93 - 80" in 11828
replace byhand_manipadrsHP = "DG 26 # 6P - 18" in 11837
replace byhand_manipadrsHP = "DG 6H3 # 83 - 04" in 11839
replace byhand_manipadrsHP = "DG 26 # 72U - 52" in 11847
replace byhand_manipadrsHP = "DG 26 64 # 72U - 52" in 11847
replace byhand_manipadrsHP = "DG 26F22 # 104 - 03" in 11848
replace byhand_manipadrsHP = "DG 26 P22 # 104 - 03" in 11849
replace byhand_manipadrsHP = "DG 26P # 87 - 46" in 11854
replace byhand_manipadrsHP = "DG 26G4 # 72U - 45" in 11856
replace byhand_manipadrsHP = "DG 26P3 # 83 - 39" in 11857
replace byhand_manipadrsHP = "DG 26P8 # 105 - 11" in 11858
replace byhand_manipadrsHP = "DG 26G11 # 72S1 - 53" in 11864
replace byhand_manipadrsHP = "DG 26P19 # 105B - 17" in 11867
replace byhand_manipadrsHP = "DG 26P9 # 105A - 03" in 11868
replace byhand_manipadrsHP = "KR 26G # 73" in 11879
replace byhand_manipadrsHP = "KR 26G # 73" in 11880
replace byhand_manipadrsHP = "KR 26G # 73" in 11881
replace byhand_manipadrsHP = "DG 26 # 73 - 13" in 11883
replace byhand_manipadrsHP = "DG 26G5 # 72U - 60" in 11890
replace byhand_manipadrsHP = "DG 26 # 87 - 24" in 11892
replace byhand_manipadrsHP = "DG 26P # 105A - 15" in 11893

replace byhand_manipadrsHP = "DG 26H1 # 83 - 73" in 11895
replace byhand_manipadrsHP = "DG 26K # 83 - 26" in 11896
replace byhand_manipadrsHP = "DG 26P3 # 93 - 59" in 11899
replace byhand_manipadrsHP = "DG 26P16 # 93 - 17" in 11902
replace byhand_manipadrsHP = "DG 26I1 # 87 - 10" in 11903
replace byhand_manipadrsHP = "DG 26G 7 # 72T - 53" in 11904
replace byhand_manipadrsHP = "DG 26B4 # 96 - 80" in 11908
replace byhand_manipadrsHP = "" in 11909
replace byhand_manipadrsHP = "DG 26G5 # 73 - 14" in 11912

replace byhand_manipadrsHP = "KR 26I2 # 96 - 74" in 11914
replace byhand_manipadrsHP = "DG 26G12 # 77 - 83" in 11918
replace byhand_manipadrsHP = "DG 26P14 # 105A - 66" in 11922
replace byhand_manipadrsHP = "DG 26P14 # 105A - 66" in 11923
replace byhand_manipadrsHP = "DG 26P14 # 105A - 66" in 11924
replace byhand_manipadrsHP = "DG 26G10 # 72 - 46" in 11925
replace byhand_manipadrsHP = "DG 26P8 # 105 - 24" in 11926
replace byhand_manipadrsHP = "DG 26 O # 83 - 32" in 11927
replace byhand_manipadrsHP = "KR 26L # 72W1 - 53" in 11930
replace byhand_manipadrsHP = "DG 26I1 # 73 - 81" in 11931
replace byhand_manipadrsHP = "DG 26G7 # 72 - 11" in 11932
replace byhand_manipadrsHP = "DG 26J # 77 - 57" in 11937
replace byhand_manipadrsHP = "DG 26G6 # 72T - 38" in 11938
replace byhand_manipadrsHP = "DG 26G6 # 72T - 38" in 11939
replace byhand_manipadrsHP = "DG 26 4 # 180 - 24" in 11942
replace byhand_manipadrsHP = "DG 26G4 # 60" in 11943
replace byhand_manipadrsHP = "CL 26B2 # 73D - 10" in 11944
replace byhand_manipadrsHP = "DG 26P18 # 105A - 39" in 11946
replace byhand_manipadrsHP = "DG 26I3 # 96 - 38" in 11947
replace byhand_manipadrsHP = "DG 26K # 87 - 38" in 11950
replace byhand_manipadrsHP = "DG 26 4 # 93 - 25" in 11951
replace byhand_manipadrsHP = "DG 26 1 # 73 - 73" in 11956
replace byhand_manipadrsHP = "DG 26P15 # 105A - 11" in 11960

replace byhand_manipadrsHP = "DG 26P15 # 105A - 11" in 11961
replace byhand_manipadrsHP = "DG 26P1 # 73 - 39" in 11966
replace byhand_manipadrsHP = "DG 26B1 # 73 - 52" in 11969
replace byhand_manipadrsHP = "CL 103D # 26P10 - 94 - 74" in 11971
replace byhand_manipadrsHP = "KR 82 # 6A - 17" in 11973

replace byhand_manipadrsHP = "KR 85C # 9 - 28" in 11975
replace byhand_manipadrsHP = "KR 83 # 6A - 32" in 11982
replace byhand_manipadrsHP = "KR 84 # 13B1 - 48" in 12004

replace byhand_manipadrsHP = "CL 9 # 83A - 24" in 12015
replace byhand_manipadrsHP = "KR 94D # 80" in 12026
replace byhand_manipadrsHP = "CL 94D O # 1A - 56" in 12031
replace byhand_manipadrsHP = "KR 93 O # 2C - 13" in 12046
replace byhand_manipadrsHP = "KR 93 O # 2C - 13" in 12047
replace byhand_manipadrsHP = "KR 97 # 2A - 44" in 12054
replace byhand_manipadrsHP = "KR 97 # 2A - 44" in 12055
replace byhand_manipadrsHP = "KR 92 # 2C - 30" in 12061
replace byhand_manipadrsHP = "KR 94A1 E # 4A - 11" in 12067
replace byhand_manipadrsHP = "KR 100A O # 1D - 10" in 12080

replace byhand_manipadrsHP = "KR 9AB # 3 - 2 - 46" in 12081
replace byhand_manipadrsHP = "CL 12 O # 94B - 12" in 12098
replace byhand_manipadrsHP = "KR 93C Bis # 2B - 12" in 12105
replace byhand_manipadrsHP = "KR 93C Bis # 2B - 12" in 12106
replace byhand_manipadrsHP = "KR 90 3 # 16 - 129" in 12107

replace byhand_manipadrsHP = "" in 12126
replace byhand_manipadrsHP = "KR 98 # 2D - 11" in 12128
replace byhand_manipadrsHP = "KR 92 O # 2C2 - 06" in 12144
replace byhand_manipadrsHP = "KR 92 O # 2C2- 06" in 12145
replace byhand_manipadrsHP = "" in 12161
replace byhand_manipadrsHP = "KR 94 O # 3 Bis - 62" in 12165
replace byhand_manipadrsHP = "KR 82 Bis" in 12180
replace byhand_manipadrsHP = "KR 82 Bis" in 12181
replace byhand_manipadrsHP = "AV 2 O # 89 - 40" in 12183
replace byhand_manipadrsHP = "AV 2 O # 89 - 40" in 12184
replace byhand_manipadrsHP = "KR 96 # 3B - 45" in 12197
replace byhand_manipadrsHP = "KR 96 # 3B - 45" in 12198
replace byhand_manipadrsHP = "KR 96 # 3B - 45" in 12199
replace byhand_manipadrsHP = "KR 96 # 3B - 45" in 12200
replace byhand_manipadrsHP = "KR 93 # 2B - 130" in 12227
replace byhand_manipadrsHP = "KR 94A O # 3 2B - 46" in 12228
replace byhand_manipadrsHP = "KR 94A O # 3 2B - 46" in 12229
replace byhand_manipadrsHP = "KR 94A O # 3 2B - 46" in 12230
replace byhand_manipadrsHP = "KR 94A O # 3 2B - 46" in 12231
replace byhand_manipadrsHP = "KR 94A O # 3 2B - 46" in 12232
replace byhand_manipadrsHP = "KR 94A O # 3 2B - 46" in 12233
replace byhand_manipadrsHP = "KR 94A O # 3 2B - 46" in 12234
replace byhand_manipadrsHP = "KR 94A O # 3 2B - 46" in 12235
replace byhand_manipadrsHP = "KR 94A O # 3 2B - 46" in 12236
replace byhand_manipadrsHP = "KR 94A O # 3 2B - 46" in 12237
replace byhand_manipadrsHP = "KR 94A O # 3 2B - 46" in 12238
replace byhand_manipadrsHP = "CL 3B # 97A - 05" in 12266

replace byhand_manipadrsHP = "CL 49 N # 6N2 - 68" in 12288
replace byhand_manipadrsHP = "AV 7AM # 53A - 77" in 12290
replace byhand_manipadrsHP = "AV 7AM # 53A - 77" in 12291
replace byhand_manipadrsHP = "AV 8 N # 52B - 20" in 12300
replace byhand_manipadrsHP = "CL 53AN # 7A - 124" in 12302
replace byhand_manipadrsHP = "CL 67 # 1AG - 24" in 12316
replace byhand_manipadrsHP = "KR 1A 11 # 69 - 94" in 12319
replace byhand_manipadrsHP = "KR 1A 9 # 69 - 16" in 12322
replace byhand_manipadrsHP = "KR 1A 11 # 69 - 38" in 12325
replace byhand_manipadrsHP = "KR 1 Bis # 62A - 95" in 12326
replace byhand_manipadrsHP = "KR 1A 9 # 69 - 39" in 12333
replace byhand_manipadrsHP = "CL 69 # 1A5 - 156" in 12337
replace byhand_manipadrsHP = "CL 1 # 21M - 02" in 12347
replace byhand_manipadrsHP = "CL 2 O # 24E - 46" in 12348
replace byhand_manipadrsHP = "CL 2 O # 24E - 46" in 12349
replace byhand_manipadrsHP = "CL 4A # 24A - 65" in 12352
replace byhand_manipadrsHP = "CL 88 # 28E - 622" in 12358
replace byhand_manipadrsHP = "CL 83 # 4 - 3" in 12360
replace byhand_manipadrsHP = "CL 84 # 28D - 244" in 12361
replace byhand_manipadrsHP = "CL 82 # 28D - 94" in 12363
replace byhand_manipadrsHP = "CL 9 # 28C - 15" in 12365
replace byhand_manipadrsHP = "CL 86A # 28E6 - 25" in 12368
replace byhand_manipadrsHP = "CL 88 # 28E3 - 40" in 12372
replace byhand_manipadrsHP = "CL 92 # 28D - 268" in 12374
replace byhand_manipadrsHP = "CL 80 # 28D4 - 52" in 12382
replace byhand_manipadrsHP = "CL 76 N # 28B - 52" in 12394
replace byhand_manipadrsHP = "CL 90 # 9028E - 19" in 12400
replace byhand_manipadrsHP = "CL 90 # 28E - 19" in 12400
replace byhand_manipadrsHP = "KR 43A # 46 - 139" in 12401
replace byhand_manipadrsHP = "CL 85 # 28D2 - 30" in 12404
replace byhand_manipadrsHP = "CL 82 # 28D2 - 106" in 12405
replace byhand_manipadrsHP = "CL 84 # 28D4 - 16" in 12406

replace byhand_manipadrsHP = "KR 28 E # 76A - 10" in 12413
replace byhand_manipadrsHP = "KR 28 E # 76A - 10" in 12414
replace byhand_manipadrsHP = "CL 82 # 28E3 - 39" in 12416
replace byhand_manipadrsHP = "CL 82 # 28E3 - 39" in 12417
replace byhand_manipadrsHP = "CL 76 # 28E2 - 96" in 12418
replace byhand_manipadrsHP = "CL 83A N # 28D - 33" in 12421
replace byhand_manipadrsHP = "CL 83A # 28D - 417" in 12425
replace byhand_manipadrsHP = "CL 85 # 28DG4 " in 12426
replace byhand_manipadrsHP = "CL 85A # 28EG - 74" in 12428
replace byhand_manipadrsHP = "CL 78 N # 28E - 228" in 12433
replace byhand_manipadrsHP = "CL 83 # 28D1 - 13" in 12436
replace byhand_manipadrsHP = "CL 88 # 28D - 275" in 12437
replace byhand_manipadrsHP = "CL 81 # 28E3 - 11" in 12443
replace byhand_manipadrsHP = "CL 79 N # 28E - 21" in 12445
replace byhand_manipadrsHP = "CL 76 # 28E1 - 09" in 12446
replace byhand_manipadrsHP = "CL 77 # 28D - 09" in 12449
replace byhand_manipadrsHP = "CL 96 # 28I - 19" in 12453
replace byhand_manipadrsHP = "CL 96 # 28I - 19" in 12454
replace byhand_manipadrsHP = "CL 94 # 28D2 - 83" in 12457
replace byhand_manipadrsHP = "CL 82 # 28D2 - 95" in 12458
replace byhand_manipadrsHP = "CL 79 # 28E6 - 57" in 12459

replace byhand_manipadrsHP = "CL 96 # 27E6 - 46" in 12466
replace byhand_manipadrsHP = "CL 82 # 28D - 75" in 12470
replace byhand_manipadrsHP = "DG 28D # 33 - 31" in 12471
replace byhand_manipadrsHP = "CL 77 # 28F - 75" in 12472
replace byhand_manipadrsHP = "CL 92 # 28D4 - 73" in 12475
replace byhand_manipadrsHP = "CL 78 #" in 12476
replace byhand_manipadrsHP = "CL 91 # 28D2 - 35" in 12480
replace byhand_manipadrsHP = "CL 96 # 28I - 18" in 12484
replace byhand_manipadrsHP = "CL 93 # 28D2 - 10" in 12485
replace byhand_manipadrsHP = "CL 86 # 28D - 39" in 12493
replace byhand_manipadrsHP = "CL 76 # 28E - 110" in 12496
replace byhand_manipadrsHP = "CL 78 # 28D - 16" in 12503
replace byhand_manipadrsHP = "CL 79 # 28D2 - 09" in 12506
replace byhand_manipadrsHP = "CL 83 # 28D2 - 22" in 12508
replace byhand_manipadrsHP = "CL 80 # 28D2 - 106" in 12515
replace byhand_manipadrsHP = "CL 80 # 28D2T - 06" in 12516
replace byhand_manipadrsHP = "CL 80 # 28D4 - 27" in 12521
replace byhand_manipadrsHP = "CL 86 # 28D1 - 09" in 12531
replace byhand_manipadrsHP = "CL 96 # 28I - 19" in 12533
replace byhand_manipadrsHP = "CL 112 # 28 2 - 12" in 12543
replace byhand_manipadrsHP = "CL 81 # 28D2 - 71" in 12551
replace byhand_manipadrsHP = "CL 77 # 28E5 - 29" in 12552
replace byhand_manipadrsHP = "CL 77 # 28E5 - 29" in 12553
replace byhand_manipadrsHP = "CL 96 3 # 28H - 04" in 12564
replace byhand_manipadrsHP = "CL 83B1 # 45 - 61" in 12567
replace byhand_manipadrsHP = "CL 90 # 28K1 - 45" in 12571
replace byhand_manipadrsHP = "CL 85 # 28D2 - 50" in 12572
replace byhand_manipadrsHP = "CL 92 # 28E4 - 64" in 12579
replace byhand_manipadrsHP = "CL 86 # 28D - 61" in 12585

replace byhand_manipadrsHP = "KR 26G # 12 - 63" in 12601
replace byhand_manipadrsHP = "CL 77 # 28D2 - 27" in 12606
replace byhand_manipadrsHP = "KR 28D1 # 85 - 20" in 12614
replace byhand_manipadrsHP = "CL 85 # 28E - 341" in 12627
replace byhand_manipadrsHP = "CL 57 # 28 - 82" in 12641

replace byhand_manipadrsHP = "CL 91 # 28D - 86" in 12645
replace byhand_manipadrsHP = "CL 76A # 28DZ - 35" in 12646
replace byhand_manipadrsHP = "CL 76A # 28D2 - 35" in 12646
replace byhand_manipadrsHP = "CL 83 # 28E3 - 67" in 12652
replace byhand_manipadrsHP = "KR 28G # 107" in 12664
replace byhand_manipadrsHP = "CL 85A # 28E6 - 70" in 12679
replace byhand_manipadrsHP = "KR 28E5 # 36E - 17" in 12683
replace byhand_manipadrsHP = "CL 26 # 28C - 06" in 12691
replace byhand_manipadrsHP = "" in 12693
replace byhand_manipadrsHP = "CL 44" in 12694
replace byhand_manipadrsHP = "AV 43B O # 5B - 53" in 12696
replace byhand_manipadrsHP = "CL 5 O # 43A - 01" in 12700
replace byhand_manipadrsHP = "CL 33B O # 5A - 44" in 12703
replace byhand_manipadrsHP = "AV 46 O # 10C - 30" in 12711
replace byhand_manipadrsHP = "CL 9 O # 43A - 43" in 12717
replace byhand_manipadrsHP = "KR 95 # 11 - 73" in 12731
replace byhand_manipadrsHP = "CL 33F # 11M - 28" in 12740
replace byhand_manipadrsHP = "CL 1A11G # 33A - 100" in 12746

replace byhand_manipadrsHP = "DG 72E Bis # 15 - 26L72" in 12758
replace byhand_manipadrsHP = "KR 11B # 33B - 44" in 12761
replace byhand_manipadrsHP = "KR 11F # 33F - 63" in 12763
replace byhand_manipadrsHP = "KR 11F # 33F - 33" in 12764
replace byhand_manipadrsHP = "CL 31 # 11G - 26" in 12772
replace byhand_manipadrsHP = "KR 11C # 33A - 37" in 12774
replace byhand_manipadrsHP = "KR 79 # 1B2 - 16" in 12790
replace byhand_manipadrsHP = "KR 80 # 2C - 33" in 12793
replace byhand_manipadrsHP = "KR 77 # 3A - 22" in 12796
replace byhand_manipadrsHP = "CL 21B N # 78A - 30" in 12806
replace byhand_manipadrsHP = "KR 76C # 2D - 77" in 12809
replace byhand_manipadrsHP = "KR 5 O # 2 - 58" in 12810
replace byhand_manipadrsHP = "KR 82 # 1B - 06" in 12821
replace byhand_manipadrsHP = "KR 82 # 1B - 06" in 12822
replace byhand_manipadrsHP = "KR 82 # 1B - 06" in 12823
replace byhand_manipadrsHP = "KR 82 # 1B - 06" in 12824
replace byhand_manipadrsHP = "KR 82 # 1B - 06" in 12825
replace byhand_manipadrsHP = "TV 2A # 74 Bis 5 - 97" in 12826
replace byhand_manipadrsHP = "KR 78 # 2C - 105" in 12829
replace byhand_manipadrsHP = "KR 78 # 2C - 105" in 12830
replace byhand_manipadrsHP = "KR 78 # 2C - 105" in 12831
replace byhand_manipadrsHP = "KR 78 # 2C - 105" in 12832
replace byhand_manipadrsHP = "KR 78 # 2C - 105" in 12833
replace byhand_manipadrsHP = "KR 78 # 2C - 105" in 12834
replace byhand_manipadrsHP = "KR 78 # 2C - 105" in 12835
replace byhand_manipadrsHP = "KR 78 # 2C - 105" in 12836
replace byhand_manipadrsHP = "KR 78 # 2C - 105" in 12837
replace byhand_manipadrsHP = "KR 78A # 1 Bis - 10" in 12857
replace byhand_manipadrsHP = "CL 2B Bis O # 82D - 11" in 12860
replace byhand_manipadrsHP = "CL 2B # 76C - 26" in 12865

replace byhand_manipadrsHP = "KR 78 # 3 - 56" in 12872
replace byhand_manipadrsHP = "KR 94 1 # 3 O - 66" in 12888
replace byhand_manipadrsHP = "KR 94 1 # 3 O - 66" in 12889
replace byhand_manipadrsHP = "CL 79 # 26C1 - 12" in 12891
replace byhand_manipadrsHP = "CL 79 # 26C1 - 12" in 12892
replace byhand_manipadrsHP = "KR 3D O # 82C - 32" in 12893
replace byhand_manipadrsHP = "KR 3D O # 82C - 32" in 12894
replace byhand_manipadrsHP = "KR 77 # 3D - 92" in 12923
replace byhand_manipadrsHP = "KR 78 N # 2C - 91B" in 12929
replace byhand_manipadrsHP = "KR 77A # 2A - 37" in 12948
replace byhand_manipadrsHP = "KR 93C Bis O # 2B - 30" in 12955
replace byhand_manipadrsHP = "CL 2 O # 7 Bis C - 232" in 12956
replace byhand_manipadrsHP = "CL 1B O # 4 O - 201" in 12961
replace byhand_manipadrsHP = "CL 1B # 4A - 201" in 12962
replace byhand_manipadrsHP = "AV 7 O" in 12963
replace byhand_manipadrsHP = "CL 50 # 25A - 30" in 12968
replace byhand_manipadrsHP = "KR 25A # 56A - 10" in 12979
replace byhand_manipadrsHP = "CL 70 # 26I - 14" in 12986
replace byhand_manipadrsHP = "CL 70 # 28B - 06" in 12995
replace byhand_manipadrsHP = "KR 24B # 59A - 23" in 12997
replace byhand_manipadrsHP = "KR 26 O # 54 - 56" in 13004
replace byhand_manipadrsHP = "KR 26M2 # 49 - 04" in 13007
replace byhand_manipadrsHP = "KR 26 5N # 52 - 39" in 13018
replace byhand_manipadrsHP = "KR 17D # 28A - 43" in 13036
replace byhand_manipadrsHP = "CL 57 # 24B - 14" in 13053
replace byhand_manipadrsHP = "KR 26M # 56A - 13" in 13068
replace byhand_manipadrsHP = "KR 22 # 51 - 24" in 13087
replace byhand_manipadrsHP = "KR 56 # 44" in 13097
replace byhand_manipadrsHP = "CL 72F1 # 28D3 - 75" in 13110
replace byhand_manipadrsHP = "KR 26 O # 28C - 05" in 13123
replace byhand_manipadrsHP = "CL 72H # 27C - 26" in 13130
replace byhand_manipadrsHP = "" in 13157
replace byhand_manipadrsHP = "KR 26 O # 54 - 56" in 13160

replace byhand_manipadrsHP = "CL 54 # 28 E - 66" in 13177
replace byhand_manipadrsHP = "CL 34 CA # 29B - 09" in 13208
replace byhand_manipadrsHP = "CL 153" in 13209
replace byhand_manipadrsHP = "CL 153" in 13210
replace byhand_manipadrsHP = "CL 8A # 44A - 37" in 13227
replace byhand_manipadrsHP = "CL 70 # 7G Bis - 05" in 13230
replace byhand_manipadrsHP = "KR 53 # 5B - 12" in 13233
replace byhand_manipadrsHP = "CL 3 # 0 - 51" in 13234
replace byhand_manipadrsHP = "KR 3 DN # 71C - 59" in 13241
replace byhand_manipadrsHP = "KR 3BN # 71F - 55" in 13242
replace byhand_manipadrsHP = "CL 71D # 3A 2A - 35" in 13244
replace byhand_manipadrsHP = "CL 71D # 3A 2N - 35" in 13245
replace byhand_manipadrsHP = "KR 3 CN # 71C - 78" in 13247
replace byhand_manipadrsHP = "CL 72B # 5A - 36" in 13248
replace byhand_manipadrsHP = "CL 71D # 3CN - 24" in 13249
replace byhand_manipadrsHP = "CL 71C # 3A5N - 05" in 13250
replace byhand_manipadrsHP = "KR 3EN # 70 - 90" in 13251
replace byhand_manipadrsHP = "KR 3EN # 70 - 50" in 13254
replace byhand_manipadrsHP = "CL 71C # 3A 4N - 05" in 13258
replace byhand_manipadrsHP = "CL 71C # 3A 4N - 05" in 13259
replace byhand_manipadrsHP = "CL 70 # 3 N - 110" in 13261
replace byhand_manipadrsHP = "CL 51 # 6 N - 44" in 13265
replace byhand_manipadrsHP = "KR 5 N # 51N - 53" in 13266
replace byhand_manipadrsHP = "CL 48 # 5N - 34" in 13274
replace byhand_manipadrsHP = "CL 51AN # 7AN - 17" in 13280
replace byhand_manipadrsHP = "CL 10A # 36A - 35" in 13281
replace byhand_manipadrsHP = "KR 35 # 12A - 104" in 13297
replace byhand_manipadrsHP = "CL 57 N # 5N - 41" in 13305
replace byhand_manipadrsHP = "CL 60 # 2DN - 32" in 13314
replace byhand_manipadrsHP = "CL 60 # 2DN - 32" in 13315
replace byhand_manipadrsHP = "CL 60 # 2DN - 32" in 13316
replace byhand_manipadrsHP = "CL 72Y # 27D - 17" in 13319
replace byhand_manipadrsHP = "KR 27 DN # 72W2 - 19" in 13322
replace byhand_manipadrsHP = "KR 27A1 # 72Y - 24" in 13323

replace byhand_manipadrsHP = "CL 77 # 28F - 69" in 13329
replace byhand_manipadrsHP = "KR 27 # 72UB - 07" in 13340
replace byhand_manipadrsHP = "KR 27D # 72Y - 94" in 13346
replace byhand_manipadrsHP = "KR 27D # 72Y - 94" in 13347
replace byhand_manipadrsHP = "KR 27 # 72V - 73" in 13355
replace byhand_manipadrsHP = "KR 26R # 72 0 - 12" in 13361
replace byhand_manipadrsHP = "CL 72P # 28 1 - 20" in 13364
replace byhand_manipadrsHP = "KR 27 # 72 UV - 07" in 13375
replace byhand_manipadrsHP = "KR 27D # 71 - 02" in 13376
replace byhand_manipadrsHP = "AV 9 O # 19C - 12" in 13396
replace byhand_manipadrsHP = "KR 47 3 # 12A - 75" in 13419
replace byhand_manipadrsHP = "KR 45 # 12B - 67" in 13432
replace byhand_manipadrsHP = "KR 44A # 12 - 70" in 13450
replace byhand_manipadrsHP = "KR 36 3 # 10 - 155" in 13461
replace byhand_manipadrsHP = "KR 10 # 12A Bis - 70 - 28" in 13463
replace byhand_manipadrsHP = "CL 16A # 107A - 60" in 13477
replace byhand_manipadrsHP = "KR 1D Bis # 5AB - 10" in 13485
replace byhand_manipadrsHP = "KR 1D Bis # 5AB - 10" in 13486
replace byhand_manipadrsHP = "KR 4 N # 36" in 13491
replace byhand_manipadrsHP = "KR 1KN # 82 - 38" in 13492
replace byhand_manipadrsHP = "" in 13494
replace byhand_manipadrsHP = "KR 1DN # 77 - 70" in 13499
replace byhand_manipadrsHP = "KR 3 EN # 70 - 69" in 13500
replace byhand_manipadrsHP = "CL 72 EN # 41" in 13503
replace byhand_manipadrsHP = "KR 1J # 73A - 27" in 13511
replace byhand_manipadrsHP = "KR 3 N # 72 2 - 28" in 13512
replace byhand_manipadrsHP = "CL 71G # 3EN - 23" in 13513
replace byhand_manipadrsHP = "CL 71G # 3EN - 59" in 13514
replace byhand_manipadrsHP = "CL 70 # 13N - 80" in 13515
replace byhand_manipadrsHP = "KR 1DN # 77 - 33" in 13520
replace byhand_manipadrsHP = "KR 1 DN # 77 - 33" in 13521
replace byhand_manipadrsHP = "KR 1A # 54A - 110" in 13529
replace byhand_manipadrsHP = "KR 1A HN # 50 - 04" in 13530
replace byhand_manipadrsHP = "CL 63A # 2B1 - 03" in 13540
replace byhand_manipadrsHP = "CL 81 # 2 Bis - 17" in 13551
replace byhand_manipadrsHP = "" in 13552
replace byhand_manipadrsHP = "KR 1T # 4 74 - 18" in 13556
replace byhand_manipadrsHP = "KR 1S # 71A - 26B" in 13559
replace byhand_manipadrsHP = "CL 84 # 1 C3 - 24" in 13563
replace byhand_manipadrsHP = "KR 2C Bis # 75 - 07" in 13567
replace byhand_manipadrsHP = "KR 2D # 73A - 74" in 13571
replace byhand_manipadrsHP = "KR 1DN # 82 - 46" in 13574
replace byhand_manipadrsHP = "CL 70 N # 2 - 2N - 271" in 13577
replace byhand_manipadrsHP = "CL 70 N # 2 2N - 271" in 13577
replace byhand_manipadrsHP = "KR 1 KN # 82 - 56" in 13580
replace byhand_manipadrsHP = "KR 2B # 73A - 68" in 13585
replace byhand_manipadrsHP = "CL 84 1B # 3 - 30" in 13590
replace byhand_manipadrsHP = "KR 1C 4 # 67A - 70" in 13592
replace byhand_manipadrsHP = "KR 1J # 75 - 61" in 13594
replace byhand_manipadrsHP = "KR 2 # 75 - 63" in 13595
replace byhand_manipadrsHP = "KR 1B2 # 73A - 39" in 13597
replace byhand_manipadrsHP = "KR 1B2 # 73A - 39" in 13598
replace byhand_manipadrsHP = "KR 1B2 # 73A - 39" in 13599
replace byhand_manipadrsHP = "KR 1C4 # 78 - 31" in 13601
replace byhand_manipadrsHP = "KR 1N # 77 Bis - 31" in 13610
replace byhand_manipadrsHP = "KR 2 E # 73A - 47" in 13612
replace byhand_manipadrsHP = "KR 1B3 # 76 - 10" in 13613
replace byhand_manipadrsHP = "KR 2C Bis # 75 - 23" in 13615
replace byhand_manipadrsHP = "KR 67 # 150" in 13617
replace byhand_manipadrsHP = "KR 1B1 # 77 - 59" in 13618
replace byhand_manipadrsHP = "KR 2 Bis # 78 - 59" in 13625
replace byhand_manipadrsHP = "KR 1C4 # 77 - 34" in 13629
replace byhand_manipadrsHP = "CL 77 # 1C2 - 23" in 13632
replace byhand_manipadrsHP = "KR 1B2 # 73A - 48" in 13635
replace byhand_manipadrsHP = "KR 1B1 # 74 - 12" in 13637
replace byhand_manipadrsHP = "CL 77 # 1B3 - 18" in 13639
replace byhand_manipadrsHP = "CL 77 # 1B3 - 31" in 13644
replace byhand_manipadrsHP = "CL 73A # 1I - 19" in 13649

replace byhand_manipadrsHP = "KR 1 # 73 - 27" in 13650
replace byhand_manipadrsHP = "KR 1 Bis 3 # 73A - 68" in 13652
replace byhand_manipadrsHP = "KR 1 EW # 75 - 16" in 13659
replace byhand_manipadrsHP = "KR 1 EW # 75 - 16" in 13661
replace byhand_manipadrsHP = "KR 41 # 96A - 115" in 13678
replace byhand_manipadrsHP = "KR 1B1 # 76 - 29" in 13681
replace byhand_manipadrsHP = "CL 123A # 28D - 108" in 13683
replace byhand_manipadrsHP = "KR 28 # 123A4 - 39" in 13686
replace byhand_manipadrsHP = "KR 28D6 # 12B - 63" in 13687

replace byhand_manipadrsHP = "CL 123 # 2BA1 - 97" in 13689
replace byhand_manipadrsHP = "KR 28FS # 122A - 40" in 13690
replace byhand_manipadrsHP = "KR 28A 10 # 123A - 09" in 13692
replace byhand_manipadrsHP = "KR 28F4 # 122A - 10" in 13694
replace byhand_manipadrsHP = "CL 122" in 13699
replace byhand_manipadrsHP = "KR 28 # 122A - 26" in 13701
replace byhand_manipadrsHP = "KR 28E3 # 120B - 52" in 13702
replace byhand_manipadrsHP = "KR 28 E # 121D - 06" in 13705
replace byhand_manipadrsHP = "KR 28F6 # 122A - 35" in 13708
replace byhand_manipadrsHP = "KR 28E4 # 113A - 29" in 13712
replace byhand_manipadrsHP = "KR 28G # 122A - 47" in 13713
replace byhand_manipadrsHP = "KR 28GN # 122A - 83" in 13720
replace byhand_manipadrsHP = "KR 28B1 # 12 Bis - 20" in 13721
replace byhand_manipadrsHP = "KR 28 5 # 122E - 19" in 13723
replace byhand_manipadrsHP = "KR 28FA # 121A - 10" in 13725
replace byhand_manipadrsHP = "KR 28 # 122D - 62" in 13726
replace byhand_manipadrsHP = "CL 122F Bis # 28E2 - 56" in 13727
replace byhand_manipadrsHP = "KR 28D7 # 120A - 69" in 13729

replace byhand_manipadrsHP = "KR 28 D2 # 120B - 21" in 13732
replace byhand_manipadrsHP = "CL 122F # 28D10 - 32" in 13734
replace byhand_manipadrsHP = "KR 4 N # 43C - 31" in 13739
replace byhand_manipadrsHP = "KR 7 # 46NB - 20" in 13741
replace byhand_manipadrsHP = "KR 8 # 43N - 37" in 13745
replace byhand_manipadrsHP = "KR 8 # 43N - 37" in 13746
replace byhand_manipadrsHP = "CL 42 # 7 N - 16" in 13751
replace byhand_manipadrsHP = "KR 27G # 72W - 226" in 13754
replace byhand_manipadrsHP = "KR 4N # 46A - 29" in 13762
replace byhand_manipadrsHP = "CL 46B N # 8AN - 23" in 13763
replace byhand_manipadrsHP = "CL 46B N # 8AN - 23" in 13764

replace byhand_manipadrsHP = "KR 4A N # 44AN - 18" in 13776
replace byhand_manipadrsHP = "KR 5 N # 42N - 35" in 13802
replace byhand_manipadrsHP = "" in 13803
replace byhand_manipadrsHP = "CL 46B # 4N - 31" in 13806
replace byhand_manipadrsHP = "KR 7 # 47N - 21CA - 176" in 13811
replace byhand_manipadrsHP = "KR 1 # 45 N - 38" in 13815
replace byhand_manipadrsHP = "CL 5N # 39" in 13816
replace byhand_manipadrsHP = "CL 45A # 5N - 87" in 13819
replace byhand_manipadrsHP = "KR 1C S # 10C - 74" in 13823
replace byhand_manipadrsHP = "CL 64B # 2D - 33" in 13826
replace byhand_manipadrsHP = "CL 65B # 2D - 02" in 13829
replace byhand_manipadrsHP = "CL 32B3 # 12 - 57" in 13846
replace byhand_manipadrsHP = "KR 4B # 34 - 47" in 13853
replace byhand_manipadrsHP = "KR 28D4 # 121B - 12" in 13867
replace byhand_manipadrsHP = "KR 28 DC # 121 - 33" in 13868
replace byhand_manipadrsHP = "KR 28B # 122D - 16" in 13870
replace byhand_manipadrsHP = "CL 121A # 28B6 - 13" in 13871
replace byhand_manipadrsHP = "KR 28 N # 124B - 36" in 13872
replace byhand_manipadrsHP = "KR 28E3 # 123B - 25" in 13874
replace byhand_manipadrsHP = "CL 122B # 28A - 113" in 13879
replace byhand_manipadrsHP = "KR 28N # 124BP - 24" in 13881
replace byhand_manipadrsHP = "CL 125 # 28E - 75" in 13882
replace byhand_manipadrsHP = "CL 121C # 09" in 13883
replace byhand_manipadrsHP = "CL 125A # 28B - 119" in 13884
replace byhand_manipadrsHP = "KR 28 DC # 121 - 33" in 13885
replace byhand_manipadrsHP = "CL 122 Bis # 28D4 - 45" in 13887
replace byhand_manipadrsHP = "CL 122 Bis # 28D7 - 38" in 13888
replace byhand_manipadrsHP = "CL 121 # 28B - 49" in 13889
replace byhand_manipadrsHP = "CL 124B # 28B1 - 51" in 13891
replace byhand_manipadrsHP = "KR 28D 8 # 122D - 44" in 13892
replace byhand_manipadrsHP = "CL 122 # 18B - 212" in 13893
replace byhand_manipadrsHP = "KR 28G2 # 124C - 45" in 13894
replace byhand_manipadrsHP = "CL 124A # 28B1 - 79" in 13898
replace byhand_manipadrsHP = "CL 121 # 28B - 49" in 13899
replace byhand_manipadrsHP = "KR 28D N # 121A - 20" in 13901
replace byhand_manipadrsHP = "KR 28D4 # 121B - 05" in 13902
replace byhand_manipadrsHP = "CL 123 # 38A Bis - 25" in 13904
replace byhand_manipadrsHP = "CL 125A # 28B - 120" in 13915
replace byhand_manipadrsHP = "KR 28F" in 13918
replace byhand_manipadrsHP = "KR 28F # 28D - 446" in 13919
replace byhand_manipadrsHP = "CL 124B # 28B1 - 04" in 13922
replace byhand_manipadrsHP = "CL 122 # 28D4 - 31" in 13923
replace byhand_manipadrsHP = "KR 10 # 1 S - 260" in 13924
replace byhand_manipadrsHP = "CL 123D2 Bis # 23" in 13926
replace byhand_manipadrsHP = "KR 28A # 124N - 28" in 13930
replace byhand_manipadrsHP = "KR 28E3 # 124C - 42" in 13939
replace byhand_manipadrsHP = "KR 28 C11 # 125 - 76" in 13941
replace byhand_manipadrsHP = "KR 28 E 3A # 124A - 27" in 13946
replace byhand_manipadrsHP = "KR 28D # 123A - 49" in 13947
replace byhand_manipadrsHP = "CL 22 - # 28D1 - 25" in 13948
replace byhand_manipadrsHP = "CL 22 # 28D1 - 25" in 13948
replace byhand_manipadrsHP = "CL 122 - # 28D1 - 25" in 13949
replace byhand_manipadrsHP = "KR 28" in 13950
replace byhand_manipadrsHP = "CL 32 # 27B - 12" in 14003

replace byhand_manipadrsHP = "CL 28 # 24A - 104" in 14007
replace byhand_manipadrsHP = "CL 18 3 # 67 - 48" in 14016
replace byhand_manipadrsHP = "AV 2 # 36 N - 38" in 14023
replace byhand_manipadrsHP = "CL 49 N # 3EN - 49" in 14029
replace byhand_manipadrsHP = "CL 39 N # 3CN - 129" in 14035
replace byhand_manipadrsHP = "CL 34 N # 2NA - 63" in 14040
replace byhand_manipadrsHP = "CL 36AN # 3CN - 31" in 14046
replace byhand_manipadrsHP = "CL 37A # 3CN - 31" in 14047
replace byhand_manipadrsHP = "CL 36AN # 3CN - 31" in 14048
replace byhand_manipadrsHP = "CL 37A # 3CN - 31" in 14049
replace byhand_manipadrsHP = "CL 37A # 3CN - 31" in 14050
replace byhand_manipadrsHP = "CL 33A N # 2EN - 54" in 14052
replace byhand_manipadrsHP = "CL 38A # 2A - 67" in 14056
replace byhand_manipadrsHP = "CL 34A N # 2AN - 63" in 14060
replace byhand_manipadrsHP = "CL 34A N # 2AN - 63" in 14061
replace byhand_manipadrsHP = "KR 76AB1 # 05" in 14068
replace byhand_manipadrsHP = "KR 76AB1 # 05" in 14069
replace byhand_manipadrsHP = "KR 74C # 1B - 105" in 14072
replace byhand_manipadrsHP = "KR 74A # 1B - 135" in 14156
replace byhand_manipadrsHP = "KR 78 # 1H - 23" in 14160
replace byhand_manipadrsHP = "TV 2 # 1C - 140" in 14175
replace byhand_manipadrsHP = "C 37 # 34B - 35" in 14193
replace byhand_manipadrsHP = "KR 37 # 34B - 35" in 14193
replace byhand_manipadrsHP = "" in 14202
replace byhand_manipadrsHP = "KR 33 # 34B - 10" in 14207
replace byhand_manipadrsHP = "KR 33A # 35A - 10" in 14210
replace byhand_manipadrsHP = "KR 32C # 35 - 16" in 14224
replace byhand_manipadrsHP = "KR 32A # 35 - 29" in 14226
replace byhand_manipadrsHP = "KR 33D3 # 35 - 52" in 14227
replace byhand_manipadrsHP = "KR 33A # 34B - 30" in 14232
replace byhand_manipadrsHP = "KR 32B # 34C - 31" in 14248
replace byhand_manipadrsHP = "KR 53 # 13A - 60" in 14259
replace byhand_manipadrsHP = "CL 18 # 56" in 14263
replace byhand_manipadrsHP = "KR 56A # 13E - 45" in 14302
replace byhand_manipadrsHP = "CL 13A3 # 50 - 57" in 14306
replace byhand_manipadrsHP = "CL 13A3 # 50 - 57" in 14308
replace byhand_manipadrsHP = "CL 13A3 # 50 - 57" in 14309
replace byhand_manipadrsHP = "CL 13A3 # 50 - 57" in 14310
replace byhand_manipadrsHP = "CL 13A3 # 50 - 57" in 14311
replace byhand_manipadrsHP = "CL 13A3 # 50 - 57" in 14312
replace byhand_manipadrsHP = "CL 13A3 # 50 - 57" in 14313
replace byhand_manipadrsHP = "CL 13A3 # 50 - 57" in 14314
replace byhand_manipadrsHP = "CL 13A3 # 50 - 57" in 14315
replace byhand_manipadrsHP = "KR 58 # 13A - 58" in 14320
replace byhand_manipadrsHP = "CL 47 # 50 - 38" in 14329
replace byhand_manipadrsHP = "CL 13C # 57A - 16" in 14343
replace byhand_manipadrsHP = "KR 013 # 42" in 14356
replace byhand_manipadrsHP = "KR 50 # 13 E - 66" in 14378
replace byhand_manipadrsHP = "KR 50 # 13 E - 66" in 14379
replace byhand_manipadrsHP = "KR 54 # 11A - 04" in 14380
replace byhand_manipadrsHP = "KR 53 # 11A - 47" in 14381
replace byhand_manipadrsHP = "KR 17 # 18 - 49" in 14388
replace byhand_manipadrsHP = "KR 17 # 18 - 49" in 14389
replace byhand_manipadrsHP = "CL 27A # 17F2 - 03" in 14390
replace byhand_manipadrsHP = "KR 17S # 28A - 23" in 14392
replace byhand_manipadrsHP = "KR 17F2 # 18 - 52" in 14393
replace byhand_manipadrsHP = "DG 18A # 17G - 26" in 14396
replace byhand_manipadrsHP = "DG 18 # 17G - 85" in 14405
replace byhand_manipadrsHP = "DG 18A # 17F1 - 15" in 14406
replace byhand_manipadrsHP = "DG 20 # 28A - 11" in 14413
replace byhand_manipadrsHP = "KR 17F1 # 18 - 35" in 14414
replace byhand_manipadrsHP = "KR 17 F1 # 18 - 35" in 14415
replace byhand_manipadrsHP = "KR 17 F1 # 18 - 35" in 14416
replace byhand_manipadrsHP = "KR 17 F1 # 18 - 35" in 14417
replace byhand_manipadrsHP = "KR 17 F1 # 18 - 35" in 14418
replace byhand_manipadrsHP = "KR 17F # 33A - 27" in 14419
replace byhand_manipadrsHP = "KR 17 EN # 25 - 74" in 14420
replace byhand_manipadrsHP = "DG 18B # 17C - 40" in 14421
replace byhand_manipadrsHP = "KR 17 D1 # 28A - 52" in 14424
replace byhand_manipadrsHP = "KR 17 D1 # 28A - 52" in 14425
replace byhand_manipadrsHP = "DG 18E # 17G - 55" in 14427
replace byhand_manipadrsHP = "DG 18E # 17G - 55" in 14428
replace byhand_manipadrsHP = "KR 17D1 # 28A - 38" in 14429
replace byhand_manipadrsHP = "KR 17D1 # 28A - 38" in 14430
replace byhand_manipadrsHP = "KR 17D # 28A - 54" in 14435
replace byhand_manipadrsHP = "KR 17B1 # 28A - 38" in 14436
replace byhand_manipadrsHP = "TV 28A # 18A - 58" in 14437
replace byhand_manipadrsHP = "KR 26F1 # 97 - 65" in 14438
replace byhand_manipadrsHP = "DG 110 # 26C - 44" in 14443
replace byhand_manipadrsHP = "CL 88D # 28D2 - 72" in 14457
replace byhand_manipadrsHP = "CL 109 # 26B1 - 49" in 14461
replace byhand_manipadrsHP = "CL 99 # 26I - 18" in 14462
replace byhand_manipadrsHP = "DG 46 O # 54A - 31" in 14472
replace byhand_manipadrsHP = "CL 100 # 26B - 138" in 14474
replace byhand_manipadrsHP = "KR 26B3 # 89 - 46" in 14475
replace byhand_manipadrsHP = "KR 28C1 # 85 - 24" in 14480
replace byhand_manipadrsHP = "" in 14482
replace byhand_manipadrsHP = "KR 26G # 97 - 45" in 14484
replace byhand_manipadrsHP = "CL 80 Bis # 26 - 71" in 14485
replace byhand_manipadrsHP = "KR 26D1 # 91 - 46" in 14488
replace byhand_manipadrsHP = "DG 110 # 26I I3 - 29" in 14489
replace byhand_manipadrsHP = "DG 109 # 26G - 14" in 14490
replace byhand_manipadrsHP = "KR 26B3 # 80 - 47" in 14492
replace byhand_manipadrsHP = "KR 26C1 # 94 - 58" in 14493
replace byhand_manipadrsHP = "KR 26C1 # 94 - 58" in 14494
replace byhand_manipadrsHP = "KR 26A # 108A - 18" in 14497
replace byhand_manipadrsHP = "CL 91 # 26B3 - 33" in 14510

replace byhand_manipadrsHP = "CL 80 E1 # 26 - 30" in 14520
replace byhand_manipadrsHP = "KR 26A # 108A - 22" in 14532
replace byhand_manipadrsHP = "KR 26A # 108A - 22" in 14533
replace byhand_manipadrsHP = "KR 26M # 72W - 109" in 14535
replace byhand_manipadrsHP = "KR 26C1 # 97 - 09" in 14536
replace byhand_manipadrsHP = "CL 98 # 26B1 - 100" in 14538
replace byhand_manipadrsHP = "KR 26B2 # 91 - 35" in 14541
replace byhand_manipadrsHP = "CL 87 # 26B - 53" in 14542
replace byhand_manipadrsHP = "CL 89 # 26B - 14" in 14550
replace byhand_manipadrsHP = "CL 91 # 26 - 15 - 09" in 14556
replace byhand_manipadrsHP = "CL 90 # 26D - 13X" in 14557
replace byhand_manipadrsHP = "CL 78 # 8A - 25" in 14568
replace byhand_manipadrsHP = "DG 26K # 87 - 18" in 14576
replace byhand_manipadrsHP = "CL 78 # 8A - 23" in 14577
replace byhand_manipadrsHP = "CL 76 # 8C - 17" in 14579
replace byhand_manipadrsHP = "KR 6A # 71D - 57" in 14610
replace byhand_manipadrsHP = "KR 6B # 71D - 33" in 14621
replace byhand_manipadrsHP = "CL 5 11 # 10 - 97" in 14623
replace byhand_manipadrsHP = "CL 5 # 11 - 10 - 97" in 14623
replace byhand_manipadrsHP = "DG 23 # 30 - 35" in 14624
replace byhand_manipadrsHP = "DG 21 # 29 - 60" in 14625
replace byhand_manipadrsHP = "DG 21 # 29 - 60" in 14626
replace byhand_manipadrsHP = "DG 22 # 30 - 37" in 14627
replace byhand_manipadrsHP = "DG 22 # 30 - 37" in 14628
replace byhand_manipadrsHP = "DG 22 # 30 - 37" in 14629
replace byhand_manipadrsHP = "DG 22 # 30 - 42" in 14633
replace byhand_manipadrsHP = "TV 31 # 21 - 09" in 14634
replace byhand_manipadrsHP = "KR 17C # 33D - 14" in 14636
replace byhand_manipadrsHP = "KR 17C # 21 - 24" in 14641
replace byhand_manipadrsHP = "DG 22 # 30 - 42" in 14644
replace byhand_manipadrsHP = "KR 44 # 37 - 63" in 14700
replace byhand_manipadrsHP = "CL 43 # 43A - 17" in 14763
replace byhand_manipadrsHP = "KR 41A # 43 - 54B" in 14773
replace byhand_manipadrsHP = "KR 41A # 43 - 54B" in 14774
replace byhand_manipadrsHP = "CL 43 # 43A - 18" in 14781
replace byhand_manipadrsHP = "CL 93A # 42b - 09" in 14786
replace byhand_manipadrsHP = "KR 39A # 42B - 09" in 14787
replace byhand_manipadrsHP = "CL 93A # 42B - 09" in 14786
replace byhand_manipadrsHP = "KR 42 # 38 - 49" in 14814
replace byhand_manipadrsHP = "KR 26K # 71B1 - 09" in 14821
replace byhand_manipadrsHP = "" in 14822
replace byhand_manipadrsHP = "DG 71C1 # 26J - 51" in 14823
replace byhand_manipadrsHP = "DG 71C1 # 2B1 - 51" in 14824
replace byhand_manipadrsHP = "DG 72C # 26J - 55" in 14825
replace byhand_manipadrsHP = "KR 26J # 72A - 28" in 14827
replace byhand_manipadrsHP = "KR 26M # 72 - 09" in 14831
replace byhand_manipadrsHP = "KR 26M # 72 - 21" in 14835
replace byhand_manipadrsHP = "TV 26J # 70 - 56" in 14838
replace byhand_manipadrsHP = "KR 26 I2 # 72C - 22" in 14839
replace byhand_manipadrsHP = "TV 26J # 70 - 122" in 14840
replace byhand_manipadrsHP = "KR 26U # 71A1 - 26" in 14842
replace byhand_manipadrsHP = "KR 26L # 72E Bis - 35" in 14849

replace byhand_manipadrsHP = "KR 26K # 71B1 - 09" in 14850
replace byhand_manipadrsHP = "KR 26L # 71C - 20" in 14851
replace byhand_manipadrsHP = "KR 26D 70 # 70 - 12" in 14852
replace byhand_manipadrsHP = "KR 26 KD # 71A - 121" in 14853
replace byhand_manipadrsHP = "KR 26M # 71 - 15" in 14857
replace byhand_manipadrsHP = "DG 72 # 26 2 - 83" in 14858
replace byhand_manipadrsHP = "KR 26I # 71B1 - 10" in 14862
replace byhand_manipadrsHP = "DG 28C # 42A - 37" in 14867
replace byhand_manipadrsHP = "DG 28C # 42A - 27" in 14868
replace byhand_manipadrsHP = "KR 26M # 71A - 21" in 14869
replace byhand_manipadrsHP = "KR 26B # 71B1 - 26" in 14874
replace byhand_manipadrsHP = "KR 26K # 71A1 - 15" in 14875
replace byhand_manipadrsHP = "KR 26L # 70 - 32" in 14877
replace byhand_manipadrsHP = "CL 74 # 26C1 - 19" in 14878
replace byhand_manipadrsHP = "CL 17C # 29 - 31" in 14909
replace byhand_manipadrsHP = "KR 17 # 29T - 17" in 14910
replace byhand_manipadrsHP = "KR 17CT # 30 - 67" in 14913
replace byhand_manipadrsHP = "KR 17V # 27B - 50" in 14914
replace byhand_manipadrsHP = "KR 17C # 31 - 22" in 14916
replace byhand_manipadrsHP = "DG 20 # 17K - 19" in 14917
replace byhand_manipadrsHP = "KR 17C # 29 - 31" in 14922
replace byhand_manipadrsHP = "KR 20 # 33C - 178" in 14923
replace byhand_manipadrsHP = "KR 17F # 29 - 39" in 14928
replace byhand_manipadrsHP = "KR 17F # 29 - 39" in 14929
replace byhand_manipadrsHP = "KR 17F # 29 - 39" in 14930
replace byhand_manipadrsHP = "KR 17F # 29 - 39" in 14931
replace byhand_manipadrsHP = "KR 17F # 29 - 39" in 14932
replace byhand_manipadrsHP = "TV 30 # 17F - 68" in 14945
replace byhand_manipadrsHP = "KR 17D # 30 - 38" in 14950
replace byhand_manipadrsHP = "CL 47 # 2B1 - 17" in 14956
replace byhand_manipadrsHP = "KR 4N # 44AN - 23" in 14957
replace byhand_manipadrsHP = "CL 54 # 11D - 54" in 14960
replace byhand_manipadrsHP = "KR 4 E # 46A - 47" in 14962
replace byhand_manipadrsHP = "KR 2 # 45C - 03" in 14967
replace byhand_manipadrsHP = "KR 1D # 46C - 27" in 14969

replace byhand_manipadrsHP = "KR 2 C111 # 45 2A - 27" in 14973
replace byhand_manipadrsHP = "CL 56 # 4B - 145" in 14974
replace byhand_manipadrsHP = "KR 1H # 46C - 57" in 14977*/

rename NOMBRE barrio

/*replace byhand_manipadrsHP = "KR 2 C111 # 45 2A - 27" in 14973
replace byhand_manipadrsHP = "CL 56 # 4B - 145" in 14974
replace byhand_manipadrsHP = "KR 1H # 46C - 57" in 14977
replace byhand_manipadrsHP = "CL 76A # 1 E - 19" in 14986
replace byhand_manipadrsHP = "KR 4D # 52A - 29" in 14988
replace byhand_manipadrsHP = "KR 2B1 # 47 - 30" in 14993
replace byhand_manipadrsHP = "KR 1G # 46E - 16" in 14995
replace byhand_manipadrsHP = "CL 45C # 1D2 - 03" in 14997
replace byhand_manipadrsHP = "KR 1H # 4C - 15" in 15001
replace byhand_manipadrsHP = "CL 71 # 1A1 - 44" in 15004
replace byhand_manipadrsHP = "CL 46 # 2C - 37" in 15005
replace byhand_manipadrsHP = "CL 84 # 1KN - 04" in 15025

replace byhand_manipadrsHP = "CL 56 # 31C - 2 Bis 08" in 15029
replace byhand_manipadrsHP = "CL 58A # 1B1 - 11" in 15034
replace byhand_manipadrsHP = "KR 1E # 46 - 54" in 15036
replace byhand_manipadrsHP = "CL 56 # 1C2B - 08" in 15044
replace byhand_manipadrsHP = "CL 2A O # 4A - 10" in 15082
replace byhand_manipadrsHP = "KR 5 # 3 1 - 38" in 15087
replace byhand_manipadrsHP = "CL 34A # 27 - 08" in 15096
replace byhand_manipadrsHP = "CL 34 # 27 - 52" in 15100
replace byhand_manipadrsHP = "KR 29 # 28B - 01" in 15101
replace byhand_manipadrsHP = "CL 26 # 32A - 22" in 15102
replace byhand_manipadrsHP = "KR 29D # 28B2 - 5" in 15104
replace byhand_manipadrsHP = "KR 26 # 32A - 22" in 15107
replace byhand_manipadrsHP = "CL 34A # 27 - 44" in 15108
replace byhand_manipadrsHP = "CL 34A # 27 - 44" in 15109
replace byhand_manipadrsHP = "TV 26 # 28C - 42" in 15112
replace byhand_manipadrsHP = "KR 27 # 33H - 34" in 15121

replace byhand_manipadrsHP = "KR 33A # 45 - 05" in 15136
replace byhand_manipadrsHP = "KR 32 # 32 - 13" in 15171
replace byhand_manipadrsHP = "KR 36A # 30 - 50" in 15178
replace byhand_manipadrsHP = "KR 32 3 # 32 - 22" in 15188
replace byhand_manipadrsHP = "KR 35 # 31A - 66" in 15194
replace byhand_manipadrsHP = "KR 35 # 31A - 66" in 15196
replace byhand_manipadrsHP = "KR 33B # 30 - 72" in 15198
replace byhand_manipadrsHP = "CL 3A # 18 - 16" in 15234
replace byhand_manipadrsHP = "KR 13 # 2 - 20" in 15243
replace byhand_manipadrsHP = "CL 1A # 121 - 33" in 15244
replace byhand_manipadrsHP = "KR 13# 2 - 22" in 15247
replace byhand_manipadrsHP = "KR 12 O # 219" in 15249
replace byhand_manipadrsHP = "CL 23M2 # 28 - C27" in 15267
replace byhand_manipadrsHP = "CL 23M2 # 28C - 27" in 15267
replace byhand_manipadrsHP = "KR 24 # 24 - 30" in 15273
replace byhand_manipadrsHP = "KR 36A N # 5B 1 - 38" in 15282
replace byhand_manipadrsHP = "KR 30 3# 5C - 21" in 15288
replace byhand_manipadrsHP = "KR 30 # 5B1 - 70" in 15293
replace byhand_manipadrsHP = "KR 36C # 5B1 - 39" in 15294
replace byhand_manipadrsHP = "AV 6 # 38 - 32" in 15300
replace byhand_manipadrsHP = "AV 6 # 38 - 32" in 15301
replace byhand_manipadrsHP = "KR 37 # 5B1 - 37" in 15302
replace byhand_manipadrsHP = "KR 36B5B # 3 - 78" in 15306
replace byhand_manipadrsHP = "KR 36B # 5B 3 - 78" in 15306
replace byhand_manipadrsHP = "CL 5B3 # 38 - 20" in 15315
replace byhand_manipadrsHP = "CL 4C # 38D - 22" in 15325
replace byhand_manipadrsHP = "KR 24CB # 2 - 150" in 15329
replace byhand_manipadrsHP = "CL 5B3 # 37 - 35" in 15331
replace byhand_manipadrsHP = "KR 9 # 5A - 60" in 15334
replace byhand_manipadrsHP = "KR 89 # 18 - 72 - CS - 11" in 15339
replace byhand_manipadrsHP = "KR 89 # 18 - 72 CS 11" in 15339
replace byhand_manipadrsHP = "KR 89 # 18 - 72 CS 11" in 15340
replace byhand_manipadrsHP = "CL 94A Bis # 19" in 15346
replace byhand_manipadrsHP = "CL 23 KR # 50" in 15362
replace byhand_manipadrsHP = "CL 23 # 50" in 15362
replace byhand_manipadrsHP = "CL 23" in 15363
replace byhand_manipadrsHP = "KR 14 # 05" in 15368
replace byhand_manipadrsHP = "KR 13 # 12A - 14" in 15388
replace byhand_manipadrsHP = "CL 33B # 26B - 18" in 15394
replace byhand_manipadrsHP = "CL 18 # 41C - 68" in 15442
replace byhand_manipadrsHP = "CL 20B # 46A S - 15" in 15445
replace byhand_manipadrsHP = "KR 48C # 23I - 89" in 15458
replace byhand_manipadrsHP = "CL 23 # 46A - 19" in 15497
replace byhand_manipadrsHP = "KR 47A # 17A - 15" in 15507
replace byhand_manipadrsHP = "CL 43 # 34" in 15517
replace byhand_manipadrsHP = "KR 41C # 18 - 45" in 15533
replace byhand_manipadrsHP = "CL 23 # 49A - 39" in 15535
replace byhand_manipadrsHP = "CL 23 # 10B - 55" in 15536
replace byhand_manipadrsHP = "KR 1C1 # 71 - 14" in 15538
replace byhand_manipadrsHP = "CL 72A # 1A3 - 60" in 15540
replace byhand_manipadrsHP = "CL 72A # 1AZ - 24" in 15542
replace byhand_manipadrsHP = "CL 72A # 1A2 - 24" in 15542
replace byhand_manipadrsHP = "KR 1A # 73 Bis - 08" in 15553
replace byhand_manipadrsHP = "KR 1A12 # 73 - 09" in 15555
replace byhand_manipadrsHP = "KR N 72A # 20" in 15560
replace byhand_manipadrsHP = "" in 15560
replace byhand_manipadrsHP = "KR 1A 10 # 73 - 39" in 15561
replace byhand_manipadrsHP = "KR 1B 1 # 72 - 61" in 15563
replace byhand_manipadrsHP = "KR 1 9 # 72 - 21" in 15571
replace byhand_manipadrsHP = "CL 70 # 1A9 - 25" in 15573
replace byhand_manipadrsHP = "CL 72A # 1A 1 - 02" in 15577
replace byhand_manipadrsHP = "KR 1A13 # 70 - 81" in 15579
replace byhand_manipadrsHP = "KR 1A13 # 70 - 104" in 15583
replace byhand_manipadrsHP = "KR 1C1 # 71 - 14" in 15590
replace byhand_manipadrsHP = "KR 26B2 # 73A - 23" in 15596
replace byhand_manipadrsHP = "KR 1A14 # 71 - 46" in 15597
replace byhand_manipadrsHP = "CL 72A # 1A3 - 25B" in 15608
replace byhand_manipadrsHP = "CL 73 # 1C - 12" in 15610
replace byhand_manipadrsHP = "CL 73 # 1C1 - 81" in 15611
replace byhand_manipadrsHP = "CL 73 # 1C1 - 81" in 15612
replace byhand_manipadrsHP = "All 72A # 1 - 28" in 15614
replace byhand_manipadrsHP = "KR 1A 2C # 73 - 37" in 15615
replace byhand_manipadrsHP = "KR 1A11 # 72 - 22" in 15618
replace byhand_manipadrsHP = "KR 1A9 # 73 - 39" in 15624
replace byhand_manipadrsHP = "KR 1A8 # 73 - 41" in 15626
replace byhand_manipadrsHP = "KR 1 10 # 72 - 18" in 15632
replace byhand_manipadrsHP = "CL 72C # 1A 4 - 20" in 15633
replace byhand_manipadrsHP = "KR 1C2 # 72 - 49" in 15634
replace byhand_manipadrsHP = "KR 1B2 # 70 - 76" in 15635
replace byhand_manipadrsHP = "KR 1A7 # 71 - 106" in 15642
replace byhand_manipadrsHP = "DG 14 # 72A - 01" in 15644
replace byhand_manipadrsHP = "KR 1A2B # 73 - 08" in 15646
replace byhand_manipadrsHP = "CL 73A # 1E - 20" in 15652
replace byhand_manipadrsHP = "KR 1 Bis # 56 - 161 A 1036" in 15653
replace byhand_manipadrsHP = "CL 73 # 1A 10 - 35" in 15656
replace byhand_manipadrsHP = "KR 1AB1 # 72 - 81" in 15659
replace byhand_manipadrsHP = "KR 1A8 # 72 - 69" in 15664
replace byhand_manipadrsHP = "KR 731A # 10 - 35" in 15665
replace byhand_manipadrsHP = "KR 1A8 - # 72 - 32" in 15666
replace byhand_manipadrsHP = "KR 1A 14 # 72 - 100" in 15671
replace byhand_manipadrsHP = "KR 1A 14 # 72 - 100" in 15672
replace byhand_manipadrsHP = "CL 72C # 1A 2 - 62" in 15675
replace byhand_manipadrsHP = "KR 1AB # 70 - 69" in 15676
replace byhand_manipadrsHP = "KR 1A6 # 71 - 74" in 15677
replace byhand_manipadrsHP = "KR 1A4A # 7 3 - 42" in 15686
replace byhand_manipadrsHP = "KR 1A4A # 73 - 42" in 15686
replace byhand_manipadrsHP = "CL 72D1 # A1 - 44" in 15689
replace byhand_manipadrsHP = "CL 73A # 1C1 - 04" in 15690
replace byhand_manipadrsHP = "KR 7C Bis # 72B - 12" in 15691
replace byhand_manipadrsHP = "CL 72 # 1A3 - 89" in 15698
replace byhand_manipadrsHP = "KR 1A # 70C - 25" in 15699
replace byhand_manipadrsHP = "CL 72B # 1A 4B - 71" in 15700
replace byhand_manipadrsHP = "CL 72C # 1A2 - 86" in 15701
replace byhand_manipadrsHP = "CL 72D # 1A 1 - 68" in 15705
replace byhand_manipadrsHP = "CL 72D # 1A1 - 68" in 15705
replace byhand_manipadrsHP = "CL 70 # 31A9 - 15" in 15710
replace byhand_manipadrsHP = "CL 70 # 31A9 - 15" in 15711
replace byhand_manipadrsHP = "KR 1A7 # 72 - 13" in 15712
replace byhand_manipadrsHP = "CL 72A # 1A4B - 37" in 15713
replace byhand_manipadrsHP = "CL 73 Bis # 1A - 05" in 15714
replace byhand_manipadrsHP = "KR 1 14 # 70 - 104" in 15716
replace byhand_manipadrsHP = "KR 1A4 # 54 - 73 - 42" in 15718
replace byhand_manipadrsHP = "KR 1A4 # 54 - 73 - 42" in 15719
replace byhand_manipadrsHP = "KR 7C Bis # 63 - 20" in 15724
replace byhand_manipadrsHP = "KR 7C Bis # 63 - 20" in 15725
replace byhand_manipadrsHP = "KR 7 E Bis # 61 - 18" in 15727
replace byhand_manipadrsHP = "KR 7CB # 65 - 20" in 15730
replace byhand_manipadrsHP = "CL 22 # 7A - 35" in 15747
replace byhand_manipadrsHP = "KR 7 # 197 - 29" in 15749
replace byhand_manipadrsHP = "KR 3 # 19" in 15750
replace byhand_manipadrsHP = "KR 2A # 19 - 63B" in 15765
replace byhand_manipadrsHP = "CL 22 # 7A - 20B" in 15771
replace byhand_manipadrsHP = "KR 2 # 19 - 76" in 15792
replace byhand_manipadrsHP = "KR 13 # 14A - 25" in 15815
replace byhand_manipadrsHP = "KR 1 N # 10 CN - 60" in 15827
replace byhand_manipadrsHP = "DG 30A # 30A - 09" in 15828
replace byhand_manipadrsHP = "CL 14 # 4A - 20" in 15839
replace byhand_manipadrsHP = "DG 32 # 32C - 02" in 15841
replace byhand_manipadrsHP = "KR 31 # 32 - 37" in 15856
replace byhand_manipadrsHP = "CL 26 # 5B - 79" in 15857
replace byhand_manipadrsHP = "KR 29A # 31 - 40" in 15859
replace byhand_manipadrsHP = "KR 29A # 31 - 40" in 15860
replace byhand_manipadrsHP = "CL 36 # 29A - 40" in 15862
replace byhand_manipadrsHP = "KR 2A # 31 - 06" in 15864
replace byhand_manipadrsHP = "DG 31 # 31A - 19" in 15868
replace byhand_manipadrsHP = "KR 30 # 32 - 23" in 15869
replace byhand_manipadrsHP = "DG 28B # 28 - 39" in 15872
replace byhand_manipadrsHP = "DG 28B # 28 - 39" in 15873
replace byhand_manipadrsHP = "KR 29B # 30A - 25" in 15877
replace byhand_manipadrsHP = "KR 29 # 31 - 21" in 15894
replace byhand_manipadrsHP = "KR 31 # 32 - 37" in 15897
replace byhand_manipadrsHP = "DG 30 # 29A - 125" in 15898
replace byhand_manipadrsHP = "CL 35 G2 # 29A - 11" in 15899
replace byhand_manipadrsHP = "KR 31 # 33 - 12" in 15906
replace byhand_manipadrsHP = "KR 29 # 31 - 87" in 15907
replace byhand_manipadrsHP = "KR 31A # 31 - 26" in 15912
replace byhand_manipadrsHP = "CL 44 # 29 - 19" in 15914
replace byhand_manipadrsHP = "CL 25 N # 2 Bis N - 20" in 15916
replace byhand_manipadrsHP = "KR 37 3 # 25 - 16" in 15918
replace byhand_manipadrsHP = "CL 31N # 2A - 25" in 15922

replace byhand_manipadrsHP = "KR 59A3 # 11 - 57" in 15929
replace byhand_manipadrsHP = "KR 29B # 17 - 35" in 15960
replace byhand_manipadrsHP = "CL 19A # 32A - 71" in 15963
replace byhand_manipadrsHP = "CL 19 # 18 - 05" in 15987
replace byhand_manipadrsHP = "CL 14 # 29B - 21" in 16043
replace byhand_manipadrsHP = "CL 18 # 29A - 27" in 16049
replace byhand_manipadrsHP = "KR 31 # 23B" in 16063
replace byhand_manipadrsHP = "KR 31 # 23B" in 16064
replace byhand_manipadrsHP = "CL 23 # 33 - 19" in 16065
replace byhand_manipadrsHP = "KR 19 # 33F - 19" in 16076
replace byhand_manipadrsHP = "KR 20 # 33T - 57" in 16088
replace byhand_manipadrsHP = "KR 22 # 36 - 78" in 16094
replace byhand_manipadrsHP = "KR 38B # 3 - 95" in 16131
replace byhand_manipadrsHP = "KR 37 # 1 O - 82" in 16143
replace byhand_manipadrsHP = "DG 23 # 31 - 29" in 16145
replace byhand_manipadrsHP = "DG 23 # 31 - 29" in 16146
replace byhand_manipadrsHP = "KR 23 # 33F - 44" in 16151
replace byhand_manipadrsHP = "DG 19 # 25 - 22" in 16153
replace byhand_manipadrsHP = "DG 23 # 31 - 15" in 16168
replace byhand_manipadrsHP = "KR 24A # 33C - 184" in 16171
replace byhand_manipadrsHP = "KR 24A # 29 - 85" in 16172
replace byhand_manipadrsHP = "KR 24A # 29 - 85" in 16173
replace byhand_manipadrsHP = "KR 20 # 33C - 72" in 16175
replace byhand_manipadrsHP = "KR 23 # 29 - 118" in 16180
replace byhand_manipadrsHP = "TV 29 # 20 - 50" in 16183
replace byhand_manipadrsHP = "KR 19 # 33C - 33" in 16185
replace byhand_manipadrsHP = "KR 23 # 29 - 118" in 16187
replace byhand_manipadrsHP = "KR 23 # 29 - 118" in 16188
replace byhand_manipadrsHP = "KR 22 # 33 E - 83" in 16200
replace byhand_manipadrsHP = "KR 17C # 23 - 18" in 16201
replace byhand_manipadrsHP = "KR 24B # 29 - 63" in 16203
replace byhand_manipadrsHP = "DG 24A # 25 - 63" in 16205
replace byhand_manipadrsHP = "KR 20 # 33C - 107" in 16210
replace byhand_manipadrsHP = "KR 24C # 33C - 165" in 16214
replace byhand_manipadrsHP = "KR 24C # 33C - 17" in 16218
replace byhand_manipadrsHP = "DG 19 # 25 - 22" in 16220
replace byhand_manipadrsHP = "AV 4 O # 21A - 57" in 16222
replace byhand_manipadrsHP = "DG 22 # 17C - 63" in 16231
replace byhand_manipadrsHP = "AV 4 O # 9 - 43" in 16253
replace byhand_manipadrsHP = "KR 1 # 26" in 16261
replace byhand_manipadrsHP = "KR 1 # 26" in 16262
replace byhand_manipadrsHP = "KR 2 # 36A - 58" in 16266
replace byhand_manipadrsHP = "CL 33 # 1A - 22" in 16269
replace byhand_manipadrsHP = "KR 46 # 13A - 47" in 16274
replace byhand_manipadrsHP = "KR 13B # 21" in 16283
replace byhand_manipadrsHP = "KR 47 3 # 13A - 52" in 16293
replace byhand_manipadrsHP = "KR 44 N # 13A - 67" in 16305

replace byhand_manipadrsHP = "KR 46A # 13B - 66" in 16310
replace byhand_manipadrsHP = "KR 16B O # 2C3 - 08" in 16317
replace byhand_manipadrsHP = "CL 3 O # 73B - 46" in 16318
replace byhand_manipadrsHP = "CL 3 O # 73B - 46" in 16319
replace byhand_manipadrsHP = "CL 28 O # 73A" in 16321
replace byhand_manipadrsHP = "CL 2B O # 73D - 16" in 16323
replace byhand_manipadrsHP = "KR 94 # 1B - 28" in 16331
replace byhand_manipadrsHP = "KR 94 # 1B - 46" in 16341
replace byhand_manipadrsHP = "KR 94A # 1A - 11" in 16342
replace byhand_manipadrsHP = "KR 94 2 O # 2 Bis - 18" in 16349
replace byhand_manipadrsHP = "KR 82 O # 3D - 23" in 16350
replace byhand_manipadrsHP = "KR 94 # 2B - 43" in 16351
replace byhand_manipadrsHP = "KR 9A # 1 - 122" in 16365
replace byhand_manipadrsHP = "KR 9A A1 # 122" in 16365
replace byhand_manipadrsHP = "" in 16365
replace byhand_manipadrsHP = "KR 9A A1 # 122" in 16365
replace byhand_manipadrsHP = "" in 16365
replace byhand_manipadrsHP = "CL 1 # 94A Bis - 53" in 16367
replace byhand_manipadrsHP = "CL 1 # 94A - 53" in 16368
replace byhand_manipadrsHP = "CL 1 # 91A Bis - 53" in 16369
replace byhand_manipadrsHP = "CL 1 # 94A Bis - 53" in 16368
replace byhand_manipadrsHP = "CL 1 # 94A Bis - 53" in 16369
replace byhand_manipadrsHP = "KR 94 O # 1A - 89" in 16388
replace byhand_manipadrsHP = "CL 2 # 94 - 23" in 16403

replace byhand_manipadrsHP = "KR 37 # 1 O - 45" in 16410
replace byhand_manipadrsHP = "CL 54 N # 9N - 12" in 16421
replace byhand_manipadrsHP = "CL 22A O" in 16422
replace byhand_manipadrsHP = "CL 16B" in 16425
replace byhand_manipadrsHP = "KR 93 # 2C - 126" in 16428
replace byhand_manipadrsHP = "KR 93 # 2C - 126" in 16429
replace byhand_manipadrsHP = "KR 93 # 2C - 126" in 16430
replace byhand_manipadrsHP = "KR 93 # 2C - 126" in 16431
replace byhand_manipadrsHP = "KR 93 # 2C - 126" in 16432
replace byhand_manipadrsHP = "KR 93 # 2C - 126" in 16433
replace byhand_manipadrsHP = "KR 95 # 2B - 59" in 16436
replace byhand_manipadrsHP = "KR 97 # 20 - 29" in 16437
replace byhand_manipadrsHP = "AV 5 E # 42 - 26" in 16439
replace byhand_manipadrsHP = "KR 1IN # 77 - 05" in 16440
replace byhand_manipadrsHP = "CL 72C # 1 - 76" in 16441
replace byhand_manipadrsHP = "CL 84 # 14 - 32B" in 16444
replace byhand_manipadrsHP = "KR 1JN # 81 - 20" in 16445
replace byhand_manipadrsHP = "KR 1 LN # 81 - 89" in 16446
replace byhand_manipadrsHP = "KR 1F # 82 - 75" in 16449
replace byhand_manipadrsHP = "KR 1IN # 82 - 44" in 16451
replace byhand_manipadrsHP = "CL 71I1 # 3EN - 22" in 16454
replace byhand_manipadrsHP = "KR 1 JN # 82 - 16" in 16456
replace byhand_manipadrsHP = "CL 72C # 28 - 11" in 16475
replace byhand_manipadrsHP = "DG 18 # 71A - 66" in 16484
replace byhand_manipadrsHP = "KR 9 # 72B - 58" in 16491
replace byhand_manipadrsHP = "DG 14 # 71A - 45" in 16494
replace byhand_manipadrsHP = "DG 13 # 71AG - 6" in 16497
replace byhand_manipadrsHP = "KR 22 # 72 1 - 06" in 16500
replace byhand_manipadrsHP = "DG 18B # 17F1 - 28" in 16503
replace byhand_manipadrsHP = "DG 19 # 71A - 11" in 16507
replace byhand_manipadrsHP = "CL 72B # 8D - 09" in 16511
replace byhand_manipadrsHP = "TV 72 S # 26G9 - 26" in 16512
replace byhand_manipadrsHP = "TV 72 # 166 9 - 26" in 16513
replace byhand_manipadrsHP = "DG 14 # 71A - 122" in 16523
replace byhand_manipadrsHP = "KR 107 # 2B - 45" in 16525
replace byhand_manipadrsHP = "KR 24 E # 11A - 24" in 16529
replace byhand_manipadrsHP = "C 37 # 17A - 40" in 16531
replace byhand_manipadrsHP = "DG 19 # 72A - 57" in 16538
replace byhand_manipadrsHP = "KR 197 # 72 - 13A3" in 16544
replace byhand_manipadrsHP = "DG 13 # 71 - 48" in 16545
replace byhand_manipadrsHP = "DG 16 # 71A - 122" in 16552
replace byhand_manipadrsHP = "KR 8C # 72B - 59" in 16554
replace byhand_manipadrsHP = "DG 14 # 71A - 21" in 16557
replace byhand_manipadrsHP = "DG 19 # 72A - 51" in 16560
replace byhand_manipadrsHP = "DG 13 # 71B - 17" in 16568
replace byhand_manipadrsHP = "KR 74D O # 2 - 34" in 16569
replace byhand_manipadrsHP = "CL 6G # 51B - 33" in 16574
replace byhand_manipadrsHP = "CL 11 # 11 - 66" in 16575
replace byhand_manipadrsHP = "CL 6AE # 40C - 17" in 16581
replace byhand_manipadrsHP = "CL 6H O # 50C - 30" in 16586
replace byhand_manipadrsHP = "KR 50FN # 13B - 29" in 16592
replace byhand_manipadrsHP = "KR 50 # 8 Bis - 64 O" in 16593
replace byhand_manipadrsHP = "KR 50 # 8 Bis - 64 O" in 16594
replace byhand_manipadrsHP = "KR 40B O # 5B - 45" in 16595
replace byhand_manipadrsHP = "CL 13 # 46A - 25" in 16601
replace byhand_manipadrsHP = "KR 53 # 2" in 16603
replace byhand_manipadrsHP = "CL 123A # 28 E1 - 27" in 16607
replace byhand_manipadrsHP = "CL 18 O # 50D - 14" in 16612
replace byhand_manipadrsHP = "KR 52A # 34 - 10A" in 16613
replace byhand_manipadrsHP = "CL 2 O # 51 - 118" in 16631
replace byhand_manipadrsHP = "CL 6 # 49 - 70" in 16635
replace byhand_manipadrsHP = "KR 42 6 O # 3 - 63" in 16647
replace byhand_manipadrsHP = "KR 42 # 6 O 3 - 63" in 16647
replace byhand_manipadrsHP = "CL 9B O # 50 - 13" in 16651
replace byhand_manipadrsHP = "CL 3 O # 42A - 03" in 16653
replace byhand_manipadrsHP = "CL 6B # 52 - 99" in 16673
replace byhand_manipadrsHP = "CL 10 # 52 - 83" in 16676
replace byhand_manipadrsHP = "CL 5 O # 51 - 15" in 16678
replace byhand_manipadrsHP = "KR 53 # 12 13 - 23" in 16680
replace byhand_manipadrsHP = "KR 50 # 1 - 42 O" in 16695
replace byhand_manipadrsHP = "KR 54A # 47 - 07" in 16710
replace byhand_manipadrsHP = "CL 11 O # 50 - 25" in 16711
replace byhand_manipadrsHP = "CL 3 O # 3A - 45" in 16718
replace byhand_manipadrsHP = "CL 18 # 49B1 - 47" in 16722
replace byhand_manipadrsHP = "" in 16727
replace byhand_manipadrsHP = "CL 6A # 11C" in 16745
replace byhand_manipadrsHP = "KR 43 O # 8B - 30" in 16752
replace byhand_manipadrsHP = "KR 17F # 28A - 23" in 16762
replace byhand_manipadrsHP = "KR 17B # 28A - 57" in 16767
replace byhand_manipadrsHP = "KR 3 O" in 16774
replace byhand_manipadrsHP = "CL 99 # 27D - 130" in 16784
replace byhand_manipadrsHP = "KR 42 # 5B - 17" in 16790
replace byhand_manipadrsHP = "KR 1A6 # 73 - 73" in 16792
replace byhand_manipadrsHP = "CL 3 # 140" in 16815
replace byhand_manipadrsHP = "" in 16821
replace byhand_manipadrsHP = "" in 16822
replace byhand_manipadrsHP = "" in 16823
replace byhand_manipadrsHP = "" in 16824
replace byhand_manipadrsHP = "" in 16825
replace byhand_manipadrsHP = "KR 28B # 28C - 43" in 16830
replace byhand_manipadrsHP = "KR 28C # 28C - 36" in 16863
replace byhand_manipadrsHP = "CL 55A # 28G - 32" in 16871
replace byhand_manipadrsHP = "KR 28 AD # 28 - 56" in 16873
replace byhand_manipadrsHP = "CL 44 # 28F - 33" in 16890
replace byhand_manipadrsHP = "CL 123A # 28D 10 - 13" in 16896
replace byhand_manipadrsHP = "CL 123A3 # 28E3 - 19" in 16897
replace byhand_manipadrsHP = "CL 16 # 12A - 13" in 16912
replace byhand_manipadrsHP = "KR 9 # 16 - 140" in 16915
replace byhand_manipadrsHP = "KR 10 # 18" in 16921
replace byhand_manipadrsHP = "CL 16 # 11B - 15" in 16927
replace byhand_manipadrsHP = "KR 8 # 16C - 44" in 16936
replace byhand_manipadrsHP = "CL 11 32 # 6B1 - 23" in 16938
replace byhand_manipadrsHP = "CL 16B # 12B - 05" in 16945
replace byhand_manipadrsHP = "CL 125C # 28F - 49" in 16954
replace byhand_manipadrsHP = "CL 31 # 2BW - 40" in 16960
replace byhand_manipadrsHP = "KR 3N # 32N - 21" in 16962
replace byhand_manipadrsHP = "KR 1 1C # 34 - 58" in 16963
replace byhand_manipadrsHP = "KR 1 EN FN # 73 - 10" in 16965
replace byhand_manipadrsHP = "KR 28E2 # 122D - 34" in 16967
replace byhand_manipadrsHP = "CL 123 # 28B - 14" in 16970
replace byhand_manipadrsHP = "CL 123 # 28B - 14" in 16971
replace byhand_manipadrsHP = "CL 123 # 28B - 14" in 16972
replace byhand_manipadrsHP = "KR 28D 8 # 122D - 38" in 16975
replace byhand_manipadrsHP = "CL 122 # 28D7 - 49" in 16976
replace byhand_manipadrsHP = "CL 125 # 26 14 - 60" in 16978
replace byhand_manipadrsHP = "CL 122E # 28D 10 - 39" in 16979
replace byhand_manipadrsHP = "AV 7A O # 22A - 11" in 16987
replace byhand_manipadrsHP = "AV 5B O # 33A - 03" in 16996
replace byhand_manipadrsHP = "AV 5B O # 33A - 03" in 16997
replace byhand_manipadrsHP = "AV A Bis # 16 - 156" in 17000
replace byhand_manipadrsHP = "CL 30 O # 8C 05" in 17009
replace byhand_manipadrsHP = "CL 24 O # 8 - 35" in 17032
replace byhand_manipadrsHP = "AV 8 O # 19 E - 30" in 17033
replace byhand_manipadrsHP = "CL 21 O # 4 Bis 2 - 35" in 17046
replace byhand_manipadrsHP = "AV 12 O # 40 - 00" in 17047
replace byhand_manipadrsHP = "AV 8B # 31 - 71" in 17049
replace byhand_manipadrsHP = "AV 8 # 8A - 52" in 17059
replace byhand_manipadrsHP = "CL 20O # 4 - 58" in 17064
replace byhand_manipadrsHP = "CL 20O # 4 - 58" in 17065
replace byhand_manipadrsHP = "CL 30A O # 6 - 69" in 17066
replace byhand_manipadrsHP = "TV 27 # 28C - 41" in 17082
replace byhand_manipadrsHP = "AV 6 # 23" in 17084
replace byhand_manipadrsHP = "AV 6 # 23" in 17085
replace byhand_manipadrsHP = "CL 9 O N # 4B 43 - 49" in 17086
replace byhand_manipadrsHP = "AV 5 # 22 - 90" in 17087
replace byhand_manipadrsHP = "AV 6A O # 25 - 35" in 17090
replace byhand_manipadrsHP = "AV 8 O # 29N - 8B - 20" in 17093
replace byhand_manipadrsHP = "AV 5C Bis # 47B - 03" in 17096
replace byhand_manipadrsHP = "AV 4 O # 21B - 51" in 17107
replace byhand_manipadrsHP = "AV 8 O # 24 - 06" in 17108
replace byhand_manipadrsHP = "AV 8 O # 29 - 8B - 20" in 17093
replace byhand_manipadrsHP = "AV 6 O # 22A - 60" in 17112
replace byhand_manipadrsHP = "AV 8 O # 22 Bis - 18" in 17122
replace byhand_manipadrsHP = "AV 4 1 Bis O # 10 - 57" in 17127
replace byhand_manipadrsHP = "AV 70E # 3 19 - 60" in 17132
replace byhand_manipadrsHP = "AV 70E3 # 19 - 60" in 17132
replace byhand_manipadrsHP = "CL 12B O # 4 Bis 1 - 26" in 17135
replace byhand_manipadrsHP = "AV 15 O # 9A - 290" in 17140
replace byhand_manipadrsHP = "AV 5 O # 11 - 04" in 17142
replace byhand_manipadrsHP = "CL 19 O # 8A - 122" in 17143
replace byhand_manipadrsHP = "CL 30 O # 6 - 98" in 17153
replace byhand_manipadrsHP = "AV 6 O # 22 - 34" in 17154
replace byhand_manipadrsHP = "CL 72A # 4 - 108 C24" in 17160
replace byhand_manipadrsHP = "CL 54 # 1B1 - 12" in 17167
replace byhand_manipadrsHP = "CL 59 # 1C - 125" in 17174
replace byhand_manipadrsHP = "KR Bis # 46 - 50" in 17182
replace byhand_manipadrsHP = "CL 54 # 1A - 67" in 17183
replace byhand_manipadrsHP = "KR 1C3 # 58 - 30" in 17204
replace byhand_manipadrsHP = "KR 1 Bis # 59 - 15" in 17207
replace byhand_manipadrsHP = "CL 59 # 1 Bis - 35" in 17212
replace byhand_manipadrsHP = "CL 1 # 56 - 70" in 17213
replace byhand_manipadrsHP = "KR 1B # 57 - 102" in 17218
replace byhand_manipadrsHP = "CL 59 # 1 Bis - 30" in 17219
replace byhand_manipadrsHP = "KR 1AB # 57 - 102" in 17221
replace byhand_manipadrsHP = "CL 54 # 1B2 - 24" in 17228
replace byhand_manipadrsHP = "CL 59 # 1C - 73" in 17237
replace byhand_manipadrsHP = "KR 1 A 14 # 54A - 110" in 17238
replace byhand_manipadrsHP = "KR 1A # 55 - 70 - 50" in 17252
replace byhand_manipadrsHP = "KR 1A 55 # 70 - 50" in 17252
replace byhand_manipadrsHP = "KR 24D3 # 21 - 28" in 17271
replace byhand_manipadrsHP = "KR 26 # 70B - 23" in 17276
replace byhand_manipadrsHP = "KR 23C # 72B - 35" in 17281
replace byhand_manipadrsHP = "DG 70C3 # 24B1 - 45" in 17290
replace byhand_manipadrsHP = "KR 23A # 72B - 91" in 17291
replace byhand_manipadrsHP = "CL 70 # 25B - 49" in 17296
replace byhand_manipadrsHP = "KR 25C # 71 - 20" in 17306
replace byhand_manipadrsHP = "KR 28B # 72F - 55" in 17329
replace byhand_manipadrsHP = "CL 71 # 26C - 24" in 17335
replace byhand_manipadrsHP = "KR 24D # 72 - 63" in 17340
replace byhand_manipadrsHP = "KR 26H2 # 71 - 14" in 17355
replace byhand_manipadrsHP = "KR 89 10 # 80 - 222 - T11" in 17368
replace byhand_manipadrsHP = "KR 89 10 # 80 - 222" in 17368
replace byhand_manipadrsHP = "KR 42 3 # 39A - 25" in 17374
replace byhand_manipadrsHP = "KR 42A1 # 43 - 18" in 17378
replace byhand_manipadrsHP = "KR 42A1 # 42 - 72" in 17401
replace byhand_manipadrsHP = "KR 42A1 # 42 - 72" in 17426
replace byhand_manipadrsHP = "CL 36 # 41E - 69" in 17436
replace byhand_manipadrsHP = "KR 1A4C # 73 - 10" in 17441
replace byhand_manipadrsHP = "KR 8N # 46AN - 09" in 17450
replace byhand_manipadrsHP = "KR 42 # 40 - 56" in 17457
replace byhand_manipadrsHP = "KR 42A1 # 45 - 03" in 17459
replace byhand_manipadrsHP = "CL 42 # 42A1 - 06" in 17462

replace byhand_manipadrsHP = "CL 41 # 42C - 39" in 17477
replace byhand_manipadrsHP = "KR 24A # 33C - 84" in 17504
replace byhand_manipadrsHP = "CL 37 # 41G - 72" in 17505
replace byhand_manipadrsHP = "KR 41 E # 38 - 80" in 17530
replace byhand_manipadrsHP = "KR 41 # 53" in 17534
replace byhand_manipadrsHP = "KR 39 # 35A - 91" in 17585
replace byhand_manipadrsHP = "CL 45A # 5A - 150" in 17591
replace byhand_manipadrsHP = "DG 22 # 29 - 61" in 17609
replace byhand_manipadrsHP = "CL 10C # 46 - 12" in 17619
replace byhand_manipadrsHP = "KR 33 # 10A - 133" in 17624
replace byhand_manipadrsHP = "KR 33 # 10A - 133" in 17625
replace byhand_manipadrsHP = "CL 12B # 29A1 - 20" in 17628
replace byhand_manipadrsHP = "KR 32 # 10A - 130" in 17629
replace byhand_manipadrsHP = "CL 29 # 11B - 40" in 17632
replace byhand_manipadrsHP = "DG 23 # 10B - 137" in 17635
replace byhand_manipadrsHP = "DG 12C # 27" in 17636
replace byhand_manipadrsHP = "CL 66 # 12BI5 - 64" in 17649
replace byhand_manipadrsHP = "CL 54 N # 11A - 35" in 17653
replace byhand_manipadrsHP = "CL 63 3 # 12B - 28" in 17655
replace byhand_manipadrsHP = "CL 63 3 # 12B - 28" in 17656
replace byhand_manipadrsHP = "CL 63 3 # 12B - 28" in 17657
replace byhand_manipadrsHP = "KR 21B # 80C - 199" in 17674
replace byhand_manipadrsHP = "CL 88" in 17680
replace byhand_manipadrsHP = "CL 83D # 24F - 29" in 17694
replace byhand_manipadrsHP = "KR 49A # 56H - 03" in 17699
replace byhand_manipadrsHP = "TV 00 # 94" in 17702
replace byhand_manipadrsHP = "CL 101C # 22B - 110" in 17722
replace byhand_manipadrsHP = "CL 82 # 24A - 63" in 17744
replace byhand_manipadrsHP = "KR 28C # 122A - 10" in 17758
replace byhand_manipadrsHP = "CL 116 # 20 - 26" in 17763
replace byhand_manipadrsHP = "CL 84A # 20A - 02" in 17767
replace byhand_manipadrsHP = "CL 83D # 22 - 06" in 17775
replace byhand_manipadrsHP = "KR 21H # 80C - 135" in 17781
replace byhand_manipadrsHP = "CL 82D3 # 23 - 65" in 17786
replace byhand_manipadrsHP = "KR 24F4 # 82 - 12" in 17792
replace byhand_manipadrsHP = "KR 24F4 # 82 - 5" in 17793
replace byhand_manipadrsHP = "CL 80 E # 23A - 12" in 17796
replace byhand_manipadrsHP = "CL 79A # 23 - 38" in 17800
replace byhand_manipadrsHP = "KR 24F3 # 82 - 10" in 17802
replace byhand_manipadrsHP = "KR 21B # 80C - 128" in 17808
replace byhand_manipadrsHP = "CL 8C # 23A - 79" in 17813
replace byhand_manipadrsHP = "CL 89 # 20A - 33" in 17822
replace byhand_manipadrsHP = "KR 21 # 80C - 104" in 17823
replace byhand_manipadrsHP = "CL 109 # 14 - 99" in 17828
replace byhand_manipadrsHP = "DG 26 G 8 # 1 - 17" in 17834
replace byhand_manipadrsHP = "CL 82D # 20 - 41" in 17837
replace byhand_manipadrsHP = "KR 28F E # 128 - 64" in 17867
replace byhand_manipadrsHP = "KR 28F E # 128 - 64" in 17868
replace byhand_manipadrsHP = "KR 28F E # 128 - 64" in 17869
replace byhand_manipadrsHP = "KR 28F E # 128 - 64" in 17870
replace byhand_manipadrsHP = "CL 83D # 20A - 103" in 17880
replace byhand_manipadrsHP = "CL 82 # 23A - 82" in 17891
replace byhand_manipadrsHP = "CL 85 # 20A" in 17894
replace byhand_manipadrsHP = "AV 3 N # 20N - 52" in 17905
replace byhand_manipadrsHP = "CL 53 # 10A - 15" in 17919
replace byhand_manipadrsHP = "KR 11 # 48 - 33" in 17928
replace byhand_manipadrsHP = "KR 10 3 # 54 - 31" in 17934
replace byhand_manipadrsHP = "CL 50 # 12C - 57" in 17942

replace byhand_manipadrsHP = "KR 8 # 54 - 28" in 17945
replace byhand_manipadrsHP = "KR 12 # 49 - 30" in 17946
replace byhand_manipadrsHP = "CL 48 # 12A - 26" in 17953
replace byhand_manipadrsHP = "CL 53 N # 8B - 56" in 17960
replace byhand_manipadrsHP = "CL 49 # 12A - 60" in 17974
replace byhand_manipadrsHP = "KR 1B Bis # 59 - 94" in 17982
replace byhand_manipadrsHP = "KR 9 N # 52 Bis - 25" in 17983
replace byhand_manipadrsHP = "KR 9 N # 52 Bis - 25" in 17984
replace byhand_manipadrsHP = "KR 1C Bis # 58A1 - 24" in 17990
replace byhand_manipadrsHP = "KR 1 P2 # 60AB - 112P" in 17993
replace byhand_manipadrsHP = "KR 1C Bis # 58A 1 - 17" in 17999
replace byhand_manipadrsHP = "KR 1D2 # 6A - 14" in 18000
replace byhand_manipadrsHP = "CL 4 58A # 01 - 02" in 18001
replace byhand_manipadrsHP = "CL 4 58A # 01 - 02" in 18002
replace byhand_manipadrsHP = "KR 25F # 70B - 70" in 18004
replace byhand_manipadrsHP = "KR 28B2 # 70A1 - 76" in 18005
replace byhand_manipadrsHP = "DG 7BA2 # 24 - 11" in 18007
replace byhand_manipadrsHP = "DG 7BA2 # 24 - 11" in 18008
replace byhand_manipadrsHP = "DG 7BA2 # 24 - 11" in 18009
replace byhand_manipadrsHP = "DG 7BA2 # 24 - 11" in 18010
replace byhand_manipadrsHP = "DG 7BA2 # 24 - 11" in 18011
replace byhand_manipadrsHP = "KR 28B3 # 70E - 110" in 18013
replace byhand_manipadrsHP = "KR 26H # 70D - 39" in 18014
replace byhand_manipadrsHP = "DG 70A32 # 24 - 155" in 18020
replace byhand_manipadrsHP = "DG 70A32 # 24 - 155" in 18021
replace byhand_manipadrsHP = "DG 70A32 # 24 - 155" in 18022
replace byhand_manipadrsHP = "DG 70A32 # 24 - 155" in 18023
replace byhand_manipadrsHP = "DG 70A32 # 24 - 155" in 18024
replace byhand_manipadrsHP = "DG 70A32 # 24 - 155" in 18025
replace byhand_manipadrsHP = "DG 70A32 # 24 - 155" in 18026
replace byhand_manipadrsHP = "KR 24A1B # 70 - 73" in 18030
replace byhand_manipadrsHP = "KR 26D # 70A - 35" in 18032
replace byhand_manipadrsHP = "KR 26G # 70 - 23" in 18035
replace byhand_manipadrsHP = "DG 70 # 23A - 138" in 18036
replace byhand_manipadrsHP = "DG 71A1 # 24B1 - 10" in 18037
replace byhand_manipadrsHP = "DG 70E # 24D - 103" in 18038
replace byhand_manipadrsHP = "KR 24B # 70A1 - 85" in 18039
replace byhand_manipadrsHP = "KR 24D # 70 E - 47" in 18040
replace byhand_manipadrsHP = "KR 24D # 70 E - 47" in 18041
replace byhand_manipadrsHP = "KR 25A # 70B - 40" in 18042
replace byhand_manipadrsHP = "KR 24A # 70 - 90" in 18043
replace byhand_manipadrsHP = "KR 24D # 70C - 83" in 18047
replace byhand_manipadrsHP = "CL 24F # 70B - 28" in 18048
replace byhand_manipadrsHP = "KR 26 E # 70 - 35" in 18050
replace byhand_manipadrsHP = "KR 24 A1 # 70 - 13" in 18052
replace byhand_manipadrsHP = "KR 24E # 70B - 74" in 18053
replace byhand_manipadrsHP = "KR 25B # 70A - 58" in 18054
replace byhand_manipadrsHP = "KR 25B # 70A - 46" in 18055
replace byhand_manipadrsHP = "KR 24E # 70A - 40" in 18058
replace byhand_manipadrsHP = "KR 24E # 70A - 40" in 18059
replace byhand_manipadrsHP = "KR 24F # 70B - 35" in 18060
replace byhand_manipadrsHP = "DG 72C" in 18065
replace byhand_manipadrsHP = "KR 24 # 70E - 19" in 18071
replace byhand_manipadrsHP = "DG 70 # 25C - 18" in 18072
replace byhand_manipadrsHP = "KR 26A # 70A - 73" in 18075
replace byhand_manipadrsHP = "KR 26 # 70D - 68" in 18076
replace byhand_manipadrsHP = "DG 70G # 24D - 62" in 18077
replace byhand_manipadrsHP = "KR 25C # 70B - 35" in 18084
replace byhand_manipadrsHP = "KR 26 # 70B - 23" in 18085
replace byhand_manipadrsHP = "KR 25F # 70A - 23" in 18095
replace byhand_manipadrsHP = "KR 24 Bis # 70 - 11" in 18096
replace byhand_manipadrsHP = "KR 24 # 70 E - 68" in 18098
replace byhand_manipadrsHP = "KR 25 # 70A - 52" in 18100
replace byhand_manipadrsHP = "KR 25B # 70B - 71" in 18104
replace byhand_manipadrsHP = "KR 25B # 70B - 41" in 18105
replace byhand_manipadrsHP = "KR 26 1 # 72 - 15" in 18110
replace byhand_manipadrsHP = "KR 24 # 70 - 17" in 18111
replace byhand_manipadrsHP = "KR 24 # 70 - 17" in 18112
replace byhand_manipadrsHP = "DG 70F # 25D - 91" in 18114
replace byhand_manipadrsHP = "KR 26D # 70A - 35" in 18118
replace byhand_manipadrsHP = "KR 25D # 70A - 70" in 18119
replace byhand_manipadrsHP = "KR 25D # 70A - 70" in 18120
replace byhand_manipadrsHP = "KR 26G # 70B - 65" in 18121
replace byhand_manipadrsHP = "KR 25A # 70 - 11" in 18123
replace byhand_manipadrsHP = "DG 72B # 26 - 24" in 18124
replace byhand_manipadrsHP = "KR 24 F # 70B - 35" in 18126
replace byhand_manipadrsHP = "KR 24B3 # 70 E - 109" in 18127
replace byhand_manipadrsHP = "KR 24A1 # 70E - 109" in 18130
replace byhand_manipadrsHP = "KR 324C # 70 - 59" in 18132
replace byhand_manipadrsHP = "KR 324C # 70 - 59" in 18133
replace byhand_manipadrsHP = "KR 324C # 70 - 59" in 18134
replace byhand_manipadrsHP = "KR 24C # 70 - B54" in 18135
replace byhand_manipadrsHP = "KR 24C # 70B - 54" in 18135
replace byhand_manipadrsHP = "KR 24B2 # 70E - 30" in 18136
replace byhand_manipadrsHP = "CL 73 # 25T - 22" in 18138
replace byhand_manipadrsHP = "KR 26 # 70D6 - 7" in 18139
replace byhand_manipadrsHP = "KR 26 # 70D6 - 7" in 18140
replace byhand_manipadrsHP = "KR 24A1 # 70 - 98" in 18141
replace byhand_manipadrsHP = "KR 25C # 70B - 10" in 18142
replace byhand_manipadrsHP = "KR 24B4 # 70E - 130" in 18143
replace byhand_manipadrsHP = "KR 24 B4 # 70 - 35" in 18145
replace byhand_manipadrsHP = "DG 70 # 26 3 - 42" in 18146
replace byhand_manipadrsHP = "KR 24B4 # 70 - 65" in 18150

replace byhand_manipadrsHP = "KR 24B1 # 70 - 16" in 18151
replace byhand_manipadrsHP = "DG 28C # 42C - 13" in 18171
replace byhand_manipadrsHP = "KR 42B # 28B - 18" in 18185
replace byhand_manipadrsHP = "KR 43A # 28B - 19" in 18193
replace byhand_manipadrsHP = "KR 42 # 26D - 32" in 18200
replace byhand_manipadrsHP = "KR 45 # 26B - 74" in 18204
replace byhand_manipadrsHP = "CL 70 # 26G6 - 16" in 18217
replace byhand_manipadrsHP = "CL 98 # 26G - 41" in 18220
replace byhand_manipadrsHP = "CL 78N # 28D4 - 76" in 18222
replace byhand_manipadrsHP = "KR 26P2 # 94 - 17" in 18225
replace byhand_manipadrsHP = "CL 98 # 26G2 - 37" in 18228
replace byhand_manipadrsHP = "CL 38 # 13N - 76" in 18243
replace byhand_manipadrsHP = "KR 26G1 # 94 - 28" in 18249
replace byhand_manipadrsHP = "CL 96 # 26G - 49" in 18251
replace byhand_manipadrsHP = "CL 98A # 26G - 79" in 18253
replace byhand_manipadrsHP = "CL 97 # 26G5 - 15" in 18259
replace byhand_manipadrsHP = "CL 26H # 92 - 14" in 18264
replace byhand_manipadrsHP = "CL 90C # 26H - 08" in 18270
replace byhand_manipadrsHP = "TV 103 # 95" in 18273
replace byhand_manipadrsHP = "TV 103 # 26 86 - 16" in 18274
replace byhand_manipadrsHP = "CL 98 # 26G5 - 14" in 18276
replace byhand_manipadrsHP = "KR 28B 3 # 72A - 59" in 18282
replace byhand_manipadrsHP = "CL 72F5 # 3 28 E - 12" in 18294
replace byhand_manipadrsHP = "CL 72F 53 # 28 E - 12" in 18294
replace byhand_manipadrsHP = "DG 22 # 26L - 101" in 18312
replace byhand_manipadrsHP = "KR 26L # 72 E Bis - 05" in 18313
replace byhand_manipadrsHP = "DG 29A # 27 - 111" in 18316
replace byhand_manipadrsHP = "DG 28C # 28 - 06" in 18318
replace byhand_manipadrsHP = "DG 28D # 28 - 60" in 18322
replace byhand_manipadrsHP = "TV 28B3 # 28A - 22" in 18326
replace byhand_manipadrsHP = "CL 32 HT # 27 - 60" in 18327
replace byhand_manipadrsHP = "KR 27 # 28B - 16" in 18334
replace byhand_manipadrsHP = "TV 33E # 28 - 29" in 18335
replace byhand_manipadrsHP = "TV 28 # 28 - 48" in 18336
replace byhand_manipadrsHP = "TV 28 # 28 - 48" in 18337
replace byhand_manipadrsHP = "TV 27 # 28C - 23" in 18340
replace byhand_manipadrsHP = "DG 29 # 33E - 38" in 18343
replace byhand_manipadrsHP = "DG 26P9 # 10 - 52" in 18344
replace byhand_manipadrsHP = "DG 28D # 28 - 60" in 18346
replace byhand_manipadrsHP = "TV 26D # 28C - 31" in 18358
replace byhand_manipadrsHP = "DG 28D # 27 - 33" in 18361
replace byhand_manipadrsHP = "DG 28D # 27 - 33" in 18362
replace byhand_manipadrsHP = "DG 28D # 27 - 33" in 18363
replace byhand_manipadrsHP = "DG 28D # 27 - 33" in 18364
replace byhand_manipadrsHP = "DG 28DF # 28D3 - 18" in 18365
replace byhand_manipadrsHP = "TV 27D2 # 8C - 12" in 18366
replace byhand_manipadrsHP = "DG 28A # 28 - 45" in 18367
replace byhand_manipadrsHP = "TV 27" in 18370
replace byhand_manipadrsHP = "DG 28 # 28 - 44" in 18371
replace byhand_manipadrsHP = "TV 27 3 # 28 - 25" in 18372
replace byhand_manipadrsHP = "TV 28 # 28C - 20" in 18373
replace byhand_manipadrsHP = "TV 29 # 28 - 62" in 18374
replace byhand_manipadrsHP = "TV 29D # 28T - 38" in 18380
replace byhand_manipadrsHP = "TV 25 3 # 32 - 19" in 18385
replace byhand_manipadrsHP = "TV 25 # 32 - 19" in 18385
replace byhand_manipadrsHP = "DG 28 # 28 - 14" in 18391
replace byhand_manipadrsHP = "CL 47C # 3EN - 131" in 18392
replace byhand_manipadrsHP = "CL 41 N # 3C - 71" in 18403
replace byhand_manipadrsHP = "CL 47BN # 3CN - 45" in 18410
replace byhand_manipadrsHP = "CL 47BN # 3CN - 45" in 18411
replace byhand_manipadrsHP = "CL 47BN # 3CN - 45" in 18412
replace byhand_manipadrsHP = "AV 3B # 40 - 143" in 18428
replace byhand_manipadrsHP = "AV 3CN # 42 N - 73" in 18429
replace byhand_manipadrsHP = "CL 41 N # 3N - 37" in 18430
replace byhand_manipadrsHP = "AV 3FN # 45N - 30" in 18432
replace byhand_manipadrsHP = "AV 3 CM # 40 - 20" in 18433
replace byhand_manipadrsHP = "CL 5 O # 34 - 8A - 27" in 18443
replace byhand_manipadrsHP = "CL 5 O 34 # 8A - 27" in 18443
replace byhand_manipadrsHP = "CL 47A O # 5C Bis - 23" in 18445
replace byhand_manipadrsHP = "CL 47A O # 5C Bis - 23" in 18446
replace byhand_manipadrsHP = "DG 28D3 # 72F - 38" in 18453
replace byhand_manipadrsHP = "DG 28B3 # 72F4 - 18" in 18454
replace byhand_manipadrsHP = "DG 28D5 # 2F3 - 18" in 18456
replace byhand_manipadrsHP = "DG 28D" in 18457
replace byhand_manipadrsHP = "TV 72 # 4D 28 - 07" in 18458
replace byhand_manipadrsHP = "TV 72F3 # 28D3 - 53" in 18463
replace byhand_manipadrsHP = "DG 28D 3T # 72FA - 52" in 18465
replace byhand_manipadrsHP = "DG 28D1 # 72B - 10" in 18466
replace byhand_manipadrsHP = "TV 72F # 28D1 - 38" in 18467
replace byhand_manipadrsHP = "TV 72F # 28 01 - 38" in 18468
replace byhand_manipadrsHP = "CL 72 IT # 28F - 66" in 18470
replace byhand_manipadrsHP = "DG 28D3 # 72A1 - 04" in 18476
replace byhand_manipadrsHP = "DG 28D5 # 72F2 - 03" in 18478
replace byhand_manipadrsHP = "DG 28D2 # 71A - 17" in 18486
replace byhand_manipadrsHP = "DG 28D5 # 72F3 - 18" in 18487
replace byhand_manipadrsHP = "DG 28D4 # 72F - 25" in 18489
replace byhand_manipadrsHP = "DG 28D4 # 28D - 317" in 18491
replace byhand_manipadrsHP = "DG 28D4 # 28D - 317" in 18492
replace byhand_manipadrsHP = "DG 28D6 # 72F - 41" in 18494
replace byhand_manipadrsHP = "CL 71A # 28E - 32" in 18496
replace byhand_manipadrsHP = "DG 28D2 # 72A - 60" in 18498
replace byhand_manipadrsHP = "DG 28D1 # 72B - 10" in 18500

replace byhand_manipadrsHP = "DG 28D2 # 72A - 62" in 18507
replace byhand_manipadrsHP = "KR 28G3 # 72T - 32" in 18513
replace byhand_manipadrsHP = "DG 28D4 # 72F1 - 03" in 18516
replace byhand_manipadrsHP = "CL 72I # 28F - 50" in 18521
replace byhand_manipadrsHP = "CL 72I # 28F - 50" in 18522
replace byhand_manipadrsHP = "DG 28D4 # 72F2 - 03" in 18528
replace byhand_manipadrsHP = "DG 28D5 # 74F - 04" in 18530
*/
*list multiple with same num_ide_
*list multiples by fecha, num_id_, and NOMBRE, semana 

drop if byhand_manipadrsHP  ==""

*export text file for geocoding 
rename byhand_manipadrsHP direcion
outfile ID_CODE direcion using "krystosik_homeaddress_dengue_chikv.txt", noquote replace

order ID_CODE direcion dir_res_
drop manipadrsHP- manipadrsH pound- pound1space_origionalB5 address_complete suffix2b- suffix5 variabl_zikabarrio drop_ suffix freq_COD_BARRIO
rename _count count
rename _pos1 pos1
rename _pos2 pos2
rename _pos3 pos3
rename _pos4 pos4
rename _pos5 pos5
rename _pos6 pos6
rename _pos7 pos7
rename _pos8 pos8
rename _pos9 pos9
*rename ID_BARRIO id_barrio
rename COD_BARRIO cod_barrio
rename ESTRATO_MO estrato_mo

save temp.dta, replace
*/

*From HERE
/*********************************
 *Amy Krystosik                  *
 *chikv and dengue in cali       *
 *dissertation                   *
 *last updated January 3, 2016  *
 *********************************/

cd "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data"
capture log close 
log using "dissertation_fromHERE.smcl", text replace 
set scrollbufsize 100000
set more 1
use temp.dta, clear



*data cleaning
bysort  num_ide_  fec_not cod_eve: gen freq_cedula = _N
sort num_ide_   fec_not direcion cod_eve
quietly by num_ide_  fec_not direcion cod_eve:  gen dup = cond(_N==1,0,_n)
tabulate dup
export excel num_ide_ cod_eve direcion barrio dir_res_  fec_not freq_cedula dup using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\freq_cedula.xls", firstrow(variables) replace
drop if dup>1
bysort  num_ide_  fec_not cod_eve: gen freq_cedula2 = _N

order direcion  num_ide_  dir_res_ freq_cedula2 dup cod_eve barrio
gsort  - freq_cedula2 num_ide_  

*manual changes based on searching for address and using the most common clasfinal.
/*
replace direcion = "DG 28 E # 29 - 48" in 3
replace direcion = "DG 28 E # 29 - 48" in 2
replace direcion = "DG 28 E # 29 - 48" in 1
replace direcion = "CL 72K # 3N - 31" in 5
replace direcion = "CL 72K # 3N - 31" in 4
replace direcion = "AV 2IN # 45N - 83" in 6
replace direcion = "KR 29B3 # 27 - 56" in 8
replace direcion = "KR 13 # 46 - 13" in 10
replace direcion = "KR 75 Bis # 72 - 116" in 14
replace direcion = "DG 71C1 # 26J - 51" in 17
replace direcion = "CL 77B # 23 - 25" in 19
replace clasfinal = "2" in 21
replace direcion = "CL 3C # 70 - 67" in 22
replace direcion = "KR 95 # 2B - 80" in 24
replace direcion = "AV 4 # 32 - 44 - 158" in 26
replace direcion = "AV 4 # 32 - 44 - 158" in 27
replace direcion = "AV 4 32 # 44 - 158" in 26
replace direcion = "AV 4 # 32 - 44 - 158" in 26
replace direcion = "KR 94 # 3W O" in 28
replace direcion = "CL 125 # 28F - 55" in 31
replace direcion = "CL 2A # 9 Bis" in 33
replace direcion = "KR 26 I3 # 95 - 24" in 35
replace direcion = "KR 24G # 85 - 101" in 36
replace direcion = "KR 1AB Bis # 73A - 70" in 38
replace direcion = "CL 36 # 30 - 44" in 40
replace direcion = "CL 43B # 32B - 29" in 43
replace direcion = "KR 26C1 # 94 - 58" in 44
replace direcion = "CL 45 # 83B - 4N" in 46
replace clasfinal = "2" in 46
replace direcion = "KR 44A # 40 - 22" in 49
replace direcion = "DG 71AN # 22 - 74 " in 50
replace direcion = "DG 71AN # 22 - 74 " in 51
replace clasfinal = "2" in 51
replace clasfinal = "2" in 52
replace direcion = "CL 71" in 55
replace direcion = "CL 15 # 36B" in 57
replace direcion = "KR 1 9 # 72 - 21" in 58
replace direcion = "KR 62B # 14 3 - 65" in 61
replace direcion = "CL 23 # 13F - 21" in 62
replace direcion = "KR 48C # 23I - 89" in 65
replace clasfinal = "2" in 64
replace direcion = "CL 15 # 121 - 66" in 66
replace direcion = "KR 27AT # 29 - 33" in 68
replace direcion = "CL 13E # 53 - 34" in 71
replace direcion = "CL 123 # 28B - 14" in 73
replace direcion = "KR 92 O # 2C2- 06" in 75
replace direcion = "CL 56J # 47D - 38" in 77
replace direcion = "KR 40M # 30C - 71" in 79

replace direcion = "KR 24 # 28 - 40" in 81
replace direcion = "KR 1C3 # 64 - 12" in 85
replace direcion = "AV 8N3 # 52B - 34" in 86
replace direcion = "KR 42 # 55B - 93" in 88
replace direcion = "KR 42 # 55B - 93" in 89
replace direcion = "CL 83A # 3AN - 32" in 91

replace direcion = "CL 55A # 28G - 48" in 92
replace direcion = "KR 7B Bis # 70 - 100" in 95
replace clasfinal = "2" in 94
replace direcion = "KR 42A # 38 - 79" in 97
replace direcion = "CL 13A3 # 50 - 57" in 99
replace clasfinal = "2" in 100
replace direcion = "KR 7 RB # 72 - 31" in 103
replace direcion = "KR 7 RB # 72 - 31" in 102
replace direcion = "KR 90 # 28 - 64" in 105
replace direcion = "KR 17F # 29 - 39" in 107
replace direcion = "CL 47A N # 5AN - 60" in 108
replace direcion = "KR 25E # 26B - 52" in 111
replace clasfinal = "2" in 109
replace direcion = "KR 49C1 # 7 - 26" in 112
replace direcion = "KR 87 O # 97" in 114
replace direcion = "KR 26I # 123 - 56" in 116
replace clasfinal = "2" in 119

replace direcion = "KR 28D # 100" in 118
replace clasfinal = "2" in 120
replace direcion = "KR 27F # 121 - 22" in 123

replace direcion = "CL 2 O # 24E - 46" in 125
replace direcion = "KR 39 E # 51 - 11" in 126
replace direcion = "KR 7M1 # 92 - 33" in 128
replace direcion = "KR 83CE # 46 - 24" in 131
replace direcion = "KR 18 # 71A - 118" in 132
replace direcion = "KR 43 # 14C - 35" in 135
replace direcion = "KR 17F1 # 18 - 35" in 137
replace direcion = "CL 44 # 28B - 25" in 138
replace direcion = "CL 42 O # 5A - 33" in 141
replace direcion = "KR 35 # 31A - 66" in 142
replace direcion = "CL 37A # 3CN - 31" in 144
replace direcion = "KR 64A # 14C - 71" in 146
replace direcion = "KR 14 # 6 - 54B" in 148

replace direcion = "KR 40A # 12B - 77" in 151
replace direcion = "KR 39C # 55A - 26" in 153

replace clasfinal = "2" in 155
replace clasfinal = "2" in 156
replace direcion = "KR 1DN # 77 - 33" in 158
replace direcion = "KR 41E2 # 49 - 23" in 160
replace direcion = "KR 94 # 1A - 70" in 163
replace direcion = "CL 70 N # 2AN - 121" in 164
replace direcion = "KR 95 # 1 Bis - 97" in 167
replace direcion = "KR 32 # 34 - 17" in 169
replace direcion = "CL 45 # 83D - 37" in 170
replace direcion = "CL 45 # 83D - 37" in 171
replace direcion = "KR 40A # 2C - 92" in 172
replace direcion = "KR 39A # 42B - 09" in 174
replace direcion = "KR 39A # 42B - 09" in 175
replace direcion = "KR 1 # 66 - 42" in 177
replace direcion = "KR 1B2 # 64 - 21" in 178
replace direcion = "KR 324C # 70 - 59" in 180
replace direcion = "KR 24C # 70 - 59" in 180
replace direcion = "KR 24C # 70 - 59" in 181
replace direcion = "AV 2HN # 52A - 05" in 183
replace direcion = "KR 1C5 # 63 - 80" in 185
replace direcion = "KR 41E3 # 55B - 93" in 186
replace direcion = "KR 7M1 # 92 - 46" in 188
replace direcion = "KR 1A10 # 73A - 53" in 190
replace direcion = "KR 5 N # 38 - 30" in 192
replace direcion = "KR 5 N # 38 - 30" in 193
replace direcion = "KR 1D # 46A - 36" in 194
replace direcion = "CL 70 # 2AN 1S1N - 203" in 197
replace direcion = "KR 46C # 40 - 16" in 199
replace direcion = "KR 7T Bis # 72 - 131" in 200
*/

/*
*data cleaning
bysort  num_ide_  fec_not cod_eve: gen freq_cedula = _N

sort num_ide_   fec_not direcion clasfinal cod_eve
quietly by num_ide_  fec_not direcion clasfinal cod_eve:  gen dup = cond(_N==1,0,_n)
tabulate dup
export excel num_ide_ cod_eve direcion clasfinal barrio dir_res_  fec_not freq_cedula dup using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\freq_cedula.xls", firstrow(variables) replace
drop if dup>1

bysort  num_ide_  fec_not cod_eve: gen freq_cedula2 = _N
order direcion clasfinal num_ide_  dir_res_ freq_cedula2 dup cod_eve barrio
gsort  - freq_cedula2 num_ide_  
*/

*rerun dups by num_ide_   fec_not direcion clasfinal cod_eve
sort num_ide_   fec_not direcion  cod_eve
quietly by num_ide_  fec_not direcion  cod_eve:  gen dup2 = cond(_N==1,0,_n)
tabulate dup2
drop if dup2>1

*rerun dups by num_ide_  semana cod_eve 
sort num_ide_  semana cod_eve 
quietly by num_ide_  semana cod_eve:  gen dup4 = cond(_N==1,0,_n)
tabulate dup4
drop if dup4>1

bysort  num_ide_  semana cod_eve: gen freq_cedula4 = _N
order direcion  num_ide_  dir_res_ freq_cedula4 freq_cedula2 dup cod_eve barrio
gsort - freq_cedula4 num_ide_  

replace direcion = trim( direcion)
replace direcion = itrim( direcion)

*remove prisoners
*tab gp_carcela
*drop if gp_carcela == "1" 

*check dates
tab semana
tab year

*check formats for each collum
*id
list num_ide_ if regexm(num_ide_, "[0-9]+")==1 

*edad
list edad if regexm(edad, "[0-9]+")==0 
destring edad, replace
order num_ide_
list num_ide_  edad if edad >= 100

*sex
tab sexo

*ethnicity
*tab per_etn_

*tab gp_discapa
*tab gp_desplaz
*tab gp_migrant
*tab gp_carcela
tab gp_gestan
*tab gp_indigen
*tab gp_pobicbf
*tab gp_mad_com
*tab gp_desmovi
*tab gp_psiquia
*tab gp_vic_vio
*tab desplazami
*tab famantdngu
*tab nom_eve
drop count -  dup4
/*
*outsheet using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\redcap.csv", comma replace
outsheet using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\alldata.csv", comma replace
outsheet using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\redcap_2000.csv" in 1/2000, comma replace
outsheet using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\redcap_4000.csv" in 2001/4000, comma replace
outsheet using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\redcap_6000.csv" in 4001/6000, comma replace
outsheet using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\redcap_8000.csv" in 6001/8000, comma replace
outsheet using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\redcap_10000.csv" in 8001/10000, comma replace
outsheet using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\redcap_12000.csv" in 10001/12000, comma replace
outsheet using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\redcap_14000.csv" in 12001/14000, comma replace
outsheet using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\redcap_16000.csv" in 14001/15712, comma replace
*/
*export for secretary of healtlh geocoding
rename direcion direccion
export excel ID_CODE direccion barrio ID_BARRIO using "direcciones_krystosik_2febrero2016", firstrow(variables) replace

tostring ID_CODE, replace
save "temp.dta", replace
save "2015-2016.dta", replace

use "2015-2016.dta", clear

append using "2014-2015.dta", generate(append_merged)

sort num_ide_  cod_eve fec_not, stable
gen ID_CODE_merged = _n

/*
*merge based on those that didn't georeference to include the neighborhood
import excel "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\sin_georreferenciar.xls", sheet("sin_georreferenciar") firstrow clear
save "sin_georreferenciar.dta", replace

use "temp.dta", clear
tostring ID_CODE, replace
merge m:1 ID_CODE direccion using "sin_georreferenciar.dta"
export excel ID_CODE  dir_res_ direccion barrio ID_BARRIO using "sin_georreferenciar_barrio.xls" if _merge == 3, firstrow(variables) replace 
list ID_CODE if _merge == 2
*drop _merge
*/

/*
*upload the new addresses from javier
use "temp.dta", clear
drop if ID_CODE =="."
drop if ID_CODE ==" "
drop if ID_CODE ==""
save "temp_nozika.dta", replace

import excel "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\singeoreferenciar\sin_georreferenciar_javier.xls", sheet("Sheet1") firstrow clear
save "sin_georreferenciar_javier.dta", replace
drop if ID_CODE =="."
drop if ID_CODE ==" "
drop if ID_CODE ==""
merge 1:1 ID_CODE using "temp_nozika.dta" 
save "temp_nozika.dta", replace

use "temp.dta", clear
drop if ID_CODE !="."
save "temp_zika.dta", replace

append using "temp_nozika.dta", generate(append_javier)
drop if Z_ID_CODE ==.
save "temp_javier.dta", replace
*/

*********************epi analysis********************
destring edad sexo ocupacion_ per_etn_ gp_discapa gp_desplaz gp_migrant gp_gestan gp_indigen gp_pobicbf gp_mad_com gp_desmovi gp_psiquia gp_otros gp_vic_vio, replace
replace  gp_discapa = 0 if  gp_discapa == 2
replace  gp_desplaz= 0 if  gp_desplaz== 2
replace  gp_migrant= 0 if  gp_migrant== 2
replace  gp_gestan = 0 if  gp_gestan == 2
replace  gp_pobicbf = 0 if  gp_pobicbf == 2
replace  gp_mad_com = 0 if  gp_mad_com == 2
replace  gp_desmovi= 0 if  gp_desmovi== 2
replace  gp_psiquia = 0 if  gp_psiquia == 2
replace  gp_vic_vio = 0 if  gp_vic_vio == 2
replace  gp_otros = 0 if  gp_otros == 2


tab sexo_, gen (sex)
gen female = .
replace female = 1 if sex1 ==1
replace female = 0 if sex2 ==1

describe 
sum 

*uniqe identifer
isid ID_CODE_merged

/*Statistical analysis: For the descriptive analysis, the cases will be stratified by severity and described according to age, sex, ethnicity, occupation, and 
social risk group (pregnant, displaced, migrant). 
*/
tab nom_eve

*create outcome category of chikv and dengue without and with severity and grave and death. 
destring clasfinal, replace
gen outcome = .
*outcome = 1 for dengue without warning
replace outcome =1 if clasfinal == 1
*outcome = 2 for dengue with warning signs
replace outcome =2 if clasfinal == 2
*outcome = 3 for dengue grave
replace outcome = 3 if dengue_death3 == 1
*outcome = 4 for dengue death
replace outcome = 4 if dengue_death4 == 1

*outcome = 5 for dengue unclassified
replace outcome =5 if cod_eve == 210 & outcome ==.

*outcome = 6 for chikungunya 
replace outcome = 6 if  cod_eve == 217

*outcome = 7  for zika
replace outcome = 7 if cod_eve == 895



*sum the factors by dengue severity
tab outcome 
by outcome, sort: summarize edad female ocupacion_ per_etn_ gp_discapa gp_desplaz gp_migrant gp_gestan gp_indigen gp_pobicbf gp_mad_com gp_desmovi gp_psiquia gp_otros gp_vic_vio

/*An exploratory analysis of the data will be made to check for and correct outliers and missing data. Univariate analysis will be performed to determine the 
behavior of the numeric variables and the normality of the variables will be determined through a test of Shapiro Wilk where those with p > 0.05 will be 
considered normally distributed and a mean and standard deviation calculated. For non-normal variables, median and interquartile ranges will be presented. 
Categorical variables will be presented as proportions and strata will be compared with chi-squared tests with Fisherís exact test used for tables with 
values less than five in any cell.
*/

*shapiro wilk test
swilk edad female ocupacion_ per_etn_ gp_discapa gp_desplaz gp_migrant gp_gestan gp_pobicbf gp_mad_com gp_desmovi gp_psiquia gp_otros gp_vic_vio
*all variables are normally distrubted with p>.05
*mean and stddev
summarize edad

*non-normal variables, median and interquartile ranges
describe edad
median edad, by(outcome) 
median ocupacion_, by(outcome) 
median per_etn_, by(outcome) 
median gp_discapa, by(outcome) 
median gp_desplaz, by(outcome) 
median gp_migrant, by(outcome) 
median gp_gestan, by(outcome) 
median gp_pobicbf, by(outcome) 
median gp_mad_com , by(outcome) 
median gp_desmovi , by(outcome) 
median gp_desmovi , by(outcome) 
median gp_psiquia , by(outcome) 
median gp_otros , by(outcome) 
median gp_vic_vio, by(outcome) 



*categorical variables
tab outcome
tab sexo 

*categorize ocupacion_ 


rename edad edad_cont
xtile edad_cat = edad_cont, nquantiles(10)

gen edad_cat5 =. 
replace edad_cat5 =1 if edad_cont <= 4 
replace edad_cat5 =2 if edad_cont >=5 & edad_cont <=9
replace edad_cat5 =3 if edad_cont >=10 & edad_cont <=14
replace edad_cat5 =4 if edad_cont >=15 & edad_cont <=19
replace edad_cat5 =5 if edad_cont >=20 & edad_cont <=24
replace edad_cat5 =6 if edad_cont >=25 & edad_cont <=29
replace edad_cat5 =7 if edad_cont >=30 & edad_cont <=34
replace edad_cat5 =8 if edad_cont >=35 & edad_cont <=39
replace edad_cat5 =9 if edad_cont >=40 & edad_cont <=44
replace edad_cat5 =10 if edad_cont >=45 & edad_cont <=49
replace edad_cat5 =11 if edad_cont >=50 & edad_cont <=54
replace edad_cat5 =12 if edad_cont >=55 & edad_cont <=59
replace edad_cat5 =13 if edad_cont >=60 & edad_cont <=64
replace edad_cat5 =14 if edad_cont >=65

tostring edad_cat5, generate(edad_cat_5name)  
replace edad_cat_5name= "0-4" if edad_cat_5name== "1"
replace edad_cat_5name = "5-9" if edad_cat_5name== "2"
replace edad_cat_5name = "10-14" if edad_cat_5name== "3"
replace edad_cat_5name = "15-19" if edad_cat_5name== "4"
replace edad_cat_5name = "20-24" if edad_cat_5name== "5"
replace edad_cat_5name = "25-29" if edad_cat_5name== "6"
replace edad_cat_5name = "30-34" if edad_cat_5name== "7"
replace edad_cat_5name = "35-39" if edad_cat_5name== "8"
replace edad_cat_5name = "40-44" if edad_cat_5name== "9"
replace edad_cat_5name = "45-49" if edad_cat_5name== "10"
replace edad_cat_5name = "50-54" if edad_cat_5name== "11"
replace edad_cat_5name = "55-59" if edad_cat_5name== "12"
replace edad_cat_5name = "60-64" if edad_cat_5name== "13"
replace edad_cat_5name = "65+" if edad_cat_5name== "14"

tab edad_cat5 edad_cat_5name 




gen edad_cat_epi =. 
replace edad_cat_epi= 1 if edad_cont < 15 
replace edad_cat_epi = 2 if edad_cont >=15 & edad_cont <35
replace edad_cat_epi = 3 if edad_cont >=35 & edad_cont <65
replace edad_cat_epi = 4 if edad_cont >=65 

tostring edad_cat_epi, generate(edad_epi_name)  

replace edad_epi_name= "0-14" if edad_epi_name== "1"
replace edad_epi_name= "15-34" if edad_epi_name== "2"
replace edad_epi_name= "35-64" if edad_epi_name== "3"
replace edad_epi_name= "65+" if edad_epi_name== "4"
tab edad_epi_name edad_cat_epi

tostring cod_eve, replace
replace nom_eve ="Chikungunya" if cod_eve == "217"
replace nom_eve ="Dengue" if cod_eve == "210"
replace nom_eve ="Severe Dengue" if cod_eve == "220"
replace nom_eve ="Dengue Death" if cod_eve == "580"
replace nom_eve ="Zika" if cod_eve == "895"

rename  gp_vic_vio violence_victims
rename  edad_epi_name Age_Categories 
rename per_etn_ ethnicity 
rename gp_discapa Disabled
rename gp_desplaz Displaced
rename gp_migrant migrant 
rename gp_gestan pregnant 
rename gp_pobicbf youth_government_care 
rename gp_mad_com Community_mother 
rename gp_desmovi ex_paramil_ex_guerilla 
rename gp_psiquia under_psychiatric_care 
rename gp_otros other_group 
rename sexo_ Sex

tostring ethnicity, replace
replace ethnicity ="Indigenous" if ethnicity =="1"
replace ethnicity ="Rom, gitano" if ethnicity =="2"
replace ethnicity ="Raizal" if ethnicity =="3"
replace ethnicity ="Negro mulato afrocolombian" if ethnicity =="5"
replace ethnicity ="other" if ethnicity =="6"

*table 1 for all cases by outcome where 0 is chkv, 1 is dengue without warning signs, 2 is dengue with warning signs, 3 is denuge grave, 4 is dengue death
table1, vars(Age_Categories cat\ Sex cat \ ethnicity cat \ Disabled cat \ Displaced cat\migrant cat\ pregnant cat\ youth_government_care  cat\ Community_mother  cat \ ex_paramil_ex_guerilla cat\ under_psychiatric_care  cat\ other_group  cat\ violence_victims cat) by(nom_eve) saving("C:\Users\Amy\OneDrive\epi analysis\table1_nom_eve_ageepi.xls", replace) missing



*now try it with outcome which was made above in this fashion: 
/**create outcome category of chikv and dengue without and with severity and grave and death. 
destring clasfinal, replace
gen outcome = .
*outcome = 1 for dengue without warning
replace outcome =1 if clasfinal == 1
*outcome = 2 for dengue with warning signs
replace outcome =2 if clasfinal == 2
*outcome = 3 for dengue grave
replace outcome = 3 if dengue_death3 == 1
*outcome = 4 for dengue death
replace outcome = 4 if dengue_death4 == 1

*outcome = 5 for dengue unclassified
replace outcome =5 if cod_eve == 210 & outcome ==.

*outcome = 6 for chikungunya 
replace outcome = 6 if  cod_eve == 217

*outcome = 7  for zika
replace outcome = 7 if cod_eve == 895
*/
*table 1 for all cases by outcome where 0 is chkv, 1 is dengue without warning signs, 2 is dengue with warning signs, 3 is denuge grave, 4 is dengue death
table1, vars(Age_Categories cat\ Sex cat \ ethnicity cat \ Disabled cat \ Displaced cat\migrant cat\ pregnant cat\ youth_government_care  cat\ Community_mother  cat \ ex_paramil_ex_guerilla cat\ under_psychiatric_care  cat\ other_group  cat\ violence_victims cat) by(outcome) saving("C:\Users\Amy\OneDrive\epi analysis\table1_OUTCOME_ageepi.xls", replace) missing test


bysort female: tab Age_Categories nom_eve
bysort female year: tab Age_Categories nom_eve

egen sexoutcome = concat(Sex outcome)
table1, vars(Age_Categories cat\ Sex cat \ ethnicity cat \ Disabled cat \ Displaced cat\migrant cat\ pregnant cat\ youth_government_care  cat\ Community_mother  cat \ ex_paramil_ex_guerilla cat\ under_psychiatric_care  cat\ other_group  cat\ violence_victims cat) by(sexoutcome) saving("C:\Users\Amy\OneDrive\epi analysis\table1_nom_eve_ageepi.xls", replace) missing

save cases.dta, replace
*chikv
drop if nom_eve != "Chikungunya"
table1, vars(edad_cat cat ) by(Sex) saving(tableagechikv.xls, replace) 
*zika
use cases.dta, clear
drop if nom_eve != "Zika"
*table1, vars(edad_cat cat) by(Sex) saving(tableagezika.xls, replace) 
*dengue
use cases.dta, clear
keep if dengue == 1
*table1, vars(edad_cat cat ) by(Sex) saving(tableagedengue.xls, replace) 
use cases.dta, clear

*come back here. 
*explore date of onset of symptoms versus date of reporting
desc fec_not ini_sin_
destring fec_not, generate(notificatiiondate)
destring ini_sin_, generate(symptomdate)
*gen difference_days = fec_not - ini_sin_

/*The cumulative incidence will be calculated as a ratio taking as the numerator the number of cases diagnosed with serologic testing during the time period 
of interest and the denominator as the population of Cali for the year. An incidence trend line will be estimated over time.
*/
*cs does not work becuase it is not a case control study
*try instead incidence measures with urban population of cali measures: 2014 = 2,308,086; 2015 = 2,333,213
*adjust these for time in weeks, we have more data for 2015 than 2014. graph the ratio over the weeks. export the ratio by week and graph in excel.

tab nom_eve year

* cumulative incidence of all dengue in 2014
display  1820 / 2308086

*cumulative incidence of chik in 2015
display  2278 / 2333213

*cumulative incidence of all dengue in 2015
display 14349 + 68 + 16
display  14433 / 2333213

*cumulative incidence of chik and dengue over 2014-2015
display 28785 / 2333213

egen semanayear  = concat(semana year)
table1, vars(semanayear cat) by(nom_eve) saving(table2.xls, replace)
table semana nom_eve, by(year) col scol row m

/*cs outcome female
cs outcome female, by(outcome)
cs outcome Disabled
cs outcome Displaced 
cs outcome gp_migrant 
cs outcome pregnant 
cs outcome Community_mother 
cs outcome ex_paramil_ex_guerilla 
cs outcome under_psychiatric_care 
cs outcome other_group 
cs outcome violence_victims
cs outcome youth_government_care 
*/


/*The disease specific mortality rate will be calculated as the ratio between the number of dengue or chikungunya - related deaths during the study period and the 
denominator of the population of Cali for the year. 
*/


/*The case-fatality rate will be calculated as the ratio between the number of dengue or chikungunya -related deaths during the study period and the denominator of 
all patients with positive serological test for dengue or chikungunya.
*/

/*For the regression analysis, a geographically weighted Poisson regression will be used to predict disease incidence according to Formula 4 (Nakaya et al., 2005). 
*/
mlogit outcome edad_cont female pregnant other_group

/*Sample Size: All eligible dengue and chikungunya cases with will be included in the epidemiological analysis. 
*/

/*The geographically weighted semiparametric Poisson regression will require a minimum sample size of 355 cases of chikungunya or dengue based on the parameters 
listed in Table 2 using an A-priori Sample Size Calculator for Multiple Regression (Soper, 2015). The minimal detectable effect size was determined to be 0.028 
assuming 44,877 cases, alpha = 0.05, and power = 0.80 assuming single level experiment with individual level outcome using Optimal Design Software. Based on previous 
research, the minimum expected effect size is xxx. 
*/
mlogit outcome edad_cont female pregnant other_group

rename year anos
rename _merge merged

destring ano, replace
destring semana, replace
tab nom_eve if ano == 2014 & semana <= 40
drop if ano == 2014 & semana <= 40


save "C:\Users\Amy\OneDrive\epi analysis\temp.dta", replace


/****************************************************
 *Amy Krystosik                  					*
 *chikv, dengue, and zika in cali, colombia       	*
 *PHD dissertation                   				*
 *last updated July 24, 2016  						*
 ***************************************************/
cd "C:\Users\Amy\OneDrive\epi analysis" 

use "C:\Users\Amy\OneDrive\epi analysis\temp.dta", clear

capture log close 
log using "dissertation.smcl", text replace 
set scrollbufsize 100000
set more 1


**delete repeat observatrions (same id within one week).
*data cleaning
*drop freq_cedula
bysort  num_ide_ fec_not nom_eve: gen freq_cedula = _N
sort num_ide_ fec_not nom_eve
drop dup
quietly by num_ide_ fec_not nom_eve:  gen dup = cond(_N==1,0,_n)
tabulate dup nom_eve
drop if dup > 0


rename  ID_CODE_merged CODIGO
order CODIGO
tostring CODIGO, replace

*drop variables we don't use in analysis
	drop direccion dir_res_ freq_cedula4 freq_cedula2 ID_CODE localidad_ nom_upgd ndep_proce nmun_proce ndep_resi nmun_resi COD_COMUNA AREA PERIMETRO estrato_mo ACUERDO LIMITES dengue dengue_status dengue_death1 dengue_death2 dengue_death3 dengue_death4 chkv_status country append_merged direcionjavier cod_pre cod_sub pri_nom_ seg_nom_ pri_ape_ seg_ape_ tip_ide_ cod_pais_o cod_dpto_o cod_mun_o area_ cen_pobla_ vereda_ tip_ss_ cod_ase_ cod_dpto_r cod_mun_r fec_con_ tip_cas_ tip_cas_num fec_hos_ con_fin_ fec_def_ ajuste_ adjustment_num telefono_ cer_def_ cbmte_ nuni_modif fec_arc_xl nom_dil_f_ tel_dil_f_ fec_aju_ fm_fuerza fm_unidad fm_grado nmun_notif ndep_notif nreg chikv2015 control fec_exp nit_upgd cod_mun_d famantdngu direclabor fiebre cefalea dolrretroo malgias artralgia erupcionr dolor_abdo vomito diarrea somnolenci hipotensio hepatomeg hem_mucosa hipotermia caida_plaq acum_liqui aum_hemato extravasac hemorr_hem choque dao_organ muesttejid mueshigado muesbazo muespulmon muescerebr muesmiocar muesmedula muesrion classfinal_num conducta append20142015 merged sex1 sex2 freq_cedula dup

*export raw data
	save "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\dengue_chikv_oct2014-oct2015_cali.dta", replace
	save "dengue_chikv_oct2014-oct2015_cali.dta", replace
	export excel using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\dengue_chikv_zika_oct2014-abril2016_cali.xls", firstrow(variables) replace
	export excel using "dengue_chikv_zika_oct2014-abril2016_cali.xls", firstrow(variables) sheet("sheet1") replace

*export the new addresses for javier/*export for secretary of healtlh geocoding
	export excel CODIGO ID_CODE direccion dir_res_ barrio ID_BARRIO using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\direcciones_krystosik_5mayo2016B", firstrow(variables) replace
	export excel CODIGO ID_CODE direccion dir_res_ barrio ID_BARRIO using "direcciones_krystosik_5mayo2016B", firstrow(variables) sheet("sheet1") replace


	
****************************************************************incidence****************************************************************
	*pop standardization incidence by agecatepi and sex***
		import excel "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\population\population year sex cali_epiagecats.xls", sheet("Sheet1") firstrow clear
		tostring stratavar_age, replace
		collapse (sum) popvar, by(stratavars_year stratavars_female stratavar_age)

		gen popvar_weighted_epiagecats = .
		replace popvar_weighted_epiagecats= popvar*(14/52) if stratavars_year == 2014
		replace popvar_weighted_epiagecats= popvar if stratavars_year == 2015
		replace popvar_weighted_epiagecats= popvar*(12/52) if stratavars_year == 2016

		gen popvar_weighted_epiagecats_chik = .
		replace popvar_weighted_epiagecats_chik = popvar*(1/20)
		replace popvar_weighted_epiagecats_chik = popvar_weighted_epiagecats_chik*(14/52) if stratavars_year == 2014
		replace popvar_weighted_epiagecats_chik = popvar_weighted_epiagecats_chik*(12/52) if stratavars_year == 2016

		rename stratavars_year anos 
		rename stratavars_female female 
		rename stratavar_age edad_cat_epi 

		save "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\population\population year sex cali_epiagecats.dta", replace

		use "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\dengue_chikv_oct2014-oct2015_cali.dta", replace
		tostring Age_Categories, replace
		destring anos, replace
		tostring edad_cat_epi, replace
		merge m:1 anos female edad_cat_epi using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\population\population year sex cali_epiagecats.dta"
		save "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\population_cases_epiagecats.dta", replace

	*crude incidence table by age
		gen casecount = 1
		gen crudeincidence = .
		replace crudeincidence = casecount/ popvar
		export excel using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\arcgis analysis\gwr models\cases_incidence.xls", firstrow(variables) replace 

		egen crudeincidencesum = sum(crudeincidence), by(anos Sex Age_Categories nom_eve)
		collapse (mean) crudeincidencesum, by(anos Sex Age_Categories nom_eve)
		gen crudeincidence1000000 = crudeincidencesum*100000
		*bysort nom_eve stratavars_year stratavars_female stratavar_age: tab crudeincidence1000000
		export excel using "C:\Users\Amy\OneDrive\epi analysis\incidence.xls", firstrow(variables) replace 

************pop weighted incidence table by age****************
	use "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\population_cases.dta", replace
		gen casecount = 1
		gen incidenceweighted = .
		replace incidenceweighted = casecount/ popvar_weighted
		replace incidenceweighted = casecount/ popvar_weighted_chik if nom_eve == "Chikungunya" & anos == 2014
		replace incidenceweighted = casecount/ popvar_weighted_chik if nom_eve == "Chikungunya" & anos == 2015 & semana <= 45

*confirmed vs suspected dengue by death, severe, non-severe
	tab resultado, gen(result)
	gen confirmed = .
	replace confirmed = 1 if result1 ==1 
	replace confirmed = 0 if result1 == .  
	replace confirmed = 0 if result1 != 1 & nom_eve == "Dengue" 
	replace confirmed = 0 if result1 != 1 & nom_eve == "Severe Dengue" 
	replace confirmed = 0 if result1 != 1 & nom_eve == "Dengue Death" 

*create labels for lab positive vs negative
		gen Lab_result = "."
		replace Lab_result = "Positive" if resultado=="1" 
		replace Lab_result = "Negative" if resultado== "2"  
		replace Lab_result = "Not processed" if resultado== "3" 
		replace Lab_result = "Inadequate" if resultado== "4" 
		replace Lab_result = "Doubtfull" if resultado== "5" 
		replace Lab_result = "Value registered" if resultado== "6"
		replace Lab_result = "Compatible" if resultado== "7" 
		replace Lab_result = "Non-Reactive" if resultado== "11"
		replace Lab_result = "Not Compatible" if resultado== "15" 
		replace Lab_result = "Undefined" if resultado== "20"  
		replace Lab_result = "No Data" if resultado== ""  
		tab Lab_result, missing
		 
*make variables that allows us to look where values are females missing pregnancy values versus males.
	egen pregnant_females = concat(pregnant Sex)

*dengue collapsed (dengue grave and dengue death)
	gen outcome_collapsed = ""
	replace outcome_collapsed = "Dengue" if nom_eve =="Dengue" 
	replace outcome_collapsed = "Severe Dengue" if nom_eve =="Dengue Death" 
	replace outcome_collapsed = "Severe Dengue" if nom_eve == "Severe Dengue"
	replace outcome_collapsed = "Zika" if nom_eve =="Zika" 
	replace outcome_collapsed = "Chikungunya" if nom_eve =="Chikungunya"

*create collapsed outcome category of chikv and dengue without and with severity and grave and death. 
	gen outcome_collapsed_2 = .
	*outcome = 1 for dengue without warning
	replace outcome_collapsed_2 =1 if outcome ==1
	*outcome = 2 for dengue with warning signs
	replace outcome_collapsed_2 =2 if outcome == 2
	*outcome = 3 for dengue grave
	replace outcome_collapsed_2 = 3 if outcome == 3
	*outcome = 3 for dengue death
	replace outcome_collapsed_2 = 3 if outcome == 4 
	*outcome = 5 for dengue unclassified
	replace outcome_collapsed_2  =5 if outcome == 5 
	*outcome = 6 for chikungunya 
	replace outcome_collapsed_2 = 6 if  outcome == 6 
	*outcome = 7  for zika
	replace outcome_collapsed_2 = 7 if outcome == 7 

*tables with collapsed (dengue grave and dengue death) outcome with and without the strata for dengue with warning signs.
	table1, vars(Age_Categories cat\ Sex cat \ ethnicity cat \confirmed cat \Lab_result  cat\ Disabled cat \ Displaced cat \migrant cat \ pregnant cat \ pregnant_females cat \ youth_government_care cat \ Community_mother cat \ ex_paramil_ex_guerilla cat \ under_psychiatric_care cat \ other_group cat \ violence_victims cat) by(outcome_collapsed) saving("table1_outcome_collapsed.xls", replace ) missing 
	table1, vars(Age_Categories cat\ Sex cat \ ethnicity cat \confirmed cat \Lab_result  cat\ Disabled cat \ Displaced cat \migrant cat \ pregnant cat \ pregnant_females cat \ youth_government_care cat \ Community_mother cat \ ex_paramil_ex_guerilla cat \ under_psychiatric_care cat \ other_group cat \ violence_victims cat) by(outcome_collapsed_2) saving("table1_outcome_collapsed.xls", replace ) missing 
*table 1 for all cases by outcome where nom event is: Chikungunya	Dengue	Severe Dengue & Mortality	Zika
	table1, vars(Age_Categories cat\ Sex cat \ ethnicity cat \confirmed cat \Lab_result  cat\ Disabled cat \ Displaced cat \migrant cat \ pregnant cat \ pregnant_females cat \ youth_government_care cat \ Community_mother cat \ ex_paramil_ex_guerilla cat \ under_psychiatric_care cat \ other_group cat \ violence_victims cat) by(nom_eve) saving("C:\Users\Amy\OneDrive\epi analysis\table1_nom_eve_confirmed.xls", replace) missing test
*table 1 for all cases by outcome where 0 is chkv, 1 is dengue without warning signs, 2 is dengue with warning signs, 3 is denuge grave, 4 is dengue death
	table1, vars(Age_Categories cat\ Sex cat \ ethnicity cat \confirmed cat \Lab_result  cat\ Disabled cat \ Displaced cat \migrant cat \ pregnant cat \ pregnant_females cat \ youth_government_care cat \ Community_mother cat \ ex_paramil_ex_guerilla cat \ under_psychiatric_care cat \ other_group cat \ violence_victims cat) by(outcome) saving("C:\Users\Amy\OneDrive\epi analysis\table1_OUTCOME_confirmed.xls", replace) missing test 

save "temp2.dta", replace


*table incidence table with f to m ratios for nom_eve
	use temp2.dta, clear
		egen weightedincidencesum = sum(incidenceweighted), by(anos Sex Age_Categories outcome_collapsed)
		collapse (mean) weightedincidencesum, by(anos Sex Age_Categories outcome_collapsed confirmed Lab_result)
		gen weightedincidence1000000 = weightedincidencesum*100000
		export excel using "C:\Users\Amy\OneDrive\epi analysis\weightedincidencecollapased.xls", firstrow(variables) replace 
		bysort outcome_collapsed anos Age_Categories: gen weightedincidencemale = weightedincidence1000000 if Sex=="M"
		bysort outcome_collapsed anos Age_Categories: gen weightedincidencefemale = weightedincidence1000000 if Sex=="F"
		collapse (firstnm) weightedincidencemale  weightedincidencefemale , by(anos Age_Categories outcome_collapsed)
		bysort outcome_collapsed anos Age_Categories: gen ratioftom = weightedincidencefemale/weightedincidencemale
		gen lower = .
		replace lower = ratioftom - 1.96*sqrt((1/weightedincidencemale)  + (1/weightedincidencefemale))
		gen upper = .
		replace upper = ratioftom + 1.96*sqrt((1/weightedincidencemale)  + (1/weightedincidencefemale))
	export excel using "C:\Users\Amy\OneDrive\epi analysis\weightedincidenceratioscollapsed.xls", firstrow(variables) replace 

*table incidence table with f to m ratios for outcome_collapsed
	use temp2.dta, clear
		egen weightedincidencesum = sum(incidenceweighted), by(anos Sex Age_Categories outcome_collapsed)
		collapse (mean) weightedincidencesum, by(anos Sex Age_Categories outcome_collapsed confirmed Lab_result)
		gen weightedincidence1000000 = weightedincidencesum*100000
		bysort outcome_collapsed anos Age_Categories: gen weightedincidencemale = weightedincidence1000000 if Sex=="M"
		bysort outcome_collapsed anos Age_Categories: gen weightedincidencefemale = weightedincidence1000000 if Sex=="F"
		collapse (firstnm) weightedincidencemale  weightedincidencefemale , by(anos Age_Categories outcome_collapsed)
		bysort outcome_collapsed anos Age_Categories: gen ratioftom = weightedincidencefemale/weightedincidencemale
		gen lower = .
		replace lower = ratioftom - 1.96*sqrt((1/weightedincidencemale)  + (1/weightedincidencefemale))
		gen upper = .
		replace upper = ratioftom + 1.96*sqrt((1/weightedincidencemale)  + (1/weightedincidencefemale))
	export excel using "C:\Users\Amy\OneDrive\epi analysis\weightedincidenceratiosoutcome_collapsed.xls", firstrow(variables) replace

*use regular expressions to select the dates by format and then put all of them in the same format so i can subtract one from the other. 
	use temp2.dta, clear
	*concat some variable categories of interest
		egen diseaseyear = concat(anos nom_eve)
		egen diseaseyearsex = concat(anos nom_eve Sex)
		egen diseaseconfirmed= concat(nom_eve confirmed)
		*egen diseaseyear = concat(ano nom_eve)

	*quarters*
		gen quarter = .
		replace quarter = 1 if semana <= 13
		replace quarter = 2 if semana >13 & semana<= 26
		replace quarter = 3 if semana >26 & semana <= 39
		replace quarter = 4 if semana >39


	*export raw data
		export excel using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\dengue_chikv_zika_oct2014-abril2016_cali", firstrow(variables) replace
		export excel using "dengue_chikv_zika_oct2014-abril2016_cali", firstrow(variables) replace
	save "temp3.dta", replace

****incidence per 100,000 by barrio*****
		*pop standardization incidence
		*make population by barrio dataset.
			import excel "C:\Users\Amy\OneDrive\epi analysis\population\population bario cali.xls", sheet("barrio sex") firstrow clear
		*tostring stratavar_age, replace
			gen popvar_weighted_chik_barrio = .
			replace popvar_weighted_chik_barrio = Population
			gen str4 ID_barrio4 = string(ID_BARRIO,"%04.0f")
			save "C:\Users\Amy\OneDrive\epi analysis\population\population bario cali.dta", replace
		save "population bario cali.dta", replace

**use the cases spatially merged to barrio from arcgis becuase not all data has barrio from sec of health. 
	*chikv*
		import excel "C:\Users\Amy\OneDrive\epi analysis\diseasebarrio\chikvprojected_barrio.xls", sheet("chikvprojected_barrio") firstrow clear
		save "C:\Users\Amy\OneDrive\epi analysis\diseasebarrio\barrios_chikv_TableToExcel.dta", replace
		save "barrios_chikv_TableToExcel.dta", replace
			destring ID_BARRIO, replace
			gen str4 ID_barrio4 = string(ID_BARRIO,"%04.0f")
			merge m:1 ID_barrio4 using "C:\Users\Amy\OneDrive\epi analysis\population\population bario cali.dta"
			save "C:\Users\Amy\OneDrive\epi analysis\diseasebarrio\barriopopulation_chikv.dta", replace
			save "barriopopulation_chikv.dta", replace
			*crude incidence table by age and barrio
			gen casecount_barrio = 1
			gen crudeincidence_barrio = .
			replace crudeincidence_barrio = casecount/Population
			replace crudeincidence_barrio= casecount/ popvar_weighted_chik_barrio
			gen incidence =.
			replace incidence= casecount/popvar_weighted_chik_barrio
			export excel using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\arcgis analysis\gwr models\chikv_incidence_population_GWR.xls", firstrow(variables) replace
			egen crudeincidence_barriosum = sum(crudeincidence_barrio), by(ID_barrio4)
			collapse (mean) crudeincidence_barriosum, by(ID_barrio4) 
			gen crudeincidence_barriosum1000000 = crudeincidence_barriosum*100000
		*bysort nom_eve ID_BARRIO: tab crudeincidence_barriosum1000000
			export excel using "C:\Users\Amy\OneDrive\epi analysis\diseasebarrio\chikv_barrio.xls", firstrow(variables) replace 
			export excel using "chikv_barrio.xls", firstrow(variables) replace 

	*dengue*
		import excel "C:\Users\Amy\OneDrive\epi analysis\diseasebarrio\dengue_projected_barrio.xls", sheet("dengue_projected_barrio") firstrow clear
		save "C:\Users\Amy\OneDrive\epi analysis\diseasebarrio\barrios_dengue_TableToExcel.dta", replace
		save "barrios_dengue_TableToExcel.dta", replace
				destring ID_BARRIO, replace
				gen str4 ID_barrio4 = string(ID_BARRIO,"%04.0f")
				merge m:1 ID_barrio4 using "C:\Users\Amy\OneDrive\epi analysis\population\population bario cali.dta"
				save "C:\Users\Amy\OneDrive\epi analysis\diseasebarrio\barriopopulation_dengue.dta", replace
				save "barriopopulation_dengue.dta", replace
			*crude incidence table by age and barrio
				gen casecount_barrio = 1
				gen crudeincidence_barrio = .
				replace crudeincidence_barrio = casecount/Population
				gen incidence =.
				replace incidence= casecount/Population
				export excel using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\arcgis analysis\gwr models\dengue_incidence_population_GWR.xls", firstrow(variables) replace
			*replace crudeincidence_barrio= casecount/ popvar_weighted_chik_barrio if  Sheet1__nom_eve == 217
				egen crudeincidence_barriosum = sum(crudeincidence_barrio), by(ID_barrio4)
				collapse (mean) crudeincidence_barriosum, by(ID_barrio4) 
				gen crudeincidence_barriosum1000000 = crudeincidence_barriosum*100000
			*bysort nom_eve ID_BARRIO: tab crudeincidence_barriosum1000000
				export excel using "C:\Users\Amy\OneDrive\epi analysis\diseasebarrio\dengue_barrio.xls", firstrow(variables) replace 
				export excel using "dengue_barrio.xls", firstrow(variables) replace

		*zika*
				import excel "C:\Users\Amy\OneDrive\epi analysis\diseasebarrio\zikaprojected_barrio.xls", sheet("zikaprojected_barrio") firstrow clear
				save "C:\Users\Amy\OneDrive\epi analysis\diseasebarrio\barrios_zika_TableToExcel.dta", replace
				save "barrios_zika_TableToExcel.dta", replace
					destring ID_BARRIO, replace
					gen str4 ID_barrio4 = string(ID_BARRIO,"%04.0f")
					merge m:1 ID_barrio4 using "C:\Users\Amy\OneDrive\epi analysis\population\population bario cali.dta" 
				save "C:\Users\Amy\OneDrive\epi analysis\diseasebarrio\barriopopulation_zika.dta", replace
				save "barriopopulation_zika.dta", replace
			*crude incidence table by age and barrio
					gen casecount_barrio = 1
					gen crudeincidence_barrio = .
					replace crudeincidence_barrio = casecount/Population
					gen incidence =.
					replace incidence= casecount/Population
				export excel using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\arcgis analysis\gwr models\zika_incidence_population_GWR.xls", firstrow(variables) replace
			*replace crudeincidence_barrio= casecount/ popvar_weighted_chik_barrio if  Sheet1__nom_eve == 217
				egen crudeincidence_barriosum = sum(crudeincidence_barrio), by(ID_barrio4)
				collapse (mean) crudeincidence_barriosum, by(ID_barrio4) 
				gen crudeincidence_barriosum1000000 = crudeincidence_barriosum*100000
			*bysort nom_eve ID_BARRIO: tab crudeincidence_barriosum1000000
				export excel using "C:\Users\Amy\OneDrive\epi analysis\diseasebarrio\zika_barrio.xls", firstrow(variables) replace 
				export excel using "zika_barrio.xls", firstrow(variables) replace


	*******modeling*************
			use "temp3.dta", clear

			*convert barrio into numeric values
				encode barrio, generate(barrio2)
				encode fecha_nto_, generate(fecha_nto_2)

				mlogit outcome edad_cont female pregnant barrio2 fecha_nto_2
				mlogit outcome edad_cat_epi female pregnant barrio2 fecha_nto_2
