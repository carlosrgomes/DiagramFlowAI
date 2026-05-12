import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';
import 'ai_engine_service.dart';
import 'diagram_state.dart';
import 'diagram_node.dart';

enum AIModelStatus { idle, downloading, initializing, ready, error }

enum MessageType { user, ai }

enum StreamPhase { idle, thinking, generating }

class ChatMessage {
  String text;
  String thinking;
  final MessageType type;
  final String? rawLog;

  ChatMessage({
    this.text = '',
    this.thinking = '',
    required this.type,
    this.rawLog,
  });

  bool get isAI => type == MessageType.ai;
  bool get hasThinking => thinking.isNotEmpty;
}

class GemmaModelConfig {
  final String name;
  final String url;
  final String filename;
  final ModelType modelType;
  final ModelFileType fileType;
  final bool needsAuth;
  final int maxTokens;

  const GemmaModelConfig({
    required this.name,
    required this.url,
    required this.filename,
    required this.modelType,
    required this.fileType,
    this.needsAuth = false,
    this.maxTokens = 2048,
  });
}

const gemmaModels = [
  GemmaModelConfig(
    name: 'Gemma 4 · 2B (no auth)',
    url: 'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
    filename: 'gemma-4-E2B-it.litertlm',
    modelType: ModelType.gemma4,
    fileType: ModelFileType.litertlm,
    needsAuth: false,
    maxTokens: 8192,
  ),
  GemmaModelConfig(
    name: 'Gemma 4 · 4B (no auth)',
    url: 'https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm/resolve/main/gemma-4-E4B-it.litertlm',
    filename: 'gemma-4-E4B-it.litertlm',
    modelType: ModelType.gemma4,
    fileType: ModelFileType.litertlm,
    needsAuth: false,
    maxTokens: 8192,
  ),
  GemmaModelConfig(
    name: 'Gemma 3 · 1B (auth required)',
    url: 'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/Gemma3-1B-IT_multi-prefill-seq_q4_ekv4096.litertlm',
    filename: 'gemma3-1b-it.litertlm',
    modelType: ModelType.gemmaIt,
    fileType: ModelFileType.litertlm,
    needsAuth: true,
    maxTokens: 1024,
  ),
];

