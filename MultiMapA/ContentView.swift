//
//  ContentView.swift
//  MultiMapA
//
//  Created by Weerawut on 1/1/2569 BE.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @State private var mapCamera = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275),
            span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
        )
    )
    
    @AppStorage("searchText") private var searchText = ""
    
    @State private var locations = [Location]()
    @State private var selectedLocations = Set<Location>()
    
    var body: some View {
        NavigationSplitView {
            List(locations, selection: $selectedLocations) { location in
                Text(location.name)
                    .tag(location)
                    .contextMenu {
                        Button(role: .destructive) {
                            delete(location)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                    }
            }
            .frame(minWidth: 200)
        } detail: {
            Map(position: $mapCamera) {
                ForEach(locations)  { location in
                    Annotation(location.name, coordinate: location.coordinate, anchor: .top) {
                        AnnotationView(location: location)
                    }
                }
            }
            .searchable(text: $searchText)
            .onSubmit(of: .search, runSearch)
        }
        .onChange(of: selectedLocations) {
            var visibleMap = MKMapRect.null
            for location in selectedLocations {
                let mapPoint = MKMapPoint(location.coordinate)
                let mapRect = MKMapRect(x: mapPoint.x - 100_000, y: mapPoint.y - 100_000, width: 200_000, height: 200_000)
                visibleMap = visibleMap.union(mapRect)
            }
            var newRegion = MKCoordinateRegion(visibleMap)
            newRegion.span.latitudeDelta *= 1.5
            newRegion.span.longitudeDelta *= 1.5
            withAnimation {
                mapCamera = .region(newRegion)
            }
        }
        .onDeleteCommand {
            for location in selectedLocations {
                delete(location)
            }
        }
    }
    
    private func AnnotationView(location: Location) -> some View {
        VStack(spacing: 5) {
            Image(systemName: "location.circle.fill")
                .font(.title)
                .foregroundStyle(.red)
            
            VStack {
                Text(location.name)
                    .font(.headline)
                
                Text(location.country)
                    .font(.caption2)
            }
            .padding(5)
            .background(.black)
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 5))
        }
    }
    
    private func runSearch() {
        if !searchText.isEmpty, let sameSearchLocation = locations.first(where: {$0.name.localizedCaseInsensitiveContains(searchText)}) {
            selectedLocations = [sameSearchLocation]
            return
        }
        
        Task {
            let searchRequest = MKLocalSearch.Request()
            searchRequest.naturalLanguageQuery = searchText
            if let region = mapCamera.region {
                searchRequest.region = region
            }
            
            let search = MKLocalSearch(request: searchRequest)
            let response = try await search.start()
            guard let item = response.mapItems.first else { return }
            guard let itemName = item.name, let country =  item.addressRepresentations?.regionName else { return }
            let itemLocation = item.location
            
            
            let newLocation = Location(name: itemName, latitude: itemLocation.coordinate.latitude, longitude: itemLocation.coordinate.longitude, country: country)
            locations.append(newLocation)
            selectedLocations = [newLocation]
            searchText = ""
        }
    }
    
    private func delete(_ location: Location) {
        guard let index = locations.firstIndex(of: location) else { return }
        locations.remove(at: index)
        
        guard let last = locations.last else { return }
        selectedLocations = [last]
    }
}

#Preview {
    ContentView()
}
