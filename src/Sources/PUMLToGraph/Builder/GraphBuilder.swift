/// Graph Builder
///
/// Builds MultiDiGraph from parsed PUML data.
/// This implementation corresponds to the Python GraphBuilder class in graph_builder.py
///
/// Example usage:
///     let builder = GraphBuilder()
///     let graph = builder.buildGraph(parsedData: parsedData)

import Foundation

/// Builds NetworkX-style graph from parsed PUML data
public class GraphBuilder {
    /// The graph being built
    private var graph: MultiDiGraph
    
    /// Semantic description generator
    private let semanticGenerator: SemanticGenerator
    
    public init() {
        self.graph = MultiDiGraph()
        self.semanticGenerator = SemanticGenerator()
    }
    
    // MARK: - Main Build Method
    
    /// Build MultiDiGraph from parsed data
    ///
    /// Args:
    ///     parsedData: ParsedData structure from PUMLParser
    ///
    /// Returns:
    ///     MultiDiGraph with all nodes and edges
    ///
    /// Example:
    ///     let graph = builder.buildGraph(parsedData: parsedData)
    ///     print("Graph has \(graph.numberOfNodes()) nodes")
    public func buildGraph(parsedData: ParsedData) -> MultiDiGraph {
        // Reset graph
        graph = MultiDiGraph()
        
        // Step 1: Add all class/enum nodes
        for (_, classData) in parsedData.classes {
            addClassNode(classData: classData)
        }
        
        // Step 2: Add attribute and operation nodes
        for (_, classData) in parsedData.classes {
            for attr in classData.attributes {
                addAttributeNode(attr: attr, owner: classData.name)
            }
            for op in classData.operations {
                addOperationNode(op: op, owner: classData.name)
            }
            for lit in classData.enumLiterals {
                addEnumLiteralNode(lit: lit, enumName: classData.name)
            }
        }
        
        // Step 3: Add association edges
        for assoc in parsedData.associations {
            addAssociationEdges(assoc: assoc)
        }
        
        // Step 4: Add generalization edges
        for gen in parsedData.generalizations {
            addGeneralizationEdge(gen: gen)
        }
        
        // Step 5: Add realization edges
        for real in parsedData.realizations {
            addRealizationEdge(real: real)
        }
        
        // Step 6: Handle association classes
        for assocClass in parsedData.associationClasses {
            addAssociationClass(assocClass: assocClass)
        }
        
        // Step 7: Update normalized text for all classes
        updateNormalizedText()
        
        return graph
    }
    
    // MARK: - Add Class Node
    
    /// Add a class/enum/interface node
    ///
    /// Args:
    ///     classData: ParsedClass structure
    private func addClassNode(classData: ParsedClass) {
        let nodeId = classData.name
        
        // Generate semantic description
        let semanticDesc = semanticGenerator.generateClassDesc(classData: classData)
        
        // Use typed model based on class type
        if classData.type == "Enumeration" {
            let enumNode = EnumerationNodeData(
                id: nodeId,
                name: classData.name,
                stereotypes: classData.stereotypes,
                semanticDesc: semanticDesc
            )
            graph.addNode(nodeId, attributes: enumNode.toDictionary())
        } else {
            let classNode = ClassNodeData(
                id: nodeId,
                name: classData.name,
                isAbstract: classData.isAbstract,
                isInterface: classData.isInterface,
                stereotypes: classData.stereotypes,
                semanticDesc: semanticDesc
            )
            graph.addNode(nodeId, attributes: classNode.toDictionary())
        }
    }
    
    // MARK: - Add Attribute Node
    
