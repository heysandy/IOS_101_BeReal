import Foundation
import ParseSwift

struct Post: ParseObject {

    // MARK: ParseObject required
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    // MARK: Custom properties
    var caption: String?
    var user: User?
    var imageFile: ParseFile?
    var location: ParseGeoPoint?
    var locationName: String?
}
