# DiagramFlowAI

DiagramFlowAI is a multi-platform desktop application designed to bridge the gap between **AI productivity** and **enterprise privacy**. It allows software engineers and architects to transform natural language descriptions into professional architecture diagrams while keeping all sensitive data 100% local.

For a deep dive into the architecture and the "why" behind this project, read the official article: [Local-First AI Done Right: How Gemma 4 E2B and 'Thinking Mode' Powered DiagramFlowAI](https://dev.to/gde/local-first-ai-done-right-how-gemma-4-e2b-and-thinking-mode-powered-diagramflowai-3bop).

## 🚀 The Problem & Solution

### The Problem
Traditional AI diagramming tools rely on cloud-based Large Language Models (LLMs). This creates a massive hurdle for companies with strict security policies:
- **Privacy Risks:** Sensitive architectural perimeters and data flows are sent to third-party servers.
- **Compliance Issues:** Regulations often forbid sharing proprietary system designs with external APIs.
- **Latency & Dependency:** Reliance on internet connectivity and API availability.

### The Solution
DiagramFlowAI provides a **local-first** experience. By running optimized AI models directly on your hardware, it ensures that your designs never leave your machine. It combines the power of Gemma 4's reasoning capabilities with a specialized UI to make architectural diagramming as simple as talking to a peer.

## ✨ Key Features

- **Natural Language to Diagram:** Describe your architecture in plain English and get a production-ready diagram instantly.
- **Dual Output Modes:**
  - **Mermaid Syntax:** Standard, version-control-friendly code for general documentation, flows, and system designs.
  - **Cloud-Native Architecture:** Specialized support for major cloud providers. While it features optimized assets for **AWS**, it also includes comprehensive templates for **Google Cloud (GCP)** and general architectural patterns.
- **100% Local Execution:** Powered by **Gemma 4 Edge (2B/4B)** models running on **LiteRT** (formerly TensorFlow Lite). No internet required, no data leakage.
- **"Thinking Mode" Transparency:** View the model's internal reasoning traces (Chain of Thought) as it builds your diagram.
- **Self-Healing Loop:** Automatically detects and fixes Mermaid syntax errors by feeding parser feedback back into the local AI.
- **Multi-Platform:** Native desktop performance for macOS, Windows, and Linux.

## 🛠️ Technical Stack

- **Frontend:** [Flutter](https://flutter.dev/) (Material 3)
- **Local AI Runtime:** [LiteRT](https://www.tensorflow.org/lite) via the `flutter_gemma` plugin.
- **Models:** [Gemma 4](https://ai.google.dev/gemma) (optimized Edge variants E2B and E4B).
- **Rendering:** [Mermaid.js](https://mermaid.js.org/) for standard diagrams and custom high-fidelity SVG assets for cloud architectures.

## 📦 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Stable channel recommended)
- Standard development tools for your platform (Xcode for macOS, Visual Studio for Windows, or Build Essentials for Linux).

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-repo/DiagramFlowAI.git
   cd DiagramFlowAI
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the application:**
   ```bash
   flutter run
   ```

### Initial Setup

Upon the first launch, the application will guide you through downloading the required **Gemma 4 Edge** models. These models are approximately 1.5GB to 2.8GB. Once downloaded, the application works entirely offline.

## 🤝 Contributing

Contributions are welcome! Whether it's adding support for more cloud providers (GCP, Azure), improving the prompt templates, or enhancing the UI, feel free to open a PR.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---
*Created by [Carlos Barbero](https://dev.to/gde) - Part of the Gemma 4 Challenge.*
