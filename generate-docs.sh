#!/bin/bash

# Quick Documentation Generation Script
# Builds DocC archives for all Aurora modules

echo "🚀 Generating Aurora Toolkit Documentation Archives"

MODULES=("AuroraCore" "AuroraLLM" "AuroraML" "AuroraTaskLibrary" "AuroraExamples")

for module in "${MODULES[@]}"; do
    echo "📚 Generating documentation for $module..."
    swift package generate-documentation --target "$module"
    
    if [ $? -eq 0 ]; then
        echo "✅ $module documentation generated successfully"
    else
        echo "❌ Failed to generate $module documentation"
        exit 1
    fi
done

echo ""
echo "🎉 All documentation archives generated successfully!"
echo ""
echo "Documentation archives are located in:"
echo ".build/plugins/Swift-DocC/outputs/"
echo ""
echo "Open individual .doccarchive files with Xcode to view the documentation."