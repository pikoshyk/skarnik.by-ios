//
//  SKLacalization.swift
//  Skarnik
//
//  Created by Logout on 15.10.22.
//  Copyright © 2022 Skarnik. All rights reserved.
//

import Foundation

class SKLocalization: Any {
    class var searchbarSearchWords: String { "Пошук слоў" }
    class var searchbarCancel: String { "Адмена" }
    class var searchHeaderAdditionalRules: String{ "Пошук з аўтаматычнай\nпадменай і|и, ў|щ, ‘|ъ|ь, е|ё" }

    class var vocabulariesAdvancedSearch: String { "Спецпошук" }
    class var segmentHistory: String { "Гісторыя" }
    class var segmentRusBel: String { "Рус-Бел" }
    class var segmentBelRus: String { "Бел-Рус" }
    class var segmentDefinition: String { "Тлумачальны" }
    
    class var cellSubtitleHistory: String { "Гісторыя" }
    class var cellSubtitleRusBel: String { "Руска-Беларускі" }
    class var cellSubtitleBelRus: String { "Беларуска-Рускі" }
    class var cellSubtitleDenifition: String { "Тлумачальны" }
    class var cellDeleteActionTitle: String { "Выдаліць" }

    class var wordDetailsSubtitleRusBel: String { "Пераклад на беларускую мову" }
    class var wordDetailsSubtitleBelRus: String { "Пераклад на рускую мову" }
    class var wordDetailsSubtitleDenifition: String { "Тлумачэнне слова" }
    class var wordDetailsSpelling: String { "Націск" }
    class var wordDetailsSpellingTitle: String { "Націск і арфаграфія" }
    class var wordDetailsSpellingMessage: String { "для прагляду, калі ласка, абярыце слова" }
    class var wordDetailsSpellingCancel: String { "Адмена" }

    class var errorWordNotFound: String { "Слова не знойдзена." }
    class var errorNetworkErrorTryAgainLater: String { "Памылка сеткі. Паспрабуйце пазней." }
    
    class var aboutDone: String { "Добра" }
    class var aboutSubscriptionCreator: String { "Cтваральнік Скарніка" }
    class var aboutSubscriptionDeveloper: String { "Распрацоўшчык iOS аплікацыі" }
    class var aboutSubscriptionDesigner: String { "UI/UX дапамога" }
    class var aboutDescription: String { "Skarnik - электронны руска-беларускі слоўнік. За аснову ўзяты акадэмічны слоўнік, які быў выпушчаны ў 1953 годзе (пад рэдакцыяй Я. Коласа, К. Крапівы і П. Глебкі) і затым некалькі разоў перавыдаваўся з выпраўленнямі і дапаўненнямі. Skarnik дапрацаваны з улікам сучаснай практыкі.\n\nСайт skarnik.by пачаў працаваць 7 жніўня 2012 года і праца вядзецца дагэтуль, штодня.\n\nТаксама ў слоўнікавых артыкулах савецкія прыклады прыбраныя ці замененыя на беларускія." }
    class var aboutSupportHtml: String {"Праекту патрэбна дапамога: Dev, ML, PR, UX/UI. Прапановы пісаць <a href=\"mailto:belanghelp@gmail.com\">сюды</a>."}
    class var wordStressLoadingLabel: String { "Пачакайце, калі ласка" }
    class var wordStressTitle: String { "Націск" }
    class var wordStressError: String { "Нешта пайшло не так, мо праблемы з інтэрнэтам ці серверам. Паспрабуйце яшчэ раз." }

    class var widgetWordTitle: String { "Слова дня" }
    class var widgetWordDescriptioon: String { "Выпадковае слова і яго пераклад." }
    class var widgetWordSampleWord: String { "халэмус" }
    class var widgetWordSampleTranslation: String { "гибель, конец" }
}