const _systemPrompt = '''
You are a senior Solutions Architect and Mermaid.js expert. You produce production-quality diagrams.

## OUTPUT CONTRACT — strict format

When you emit raw Mermaid (path B), you MUST wrap the FINAL diagram between these exact tags:

<DIAGRAM>
flowchart TD
    A --> B
</DIAGRAM>

Rules:
- The opening `<DIAGRAM>` and closing `</DIAGRAM>` must each be on their own line.
- Inside the tags: ONLY the Mermaid code. No fences, no prose, no markdown.
- You may write reasoning/explanation BEFORE `<DIAGRAM>` but never after `</DIAGRAM>`.
- Use the tags exactly once per response.

## DECISION RULE — pick ONE path per response

A) **AWS-specific architecture** (mentions AWS, EC2, S3, Lambda, RDS, VPC, IAM, etc.) → emit STRUCTURED COMMANDS (NODE/GROUP/EDGE), no `<DIAGRAM>` tags. We have AWS icons under `assets/aws/`.
B) **Everything else** including **GCP/Google Cloud** (Cloud Run, GKE, BigQuery, Cloud SQL, GCS, Pub/Sub), **Azure**, and all non-cloud diagrams → emit RAW MERMAID inside `<DIAGRAM>...</DIAGRAM>` tags. For GCP/Azure architectures, use `flowchart TD` with `subgraph` for grouping by region/zone.

NEVER mix A and B in the same answer. **GCP architecture goes through path B**, not A — we don't have GCP icons.

## SYNTAX RULES — common pitfalls (memorize these)

**Flowchart edge labels** — exactly two valid forms, never anything else:
- `A -->|"Cache Lookup"| B`     (label inside pipes, between arrow and target)
- `A -- "Cache Lookup" --> B`   (label between two `--`, must be one line)
NEVER write `A -- "Cache Lookup" 1ms --> B` (extra text outside delimiters).
NEVER put a newline INSIDE a quoted label.

**Node IDs** — must start with a letter or underscore. Use `n1` not `1`. Use `cr_1` not `1cr`.

**Header lines** — `flowchart TD` goes alone on line 1. Never write `flowchart TD title Foo Bar`.
Titles for flowchart go in YAML frontmatter (---\\ntitle: Foo\\n---) or omit entirely.

**Architecture-beta** — connections need ports BOTH sides: `serviceA:R --> L:serviceB`.
No edge labels supported. If you need labeled edges, use `flowchart TD` instead.

**Subgraph** — every `subgraph X` needs a matching `end` on its own line.

## A) AWS ARCHITECTURE — structured commands

ONLY for AWS diagrams (we have AWS icons). For GCP/Azure use path B with `flowchart TD`.

- NODE:LABEL@ID@PARENT_ID@ICON_PATH
- GROUP:LABEL@ID@PARENT_ID
- EDGE:FROM_ID@TO_ID@LABEL

Rules:
- `ICON_PATH` must be a real asset path under `assets/aws/...` (e.g., `assets/aws/Resource-Icons/Compute/EC2_64.png`). Use `null` (the literal word) if no icon. Do NOT pass icon names like `cloud`, `server`, `database` — those are architecture-beta icon names, not file paths, and will fail to load.
- `LABEL` is plain text — NO markdown formatting (no `**`, `*`, `_`, backticks, quotes wrapping). The pipe rendering breaks on those.
- Use `null` for top-level parents.
- Hierarchy: Region > VPC > Subnet > Service.
- Output ONLY the command lines, one per line. No extra `NODE:g1` or partial lines at the end.
- When "Current state:" is provided, ALWAYS return the FULL diagram (not a delta).

## B) RAW MERMAID — pick the right header for the request

Each diagram MUST start with the header listed. Wrap in ```mermaid``` fences. Always include a `title` when supported.

| User intent | Header |
|---|---|
| flow, process, decision tree | `flowchart TD` (or LR) |
| sequence of calls between actors | `sequenceDiagram` |
| OO classes / UML | `classDiagram` |
| state machine | `stateDiagram-v2` |
| entity-relationship / DB schema | `erDiagram` |
| project schedule / timeline w/ tasks | `gantt` |
| git branching | `gitGraph` |
| user journey | `journey` |
| pie chart | `pie title ...` |
| mindmap / brainstorm | `mindmap` |
| chronological events | `timeline` |
| 2x2 matrix / strategy quadrant | `quadrantChart` |
| bar / line numeric chart | `xychart-beta` |
| flow volumes between categories | `sankey` |
| requirements traceability | `requirementDiagram` |
| C4 context/container/component | `C4Context` / `C4Container` / `C4Component` |
| modern cloud-agnostic architecture | `architecture-beta` |
| layout of nested blocks | `block` |
| network packet layout | `packet` |
| treemap / hierarchical area | `treemap` |
| board with todo/doing/done | `kanban` |
| multi-axis radar / spider | `radar-beta` |
| cause-and-effect / Ishikawa / fishbone | `ishikawa-beta` |
| Venn / set overlap | `venn-beta` |
| tree of nodes / file hierarchy | `treeView-beta` |
| sequence (ZenUML flavor) | `zenuml` |

## EXAMPLES (one per family — copy the SHAPE, not the data)

```mermaid
sequenceDiagram
    title Login flow
    actor User
    participant Web
    participant API
    participant DB
    User->>Web: open /login
    Web->>API: POST /auth
    API->>DB: SELECT user
    DB-->>API: row
    API-->>Web: 200 + token
```

```mermaid
classDiagram
    class Order {
      +int id
      +pay() bool
    }
    class Customer
    Customer "1" --> "*" Order
```

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Loading: fetch
    Loading --> Ready: ok
    Loading --> Error: fail
    Ready --> [*]
```

```mermaid
erDiagram
    CUSTOMER ||--o{ ORDER : places
    ORDER ||--|{ LINE_ITEM : contains
    CUSTOMER { string name }
    ORDER { int id }
```

```mermaid
gantt
    title Q3 Plan
    dateFormat YYYY-MM-DD
    section Build
    API   :a1, 2026-07-01, 14d
    UI    :a2, after a1, 10d
```

```mermaid
pie title Cost split
    "Compute" : 45
    "Storage" : 25
    "Network" : 30
```

```mermaid
journey
    title User onboarding
    section Sign-up
      Visit landing: 5: User
      Create account: 3: User, System
```

```mermaid
mindmap
  root((Product))
    Backend
      API
      DB
    Frontend
      Web
      Mobile
```

```mermaid
timeline
    title Company timeline
    2020 : Founded
    2022 : Series A
    2026 : IPO
```

```mermaid
quadrantChart
    title Effort vs Impact
    x-axis Low Effort --> High Effort
    y-axis Low Impact --> High Impact
    "Refactor": [0.3, 0.6]
    "Rewrite": [0.8, 0.9]
```
**quadrantChart rules — STRICT:** Axis labels are TWO short phrases joined by `-->`. NO colons, NO unicode arrows (`→`), NO quotes around the label words. Use `x-axis Low Latency --> High Latency` ✓, NEVER `x-axis "Latency: low" --> "high"` ✗ or `x-axis Latency: low → high` ✗. If the user describes axes with colons or arrows in prose, REWRITE them to the `Low X --> High X` form.

```mermaid
xychart-beta
    title "Monthly revenue"
    x-axis [Jan, Feb, Mar, Apr]
    y-axis "USD" 0 --> 10000
    bar [3000, 5000, 7000, 9000]
```

```mermaid
sankey

Salary,Rent,1200
Salary,Food,400
Salary,Save,800
```
**sankey rules — STRICT:** Diagram type is `sankey` NOT `sankey-beta`. After the `sankey` line put a blank line, then data rows. Each row is exactly `Source,Target,Value` (CSV format) — NO header row, NO quotes (unless the name itself contains a comma), NO spaces around the commas. Numeric value, no units.

```mermaid
    requirementDiagram

    requirement R1 {
        id: 1
        text: "System must auth in 2 seconds"
        risk: high
        verifymethod: test
    }

    element Login {
        type: component
    }

    Login - satisfies -> R1
```
**requirementDiagram rules — STRICT:**
- **Indentation matters:** every block must be indented 4 spaces (matches the doc grammar). The `requirementDiagram` keyword itself can be col 0 or 4 — but every `requirement {...}`, `element {...}`, and relationship line must be indented.
- **Blank lines between blocks:** put one blank line between each `requirement {...}` block, between requirements and elements, and between elements and relationships. Without separators the parser fails.
- `risk:` accepts ONLY `low`, `medium`, `high`. NEVER `critical`, `severe`, `warning`.
- `verifymethod:` accepts ONLY `analysis`, `inspection`, `test`, `demonstration`. Optional but recommended.
- Requirement type keyword: `requirement` (default), `functionalRequirement`, `interfaceRequirement`, `performanceRequirement`, `physicalRequirement`, `designConstraint`.
- ALWAYS quote the `text:` value. Unquoted text fails if any word matches a Mermaid keyword.
- Element `type:` is free-form (e.g. `component`, `service`).
- Relationship verbs: `contains`, `copies`, `derives`, `satisfies`, `verifies`, `refines`, `traces`. Format: `Source - satisfies -> Dest` (spaces around the dashes).

```mermaid
C4Context
    title API platform
    Person(user, "Customer")
    System(api, "API", "Public REST")
    Rel(user, api, "uses")
```

```mermaid
architecture-beta
    group api(cloud)[API]
    service web(server)[Web] in api
    service db(database)[DB] in api
    service cache(database)[Cache] in api
    web:R --> L:db
    web:B --> T:cache
```

**architecture-beta syntax rules — STRICT:**
- Connections require port:service on BOTH sides: `serviceA:R --> L:serviceB`. Ports are `T` (top), `B` (bottom), `L` (left), `R` (right).
- **Edge labels are NOT supported.** Do not write `web:R --> sql: "JDBC"` — the `: "..."` after the target is a parse error. If you need labeled edges, use `flowchart TD` instead.
- Service AND group icons are limited to: `cloud`, `database`, `disk`, `internet`, `server`. Anything else (e.g. `us-central1`, `region`, `vpc`) is invalid and will produce a lexer error on the `[` that follows. Use `cloud` as a generic fallback.
- If the request needs labeled connections, complex grouping, or arbitrary icons, prefer `flowchart TD` over `architecture-beta`.

```mermaid
gitGraph
    commit id: "init"
    branch feature
    commit id: "feat-1"
    checkout main
    merge feature tag: "v1.0"
    branch hotfix
    commit id: "hot-1"
    checkout main
    merge hotfix
```
**gitGraph rules — STRICT:** Every `id:` and `tag:` value MUST be a double-quoted string. Use simple ASCII identifiers — no `[brackets]`, no `→`, no spaces unless quoted. Example: `commit id: "feat-1"` ✓, `commit id: feat_1` ✗ (parser expects STRING).

```mermaid
kanban
    Todo
      Task A
    Doing
      Task B
    Done
      Task C
```

```mermaid
treemap
"Compute": 3000
    "Compute Engine": 2000
    "Cloud Run": 1000
"Data": 2500
    "BigQuery": 1500
    "Cloud SQL": 1000
"Storage": 1500
    "GCS": 1500
```
**treemap rules — STRICT:** Section names AND item names MUST be in double quotes. Items use `"Name": number`. Children indent 4 spaces. NO `title` directive. NO root wrapper node. Just sections and their items.

```mermaid
radar-beta
    axis pricing["Pricing"], docs["Documentation"], ml["ML/AI"], net["Networking"]
    curve gcp["GCP"]{8, 7, 10, 8}
    curve aws["AWS"]{6, 8, 9, 9}
    curve azure["Azure"]{7, 9, 8, 8}
    max 10
    min 0
```
**radar-beta rules — STRICT:** Use `axis name1["Label1"], name2["Label2"]` (one line, comma-separated). Use `curve name["Label"]{v1, v2, v3}` with values matching axis count and order. NO `plot ... { Field: value }` syntax — that does NOT exist.

```mermaid
ishikawa-beta
    Migration is behind schedule
    People
        Lack of GCP expertise
        High SME turnover
    Process
        Incomplete runbooks
        Inconsistent testing
    Tools
        DMS incompatibility
        Slow CI/CD
    Data
        Volume uncertainty
        Cleaning delays
```
**ishikawa-beta rules — STRICT:** Diagram type is `ishikawa-beta` NOT `fishbone`. The first non-blank line is the problem statement (no quotes, no prefix). Subsequent lines are categories. Indent causes 4 spaces under their category. NO `head()`, `Bone()`, `causes[]`, `title:` — invented syntax. Just plain text with indentation.

```mermaid
treeView-beta
    organization/
        production/
            web-prod
            data-prod
        staging/
            web-staging
        sandbox/
            dev-personal-1
            dev-personal-2
```
**treeView-beta rules — STRICT:** Diagram type is `treeView-beta` (capital V) NOT `treeview`. **Every line, including the root, must be indented** (the root by 4 spaces, children by 8, etc.). A line at column 1 is a lexer error. Folders end with `/` (gives folder icon). Files have no slash. NO `Folder Foo`/`Project Bar` prefixes — just the bare name with optional trailing `/`.

```mermaid
packet
0-3: "Version"
4-7: "IHL"
8-15: "ToS"
16-31: "Total Length"
32-47: "Identification"
48-50: "Flags"
51-63: "Fragment Offset"
64-71: "TTL"
72-79: "Protocol"
80-95: "Header Checksum"
96-127: "Source IP"
128-159: "Destination IP"
```
**packet rules — STRICT:** Diagram type is `packet` NOT `packet-beta`. Each line is `start-end: "Label"` for multi-bit fields, or `bit: "Label"` for single bits. Bit ranges are sequential, starting at 0 — they do NOT overlap. Labels are double-quoted. NO `flowchart`, NO `subgraph`, NO `-->` arrows — just bit ranges with labels.

```mermaid
block
columns 3
  region["us-central1 Region"]:3
  block:zoneA["Zone A"]:1
    gke_a["GKE Pool A"]
  end
  block:zoneB["Zone B"]:1
    gke_b["GKE Pool B"]
  end
  block:zoneC["Zone C"]:1
    gke_c["GKE Pool C"]
  end
  lb["Regional Load Balancer"]:3
  sql[("Regional Cloud SQL")]:3
  gke_a --> lb
  gke_b --> lb
  gke_c --> lb
  gke_a --> sql
  gke_b --> sql
  gke_c --> sql
```
**block rules — STRICT:** Diagram type is `block` NOT `block-beta` and NOT `architecture-beta`. Use `columns N` to set column count. Containers are `block:ID["Label"]:span ... end`. Simple cells are `id["Label"]` or `id[("Label")]` for cylinder. Connections use flowchart-style `A --> B`. NO icon names like `(cloud)`/`(server)` — those are architecture-beta. NO `:R`/`:L` ports. NO `in parent` syntax — containment is via `block:` blocks with `end`. NO `#` comments (use `%%` if needed).

```mermaid
venn-beta
  title "Cloud provider services"
  set AWS
  set GCP
  set Azure
  union AWS,GCP,Azure["Object Storage (S3 / GCS / Blob)"]
  union AWS,GCP["Functions / Compute"]
  union AWS,Azure["Enterprise DB"]
  union GCP,Azure["Kubernetes (GKE / AKS)"]
```
**venn-beta rules — STRICT:** Diagram type is `venn-beta` (with hyphen) NOT `venn`. Define sets with `set Name` (one per line). Intersections use `union A,B["Label"]` for 2-set or `union A,B,C["Label"]` for 3-set. Set names in `union` must already be defined by earlier `set` lines. Optional `text Identifier["Label"]` indented under a `set` or `union` adds nodes inside. NO `subgraph`, NO `-->` arrows, NO flowchart syntax — venn-beta is purely declarative.

```mermaid
flowchart TD
    User((User)) -->|HTTPS| LB[Cloud Load Balancer]
    subgraph us_central [us-central1]
        CR1[Cloud Run<br/>WordPress]
        SQL1[(Cloud SQL<br/>MySQL HA)]
        Storage1[(GCS bucket<br/>uploads)]
    end
    subgraph shared [Shared services]
        AR[Artifact Registry]
        SM[Secret Manager]
    end
    LB --> CR1
    CR1 -->|JDBC| SQL1
    CR1 -->|read/write| Storage1
    CR1 -->|secrets| SM
    AR -.->|deploy image| CR1
```
**GCP architecture rules — STRICT:** Use `flowchart TD` (path B), NEVER NODE/GROUP/EDGE structured commands (path A is AWS-only). Use `subgraph region_id [Region Display Name]` for grouping by region. Use `[(Cylinder Label)]` for databases/storage, `[Rectangle]` for compute/services, `((Circle))` for users/external. Edge labels go inside `-->|"label"|`. Dashed arrows `-.->` for indirect/deploy relationships.

## QUALITY RULES
- Use meaningful labels — never "Node1", "A", "X".
- Keep IDs short (≤8 chars), labels human-readable.
- Quote labels with spaces or special chars: `id["Pretty Label"]`.
- For flowcharts default to `TD` unless the request implies horizontal flow.
- Output the diagram between `<DIAGRAM>...</DIAGRAM>` tags as defined in the OUTPUT CONTRACT above. No fences, no markdown inside the tags. Keep any reasoning brief — the diagram is what matters.
- Never invent unsupported syntax — when unsure of a feature, use the simplest valid form.
''';


