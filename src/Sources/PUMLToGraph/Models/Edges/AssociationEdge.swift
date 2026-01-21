//
//  AssociationEdge.swift
//  ThesisCLI
//
//  Created by Le Anh on 21/1/26.
//

/// Association edge: Class -> Class with roles, multiplicities, and aggregation
///
/// Example:
///     let assoc = AssociationEdge(
///         id: "e0",
///         aggKind: .none,
///         navigability: .bidirectional,
///         roleSrc: "origin",
///         multSrc: "1..1",
///         roleDst: "departingFlights",
///         multDst: "0..*",
///         label: nil,
///         semanticDesc: "Class airport is associated with..."
///     )
public struct AssociationEdge: EdgeData {
    /// Unique edge identifier (allows multiple associations between same classes)
    public let id: String
    
    /// Aggregation kind (none, shared, composite)
    public var aggKind: AggregationKind
    
    /// Navigability direction
    public var navigability: Navigability
    
    /// Role name at source end
    public var roleSrc: String?
    
    /// Multiplicity at source end (e.g., "1..1", "0..*")
    public var multSrc: String
    
    /// Role name at destination end
    public var roleDst: String?
    
    /// Multiplicity at destination end
    public var multDst: String
    
    /// Optional label for the association
    public var label: String?
    
    /// Semantic description for S-BERT
    public var semanticDesc: String
    
    public var edgeType: EdgeType {
        return .assoc
    }
    
    public init(id: String, aggKind: AggregationKind = .none, navigability: Navigability = .bidirectional, roleSrc: String? = nil, multSrc: String = "0..*", roleDst: String? = nil, multDst: String = "0..*", label: String? = nil, semanticDesc: String = "") {
        self.id = id
        self.aggKind = aggKind
        self.navigability = navigability
        self.roleSrc = roleSrc
        self.multSrc = multSrc
        self.roleDst = roleDst
        self.multDst = multDst
        self.label = label
        self.semanticDesc = semanticDesc
    }
    
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "type": edgeType.rawValue,
            "id": id,
            "aggKind": aggKind.rawValue,
            "navigability": navigability.rawValue,
            "multSrc": multSrc,
            "multDst": multDst,
            "semantic_desc": semanticDesc
        ]
        
        if let roleSrc = roleSrc {
            dict["roleSrc"] = roleSrc
        }
        if let roleDst = roleDst {
            dict["roleDst"] = roleDst
        }
        if let label = label {
            dict["label"] = label
        }
        
        return dict
    }
}
