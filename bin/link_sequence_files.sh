#!/bin/bash
#
# Reccueil de commande à faire tourner sur luke
#

function LIBRARY_LAYOUT {
    local library=$1
    local short=$(awk -F ":" '{print $2}' <<< $library)

    phylopushd $library 2>&1 > /dev/null

    if [[ -d ${short}.odx ]] ; then
        if [[ -d ${short}.rdnanuc.oas ]] ; then 
            local assembly="${short}.rdnanuc"
        else 
            if [[ -d ${short}.chloro.oas ]] ; then
            local assembly="${short}.chloro"
            fi
        fi 
        oa compact ${short} ${assembly} 2>&1 | \
        awk '/Fragment length estimated/ {
                    printf "<PAIRED NOMINAL_LENGTH=\"%.0f\" NOMINAL_SDEV=\"%.0f\"/>\n",$(NF-3),$NF
                }'
    fi
    popd 2>&1 > /dev/null
}

function LIBRARY_FILES {
    local library=$1

    phylopushd $library 2>&1 >/dev/null
    local loc=$(pwd) 
    echo ${library}$(ls $loc/*q.gz | \
        sort | \
        awk -F '/' '{printf ",%s,%s",$(NF),$0 }') | \
        awk -F ',' '
            function diffindex(s1,s2) {
                ls = length(s1)
                for (i=1; i<=ls && substr(s1,i,1) == substr(s2,i,1);i++) {
                }

                return i
            }

            function experiment(s1,s2) {
                idx = diffindex(s1,s2)
                l=1

                if (substr(s1,idx-1,1)=="R") {
                    idx--
                    l++
                }
                if (substr(s1,idx-1,1)=="_") {
                    idx--
                    l++
                }

                expe = substr(s1,1,idx-1) substr(s1,idx+l,1000)
                sub(/(_clean)?\..+q\..+$/,"",expe)
                return expe
            }

            function MD5(file) {
                cmd = "md5sum " file " | awk '\''{print $1}'\''"
                cmd | getline md5
                close(cmd)
                return md5
            }

            BEGIN {OFS=","}
            { 
                print $1,experiment($2,$4),$2,$4,$3,$5,MD5($3),MD5($5)
            }
        '
    popd 2>&1 >/dev/null   
}


(echo "Sequencing_ID,ALIAS,ENA_FILE_FWD,ENA_FILE_REV,LOCAL_FILE_FWD,LOCAL_FILE_REV,MD5_FWD,MD5_REV,LIBRARY_LAYOUT" 
for lib in $(awk -F',' '(NR>1) {print $3}' sequencing_orthoskim_PhyloAlps_FINAL.csv) ; do 
    echo $(LIBRARY_FILES $lib),$(LIBRARY_LAYOUT $lib)
done) > 

interactive.phyloalps
phyloskims
module load orgasm

(echo "Sequencing_ID,ALIAS,ENA_FILE_FWD,ENA_FILE_REV,LOCAL_FILE_FWD,LOCAL_FILE_REV,MD5_FWD,MD5_REV,LIBRARY_LAYOUT" 
for lib in $(cat PHYLOALPS_HERBARIUM_64_25jan2022.csv \
                | grep Batch-Clades \
                | grep -v Genoscope \
                | awk -F',' '{print $NF}')  ; do 
    echo $(LIBRARY_FILES $lib),$(LIBRARY_LAYOUT $lib)
done) > Batch-Clades.sequence_files.csv

awk -F ',' 'BEGIN {
                    print "rm -rf batch-to-submit"  
                    print "mkdir batch-to-submit" 
                    print "pushd batch-to-submit"
                  }
            (NR>1){
                    printf "ln -s '\''%s'\''\n",$5
                    printf "ln -s '\''%s'\''\n",$6
                  } 
            END   {
                    print "popd"
                  }' Batch-Clades.sequence_files.csv \
    | bash

cd batch-to-submit
ascp  -QT -l300M -L- * Webin-43547@webin.ebi.ac.uk:.



# expe=$NF;sub(/(_clean)?\..+\..+$/,"",expe);
# awk -F ',' 'BEGIN {print "mkdir batch-to-submit"; print "pushd batch-to-submit"}{printf "ln -s '\''%s'\''\n",$(NF-2);printf "ln -s '\''%s'\''\n",$(NF-1)} END {print "popd"}' sequencing_orthoskim_PhyloAlps_FINAL.files.csv | bash
# ascp  -QT -l300M -L- * Webin-43547@webin.ebi.ac.uk:.

# awk -F ',' 'BEGIN {printf "ascp -QT -l300M -L- "}{gsub(":","\\:",$(NF-2));gsub(":","\\:",$(NF));printf "%s %s ",$(NF-2),$NF} END {print "Webin-43547@webin.ebi.ac.uk:."}' sequencing_orthoskim_PhyloAlps_FINAL.files.csv 


# ascp -QT -l300M -L- '/bettik/LECA/phyloskims/data/prerelease/clades/Soldanella_alpina_cantabrica\:1924223/CLA010117/GWM\:1243/180307_SND393_A_L001_GWM-1243_R1.fastq.gz' '/bettik/LECA/phyloskims/data/prerelease/clades/Soldanella_alpina_cantabrica\:1924223/CLA010117/GWM\:1243/180307_SND393_A_L001_GWM-1243_R2.fastq.gz' '/bettik/LECA/phyloskims/data/prerelease/clades/Soldanella_chrysosticta\:152120/CLA010132/GWM\:1245/180307_SND393_A_L001_GWM-1245_R1.fastq.gz' '/bettik/LECA/phyloskims/data/prerelease/clades/Soldanella_chrysosticta\:152120/CLA010132/GWM\:1245/180307_SND393_A_L001_GWM-1245_R2.fastq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Andromeda_polifolia\:95630/PHA000470/RSZ\:RSZAXPI001349-74/140128_I249_FCC3R3PACXX_L8_RSZAXPI001349-74_1.fq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Andromeda_polifolia\:95630/PHA000470/RSZ\:RSZAXPI001349-74/140128_I249_FCC3R3PACXX_L8_RSZAXPI001349-74_2.fq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Arctostaphylos_uva-ursi\:84009/PHA000781/RSZ\:RSZAXPI000940-64/140105_I244_FCC3J4BACXX_L5_RSZAXPI000940-64_1.fq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Arctostaphylos_uva-ursi\:84009/PHA000781/RSZ\:RSZAXPI000940-64/140105_I244_FCC3J4BACXX_L5_RSZAXPI000940-64_2.fq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Calluna_vulgaris\:13385/PHA001461/RSZ\:RSZAXPI001450-44/140122_I232_FCC3J1LACXX_L4_RSZAXPI001450-44_1.fq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Calluna_vulgaris\:13385/PHA001461/RSZ\:RSZAXPI001450-44/140122_I232_FCC3J1LACXX_L4_RSZAXPI001450-44_2.fq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Empetrum_nigrum_nigrum\:191066/PHA003227/RSZ\:RSZAXPI000830-22/140110_I251_FCC3HW8ACXX_L5_RSZAXPI000830-22_1.fq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Empetrum_nigrum_nigrum\:191066/PHA003227/RSZ\:RSZAXPI000830-22/140110_I251_FCC3HW8ACXX_L5_RSZAXPI000830-22_2.fq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Erica_arborea\:270431/PHA003341/RSZ\:RSZAXPI001351-80/140128_I249_FCC3R3PACXX_L8_RSZAXPI001351-80_1.fq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Erica_arborea\:270431/PHA003341/RSZ\:RSZAXPI001351-80/140128_I249_FCC3R3PACXX_L8_RSZAXPI001351-80_2.fq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Erica_scoparia\:270444/PHA003345/RSZ\:RSZAXPI001341-40/140116_I269_FCC3J3BACXX_L6_RSZAXPI001341-40_1.fq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Erica_scoparia\:270444/PHA003345/RSZ\:RSZAXPI001341-40/140116_I269_FCC3J3BACXX_L6_RSZAXPI001341-40_2.fq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Hottonia_palustris\:175037/PHA004642/GWM\:1240/180307_SND393_A_L001_GWM-1240_R1.fastq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Hottonia_palustris\:175037/PHA004642/GWM\:1240/180307_SND393_A_L001_GWM-1240_R2.fastq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Loiseleuria_procumbens\:45912/PHA005438/RSZ\:RSZAXPI001346-52/140128_I249_FCC3R3PACXX_L8_RSZAXPI001346-52_1.fq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Loiseleuria_procumbens\:45912/PHA005438/RSZ\:RSZAXPI001346-52/140128_I249_FCC3R3PACXX_L8_RSZAXPI001346-52_2.fq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Moneses_uniflora\:93817/PHA005879/RSZ\:RSZAXPI000854-80/140110_I251_FCC3HW8ACXX_L5_RSZAXPI000854-80_1.fq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Moneses_uniflora\:93817/PHA005879/RSZ\:RSZAXPI000854-80/140110_I251_FCC3HW8ACXX_L5_RSZAXPI000854-80_2.fq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Orthilia_secunda\:93819/PHA006313/RSZ\:RSZAXPI000816-86/131227_I263_FCC368BACXX_L5_RSZAXPI000816-86_1.fq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Orthilia_secunda\:93819/PHA006313/RSZ\:RSZAXPI000816-86/131227_I263_FCC368BACXX_L5_RSZAXPI000816-86_2.fq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Pyrola_chlorantha\:93824/PHA007377/RSZ\:RSZAXPI001153-43/140128_I249_FCC3R3PACXX_L6_RSZAXPI001153-43_1.fq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Pyrola_chlorantha\:93824/PHA007377/RSZ\:RSZAXPI001153-43/140128_I249_FCC3R3PACXX_L6_RSZAXPI001153-43_2.fq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Pyrola_media\:642534/PHA007378/RSZ\:RSZAXPI000961-101/140122_I232_FCC3J1LACXX_L6_RSZAXPI000961-101_1.fq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Pyrola_media\:642534/PHA007378/RSZ\:RSZAXPI000961-101/140122_I232_FCC3J1LACXX_L6_RSZAXPI000961-101_2.fq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Pyrola_minor\:93826/PHA007382/RSZ\:RSZAXPI000819-89/131227_I263_FCC368BACXX_L5_RSZAXPI000819-89_1.fq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Pyrola_minor\:93826/PHA007382/RSZ\:RSZAXPI000819-89/131227_I263_FCC368BACXX_L5_RSZAXPI000819-89_2.fq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Pyrola_rotundifolia\:13651/PHA007385/RSZ\:RSZAXPI000824-16/140110_I251_FCC3HW8ACXX_L5_RSZAXPI000824-16_1.fq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Pyrola_rotundifolia\:13651/PHA007385/RSZ\:RSZAXPI000824-16/140110_I251_FCC3HW8ACXX_L5_RSZAXPI000824-16_2.fq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Rhododendron_ferrugineum\:49622/PHA007604/RSZ\:RSZAXPI000954-94/140122_I232_FCC3J1LACXX_L6_RSZAXPI000954-94_1.fq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Rhododendron_ferrugineum\:49622/PHA007604/RSZ\:RSZAXPI000954-94/140122_I232_FCC3J1LACXX_L6_RSZAXPI000954-94_2.fq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Rhodothamnus_chamaecistus\:45907/PHA007614/RSZ\:RSZAXPI000820-90/131227_I263_FCC368BACXX_L5_RSZAXPI000820-90_1.fq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Rhodothamnus_chamaecistus\:45907/PHA007614/RSZ\:RSZAXPI000820-90/131227_I263_FCC368BACXX_L5_RSZAXPI000820-90_2.fq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Vaccinium_vitis-idaea\:180772/PHA009507/RSZ\:RSZAXPI000939-53/140105_I244_FCC3J4BACXX_L5_RSZAXPI000939-53_1.fq.gz' '/bettik/LECA/phyloskims/data/prerelease/phyloalps/Vaccinium_vitis-idaea\:180772/PHA009507/RSZ\:RSZAXPI000939-53/140105_I244_FCC3J4BACXX_L5_RSZAXPI000939-53_2.fq.gz' Webin-43547@webin.ebi.ac.uk:.