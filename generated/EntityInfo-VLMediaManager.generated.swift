// Generated using the ObjectBox Swift Generator — https://objectbox.io
// DO NOT EDIT

// swiftlint:disable all
import ObjectBox

// MARK: - Entity metadata

extension MediaDA: ObjectBox.Entity {}
extension MediaFragmentDA: ObjectBox.Entity {}

extension MediaDA: ObjectBox.__EntityRelatable {
    internal typealias EntityType = MediaDA

    internal var _id: EntityId<MediaDA> {
        return EntityId<MediaDA>(self.id.value)
    }
}

extension MediaDA: ObjectBox.EntityInspectable {
    internal typealias EntityBindingType = MediaDABinding

    /// Generated metadata used by ObjectBox to persist the entity.
    internal static var entityInfo = ObjectBox.EntityInfo(name: "MediaDA", id: 1)

    internal static var entityBinding = EntityBindingType()

    fileprivate static func buildEntity(modelBuilder: ObjectBox.ModelBuilder) throws {
        let entityBuilder = try modelBuilder.entityBuilder(for: MediaDA.self, id: 1, uid: 7826054475424209664)
        try entityBuilder.addProperty(name: "id", type: Id.entityPropertyType, flags: [.id], id: 1, uid: 3520603377194098432)
        try entityBuilder.addProperty(name: "key", type: String.entityPropertyType, flags: [.unique, .indexHash, .indexed], id: 2, uid: 6893814764350747904, indexId: 1, indexUid: 9139549465360927488)
        try entityBuilder.addProperty(name: "createdOn", type: Date.entityPropertyType, flags: [.indexed], id: 3, uid: 7389989532419029248, indexId: 2, indexUid: 4684201273414627072)
        try entityBuilder.addProperty(name: "mimeType", type: String.entityPropertyType, id: 4, uid: 4764741986985696000)
        try entityBuilder.addProperty(name: "contentLength", type: Int64.entityPropertyType, id: 5, uid: 7503526539917484800)

        try entityBuilder.lastProperty(id: 5, uid: 7503526539917484800)
    }
}