    /// Add an attribute node and OWNS_ATTR edge
    ///
    /// Args:
    ///     attr: ParsedAttribute structure
    ///     owner: Name of the owning class
    private func addAttributeNode(attr: ParsedAttribute, owner: String) {
        let attrId = attr.id
        
        // Generate semantic description
        let semanticDesc = semanticGenerator.generateAttributeDesc(attr: attr, context: owner)
        
        // Create typed attribute node
        let attrNode = AttributeNodeData(
            id: attrId,
            name: attr.name,
            attrType: attr.type,
            visibility: attr.visibility,
            isDerived: attr.isDerived,
            owner: owner,
            properties: attr.properties,
            semanticDesc: semanticDesc
        )
        graph.addNode(attrId, attributes: attrNode.toDictionary())
        
        // Add OWNS_ATTR edge: Class → Attribute using typed edge
        let ownsAttrEdge = OwnsAttrEdge()
        graph.addEdge(from: owner, to: attrId, attributes: ownsAttrEdge.toDictionary())
        
        // Add HAS_TYPE edge if attribute type is a Class or Enumeration in the graph
        if let attrType = attr.type, graph.hasNode(attrType) {
            if let typeNode = graph.getNode(attrType),
               let nodeType = typeNode.attributes["type"] as? String,
               nodeType == "Class" || nodeType == "Enumeration" {
                let hasTypeEdge = HasTypeEdge()
                graph.addEdge(from: attrId, to: attrType, attributes: hasTypeEdge.toDictionary())
            }
        }
    }
    
    // MARK: - Add Operation Node
    
    /// Add an operation node and OWNS_OP edge
    ///
    /// Args:
    ///     op: ParsedOperation structure
    ///     owner: Name of the owning class
    private func addOperationNode(op: ParsedOperation, owner: String) {
        let opId = op.id
        
        // Generate semantic description
        let semanticDesc = semanticGenerator.generateOperationDesc(op: op, context: owner)
        
        // Convert ParsedParameter to OperationParameter
        let params = op.params.map { OperationParameter(name: $0.name, type: $0.type) }
        
        // Create typed operation node
        let opNode = OperationNodeData(
            id: opId,
            name: op.name,
            params: params,
            returnType: op.returnType,
            visibility: op.visibility,
            isDerived: op.isDerived,
            owner: owner,
            semanticDesc: semanticDesc
        )
        graph.addNode(opId, attributes: opNode.toDictionary())
        
        // Add OWNS_OP edge: Class → Operation using typed edge
        let ownsOpEdge = OwnsOpEdge()
        graph.addEdge(from: owner, to: opId, attributes: ownsOpEdge.toDictionary())
    }
    
    // MARK: - Add Enum Literal Node
    
    /// Add an enum literal node and HAS_LITERAL edge
    ///
    /// Args:
    ///     lit: ParsedEnumLiteral structure
    ///     enumName: Name of the parent enumeration
    private func addEnumLiteralNode(lit: ParsedEnumLiteral, enumName: String) {
        let litId = lit.id
        
        // Create typed enum literal node
        let litNode = EnumLiteralNodeData(id: litId, name: lit.name, enumName: enumName)
        graph.addNode(litId, attributes: litNode.toDictionary())
        
        // Add HAS_LITERAL edge: Enumeration → EnumLiteral using typed edge
        let hasLiteralEdge = HasLiteralEdge()
        graph.addEdge(from: enumName, to: litId, attributes: hasLiteralEdge.toDictionary())
    }
    
    // MARK: - Add Association Edges
    