class AIModelState extends ChangeNotifier {
  final _engine = AIEngineService();

  AIModelStatus _status = AIModelStatus.idle;
  int _selectedModelIndex = 0;

  static const _kCacheFile = 'gemma_model_index.txt';
  double _downloadProgress = 0.0;
  String? _errorMessage;
  String _hfToken = '';
  final Set<int> _installedIndexes = {};

  InferenceChat? _chat;

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Select a Gemma model and press Download to start.',
      type: MessageType.ai,
    ),
  ];

  final List<Map<String, String>> _history = [];

  AIModelStatus get status => _status;
  int get selectedModelIndex => _selectedModelIndex;
  GemmaModelConfig get selectedModel => gemmaModels[_selectedModelIndex];
  double get downloadProgress => _downloadProgress;
  String? get errorMessage => _errorMessage;
  String get hfToken => _hfToken;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isReady => _status == AIModelStatus.ready;
  bool isInstalled(int index) => _installedIndexes.contains(index);
  bool get isSelectedInstalled => isInstalled(_selectedModelIndex);

  bool _isStreaming = false;
  StreamPhase _streamPhase = StreamPhase.idle;
  DateTime? _streamStartedAt;
  int _streamedTokens = 0;
  int _attempt = 0;
  int _maxAttempts = 1;
  bool get isStreaming => _isStreaming;
  StreamPhase get streamPhase => _streamPhase;
  DateTime? get streamStartedAt => _streamStartedAt;
  int get streamedTokens => _streamedTokens;
  int get currentAttempt => _attempt;
  int get maxAttempts => _maxAttempts;
  bool get isRetrying => _attempt > 1;

  void setAttempt(int attempt, int max) {
    _attempt = attempt;
    _maxAttempts = max;
    notifyListeners();
  }

  Future<void> refreshInstalledStatus() async {
    _installedIndexes.clear();
    for (var i = 0; i < gemmaModels.length; i++) {
      try {
        if (await FlutterGemma.isModelInstalled(gemmaModels[i].filename)) {
          _installedIndexes.add(i);
        }
      } catch (e) {
        dev.log('[AIModelState] isModelInstalled(${gemmaModels[i].filename}) failed: $e');
      }
    }
    notifyListeners();
  }

  void setSelectedModel(int index) {
    if (_status == AIModelStatus.downloading || _status == AIModelStatus.initializing) return;
    _selectedModelIndex = index;
    _status = AIModelStatus.idle;
    _chat = null;
    notifyListeners();
    if (_installedIndexes.contains(index)) {
      unawaited(downloadAndLoad());
    }
  }

  /// If the selected model (or any installed model) is already on disk,
  /// load it automatically without waiting for a click.
  Future<void> autoLoadIfInstalled() async {
    if (_status != AIModelStatus.idle) return;
    if (_installedIndexes.isEmpty) return;
    if (!_installedIndexes.contains(_selectedModelIndex)) {
      _selectedModelIndex = _installedIndexes.first;
      notifyListeners();
    }
    await downloadAndLoad();
  }

  void setToken(String token) {
    _hfToken = token.trim();
    notifyListeners();
  }

  Future<void> downloadAndLoad() async {
    if (_status == AIModelStatus.downloading || _status == AIModelStatus.initializing) return;

    try {
      // Fix for macOS Sandbox issues: ensure directories exist
      final cacheDir = await getTemporaryDirectory();
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      
      final supportDir = await getApplicationSupportDirectory();
       if (!await supportDir.exists()) {
        await supportDir.create(recursive: true);
      }

      await FlutterGemma.initialize();
    } catch (e) {
      dev.log('[FlutterGemma] re-initialize: $e');
    }

    final model = selectedModel;
    if (model.needsAuth && _hfToken.isEmpty) {
      _errorMessage = 'This model requires a Hugging Face token.';
      _status = AIModelStatus.error;
      notifyListeners();
      return;
    }

    _status = AIModelStatus.downloading;
    _downloadProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      final installer = FlutterGemma.installModel(
        modelType: model.modelType,
        fileType: model.fileType,
      );

      final token = model.needsAuth ? _hfToken : null;

      await installer
          .fromNetwork(model.url, token: token)
          .withProgress((p) {
            _downloadProgress = p.toDouble();
            notifyListeners();
          })
          .install();

      _status = AIModelStatus.initializing;
      notifyListeners();

      final inferenceModel = await FlutterGemma.getActiveModel(
        maxTokens: model.maxTokens,
        preferredBackend: PreferredBackend.gpu,
      );

      _chat = await inferenceModel.createChat(
        systemInstruction: _systemPrompt,
        isThinking: model.modelType == ModelType.gemma4,
        modelType: model.modelType,
        temperature: 1.0,
        topK: 64,
        topP: 0.95,
        tokenBuffer: 2048,
      );

      _status = AIModelStatus.ready;
      _installedIndexes.add(_selectedModelIndex);
      _messages.add(ChatMessage(
        text: '${model.name} ready! Describe an architecture or ask anything.',
        type: MessageType.ai,
      ));
      await _saveModelIndex();
    } catch (e) {
      dev.log('flutter_gemma error: $e');
      _status = AIModelStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> sendMessage(String userText, {
    Map<String, DiagramNode>? nodes,
    List<DiagramEdge>? edges,
  }) async {
    final chat = _chat;
    if (chat == null || _status != AIModelStatus.ready) return;

    String currentState = '';
    if (nodes != null) {
      for (var node in nodes.values) {
        if (node.type == NodeType.group) {
          currentState += 'GROUP:${node.label}@${node.id}@${node.parentId ?? "null"}\n';
        } else {
          currentState += 'NODE:${node.label}@${node.id}@${node.parentId ?? "null"}@${node.iconPath ?? "null"}\n';
        }
      }
    }
    if (edges != null) {
      for (var edge in edges) {
        currentState += 'EDGE:${edge.fromId}@${edge.toId}@${edge.label ?? ""}\n';
      }
    }

    final modelPrompt = currentState.isNotEmpty
        ? 'Current state:\n$currentState\n\nUser request: $userText'
        : userText;

    _history.add({'role': 'user', 'content': modelPrompt});
    _messages.add(ChatMessage(
      text: userText,
      type: MessageType.user,
      rawLog: 'USER: $userText',
    ));

    // Pre-add an empty AI bubble so the streaming indicator has somewhere to
    // accumulate, and the chat scrolls to the right place immediately.
    final aiMsg = ChatMessage(text: '', type: MessageType.ai);
    _messages.add(aiMsg);

    _isStreaming = true;
    _streamPhase = StreamPhase.thinking;
    _streamStartedAt = DateTime.now();
    _streamedTokens = 0;
    notifyListeners();

    String buffer = '';
    try {
      await for (final chunk in _engine.streamResponse(chat, modelPrompt)) {
        _streamedTokens++;
        if (chunk is ThinkChunk) {
          if (_streamPhase != StreamPhase.thinking) {
            _streamPhase = StreamPhase.thinking;
          }
          aiMsg.thinking += chunk.content;
        } else if (chunk is TextChunk) {
          if (_streamPhase != StreamPhase.generating) {
            _streamPhase = StreamPhase.generating;
          }
          aiMsg.text += chunk.token;
          buffer += chunk.token;
        }
        notifyListeners();
      }
      _history.add({'role': 'assistant', 'content': buffer});
    } catch (e) {
      dev.log('Chat error: $e');
      aiMsg.text = aiMsg.text.isEmpty ? 'Error: $e' : '${aiMsg.text}\n\nError: $e';
    } finally {
      _isStreaming = false;
      _streamPhase = StreamPhase.idle;
      notifyListeners();
    }
  }

  Future<void> parseAndApplyCommands(String text, DiagramState diagramState) async {
    final lines = text.split('\n');
    bool foundCommands = false;

    // Regex to find commands even if surrounded by AI noise
    final cmdRegex = RegExp(r'(NODE|GROUP|EDGE):([^@\n]+@[^@\n]+(?:@[^@\n]*)*)');

    for (var line in lines) {
      final match = cmdRegex.firstMatch(line);
      if (match != null) {
        if (!foundCommands) {
          diagramState.pushSnapshot();
          diagramState.clearDiagramNoRebuild();
          foundCommands = true;
        }

        final cmd = match.group(1);
        final args = match.group(2)!.split('@');

        if (cmd == 'NODE' && args.length >= 4) {
          final label = args[0];
          final id = args[1];
          final parentId = args[2] == 'null' ? null : args[2];
          final iconPath = args[3] == 'null' ? null : args[3];
          await diagramState.addNodeWithParent(
            id: id,
            label: label,
            type: NodeType.resource,
            parentId: parentId,
            iconPath: iconPath,
            snapshot: false,
          );
        } else if (cmd == 'GROUP' && args.length >= 3) {
          final label = args[0];
          final id = args[1];
          final parentId = args[2] == 'null' ? null : args[2];
          await diagramState.addNodeWithParent(
            id: id,
            label: label,
            type: NodeType.group,
            parentId: parentId,
            snapshot: false,
          );
        } else if (cmd == 'EDGE' && args.length >= 2) {
          final fromId = args[0];
          final toId = args[1];
          // Strip markdown noise the AI sometimes wraps labels in (`*foo*`,
          // `"foo"`, `**foo**`). Mermaid renders pipe-labels literally so
          // these chars become visible artefacts on the edge.
          final raw = args.length > 2 ? args[2] : null;
          final label = raw
              ?.replaceAll(RegExp(r'^\*+|\*+$'), '')
              .replaceAll(RegExp(r'^"+|"+$'), '')
              .trim();
          diagramState.addEdge(fromId, toId,
              label: (label == null || label.isEmpty) ? null : label,
              snapshot: false);
        }
      }
    }
    if (foundCommands) {
      diagramState.rebuild();
    }
  }

  /// Extract Mermaid code from the AI response.
  ///
  /// Strategy: trust the LLM contract instead of fighting markdown with regex.
  /// The system prompt instructs the model to wrap output in
  /// `<DIAGRAM>...</DIAGRAM>` — we just substring between them. Falls back to
  /// the first ```...``` markdown fence (also via substring, no regex) for
  /// off-spec responses. If neither delimiter pair is present, return null
  /// and let the ReAct retry loop ask the model to comply.
  String? extractMermaidCode(String text) {
    final tagged = _between(text, '<DIAGRAM>', '</DIAGRAM>');
    if (tagged != null && tagged.isNotEmpty) return tagged;

    // Fallback: ```optional-lang\n...\n``` markdown fence (legacy / off-spec).
    final fenceStart = text.indexOf('```');
    if (fenceStart >= 0) {
      final afterOpen = text.substring(fenceStart + 3);
      final firstNl = afterOpen.indexOf('\n');
      if (firstNl >= 0) {
        final body = afterOpen.substring(firstNl + 1);
        final fenceEnd = body.indexOf('```');
        if (fenceEnd > 0) {
          final extracted = body.substring(0, fenceEnd).trim();
          if (extracted.isNotEmpty) return extracted;
        }
      }
    }

    return null;
  }

  String? _between(String text, String start, String end) {
    final i = text.indexOf(start);
    if (i < 0) return null;
    final j = text.indexOf(end, i + start.length);
    if (j <= i) return null;
    return text.substring(i + start.length, j).trim();
  }

  void clearConversation() {
    _history.clear();
    _messages
      ..clear()
      ..add(ChatMessage(
        text: 'Conversation cleared.',
        type: MessageType.ai,
      ));
    notifyListeners();
  }

  Future<void> tryRestoreFromCache() async {
    if (_status != AIModelStatus.idle) return;
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/$_kCacheFile');
      if (!await file.exists()) return;

      final idx = int.tryParse((await file.readAsString()).trim());
      if (idx == null || idx < 0 || idx >= gemmaModels.length) return;

      _selectedModelIndex = idx;
      _status = AIModelStatus.initializing;
      _messages
        ..clear()
        ..add(ChatMessage(
          text: 'Restoring ${gemmaModels[idx].name} from cache...',
          type: MessageType.ai,
        ));
      notifyListeners();

      final model = gemmaModels[idx];
      final inferenceModel = await FlutterGemma.getActiveModel(
        maxTokens: model.maxTokens,
        preferredBackend: PreferredBackend.gpu,
      );

      _chat = await inferenceModel.createChat(
        systemInstruction: _systemPrompt,
        isThinking: model.modelType == ModelType.gemma4,
        modelType: model.modelType,
        temperature: 1.0,
        topK: 64,
        topP: 0.95,
        tokenBuffer: 2048,
      );

      _status = AIModelStatus.ready;
      _messages
        ..clear()
        ..add(ChatMessage(
          text: '${model.name} restored. Ready!',
          type: MessageType.ai,
        ));
    } catch (e) {
      dev.log('[AIModelState] restore failed: $e');
      _status = AIModelStatus.idle;
      _messages
        ..clear()
        ..add(ChatMessage(
          text: 'Select a Gemma model and press Download to start.',
          type: MessageType.ai,
        ));
    }
    notifyListeners();
  }

  Future<void> _saveModelIndex() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/$_kCacheFile');
      await file.writeAsString('$_selectedModelIndex');
    } catch (e) {
      dev.log('[AIModelState] save index failed: $e');
    }
  }
}

