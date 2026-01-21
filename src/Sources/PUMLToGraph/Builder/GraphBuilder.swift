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
        
        return graph
    }
    
    // MARK: - Add Class Node
    
    /// Add a class/enum/interface node
    ///
    /// Args:
    ///     classData: ParsedClass structure
    private func addClassNode(classData: ParsedClass) {
        let nodeId = classData.name
        let nodeType = classData.type
        
        // Generate semantic description
        let semanticDesc = semanticGenerator.generateClassDesc(classData: classData)
        
        // Create node attributes
        let attributes: [String: Any] = [
            "type": nodeType,
            "name": classData.name,
            "isAbstract": classData.isAbstract,
            "isInterface": classData.isInterface,
            "stereotypes": classData.stereotypes,
            "semantic_desc": semanticDesc
        ]
        
        graph.addNode(nodeId, attributes: attributes)
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
        
        // Create node attributes
        var attributes: [String: Any] = [
            "type": "Attribute",
            "name": attr.name,
            "isDerived": attr.isDerived,
            "owner": owner,
            "semantic_desc": semanticDesc
        ]
        
        if let attrType = attr.type {
            attributes["attrType"] = attrType
        }
        if let visibility = attr.visibility {
            attributes["visibility"] = visibility
        }
        
        // Merge properties
        for (key, value) in attr.properties {
            attributes[key] = value
        }
        
        // Add attribute node
        graph.addNode(attrId, attributes: attributes)
        
        // Add OWNS_ATTR edge: Class → Attribute
        graph.addEdge(from: owner, to: attrId, attributes: ["type": EdgeType.ownsAttr.rawValue])
        
        // Add HAS_TYPE edge if attribute type is a Class or Enumeration in the graph
        if let attrType = attr.type, graph.hasNode(attrType) {
            if let typeNode = graph.getNode(attrType),
               let nodeType = typeNode.attributes["type"] as? String,
               nodeType == "Class" || nodeType == "Enumeration" {
                graph.addEdge(from: attrId, to: attrType, attributes: ["type": EdgeType.hasType.rawValue])
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
        
        // Convert params to dictionary array
        let paramsArray = op.params.map { param -> [String: Any] in
            var dict: [String: Any] = ["name": param.name]
            if let type = param.type {
                dict["type"] = type
            }
            return dict
        }
        
        // Create node attributes
        var attributes: [String: Any] = [
            "type": "Operation",
            "name": op.name,
            "params": paramsArray,
            "isDerived": op.isDerived,
            "owner": owner,
            "semantic_desc": semanticDesc
        ]
        
        if let returnType = op.returnType {
            attributes["returnType"] = returnType
        }
        if let visibility = op.visibility {
            attributes["visibility"] = visibility
        }
        
        // Add operation node
        graph.addNode(opId, attributes: attributes)
        
        // Add OWNS_OP edge: Class → Operation
        graph.addEdge(from: owner, to: opId, attributes: ["type": EdgeType.ownsOp.rawValue])
    }
    
    // MARK: - Add Enum Literal Node
    
    /// Add an enum literal node and HAS_LITERAL edge
    ///
    /// Args:
    ///     lit: ParsedEnumLiteral structure
    ///     enumName: Name of the parent enumeration
    private func addEnumLiteralNode(lit: ParsedEnumLiteral, enumName: String) {
        let litId = lit.id
        
        let attributes: [String: Any] = [
            "type": "EnumLiteral",
            "name": lit.name,
            "enum": enumName
        ]
        
        // Add literal node
        graph.addNode(litId, attributes: attributes)
        
        // Add HAS_LITERAL edge: Enumeration → EnumLiteral
        graph.addEdge(from: enumName, to: litId, attributes: ["type": EdgeType.hasLiteral.rawValue])
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
        
        // Base edge attributes
        let baseAttributes: [String: Any] = [
            "type": EdgeType.assoc.rawValue,
            "id": edgeId,
            "aggKind": assoc.aggKind
        ]
        
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
            
            var attrsFwd = baseAttributes
            attrsFwd["roleSrc"] = assoc.roleA
            attrsFwd["multSrc"] = assoc.multA
            attrsFwd["roleDst"] = assoc.roleB
            attrsFwd["multDst"] = assoc.multB
            if let label = assoc.label {
                attrsFwd["label"] = label
            }
            attrsFwd["semantic_desc"] = semanticDescFwd
            
            // Reverse direction: B → A
            let semanticDescRev = semanticGenerator.generateAssociationDesc(
                assoc: assoc,
                source: classB,
                target: classA,
                roleName: assoc.roleB,
                multiplicity: assoc.multA,
                isReverse: true
            )
            
            var attrsRev = baseAttributes
            attrsRev["roleSrc"] = assoc.roleB
            attrsRev["multSrc"] = assoc.multB
            attrsRev["roleDst"] = assoc.roleA
            attrsRev["multDst"] = assoc.multA
            if let label = assoc.label {
                attrsRev["label"] = label
            }
            attrsRev["semantic_desc"] = semanticDescRev
            
            // Handle self-referential edges with different keys
            if classA == classB {
                graph.addEdge(from: classA, to: classB, key: "\(edgeId)_fwd", attributes: attrsFwd)
                graph.addEdge(from: classB, to: classA, key: "\(edgeId)_rev", attributes: attrsRev)
            } else {
                graph.addEdge(from: classA, to: classB, key: edgeId, attributes: attrsFwd)
                graph.addEdge(from: classB, to: classA, key: edgeId, attributes: attrsRev)
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
            
            var attrs = baseAttributes
            attrs["roleSrc"] = assoc.roleA
            attrs["multSrc"] = assoc.multA
            attrs["roleDst"] = assoc.roleB
            attrs["multDst"] = assoc.multB
            if let label = assoc.label {
                attrs["label"] = label
            }
            attrs["semantic_desc"] = semanticDesc
            
            graph.addEdge(from: classA, to: classB, key: edgeId, attributes: attrs)
            
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
            
            var attrs = baseAttributes
            attrs["roleSrc"] = assoc.roleB
            attrs["multSrc"] = assoc.multB
            attrs["roleDst"] = assoc.roleA
            attrs["multDst"] = assoc.multA
            if let label = assoc.label {
                attrs["label"] = label
            }
            attrs["semantic_desc"] = semanticDesc
            
            graph.addEdge(from: classB, to: classA, key: edgeId, attributes: attrs)
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
        
        let attributes: [String: Any] = [
            "type": EdgeType.generalizes.rawValue,
            "semantic_desc": semanticDesc
        ]
        
        // Add edge from child to parent
        graph.addEdge(from: child, to: parent, attributes: attributes)
    }
    
    // MARK: - Add Realization Edge
    
    /// Add REALIZES edge (class → interface)
    ///
    /// Args:
    ///     real: ParsedRealization structure
    private func addRealizationEdge(real: ParsedRealization) {
        let className = real.className
        let interfaceName = real.interfaceName
        
        let attributes: [String: Any] = [
            "type": EdgeType.realizes.rawValue
        ]
        
        // Add edge from class to interface
        graph.addEdge(from: className, to: interfaceName, attributes: attributes)
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
            var updatedAttrs = node.attributes
            updatedAttrs["type"] = "AssociationClass"
            updatedAttrs["associationBetween"] = [classA, classB]
            
            // Update node (remove and re-add with new attributes)
            graph.addNode(assocClassName, attributes: updatedAttrs)
        }
        
        // Create bidirectional associations
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
        
        graph.addEdge(from: classA, to: assocClassName, key: edgeIdA, attributes: [
            "type": EdgeType.assoc.rawValue,
            "id": edgeIdA,
            "aggKind": "none",
            "navigability": "bi",
            "semantic_desc": descAFwd
        ])
        
        graph.addEdge(from: assocClassName, to: classA, key: edgeIdA, attributes: [
            "type": EdgeType.assoc.rawValue,
            "id": edgeIdA,
            "aggKind": "none",
            "navigability": "bi",
            "semantic_desc": descARev
        ])
        
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
        
        graph.addEdge(from: classB, to: assocClassName, key: edgeIdB, attributes: [
            "type": EdgeType.assoc.rawValue,
            "id": edgeIdB,
            "aggKind": "none",
            "navigability": "bi",
            "semantic_desc": descBFwd
        ])
        
        graph.addEdge(from: assocClassName, to: classB, key: edgeIdB, attributes: [
            "type": EdgeType.assoc.rawValue,
            "id": edgeIdB,
            "aggKind": "none",
            "navigability": "bi",
            "semantic_desc": descBRev
        ])
    }
}
