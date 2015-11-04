# encoding: UTF-8

module Prep
  def self.prepare(lines)
    keys = lines.delete lines.first
    data = lines.map do |values|
      Hash[keys.zip(values)]
    end

    ["c:/cop","c:/cop/ignorees","c:/cop/vides","c:/cop/a_traiter","c:/cop/traitees","c:/cop/a_verifier","c:/cop/en_cours"].each do |rep|
      Dir.mkdir( rep )
    end

    string = JSON.pretty_generate(data)

    nombre_a_traiter, nombre_vides, nombre_ignorees = 0, 0, 0

    JSON.parse(string).each do |objet|
      if objet["numero_ordre"] == nil
        debut_nom = "c:/cop/vides/v"
        nombre_vides+=1
        nb = nombre_vides
      elsif ["2 Soldée","3 Close","4 Rejetée"].include? objet["etat_cession"]
        debut_nom = "c:/cop/ignorees/i"
        nombre_ignorees+=1
        nb = nombre_ignorees
      else
        debut_nom = "c:/cop/a_traiter/at"
        nombre_a_traiter+=1
        nb = nombre_a_traiter
      end
      File.open(debut_nom+format("%05d",nb), 'w') do |f|
        JSON.dump(objet, f)
      end
    end
    puts "#{nombre_vides} cop vides\n#{nombre_ignorees} cop ignorées\n#{nombre_a_traiter} cop à traiter"
  end
end