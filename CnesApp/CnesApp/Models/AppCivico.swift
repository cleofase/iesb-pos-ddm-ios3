//
//  AppCivico.swift
//  CnesApp
//
//  Created by Cleofas Pereira on 17/12/2017.
//  Copyright © 2017 Cleofas Pereira. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

struct AppCivico {
    private static let urlBase = "http://mobile-aceite.tcu.gov.br/mapa-da-saude"
    private static let uriHealthUnits = "/rest/estabelecimentos"
    private static let uriHealthUnitById = "/rest/estabelecimentos/unidade/%@"
    private static let uriHealthUnitsByGeoLocation = "/rest/estabelecimentos/latitude/%@/longitude/%@/raio/%@"

    func healthUnitsUrl() -> URL {
        return URL(string: AppCivico.urlBase + AppCivico.uriHealthUnits)!
    }
    
    func healthUnitsUrl(AtLatitude latitude: String, AndLogitude longitude: String, UnderRadius radius: String ) -> URL {
        return URL(string: String(format: AppCivico.urlBase + AppCivico.uriHealthUnitsByGeoLocation,latitude, longitude, radius))!
    }
    
    func healthUnitUrl(withId id: String) -> URL {
        return URL(string: String(format: AppCivico.urlBase + AppCivico.uriHealthUnitById, id))!
    }
}

struct HealthUnit: Codable {
    var codUnidade: String?
    var cnpj: String?
    var nomeFantasia: String?
    var natureza: String?
    var tipoUnidade: String?
    var esferaAdministrativa: String?
    var vinculoSus: String?
    var retencao: String?
    var fluxoClientela: String?
    var temAtendimentoUrgencia: String?
    var temAtendimentoAmbulatorial: String?
    var temCentroCirurgico: String?
    var temObstetra: String?
    var temNeoNatal: String?
    var temDialise: String?
    var descricaoCompleta: String?
    var tipoUnidadeCnes: String?
    var categoriaUnidade: String?
    var logradouro: String?
    var numero: String?
    var bairro: String?
    var cidade: String?
    var uf: String?
    var cep: String?
    var telefone: String?
    var turnoAtendimento: String?
    var lat: Double?
    var long: Double?
    
    func annotationColor() -> UIColor {
        if let _ = temAtendimentoUrgencia, temAtendimentoUrgencia! == "Sim" {return .red}
        return .cyan
    }
}
