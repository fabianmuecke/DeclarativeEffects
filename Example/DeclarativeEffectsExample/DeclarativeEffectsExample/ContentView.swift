//
//  ContentView.swift
//  DeclarativeEffectsExample
//
//  Created by Fabian Mücke on 27.07.23.
//

import ComposableArchitecture
import DeclarativeEffects
import SwiftUI

struct ContentView: View {
    fileprivate(set) var store: Store<CatsFeature.State, CatsFeature.Action> = Store(
        initialState: .init(),
        reducer: {
            let effectHandler = CatsFeature.EffectHandler(api: CatAPI())
            DeclarativeEffectsReducer<CatsFeature.State, CatsFeature.Action, CatsFeature.Request>(
                reduce: CatsFeature.reduce(state:action:),
                effectHandler: effectHandler.handleEffect(for:)
            )
        }
    )

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                Image(systemName: "cat")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Text("Hello, The Cat API!")
                if let breed = viewStore.parameters.breeds?.first {
                    Button(action: { viewStore.send(.filter(by: nil)) }) {
                        Text("Remove filter: \(breed.rawValue)")
                    }
                }
                ZStack {
                    if let images = viewStore.images?.images {
                        ScrollView {
                            LazyVGrid(columns: [.init(.fixed(140)), .init(.fixed(140))]) {
                                ForEach(images) { image in
                                    ZStack(alignment: .bottomTrailing) {
                                        Color.gray.overlay(
                                            AsyncImage(url: image.url) { phase in
                                                switch phase {
                                                case let .success(image):
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                default:
                                                    EmptyView()
                                                }
                                            }
                                        )
                                        .frame(maxWidth: .infinity)
                                        .aspectRatio(1, contentMode: .fit)
                                        .clipped()

                                        if let breed = image.breeds.first {
                                            Button(action: { viewStore.send(.filter(by: breed.id)) }) {
                                                Text("\(breed.id.rawValue)")
                                                    .foregroundColor(.white)
                                                    .shadow(color: .black, radius: 5)
                                                    .padding()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if viewStore.isLoading {
                        Color.black
                            .opacity(0.6)
                            .cornerRadius(8)
                            .overlay(ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)))
                            .aspectRatio(1, contentMode: .fit)
                            .frame(width: 120)
                    }

                }.frame(maxHeight: .infinity)
            }
            .padding()
        }.onAppear { store.send(.start) }
    }
}

extension CatImage: Identifiable {}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: Store(initialState: .init(), reducer: {
            let effectHandler = CatsFeature.EffectHandler(api: MockCatAPI())
            DeclarativeEffectsReducer<CatsFeature.State, CatsFeature.Action, CatsFeature.Request>(
                reduce: CatsFeature.reduce(state:action:),
                effectHandler: effectHandler.handleEffect(for:)
            )
        }))
    }
}