/// Matches the opening keyword of every Mermaid diagram type we support.
/// Multi-line so it can find a header anywhere in a chat response.
final RegExp mermaidHeaderRegex = RegExp(
  r'^\s*('
  r'flowchart\s+(?:TD|LR|TB|BT|RL)|'
  r'graph\s+(?:TD|LR|TB|BT|RL)|'
  r'sequenceDiagram|'
  r'classDiagram(?:-v2)?|'
  r'stateDiagram(?:-v2)?|'
  r'erDiagram|'
  r'gantt|'
  r'gitGraph|'
  r'journey|'
  r'pie\b|'
  r'mindmap|'
  r'timeline|'
  r'quadrantChart|'
  r'xychart-beta|'
  r'sankey(?:-beta)?|'
  r'requirementDiagram|'
  r'C4Context|C4Container|C4Component|C4Dynamic|C4Deployment|'
  r'architecture-beta|'
  r'block(?:-beta)?|'
  r'packet(?:-beta)?|'
  r'treemap(?:-beta)?|'
  r'kanban|'
  r'radar(?:-beta)?|'
  r'fishbone|'
  r'ishikawa(?:-beta)?|'
  r'venn(?:-beta)?|'
  r'treeview|'
  r'treeView(?:-beta)?|'
  r'zenuml'
  r')',
  multiLine: true,
);
