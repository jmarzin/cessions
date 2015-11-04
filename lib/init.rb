# encoding: UTF-8

require 'io/console'

module Init

  def self.connecte_base_ecole(driver, login, poste)
    driver.navigate.to "http://cpt-helios6v.bercy.cp/"
    driver.switch_to.frame "content"
    driver.find_element(:partial_link_text, "Base Ecole HELIOS - Formations présentielles").click
    driver.find_element(:name, "HBL_P_F00_Portail_Caf.login").send_keys login #"UF.PC939917"
    driver.find_element(:name, "HBL_P_F00_Portail_Caf.codePosteComptable").send_keys poste #"939917"
    driver.execute_script "L('','','/HBL_P_A00_AuthentificationSimuler','simuler','','-1','','','',0,0,0,1, null, 0)"
    driver.find_element(:class, "inputcontinuer").click if driver.page_source.include?("AVERTISSEMENT")
  end

  def self.connecte_production(driver, login)

    driver.navigate.to "http://ulysse.dgfip/"
    driver.find_element(:id, 'menu-7589').click
    driver.find_element(:id, 'menu-7593').click
    driver.switch_to.window driver.window_handles[-1]
    identifiant = driver.find_elements(:id, "identifiant")
    if !identifiant.empty?
      identifiant[0].send_keys login
      pwd = ""
      while pwd == ""
        puts "Votre mot de passe ?"
        pwd = STDIN.noecho(&:gets).chomp
      end
      driver.find_element(:id, "secret_tmp").send_keys pwd[0..-2]
      driver.find_element(:class, "valid").click
    end
    if driver.page_source.include?("http://helios.appli.impots")
      driver.navigate.to "http://helios.appli.impots"
    else
      STDERR.puts "Vous n'êtes pas habilité sur Hélios"
      exit -1
    end
    driver.find_element(:class, "inputcontinuer").click if driver.page_source.include?("AVERTISSEMENT")
  end

  def self.ecran_crea_cop(driver, poste)
    driver.switch_to.frame 'frmWork'
    driver.execute_script "L('','','/CMN_GC_G00_GestionContexte','','HBL/ContexteHandler','-1','','','',0,0,1,0, null, 0);"
    Selenium::WebDriver::Wait.new(:timeout => 10).until {driver.page_source.include?("Modification Contexte") }
    #TODO changer le numéro du poste
    driver.execute_script "L('','','/HBL_GC_G00_GestionContexteValider','','HBL_CP_Share','-1','','','',0,0,1,1, null, 0);"
    driver.switch_to.default_content
    driver.switch_to.frame('frmMenu')
    driver.find_element(:id, 'divm0_1').click
    driver.execute_script("m.go('019')")
  end

end