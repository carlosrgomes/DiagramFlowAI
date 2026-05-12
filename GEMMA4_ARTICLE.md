*This is a submission for the [Gemma 4 Challenge: Write About Gemma 4](https://dev.to/challenges/google-gemma-2026-05-06)*

# Why I Picked Gemma 4's Smallest Variant for a Desktop AI App (and What Thinking Mode Quietly Unlocked)

Most "Build with X" posts I read pick the biggest model in the family and call it a day. This one is the opposite: I deliberately built a desktop product around **Gemma 4 E2B and E4B** — the small/edge variants — and skipped the 31B Dense and 26B MoE on purpose. This is the post I wish I had read before I started.

The project is **DiagramFlowAI**, a Flutter desktop app (macOS / Windows / Linux) that turns natural-language prompts into production-quality architecture diagrams — Mermaid for general use, structured commands with real AWS icons for cloud architectures. Everything runs locally via [`flutter_gemma`](https://pub.dev/packages/flutter_gemma) on top of LiteRT. No API keys, no internet after the first model download, no telemetry.

I'll talk about three things:

1. The model-selection question, honestly.
2. **Why Gemma 4's thinking mode** turned out to be the feature I didn't know I needed.
3. The pragmatic patterns I ended up with after fighting the model for a few weeks.

---

## The unfashionable choice: small over large

The Gemma 4 family ships in three flavors:

| Variant | Effective params | Designed for |
|---|---|---|
| **E2B / E4B** | 2B / 4B | Mobile, edge, browser, on-device |
| **Dense** | 31B | Server-grade local inference |
| **MoE** | 26B | High-throughput reasoning |

If you're building a server-side product, the 31B Dense is the obvious pick — quality wins. If you're building a high-throughput backend with reasoning needs, the MoE earns its keep. **My constraints pointed the other way:**

- **Local-first is non-negotiable.** Architects and engineers diagram internal systems. They're sketching auth flows, data pipelines, S3 layouts. Sending that to a cloud endpoint is a deal-breaker for the audience I care about.
- **The app needs to ship to laptops, not workstations.** A 31B dense model in 4-bit quantization still wants ~16-20 GB of RAM headroom. E4B comfortably fits in 4-6 GB and runs on integrated GPUs. That's the difference between "anyone can install it" and "only people with a 32GB machine can install it."
- **No API key, ever.** The minute the user has to paste a token, half of them bounce. E2B and E4B are gated only by Hugging Face's "press download" — no auth needed for the [`litert-community/gemma-4-E2B-it-litert-lm`](https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm) and `E4B` builds.
- **Cold start matters in a desktop app.** The first inference call after install needs to feel snappy. E2B is loading and answering in seconds on an M-series Mac. The 31B would still be paging weights in.

I gave the user a switch between E2B (faster) and E4B (more accurate on complex Mermaid syntax) instead of hardcoding one — that small UX choice shows up later as a quality lever for users with beefier machines.

```dart
// lib/models/ai_model_state.dart — the actual config in the shipped app
const gemmaModels = [
  GemmaModelConfig(
    name: 'Gemma 4 · 2B (no auth)',
    url: 'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/'
         'resolve/main/gemma-4-E2B-it.litertlm',
    filename: 'gemma-4-E2B-it.litertlm',
    modelType: ModelType.gemma4,
    fileType: ModelFileType.litertlm,
    needsAuth: false,
    maxTokens: 8192,
  ),
  GemmaModelConfig(
    name: 'Gemma 4 · 4B (no auth)',
    url: '...gemma-4-E4B-it-litert-lm/...',
    needsAuth: false,
    maxTokens: 8192,
  ),
];
```

**The honest tradeoff:** a 4B parameter model is not going to solve novel reasoning problems. If you're building math tutoring or legal analysis, climb the parameter ladder. But for a domain you can teach via the system prompt — which is exactly what diagram generation is — small models with good instruction-following are remarkably capable. Don't reach for 31B by default just because it's there.

---

## Thinking mode is the underrated feature

This is the part I want every developer building with Gemma 4 to internalize. The flutter_gemma SDK exposes Gemma 4's reasoning trace as a separate stream of `ThinkingResponse` chunks, distinct from the user-visible output:

```dart
// lib/models/ai_engine_service.dart
Stream<StreamChunk> streamResponse(InferenceChat chat, String prompt) async* {
  await chat.addQueryChunk(Message.text(text: prompt, isUser: true));
  await for (final response in chat.generateChatResponseAsync()) {
    if (response is TextResponse) {
      yield TextChunk(response.token);       // shown to user
    } else if (response is ThinkingResponse) {
      yield ThinkChunk(response.content);    // shown collapsed, "Thinking..."
    }
  }
}
```

For diagram generation, this matters more than you'd think. Mermaid syntax is **notoriously fragile** — a stray colon in a quadrantChart axis label, an unquoted string in a gitGraph `id:`, a missing `end` after a `subgraph`, and the whole render breaks. Without thinking mode, a 4B model will confidently emit a syntactically broken diagram in one shot. With thinking mode, the model spends a few hundred tokens planning structure first ("OK, this is a sequence diagram, I need actor / participant / arrow / response..."), and the final output is dramatically more likely to parse.

I show the thinking trace to the user as a collapsed accordion ("Thinking · 2.4s"). It does two things: (1) gives users a reason to trust the model when it's getting something complex right, and (2) makes the wait feel productive instead of empty. **Hide it entirely and your app feels frozen; show it raw and you overwhelm the user.** Collapsed-by-default is the move.

Enabling it in `flutter_gemma` is one parameter:

```dart
_chat = await inferenceModel.createChat(
  systemInstruction: _systemPrompt,
  isThinking: model.modelType == ModelType.gemma4,  // <-- this
  modelType: model.modelType,
  temperature: 1.0,
  topK: 64,
  topP: 0.95,
  tokenBuffer: 2048,
);
```

If you're building anything where output structure matters more than freeform prose — code, JSON, DSLs, structured commands — turn this on first and tune the rest later.

---

## The pragmatic patterns I ended up with

A few hard-won lessons that aren't obvious until you ship.

### 1. Treat the system prompt as a grammar, not a personality

My system prompt is roughly 500 lines. Almost none of it is "you are a helpful assistant." It's:

- An **output contract** with explicit delimiters: `<DIAGRAM>...</DIAGRAM>`. No regex-fighting markdown fences. The model wraps the diagram in literal tags I can substring-extract.
- A **decision rule** with one path per response: AWS architectures emit structured commands (because I have icon assets); everything else emits raw Mermaid.
- **Syntax cards** for every diagram type, each with the most common parser failures listed as `NEVER write X` examples.

The "never write X" pattern is doing more work than the positive examples. Small models pattern-match on what's in the prompt; if you only show valid syntax, they'll generalize and invent invalid syntax. Showing the failure mode inline ("`x-axis Latency: low → high` ✗") preempts entire classes of bugs.

### 2. The 8K context budget is tighter than you think

E2B and E4B have an 8192-token max. My system prompt eats roughly 3K of that. Add the user's request, the current diagram state being passed back in for edits, and the response itself — and you're using all of it. If your prompt is creeping past 4K, **start splitting it into on-demand syntax cards** loaded based on detected diagram type. I haven't done this yet, but it's the next optimization on the list.

### 3. Trust the contract, don't fight markdown

Early on I had elaborate regex trying to extract Mermaid from triple-backtick fences with optional language hints. It was fragile. The fix was to give the model a single delimiter pair and trust it:

```dart
String? extractMermaidCode(String text) {
  final tagged = _between(text, '<DIAGRAM>', '</DIAGRAM>');
  if (tagged != null && tagged.isNotEmpty) return tagged;
  // ...legacy fence fallback
}
```

The thinking mode helps here too — even when the model wants to write a paragraph of explanation, it puts the diagram in the tags because the contract is explicit.

### 4. Build a retry loop, not a perfect prompt

Even with thinking mode, ~10% of complex diagrams come back with a syntax error. Instead of prompt-engineering my way to 100% (impossible at 4B), I have a small ReAct-style loop: render attempt → on parse error, feed the error message back as a follow-up turn → re-emit. Two attempts catch nearly everything. **Stop optimizing the first shot past 90%; engineer the recovery instead.**

---

## What this means for desktop AI apps

If you'd asked me a year ago whether you could ship a useful, locally-run AI desktop app to non-technical users, I'd have said "kind of, with caveats." Gemma 4 E2B/E4B genuinely changes the answer to "yes, and the experience is good." The combination of:

- A 4B model that fits a normal laptop,
- Thinking mode that meaningfully improves structured output,
- An open weights license that lets you bundle and ship,
- An 8K context that's enough for a real system prompt,

…means the next wave of desktop apps doesn't have to choose between "send everything to a cloud LLM" and "ship a toy." Pick the smallest model that fits your domain, lean hard on the system prompt, turn thinking mode on, and engineer the recovery loop. That's the recipe.

---

## Try it / source

DiagramFlowAI is open source. Multi-platform release builds (macOS / Windows / Linux) are produced by GitHub Actions on tag push.

- **Repo:** [github.com/carlosrgomes/DiagramFlowAI](https://github.com/carlosrgomes/DiagramFlowAI)
- **Models used:** `litert-community/gemma-4-E2B-it-litert-lm`, `litert-community/gemma-4-E4B-it-litert-lm`
- **SDK:** `flutter_gemma` ^0.14

If you're picking a Gemma 4 variant for your own project: don't default to the biggest one. Map your *deployment* constraints first — where it runs, who installs it, what the cold-start budget is — and let those choose the model. For a surprising number of real products, the answer is going to be E2B or E4B, and that's a feature, not a compromise.
