# Architecture Diagram Images

This directory should contain the rendered images of the architecture diagrams for the README.md file.

## Required Images

1. `litellm-aws-architecture.png` - High-level architecture diagram
2. `litellm-aws-components.png` - Component diagram showing the relationships between different parts of the system

## How to Generate These Images

The source diagrams are available in Mermaid format in `architecture.md`. You can generate the images using:

1. **Online Mermaid Editor**: 
   - Visit https://mermaid.live/
   - Copy the diagram code from `architecture.md`
   - Export as PNG or SVG

2. **VS Code with Mermaid Extension**:
   - Install the "Markdown Preview Mermaid Support" extension
   - Open `architecture.md`
   - Use the preview to view the diagrams
   - Export as images

3. **Command Line with mermaid-cli**:
   ```bash
   npm install -g @mermaid-js/mermaid-cli
   mmdc -i architecture.md -o litellm-aws-architecture.png
   ```

## Image Specifications

- Resolution: At least 800x600 pixels
- Format: PNG or SVG (preferred)
- Style: Use the AWS color scheme as defined in the Mermaid diagrams