    /// Add association edge(s) based on navigability
    ///
    /// Args:
    ///     assoc: ParsedAssociation structure
    private func addAssociationEdges(assoc: ParsedAssociation) {
        let classA = assoc.classA
        let classB = assoc.classB
        let edgeId = assoc.id
        let navigability = assoc.navigability
        
        // Parse aggregation kind
        let aggKind = AggregationKind(rawValue: assoc.aggKind) ?? .none
        
        if navigability == "bi" {
            // Bidirectional: Create two edges
            
            // Forward direction: A → B
            let semanticDescFwd = semanticGenerator.generateAssociationDesc(
                assoc: assoc,
                source: classA,
                target: classB,
                roleName: assoc.roleA,
                multiplicity: assoc.multB,
                isReverse: false
            )
            
            let assocEdgeFwd = AssociationEdge(
                id: edgeId,
                aggKind: aggKind,
                navigability: .bidirectional,
                roleSrc: assoc.roleA,
                multSrc: assoc.multA,
                roleDst: assoc.roleB,
                multDst: assoc.multB,
                label: assoc.label,
                semanticDesc: semanticDescFwd
            )
            
            // Reverse direction: B → A
            let semanticDescRev = semanticGenerator.generateAssociationDesc(
                assoc: assoc,
                source: classB,
                target: classA,
                roleName: assoc.roleB,
                multiplicity: assoc.multA,
                isReverse: true
            )
            
            let assocEdgeRev = AssociationEdge(
                id: edgeId,
                aggKind: aggKind,
                navigability: .bidirectional,
                roleSrc: assoc.roleB,
                multSrc: assoc.multB,
                roleDst: assoc.roleA,
                multDst: assoc.multA,
                label: assoc.label,
                semanticDesc: semanticDescRev
            )
            
            // Handle self-referential edges with different keys
            if classA == classB {
                graph.addEdge(from: classA, to: classB, key: "\(edgeId)_fwd", attributes: assocEdgeFwd.toDictionary())
                graph.addEdge(from: classB, to: classA, key: "\(edgeId)_rev", attributes: assocEdgeRev.toDictionary())
            } else {
                graph.addEdge(from: classA, to: classB, key: edgeId, attributes: assocEdgeFwd.toDictionary())
                graph.addEdge(from: classB, to: classA, key: edgeId, attributes: assocEdgeRev.toDictionary())
            }
            
        } else if navigability == "src→dst" {
            // Source to destination: A → B
            let semanticDesc = semanticGenerator.generateAssociationDesc(
                assoc: assoc,
                source: classA,
                target: classB,
                roleName: assoc.roleA,
                multiplicity: assoc.multB,
                isReverse: false
            )
            
            let assocEdge = AssociationEdge(
                id: edgeId,
                aggKind: aggKind,
                navigability: .sourceToDestination,
                roleSrc: assoc.roleA,
                multSrc: assoc.multA,
                roleDst: assoc.roleB,
                multDst: assoc.multB,
                label: assoc.label,
                semanticDesc: semanticDesc
            )
            
            graph.addEdge(from: classA, to: classB, key: edgeId, attributes: assocEdge.toDictionary())
            
        } else if navigability == "dst→src" {
            // Destination to source: B → A
            let semanticDesc = semanticGenerator.generateAssociationDesc(
                assoc: assoc,
                source: classB,
                target: classA,
                roleName: assoc.roleB,
                multiplicity: assoc.multA,
                isReverse: true
            )
            
            let assocEdge = AssociationEdge(
                id: edgeId,
                aggKind: aggKind,
                navigability: .destinationToSource,
                roleSrc: assoc.roleB,
                multSrc: assoc.multB,
                roleDst: assoc.roleA,
                multDst: assoc.multA,
                label: assoc.label,
                semanticDesc: semanticDesc
            )
            
            graph.addEdge(from: classB, to: classA, key: edgeId, attributes: assocEdge.toDictionary())
        }
    }
    
    // MARK: - Add Generalization Edge
    
    /// Add GENERALIZES edge (child → parent)
    ///
    /// Args:
    ///     gen: ParsedGeneralization structure
    private func addGeneralizationEdge(gen: ParsedGeneralization) {
        let child = gen.child
        let parent = gen.parent
        
        // Generate semantic description
        let semanticDesc = semanticGenerator.generateGeneralizationDesc(child: child, parent: parent)
        
        // Create typed generalization edge
        let genEdge = GeneralizationEdge(semanticDesc: semanticDesc)
        
        // Add edge from child to parent
        graph.addEdge(from: child, to: parent, attributes: genEdge.toDictionary())
    }
    
