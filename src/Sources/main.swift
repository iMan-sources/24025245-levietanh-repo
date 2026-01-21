import Foundation

func main() {
    print("Welcome to Thesis CLI!")
    print("Swift version: \(getSwiftVersion())")
    
    // Your CLI logic here
    if CommandLine.argc > 1 {
        let arguments = Array(CommandLine.arguments.dropFirst())
        print("Arguments received: \(arguments.joined(separator: ", "))")
    } else {
        print("No arguments provided.")
        printUsage()
    }
}

func getSwiftVersion() -> String {
    #if swift(>=5.9)
    return "5.9+"
    #elseif swift(>=5.8)
    return "5.8+"
    #else
    return "Unknown"
    #endif
}

func printUsage() {
    print("""
    
    Usage:
        ThesisCLI [options] [arguments]
    
    Options:
        --help, -h      Show this help message
        --version, -v   Show version information
    
    Examples:
        ThesisCLI --help
        ThesisCLI --version
    """)
}

// Entry point
main()