extension MediaDA {
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { MediaDA.id == myId }
    internal static var id: Property<MediaDA, Id, Id> { return Property<MediaDA, Id, Id>(propertyId: 1, isPrimaryKey: true) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { MediaDA.key.startsWith("X") }
    internal static var key: Property<MediaDA, String, Void> { return Property<MediaDA, String, Void>(propertyId: 2, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { MediaDA.createdOn > 1234 }
    internal static var createdOn: Property<MediaDA, Date, Void> { return Property<MediaDA, Date, Void>(propertyId: 3, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { MediaDA.mimeType.startsWith("X") }
    internal static var mimeType: Property<MediaDA, String?, Void> { return Property<MediaDA, String?, Void>(propertyId: 4, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { MediaDA.contentLength > 1234 }
    internal static var contentLength: Property<MediaDA, Int64?, Void> { return Property<MediaDA, Int64?, Void>(propertyId: 5, isPrimaryKey: false) }
    /// Use `MediaDA.fragments` to refer to this ToMany relation property in queries,
    /// like when using `QueryBuilder.and(property:, conditions:)`.

    internal static var fragments: ToManyProperty<MediaFragmentDA> { return ToManyProperty(.valuePropertyId(5)) }


    fileprivate func __setId(identifier: ObjectBox.Id) {
        self.id = Id(identifier)
    }
}

extension ObjectBox.Property where E == MediaDA {
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .id == myId }

    internal static var id: Property<MediaDA, Id, Id> { return Property<MediaDA, Id, Id>(propertyId: 1, isPrimaryKey: true) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .key.startsWith("X") }

    internal static var key: Property<MediaDA, String, Void> { return Property<MediaDA, String, Void>(propertyId: 2, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .createdOn > 1234 }

    internal static var createdOn: Property<MediaDA, Date, Void> { return Property<MediaDA, Date, Void>(propertyId: 3, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .mimeType.startsWith("X") }

    internal static var mimeType: Property<MediaDA, String?, Void> { return Property<MediaDA, String?, Void>(propertyId: 4, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .contentLength > 1234 }

    internal static var contentLength: Property<MediaDA, Int64?, Void> { return Property<MediaDA, Int64?, Void>(propertyId: 5, isPrimaryKey: false) }

    /// Use `.fragments` to refer to this ToMany relation property in queries, like when using
    /// `QueryBuilder.and(property:, conditions:)`.

    internal static var fragments: ToManyProperty<MediaFragmentDA> { return ToManyProperty(.valuePropertyId(5)) }

}


/// Generated service type to handle persisting and reading entity data. Exposed through `MediaDA.EntityBindingType`.
internal class MediaDABinding: NSObject, ObjectBox.EntityBinding {
    internal typealias EntityType = MediaDA
    internal typealias IdType = Id

    override internal required init() {}

    internal func setEntityIdUnlessStruct(of entity: EntityType, to entityId: ObjectBox.Id) {
        entity.__setId(identifier: entityId)
    }

    internal func entityId(of entity: EntityType) -> ObjectBox.Id {
        return entity.id.value
    }

    internal func collect(fromEntity entity: EntityType, id: ObjectBox.Id,
                                  propertyCollector: ObjectBox.FlatBufferBuilder, store: ObjectBox.Store) {
        let propertyOffset_key = propertyCollector.prepare(string: entity.key)
        let propertyOffset_mimeType = propertyCollector.prepare(string: entity.mimeType)

        propertyCollector.collect(id, at: 2 + 2 * 1)
        propertyCollector.collect(entity.createdOn, at: 2 + 2 * 3)
        propertyCollector.collect(entity.contentLength, at: 2 + 2 * 5)
        propertyCollector.collect(dataOffset: propertyOffset_key, at: 2 + 2 * 2)
        propertyCollector.collect(dataOffset: propertyOffset_mimeType, at: 2 + 2 * 4)
    }

    internal func postPut(fromEntity entity: EntityType, id: ObjectBox.Id, store: ObjectBox.Store) {
        if entityId(of: entity) == 0 { // Written for first time? Attach ToMany relations:
            let fragments = ToMany<MediaFragmentDA>.backlink(
                sourceBox: store.box(for: ToMany<MediaFragmentDA>.ReferencedType.self),
                sourceProperty: ToMany<MediaFragmentDA>.ReferencedType.media,
                targetId: EntityId<MediaDA>(id.value))
            if !entity.fragments.isEmpty {
                fragments.replace(entity.fragments)
            }
            entity.fragments = fragments
        }
    }
    internal func createEntity(entityReader: ObjectBox.FlatBufferReader, store: ObjectBox.Store) -> EntityType {
        let entity = MediaDA()

        entity.id = entityReader.read(at: 2 + 2 * 1)
        entity.key = entityReader.read(at: 2 + 2 * 2)
        entity.createdOn = entityReader.read(at: 2 + 2 * 3)
        entity.mimeType = entityReader.read(at: 2 + 2 * 4)
        entity.contentLength = entityReader.read(at: 2 + 2 * 5)

        entity.fragments = ToMany<MediaFragmentDA>.backlink(
            sourceBox: store.box(for: ToMany<MediaFragmentDA>.ReferencedType.self),
            sourceProperty: ToMany<MediaFragmentDA>.ReferencedType.media,
            targetId: EntityId<MediaDA>(entity.id.value))
        return entity
    }
}



extension MediaFragmentDA: ObjectBox.__EntityRelatable {
    internal typealias EntityType = MediaFragmentDA

    internal var _id: EntityId<MediaFragmentDA> {
        return EntityId<MediaFragmentDA>(self.id.value)
    }
}

extension MediaFragmentDA: ObjectBox.EntityInspectable {
    internal typealias EntityBindingType = MediaFragmentDABinding

    /// Generated metadata used by ObjectBox to persist the entity.
    internal static var entityInfo = ObjectBox.EntityInfo(name: "MediaFragmentDA", id: 2)

    internal static var entityBinding = EntityBindingType()

    fileprivate static func buildEntity(modelBuilder: ObjectBox.ModelBuilder) throws {
        let entityBuilder = try modelBuilder.entityBuilder(for: MediaFragmentDA.self, id: 2, uid: 6139257205694976256)
        try entityBuilder.addProperty(name: "id", type: Id.entityPropertyType, flags: [.id], id: 1, uid: 1093001210366535424)
        try entityBuilder.addProperty(name: "offset", type: Int64.entityPropertyType, id: 2, uid: 4261947604798316032)
        try entityBuilder.addProperty(name: "length", type: Int64.entityPropertyType, id: 3, uid: 6586608680499776000)
        try entityBuilder.addProperty(name: "key", type: String.entityPropertyType, flags: [.indexHash, .indexed], id: 4, uid: 8967039625388311040, indexId: 3, indexUid: 8275585268177615616)
        try entityBuilder.addToOneRelation(name: "media", targetEntityInfo: ToOne<MediaDA>.Target.entityInfo, id: 5, uid: 6411480790926746368, indexId: 4, indexUid: 2916857931339252992)

        try entityBuilder.lastProperty(id: 5, uid: 6411480790926746368)
    }
}

extension MediaFragmentDA {
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { MediaFragmentDA.id == myId }
    internal static var id: Property<MediaFragmentDA, Id, Id> { return Property<MediaFragmentDA, Id, Id>(propertyId: 1, isPrimaryKey: true) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { MediaFragmentDA.offset > 1234 }
    internal static var offset: Property<MediaFragmentDA, Int64, Void> { return Property<MediaFragmentDA, Int64, Void>(propertyId: 2, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { MediaFragmentDA.length > 1234 }
    internal static var length: Property<MediaFragmentDA, Int64, Void> { return Property<MediaFragmentDA, Int64, Void>(propertyId: 3, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { MediaFragmentDA.key.startsWith("X") }
    internal static var key: Property<MediaFragmentDA, String, Void> { return Property<MediaFragmentDA, String, Void>(propertyId: 4, isPrimaryKey: false) }
    internal static var media: Property<MediaFragmentDA, EntityId<ToOne<MediaDA>.Target>, ToOne<MediaDA>.Target> { return Property(propertyId: 5) }


    fileprivate func __setId(identifier: ObjectBox.Id) {
        self.id = Id(identifier)
    }
}

extension ObjectBox.Property where E == MediaFragmentDA {
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .id == myId }

    internal static var id: Property<MediaFragmentDA, Id, Id> { return Property<MediaFragmentDA, Id, Id>(propertyId: 1, isPrimaryKey: true) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .offset > 1234 }

    internal static var offset: Property<MediaFragmentDA, Int64, Void> { return Property<MediaFragmentDA, Int64, Void>(propertyId: 2, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .length > 1234 }

    internal static var length: Property<MediaFragmentDA, Int64, Void> { return Property<MediaFragmentDA, Int64, Void>(propertyId: 3, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .key.startsWith("X") }

    internal static var key: Property<MediaFragmentDA, String, Void> { return Property<MediaFragmentDA, String, Void>(propertyId: 4, isPrimaryKey: false) }

    internal static var media: Property<MediaFragmentDA, ToOne<MediaDA>.Target.EntityBindingType.IdType, ToOne<MediaDA>.Target> { return Property<MediaFragmentDA, ToOne<MediaDA>.Target.EntityBindingType.IdType, ToOne<MediaDA>.Target>(propertyId: 5) }

}


/// Generated service type to handle persisting and reading entity data. Exposed through `MediaFragmentDA.EntityBindingType`.
internal class MediaFragmentDABinding: NSObject, ObjectBox.EntityBinding {
    internal typealias EntityType = MediaFragmentDA
    internal typealias IdType = Id

    override internal required init() {}

    internal func setEntityIdUnlessStruct(of entity: EntityType, to entityId: ObjectBox.Id) {
        entity.__setId(identifier: entityId)
    }

    internal func entityId(of entity: EntityType) -> ObjectBox.Id {
        return entity.id.value
    }

    internal func collect(fromEntity entity: EntityType, id: ObjectBox.Id,
                                  propertyCollector: ObjectBox.FlatBufferBuilder, store: ObjectBox.Store) {
        let propertyOffset_key = propertyCollector.prepare(string: entity.key)

        propertyCollector.collect(id, at: 2 + 2 * 1)
        propertyCollector.collect(entity.offset, at: 2 + 2 * 2)
        propertyCollector.collect(entity.length, at: 2 + 2 * 3)
        propertyCollector.collect(entity.media, at: 2 + 2 * 5, store: store)
        propertyCollector.collect(dataOffset: propertyOffset_key, at: 2 + 2 * 4)
    }

    internal func postPut(fromEntity entity: EntityType, id: ObjectBox.Id, store: ObjectBox.Store) {
        if entityId(of: entity) == 0 { // Written for first time? Attach ToMany relations:
            entity.media.attach(to: store.box(for: MediaDA.self))
        }
    }
    internal func setToOneRelation(_ propertyId: obx_schema_id, of entity: EntityType, to entityId: ObjectBox.Id?) {
        switch propertyId {
            case 5:
                entity.media.targetId = (entityId != nil) ? EntityId<MediaDA>(entityId!) : nil
            default:
                fatalError("Attempt to change nonexistent ToOne relation with ID \(propertyId)")
        }
    }
    internal func createEntity(entityReader: ObjectBox.FlatBufferReader, store: ObjectBox.Store) -> EntityType {
        let entity = MediaFragmentDA()

        entity.id = entityReader.read(at: 2 + 2 * 1)
        entity.offset = entityReader.read(at: 2 + 2 * 2)
        entity.length = entityReader.read(at: 2 + 2 * 3)
        entity.key = entityReader.read(at: 2 + 2 * 4)

        entity.media = entityReader.read(at: 2 + 2 * 5, store: store)
        return entity
    }
}


/// Helper function that allows calling Enum(rawValue: value) with a nil value, which will return nil.
fileprivate func optConstruct<T: RawRepresentable>(_ type: T.Type, rawValue: T.RawValue?) -> T? {
    guard let rawValue = rawValue else { return nil }
    return T(rawValue: rawValue)
}

// MARK: - Store setup

fileprivate func cModel() throws -> OpaquePointer {
    let modelBuilder = try ObjectBox.ModelBuilder()
    try MediaDA.buildEntity(modelBuilder: modelBuilder)
    try MediaFragmentDA.buildEntity(modelBuilder: modelBuilder)
    modelBuilder.lastEntity(id: 2, uid: 6139257205694976256)
    modelBuilder.lastIndex(id: 4, uid: 2916857931339252992)
    return modelBuilder.finish()
}

extension ObjectBox.Store {
    /// A store with a fully configured model. Created by the code generator with your model's metadata in place.
    ///
    /// - Parameters:
    ///   - directoryPath: Directory path to store database files in.
    ///   - maxDbSizeInKByte: Limit of on-disk space for the database files. Default is `1024 * 1024` (1 GiB).
    ///   - fileMode: UNIX-style bit mask used for the database files; default is `0o755`.
    ///   - maxReaders: Maximum amount of concurrent readers, tailored to your use case. Default is `0` (unlimited).
    internal convenience init(directoryPath: String, maxDbSizeInKByte: UInt64 = 1024 * 1024, fileMode: UInt32 = 0o755, maxReaders: UInt32 = 0) throws {
        try self.init(
            model: try cModel(),
            directory: directoryPath,
            maxDbSizeInKByte: maxDbSizeInKByte,
            fileMode: fileMode,
            maxReaders: maxReaders)
    }
}

// swiftlint:enable all
