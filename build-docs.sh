#!/bin/bash

# Build Documentation Script for Aurora Toolkit
# This script generates DocC documentation for all Aurora modules

echo "🚀 Building Aurora Toolkit Documentation"
echo "========================================"

# Define modules
MODULES=("AuroraCore" "AuroraLLM" "AuroraML" "AuroraTaskLibrary" "AuroraExamples")

# Create documentation output directory
DOC_OUTPUT="./docs"
mkdir -p "$DOC_OUTPUT"

# Function to build documentation for a single module
build_module_docs() {
    local module=$1
    echo ""
    echo "📚 Building documentation for $module..."
    
    # Generate documentation
    swift package generate-documentation --target "$module"
    
    if [ $? -eq 0 ]; then
        echo "Successfully built documentation for $module"
        
        # Copy the generated archive to our docs directory
        ARCHIVE_PATH=".build/plugins/Swift-DocC/outputs/$module.doccarchive"
        if [ -d "$ARCHIVE_PATH" ]; then
            cp -r "$ARCHIVE_PATH" "$DOC_OUTPUT/"
            echo "📁 Documentation archive copied to $DOC_OUTPUT/$module.doccarchive"
        fi
    else
        echo "Failed to build documentation for $module"
        exit 1
    fi
}

# Function to export documentation for hosting
export_for_hosting() {
    local module=$1
    echo ""
    echo "🌐 Exporting $module documentation for hosting..."
    
    swift package --allow-writing-to-directory "$DOC_OUTPUT" \
        generate-documentation --target "$module" \
        --disable-indexing \
        --transform-for-static-hosting \
        --hosting-base-path "aurora-docs" \
        --output-path "$DOC_OUTPUT/$module"
        
    if [ $? -eq 0 ]; then
        echo "Successfully exported $module for hosting"
    else
        echo "Failed to export $module for hosting"
        exit 1
    fi
}

# Build documentation for all modules
echo "Building documentation archives..."
for module in "${MODULES[@]}"; do
    build_module_docs "$module"
done

echo ""
echo "🌐 Exporting documentation for web hosting..."

# Export for hosting (optional)
for module in "${MODULES[@]}"; do
    export_for_hosting "$module"
done

echo ""
echo "🎉 Documentation build complete!"
echo ""
echo "Available documentation:"
for module in "${MODULES[@]}"; do
    echo "  - $module: $DOC_OUTPUT/$module.doccarchive"
done
echo ""
echo "To view documentation:"
echo "  1. Archive format (Recommended): open $DOC_OUTPUT/AuroraCore.doccarchive"
echo "  2. Preview mode: swift package --disable-sandbox preview-documentation --target AuroraCore"
echo ""