    // MARK: - Add Realization Edge
    
    /// Add REALIZES edge (class → interface)
    ///
    /// Args:
    ///     real: ParsedRealization structure
    private func addRealizationEdge(real: ParsedRealization) {
        let className = real.className
        let interfaceName = real.interfaceName
        
        // Create typed realization edge
        let realEdge = RealizationEdge()
        
        // Add edge from class to interface
        graph.addEdge(from: className, to: interfaceName, attributes: realEdge.toDictionary())
    }
    
    // MARK: - Add Association Class
    
    /// Handle association class notation
    ///
    /// Args:
    ///     assocClass: ParsedAssociationClass structure
    private func addAssociationClass(assocClass: ParsedAssociationClass) {
        let classA = assocClass.classA
        let classB = assocClass.classB
        let assocClassName = assocClass.assocClass
        
        // Mark the class as AssociationClass if it exists
        if let node = graph.getNode(assocClassName) {
            // Extract existing properties to create AssociationClassNodeData
            let semanticDesc = node.attributes["semantic_desc"] as? String ?? ""
            let stereotypes = node.attributes["stereotypes"] as? [String] ?? []
            let isAbstract = node.attributes["isAbstract"] as? Bool ?? false
            let isInterface = node.attributes["isInterface"] as? Bool ?? false
            
            // Create typed AssociationClassNodeData
            let assocClassNode = AssociationClassNodeData(
                id: assocClassName,
                name: assocClassName,
                associationBetween: [classA, classB],
                isAbstract: isAbstract,
                isInterface: isInterface,
                stereotypes: stereotypes,
                semanticDesc: semanticDesc
            )
            
            // Update node with typed data
            graph.addNode(assocClassName, attributes: assocClassNode.toDictionary())
        }
        
        // Create bidirectional associations using typed AssociationEdge
        // A <-> AssociationClass
        let edgeIdA = "e\(graph.numberOfEdges())"
        
        // Mock association for semantic generation
        let mockAssocA = ParsedAssociation(
            id: edgeIdA,
            classA: classA,
            classB: assocClassName,
            aggKind: "none"
        )
        
        let descAFwd = semanticGenerator.generateAssociationDesc(
            assoc: mockAssocA,
            source: classA,
            target: assocClassName,
            roleName: nil,
            multiplicity: "0..*",
            isReverse: false
        )
        
        let descARev = semanticGenerator.generateAssociationDesc(
            assoc: mockAssocA,
            source: assocClassName,
            target: classA,
            roleName: nil,
            multiplicity: "0..*",
            isReverse: true
        )
        
        // Create typed edges for A <-> AssociationClass
        let assocEdgeAFwd = AssociationEdge(
            id: edgeIdA,
            aggKind: .none,
            navigability: .bidirectional,
            multSrc: "0..*",
            multDst: "0..*",
            semanticDesc: descAFwd
        )
        
        let assocEdgeARev = AssociationEdge(
            id: edgeIdA,
            aggKind: .none,
            navigability: .bidirectional,
            multSrc: "0..*",
            multDst: "0..*",
            semanticDesc: descARev
        )
        
        graph.addEdge(from: classA, to: assocClassName, key: edgeIdA, attributes: assocEdgeAFwd.toDictionary())
        graph.addEdge(from: assocClassName, to: classA, key: edgeIdA, attributes: assocEdgeARev.toDictionary())
        
        // B <-> AssociationClass
        let edgeIdB = "e\(graph.numberOfEdges())"
        
        let mockAssocB = ParsedAssociation(
            id: edgeIdB,
            classA: classB,
            classB: assocClassName,
            aggKind: "none"
        )
        
        let descBFwd = semanticGenerator.generateAssociationDesc(
            assoc: mockAssocB,
            source: classB,
            target: assocClassName,
            roleName: nil,
            multiplicity: "0..*",
            isReverse: false
        )
        
        let descBRev = semanticGenerator.generateAssociationDesc(
            assoc: mockAssocB,
            source: assocClassName,
            target: classB,
            roleName: nil,
            multiplicity: "0..*",
            isReverse: true
        )
        
        // Create typed edges for B <-> AssociationClass
        let assocEdgeBFwd = AssociationEdge(
            id: edgeIdB,
            aggKind: .none,
            navigability: .bidirectional,
            multSrc: "0..*",
            multDst: "0..*",
            semanticDesc: descBFwd
        )
        
        let assocEdgeBRev = AssociationEdge(
            id: edgeIdB,
            aggKind: .none,
            navigability: .bidirectional,
            multSrc: "0..*",
            multDst: "0..*",
            semanticDesc: descBRev
        )
        
        graph.addEdge(from: classB, to: assocClassName, key: edgeIdB, attributes: assocEdgeBFwd.toDictionary())
        graph.addEdge(from: assocClassName, to: classB, key: edgeIdB, attributes: assocEdgeBRev.toDictionary())
    }
    
