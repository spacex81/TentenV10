////
////  ExploreGridView.swift
////  TentenV10
////
////  Created by 조윤근 on 12/5/24.
////
//
import SwiftUI
//
//struct ExploreGridView: View {
//    var images: [ImageResource] = [
//        .user1, .user2, .user3, .user4, .user5, .user6, .user7, .user8, .user9,
//        .user10, .user11, .user12, .user13, .user14, .user15, .user16, .user17, .user18, .user19,
//        .user20, .user21, .user22, .user23, .user24, .user25, .user26, .user27, .user28, .user29,
//        .user30, .user31, .user32, .user33, .user34, .user35, .user36, .user37, .user38, .user39,
//        .user40, .user41, .user42, .user43, .user44, .user45, .user46, .user47, .user48, .user49,
//        .user50, .user51
//    ]
//    
//    @State var show = false
//    @Namespace var namespace {
//        didSet {
//            NSLog("LOG: Namespace: \(namespace)")
//        }
//    }
//    @State var selectedImage: ImageResource? = nil
//    
//    var body: some View {
//        ScrollView {
//            LazyVGrid(columns: Array(repeating: GridItem(), count: 2), content: {
//                VStack {
//                    createGrid(for: images.filter{!isHeavy($0)})
//                    Spacer()
//                }
//                .zIndex(images.contains(where: isHeavy) ? 0 : 1)
//                
//                VStack {
//                    createGrid(for: images.filter{isHeavy($0)})
//                    Spacer()
//                }
//                .zIndex(images.contains(where: isHeavy) ? 1 : 0)
//            })
//        }
//        .safeAreaPadding(.horizontal, 10)
//        .overlay {
//            if show {
//                ImageView(imageN: selectedImage!, show: $show, namespace: namespace)
//            }
//        }
//    }
//    
//    // This create one column
//    func createGrid(for filteredImages: [ImageResource]) -> some View {
//        ForEach(filteredImages, id: \.self) { item in
//            GridRow {
//                Image(item).resizable().scaledToFit()
//                    .clipShape(.rect(cornerRadius: 12))
//                    .matchedGeometryEffect(id: item, in: namespace)
//                    .zIndex(selectedImage == item ? 1 : 0)
//            }
//            .onTapGesture {
//                withAnimation(.spring(duration: 0.5)){
//                    selectedImage = item
//                    show.toggle()
//                }
//            }
//        }
//    }
//    
//    func isHeavy(_ image: ImageResource) -> Bool {
//        if let index = images.firstIndex(of: image) {
//            return index % 2 == 1
//        }
//        
//        return false
//    }
//}
//
//#Preview {
//    ExploreGridView()
//}

struct ExploreGridView: View {
    var images: [ImageResource] = [
        .user1, .user2, .user3, .user4, .user5, .user6, .user7, .user8, .user9,
        .user10, .user11, .user12, .user13, .user14, .user15, .user16, .user17, .user18, .user19,
        .user20, .user21, .user22, .user23, .user24, .user25, .user26, .user27, .user28, .user29,
        .user30, .user31, .user32, .user33, .user34, .user35, .user36, .user37, .user38, .user39,
        .user40, .user41, .user42, .user43, .user44, .user45, .user46, .user47, .user48, .user49,
        .user50, .user51
    ]
    
    @State var show = false
    @Namespace var namespace
    @State var selectedImage: ImageResource? = nil
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(), count: 2), spacing: 10) {
                ForEach(images, id: \.self) { item in
                    Image(item)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        // Only apply matchedGeometryEffect if the image is not selected
                        .matchedGeometryEffect(id: item, in: namespace, isSource: !show || selectedImage != item)
                        .zIndex(selectedImage == item ? 1 : 0)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                selectedImage = item
                                show = true
                            }
                        }
                }
            }
            .padding()
        }
        .overlay {
            if show, let selectedImage {
                ImageView(imageN: selectedImage, show: $show, namespace: namespace)
            }
        }
    }
}
