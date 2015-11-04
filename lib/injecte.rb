# encoding: UTF-8

require 'fileutils'
require 'bigdecimal'
require 'selenium-webdriver'

module Injecte


    @@wait = Selenium::WebDriver::Wait.new(:timeout => 10)

    def saisir(driver, methode, texte, valeur)
      @@wait.until { driver.find_element(methode, texte) }
      item = driver.find_element(methode, texte)
      item.clear
      item.send_keys valeur
    end

    def creation(driver, cop)

      driver.switch_to.default_content
      driver.switch_to.frame "frmWork"
      #"poste":"939917" inutile, on est dessus, fixé à la connexion
      #"budget":"01102" TODO à paramétrer après création du nouveau poste
      saisir(driver,:id,"_1",cop["budget"])
      #"numero_ordre":"1388220111", inutile, TODO les nouveaux numéros seront ajoutés au fichier à traitre
      #"date_acte":"19/03/2015"
      saisir(driver, :id, "_5", cop["date_acte"])
      #"date_reception":"27/03/2015"
      saisir(driver, :id, "_6", cop["date_reception"])
      #"date_cloture":null, inutile, on ne traite que les non closes
      #"nature_cession":"9.hors paye autre cession"
      saisir(driver, :id, "_2", cop["nature_cession"].sub(/^\d+\./,''))
      #"date_acquies":null
      saisir(driver, :id, "_8", cop["date_acquies"]) unless cop["date_acquies"] == "null"
      #"date_bdr":null
      saisir(driver, :id, "_7", cop["date_bdr"]) unless cop["date_bdr"] == "null"
      #"date_certif_non_constestation":null
      saisir(driver, :id, "_9", cop["date_certif"]) unless cop["date_certif"] == "null"
      #"date_effet":"27/03/2015" TODO vérifier si pertinent
      #"date_ex_unique":"27/03/2015"
      saisir(driver, :id, "_4", cop["date_ex_unique"]) unless cop["date_ex_unique"] == "null"
      #"dem_ar":"NON" à ne pas refaire, même si c'est oui
      #"multi_bc":"NON"
      driver.find_element(:name, "COP_CF_F01_CessionOppositionCAF.#multiBudgets-checkbox").click unless cop["multi_bc"] == "NON"
      #"rap_ref":"NON" TODo voir à quoi cela correspond
      #"etat_cession":"6 Paiement partiel" inutile, le statut est déduit à la création
      #"montant":"4250000","retenue":"2550000"
      reste = BigDecimal.new(cop["montant"].sub(/,/,'.')) - BigDecimal.new(cop["retenue"].sub(/,/,'.'))
      saisir(driver, :id, "_3", format('%.2f',reste).sub(/\./,','))
      #"motif_clot":null, inutile car on ne reprend pas les cessions closes
      #"motif_cl_cp":null, inutile car on ne reprend pas les cessions closes
      #"motif_rjt":"0", inutile car on ne reprend pas les cessions rejetées
      #"motif_rj_cp":null, inutile car on ne reprend pas les cessions rejetées
      #"proposition_cloture_pic":"0", inutile car on reprend pas les cessions closes
      #"reference_opposant":"DOS 799217 001",
      saisir(driver, :name, "COP_CF_F01_CessionOppositionCAF.referenceOpposant", cop["reference_opposant"])
      #"idt_tiers_opst":"640398",
      driver.execute_script("L('COP_CF_F01_TiersOpposantCAF.#tiers','','/COP_CF_G01_RechercheTiersOpposant','','COP_CM_SHARE','-1','','','',0,0,1,0, null, 0);")
      saisir(driver, :name, "TIE_RT_F01_Criteres_CAF.identifiantMetier", cop["idt_tiers_opst"])
      driver.execute_script "L('TIE_RT_F01_Criteres_CAF','','/TIE_RT_G01_RechTiers','','COP_CM_SHARE','-1','','','',0,0,1,0, null, 0);"
      @@wait.until { driver.page_source.include?("Nom/RS") }
      driver.execute_script "L('TIE_RT_F02_ResumesTiers_MCAF','','/TIE_RT_A01_CriteresRecherche','selectionner','COP_CM_SHARE','0','','','',0,0,1,0, null, 0);"
      #"nom_tiers_opst":"COP/CREDIT MUTUEL/FED COMPAGNON", TODO à vérifier
      #"rib_opst":"FR7610278022000002056900177", TODO à vérifier
      #"idt_tiers_opse":"640382",
      @@wait.until { driver.page_source.include?("Exemplaire Unique") }
      driver.execute_script("L('COP_CF_F01_TiersOpposeCAF.#tiers','','/COP_CF_G01_RechercheTiersOppose','','COP_CM_SHARE','-1','','','',0,0,1,0, null, 0);")
      saisir(driver, :name, "TIE_RT_F01_Criteres_CAF.identifiantMetier", cop["idt_tiers_opse"])
      driver.execute_script "L('TIE_RT_F01_Criteres_CAF','','/TIE_RT_G01_RechTiers','','COP_CM_SHARE','-1','','','',0,0,1,0, null, 0);"
      @@wait.until { driver.page_source.include?("Nom/RS") }
      driver.execute_script "L('TIE_RT_F02_ResumesTiers_MCAF','','/TIE_RT_A01_CriteresRecherche','selectionner','COP_CM_SHARE','0','','','',0,0,1,0, null, 0);"
      #"tiers_opse":"FED COMPAGNON METIERS BATIMENT", TODO à vérifier
      #"rib_opse":"FR7610278022000001569354024", TODO à vérifier
      #"rang":"1", TODO trier par rang pour retrouver l'ordre
      #"bloc_notes":null}
      @@wait.until { driver.page_source.include?("Exemplaire Unique") }
      driver.execute_script "L('','','/COP_CF_G08_BlocNotes','','COP_CM_SHARE','-1','','','',0,0,1,0, null, 0);"
      texte = cop.to_s
      texte += cop["bloc_notes"] if cop["bloc_notes"]
      saisir(driver, :name, "COP_CM_F00_CessionOppositionCAF.blocNote", texte)
      driver.execute_script "L('','','/COP_CF_G08_Appliquer','','COP_CM_SHARE','-1','','','',0,0,1,0, null, 0);"
      #valider
      @@wait.until { driver.page_source.include?("Certificat non contestation") }
      driver.execute_script "L('','','/COP_CF_G01_Continuer','','COP_CM_SHARE','-1','','','',0,0,1,0, null, 0);"
      @@wait.until { driver.page_source.include?("Priorit") }
      driver.execute_script "L('','','/COP_CF_G03_Continuer','','COP_CM_SHARE','-1','','','',0,0,1,0, null, 0);"
      @@wait.until { driver.page_source.include?("Saisie de la liste des") }
      driver.execute_script "L('','','/COP_CF_G04_Continuer','','COP_CM_SHARE','-1','','','',0,0,1,0, null, 0);"
      @@wait.until { driver.page_source.include?("Edition de l'accus") }
      driver.execute_script "L('','','/COP_CF_G07_Terminer','','COP_CM_SHARE','-1','','','',0,0,1,0, null, 0);"
      #"mnt_mlv":null, TODO à faire avec sasie main-levée après création de la cession
      @@wait.until {driver.page_source.include?("Certificat non contestation") }
      driver.page_source.include?("Aucune anomalie")
    end


    def self.injecte(driver)
    dat = 'c:/cop/a_traiter/'
    dec = 'c:/cop/en_cours/'
    dt = 'c:/cop/traitees/'
    dav = 'c:/cop/a_verifier/'
    fichiers = Dir.entries( dat )
    fichiers.each do |fic|
      if /^at\d{5}$/ =~ fic
        FileUtils.mv(dat + fic, dec + fic)
        File.open(dec + fic, 'r') do |f|
          @cop = JSON.parse(f.gets)
        end
        creation(driver, @cop) ? FileUtils.mv(dec + fic, dt + fic) : FileUtils.mv(dec + fic, dav + fic)
      end
    end
  end
end