    // MARK: - Update Normalized Text
    
    /// Update normalized text for all class nodes after all edges are added
    ///
    /// This method computes the normalized_text array for each class node,
    /// containing separate components for multi-vector embedding:
    /// - Component 1: Core identity (from semantic_desc)
    /// - Component 2: Subtypes sentence (if any children exist)
    /// - Component 3+: Each outgoing association's semantic_desc
    private func updateNormalizedText() {
        // Get all Class and Enumeration nodes
        let classNodes = graph.getNodesByType("Class") + graph.getNodesByType("Enumeration") + graph.getNodesByType("AssociationClass")
        
        for classNode in classNodes {
            let nodeId = classNode.id
            var components: [String] = []
            
            // Component 1: Core identity from semantic_desc
            if let semanticDesc = classNode.attributes["semantic_desc"] as? String {
                // Remove trailing period for consistency
                let coreIdentity = semanticDesc.hasSuffix(".") 
                    ? String(semanticDesc.dropLast()) 
                    : semanticDesc
                components.append(coreIdentity)
            }
            
            // Component 2: Subtypes (children that generalize to this class)
            // These are incoming GENERALIZES edges where this class is the parent (destination)
            let incomingEdges = graph.getIncomingEdges(to: nodeId)
            var subtypes: [String] = []
            
            for edge in incomingEdges {
                if let edgeType = edge.attributes["type"] as? String,
                   edgeType == EdgeType.generalizes.rawValue {
                    // The source of a GENERALIZES edge is the child (subtype)
                    let childName = SemanticGenerator.splitIdentifier(edge.source)
                    subtypes.append(childName)
                }
            }
            
            if !subtypes.isEmpty {
                let className = SemanticGenerator.splitIdentifier(nodeId)
                let subtypesComponent = "Class \(className) has subtypes: \(subtypes.joined(separator: ", "))"
                components.append(subtypesComponent)
            }
            
            // Component 3+: Each outgoing association's semantic_desc
            let outgoingEdges = graph.getOutgoingEdges(from: nodeId)
            
            for edge in outgoingEdges {
                if let edgeType = edge.attributes["type"] as? String,
                   edgeType == EdgeType.assoc.rawValue {
                    if let assocSemanticDesc = edge.attributes["semantic_desc"] as? String {
                        // Remove trailing period for consistency
                        let assocComponent = assocSemanticDesc.hasSuffix(".")
                            ? String(assocSemanticDesc.dropLast())
                            : assocSemanticDesc
                        components.append(assocComponent)
                    }
                }
            }
            
            // Update the node with normalized_text
            var updatedAttrs = classNode.attributes
            updatedAttrs["normalized_text"] = components
            graph.addNode(nodeId, attributes: updatedAttrs)
        }
    }
}
