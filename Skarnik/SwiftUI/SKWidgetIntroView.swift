//
//  SKWidgetIntroView.swift
//  Skarnik
//
//  Created by Logout on 1.11.23.
//  Copyright © 2023 Skarnik. All rights reserved.
//

import SwiftUI

@available(iOS 17.0, *)
struct SKWidgetIntroView: View {
    var body: some View {
        NavigationStack {
            Spacer(minLength: 0)
            ScrollView {
                VStack() {
                    self.widgetView
                        .frame(width: 150, height: 150)
                        .padding(.vertical, 50)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Што новага?!")
                            .font(.headline)
                            .frame(minWidth: 0, maxWidth: .infinity)
                        Text("Мы дадалі ў аплікацыю віджэт са словам дня, але ж самы смак у тым, як мы абіраем словы для гэтага віджэта!")
                        Text("А абіраем мы іх параўноўваючы па адлегласці Левенштэйна, каб само слова і яго пераклад значна адрозніваліся паміж сабой, дэманструючы толькі самы смак беларускай мовы! ❤️‍🩹")
                    }
                    .frame(maxWidth: 300)

                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}, label: {
                        Text("Добра")
                            .font(.headline)
                    })
                }
            }
            Spacer(minLength: 0)
        }
    }
    
    var widgetView: some View {
        VStack {
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("пад чаркаю".uppercased())
                        .lineLimit(2)
                        .font(.system(size: 12))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.accentColor)
                    Text("навеселе – нареч. падпіўшы, пад чаркаю")
                        .font(.system(size: 14))
                        .fontWeight(.regular)
                        .foregroundStyle(.secondary)
                }
                .padding()
                Spacer(minLength: 0)
            }
            Spacer(minLength: 0)
        }
        .background(content: {
          RoundedRectangle(cornerRadius: 25.0)
                .fill(.white)
                .shadow(color: .gray.opacity(0.5), radius: 8, x: 0, y: 0)
        })
    }
}

@available(iOS 17.0, *)
#Preview {
    SKWidgetIntroView()
}
