# -*- coding: utf-8 -*-
########
######## 
### Annotation OMIM sur fichier tsv 
### Auteur : Kevin Yauy 29/06/2016
### Base de données OMIM restructurée de juin 2016 
### Necessite d'avoir le fichier genemapR.xlsx dans le dossier
### Input file - fichier provenant d'ANNOVAR .txt 
### avec ajout des colonnes manquantes à la fin sans laisser de blanc 
### Output file - fichier fusionné merged.xlsx
### Command line: python Omim_annotation.py inputfile
########
########


import pandas
import sys
    
inputfile = open(sys.argv[1], "r+")

#omim = pandas.read_excel('genemapR.xlsx')
omim = pandas.read_excel(sys.argv[2])
vcf = pandas.read_table(inputfile, low_memory=False)

omerged = pandas.merge(vcf,omim, on="Gene.refGene", how="left", left_index=True)
#omerged.to_excel("final_annotated.xlsx")
omerged.to_excel(sys.argv[3])