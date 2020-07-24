import Foundation
import ACMediaManager

class OnlineBlob: Decodable{
    var id: String?
    var contentType: String?
    var height: Float?
    var width: Float?
    var subBlobs: [OnlineBlob]?

    init() {}

    func isPortrait () -> Bool {
        guard  let width = self.width, let height = self.height else {
            return false
        }
        return height > width
    }
}

extension OnlineBlob: Equatable {
    static public func ==(rhs: OnlineBlob, lhs: OnlineBlob) -> Bool {
        return rhs.id == lhs.id
    }
}

extension OnlineBlob {
    public func isVideo () ->Bool {
        return contentType?.starts(with: "video") ?? false
    }
    public func getVideoBlob()-> OnlineBlob? {
        if (isVideo()){
            return self
        }
        return nil
    }

    public func getImageBlob()-> OnlineBlob?{
        if (isVideo()){
            return subBlobs?.first(where: { (blob) -> Bool in
                (blob.contentType?.starts(with: "image") ?? false)
            })
        }
        else{
            return self
        }
    }
    public func getVideoUrl()-> URL? {
        let blobId = self.getVideoBlob()?.id

        guard
            blobId != nil,
            let urlString = BlobUtils.blobUrl(blobId: blobId),
            let url = URL(string: urlString)
            else { return nil}

        return url
    }
    public func getImageUrl()-> URL?{
        let blob = self.getImageBlob()

        guard let blobId = blob?.id,
            let urlString = BlobUtils.blobUrl(blobId: blobId),
            let url = URL(string: urlString)
            else { return nil}
        return url
    }
    
    public func toNormalBlob() -> Blob{
        return Blob(id: self.id!, contentType: self.contentType!, url: self.getVideoUrl()!)
    }
}
