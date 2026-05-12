import 'package:flutter/material.dart';

enum TemplateCategory {
  architecture,
  flows,
  data,
  planning,
  knowledge,
}

extension TemplateCategoryX on TemplateCategory {
  String get label {
    switch (this) {
      case TemplateCategory.architecture: return 'Architecture & Systems';
      case TemplateCategory.flows: return 'Flows & Sequences';
      case TemplateCategory.data: return 'Data & Analytics';
      case TemplateCategory.planning: return 'Planning & Process';
      case TemplateCategory.knowledge: return 'Knowledge & Analysis';
    }
  }
}

class PromptTemplate {
  final String id;
  final IconData icon;
  final String title;
  final String diagramType; // shown as a small badge
  final String subtitle;    // 1-line context (services / topic)
  final String prompt;      // full text dispatched to Gemma
  final TemplateCategory category;

  const PromptTemplate({
    required this.id,
    required this.icon,
    required this.title,
    required this.diagramType,
    required this.subtitle,
    required this.prompt,
    required this.category,
  });
}

const List<PromptTemplate> kPromptTemplates = [
  // ── Architecture & Systems ─────────────────────────────────────────────────
  PromptTemplate(
    id: 'gcp-3tier',
    icon: Icons.dns_outlined,
    title: '3-tier HA web app',
    diagramType: 'flowchart',
    subtitle: 'LB · Cloud Run · Cloud SQL',
    category: TemplateCategory.architecture,
    prompt:
        'Draw a 3-tier highly available web application on Google Cloud. Output ONLY a '
        'Mermaid flowchart, starting with `flowchart TD` on its own line — do not include '
        'any title or text on the same line as the header, and do not output prose before '
        'or after the diagram. Structure: an external HTTPS Load Balancer at the top, then '
        'Cloud Run services in two regions (us-central1 and us-east1) as parallel paths, '
        'each connected to a shared regional HA Cloud SQL Postgres, Memorystore Redis, and '
        'Secret Manager. Use `subgraph` blocks to group services by region. Label every edge '
        'with what flows on it (e.g., "HTTPS", "JDBC", "cache", "secret lookup").',
  ),
  PromptTemplate(
    id: 'gcp-signup-flow',
    icon: Icons.account_tree_outlined,
    title: 'User signup flow',
    diagramType: 'flowchart',
    subtitle: 'Identity Platform · Firestore',
    category: TemplateCategory.architecture,
    prompt:
        'Create a flowchart of a user signup and email-verification flow on GCP: '
        'browser → Identity Platform → Cloud Run signup handler → Firestore user document → '
        'Pub/Sub welcome-email topic → Cloud Function sending email via SendGrid.',
  ),
  PromptTemplate(
    id: 'gcp-c4-context',
    icon: Icons.hub_outlined,
    title: 'C4 context — order platform',
    diagramType: 'C4Context',
    subtitle: 'Actors and external systems',
    category: TemplateCategory.architecture,
    prompt:
        'Draw a C4Context diagram for an order management platform on Google Cloud: '
        'customers, ops team, payment gateway (Stripe), shipping API (FedEx), '
        'and the central system on Cloud Run with BigQuery analytics.',
  ),
  PromptTemplate(
    id: 'gcp-region-blocks',
    icon: Icons.grid_view_outlined,
    title: 'Region & zone layout',
    diagramType: 'block',
    subtitle: 'Multi-zone GKE deployment',
    category: TemplateCategory.architecture,
    prompt:
        'Output ONLY a `block` diagram (NOT `block-beta`, NOT `architecture-beta`) of a '
        'multi-zone GCP deployment. Use `columns 3`. First a wide region header `region["us-central1 Region"]:3`. '
        'Then 3 zone containers side-by-side: `block:zoneA["Zone A"]:1` containing `gke_a["GKE Pool A"]` and `end`; '
        'similarly zoneB/gke_b and zoneC/gke_c. Then 2 wide shared services: `lb["Regional Load Balancer"]:3` '
        'and `sql[("Regional Cloud SQL")]:3`. Finally arrows `gke_a --> lb`, `gke_b --> lb`, `gke_c --> lb`, '
        '`gke_a --> sql`, `gke_b --> sql`, `gke_c --> sql`. NO icons in parens, NO ports.',
  ),
  PromptTemplate(
    id: 'gcp-class-domain',
    icon: Icons.schema_outlined,
    title: 'E-commerce domain model',
    diagramType: 'classDiagram',
    subtitle: 'Customer · Order · Product',
    category: TemplateCategory.architecture,
    prompt:
        'Draw a classDiagram for an e-commerce domain backed by Cloud Spanner: '
        'Customer, Address, Order, OrderItem, Product, Inventory, with attributes, '
        'key methods, and the relationships between them (composition, aggregation).',
  ),
  PromptTemplate(
    id: 'gcp-er-orders',
    icon: Icons.table_chart_outlined,
    title: 'Cloud SQL schema',
    diagramType: 'erDiagram',
    subtitle: 'Orders · customers · items',
    category: TemplateCategory.architecture,
    prompt:
        'Draw an erDiagram for an order management schema on Cloud SQL Postgres: '
        'customers, addresses, orders, order_items, products, inventory, with primary keys, '
        'foreign keys, and cardinalities.',
  ),

  // ── Flows & Sequences ──────────────────────────────────────────────────────
  PromptTemplate(
    id: 'gcp-oauth',
    icon: Icons.swap_horiz_outlined,
    title: 'OAuth login flow',
    diagramType: 'sequenceDiagram',
    subtitle: 'Identity Platform · JWT',
    category: TemplateCategory.flows,
    prompt:
        'Draw a sequenceDiagram for an OAuth 2.0 login flow on Google Cloud: '
        'browser → Cloud Run app → Identity Platform → Google Identity Provider → '
        'callback to Cloud Run → Firestore session document → JWT issued back to browser.',
  ),
  PromptTemplate(
    id: 'gcp-pubsub-zenuml',
    icon: Icons.bolt_outlined,
    title: 'Pub/Sub event delivery',
    diagramType: 'zenuml',
    subtitle: 'Event-driven order pipeline',
    category: TemplateCategory.flows,
    prompt:
        'Draw a zenuml sequence of an event-driven order on GCP: '
        'API Gateway → Cloud Run → Pub/Sub topic → Cloud Function subscriber → '
        'BigQuery streaming insert → Cloud Tasks → email notification.',
  ),
  PromptTemplate(
    id: 'gcp-job-state',
    icon: Icons.repeat_outlined,
    title: 'Cloud Run Job lifecycle',
    diagramType: 'stateDiagram-v2',
    subtitle: 'Pending · Running · Done',
    category: TemplateCategory.flows,
    prompt:
        'Draw a stateDiagram-v2 for the lifecycle of a Cloud Run Job execution: '
        'Pending → Running → (Succeeded | Failed | Cancelled), '
        'including retry transitions and a terminal Done state.',
  ),
  PromptTemplate(
    id: 'gcp-deploy-journey',
    icon: Icons.directions_walk_outlined,
    title: 'First deploy to Cloud Run',
    diagramType: 'journey',
    subtitle: 'Developer onboarding journey',
    category: TemplateCategory.flows,
    prompt:
        'Draw a journey diagram of a developer\'s first deploy to Cloud Run: '
        'install gcloud, run gcloud init, build the container with Cloud Build, '
        'push to Artifact Registry, deploy with gcloud run deploy, hit the public URL — '
        'rate the satisfaction at each step.',
  ),

  // ── Data & Analytics ───────────────────────────────────────────────────────
  PromptTemplate(
    id: 'gcp-sankey-pipeline',
    icon: Icons.alt_route_outlined,
    title: 'Analytics data flow',
    diagramType: 'sankey',
    subtitle: 'Pub/Sub → BigQuery → Looker',
    category: TemplateCategory.data,
    prompt:
        'Output ONLY a `sankey` diagram (NOT `sankey-beta`) of a GCP analytics pipeline. '
        'No reasoning, no prose. Header is `sankey` then a blank line then CSV rows '
        '`Source,Target,Value` (no header row, no quotes, no spaces around commas). '
        'Use these exact 6 flows: '
        'Pub/Sub,Dataflow,1000 — '
        'Dataflow,BigQuery raw,1000 — '
        'BigQuery raw,BigQuery curated,800 — '
        'BigQuery curated,Looker,500 — '
        'BigQuery curated,Vertex AI,300 — '
        'BigQuery raw,Cloud Storage,200',
  ),
  PromptTemplate(
    id: 'gcp-xy-requests',
    icon: Icons.show_chart,
    title: 'Cloud Run requests trend',
    diagramType: 'xychart-beta',
    subtitle: 'Monthly request growth',
    category: TemplateCategory.data,
    prompt:
        'Draw an xychart-beta titled "Cloud Run requests by month" with x-axis Jan through Dec '
        'and y-axis "requests (millions)" showing growth from 2 to 18 million across the year.',
  ),
  PromptTemplate(
    id: 'gcp-pie-cost',
    icon: Icons.pie_chart_outline,
    title: 'GCP monthly cost split',
    diagramType: 'pie',
    subtitle: 'Spend by service',
    category: TemplateCategory.data,
    prompt:
        'Draw a pie chart titled "GCP monthly cost split" with: Compute Engine 35, '
        'Cloud Storage 12, BigQuery 22, Cloud SQL 15, Networking 10, Other 6.',
  ),
  PromptTemplate(
    id: 'gcp-treemap-spend',
    icon: Icons.dashboard_customize_outlined,
    title: 'Spend by service category',
    diagramType: 'treemap',
    subtitle: 'Compute · Data · Storage · Net',
    category: TemplateCategory.data,
    prompt:
        'Draw a treemap of GCP spend grouped by category: Compute (Compute Engine, Cloud Run, GKE), '
        'Data (BigQuery, Cloud SQL, Spanner), Storage (GCS, Filestore), '
        'and Networking (Load Balancer, CDN, Interconnect), with realistic monthly dollar amounts.',
  ),
  PromptTemplate(
    id: 'gcp-radar-providers',
    icon: Icons.track_changes_outlined,
    title: 'GCP vs AWS vs Azure',
    diagramType: 'radar-beta',
    subtitle: 'Multi-criteria comparison',
    category: TemplateCategory.data,
    prompt:
        'Draw a radar-beta diagram comparing Google Cloud, AWS, and Azure across these axes: '
        'Pricing, Documentation quality, ML and AI maturity, Networking, '
        'Compliance certifications, and Open-source friendliness.',
  ),
  PromptTemplate(
    id: 'gcp-quadrant-services',
    icon: Icons.scatter_plot_outlined,
    title: 'GCP services: latency vs cost',
    diagramType: 'quadrantChart',
    subtitle: 'Compute · Storage · Database',
    category: TemplateCategory.data,
    prompt:
        'Draw a quadrantChart titled "GCP services by latency and cost". '
        'X-axis goes from Low Latency to High Latency. Y-axis goes from Low Cost to High Cost. '
        'Plot these services with realistic [x, y] coordinates: Cloud Functions, '
        'Cloud Run, GKE, Compute Engine, Cloud SQL, Spanner, BigQuery, and Firestore.',
  ),

  // ── Planning & Process ─────────────────────────────────────────────────────
  PromptTemplate(
    id: 'aws-to-gcp-gantt',
    icon: Icons.swap_horizontal_circle_outlined,
    title: 'AWS → GCP migration roadmap',
    diagramType: 'gantt',
    subtitle: '12-week migration plan',
    category: TemplateCategory.planning,
    prompt:
        'Draw a gantt chart titled "AWS → GCP migration — Q3 2026" with these sections: '
        'Discovery (audit current AWS workloads, dependency mapping), '
        'Build (landing zone, IAM, shared VPC, networking), '
        'Migrate (RDS → Cloud SQL via DMS, EC2 → Compute Engine via Migrate to Containers, '
        'S3 → GCS via Storage Transfer, Lambdas → Cloud Functions), '
        'Cutover (DNS swap, validation, rollback drills), '
        'and Decommission (shut down AWS resources, final billing reconciliation). '
        'Show 12 weeks of timeline with realistic task durations.',
  ),
  PromptTemplate(
    id: 'gcp-migration-kanban',
    icon: Icons.view_kanban_outlined,
    title: 'Migration sprint board',
    diagramType: 'kanban',
    subtitle: 'AWS to GCP tasks',
    category: TemplateCategory.planning,
    prompt:
        'Draw a kanban board titled "GCP migration sprint" with columns Backlog, In Progress, '
        'Blocked, and Done, populated with realistic tasks like: "IAM mapping", '
        '"Set up shared VPC", "Move RDS to Cloud SQL", "Migrate Lambdas to Cloud Functions", '
        '"Update CI/CD to Cloud Build", "Enable VPC Service Controls".',
  ),
  PromptTemplate(
    id: 'gcp-cloudbuild-git',
    icon: Icons.account_tree,
    title: 'Cloud Build branching',
    diagramType: 'gitGraph',
    subtitle: 'Trunk-based with Cloud Build',
    category: TemplateCategory.planning,
    prompt:
        'Draw a gitGraph for a trunk-based development workflow: main branch, '
        'one feature branch that merges back into main, a release tag on main, '
        'and a hotfix branch off main that merges back. Use simple commit IDs like '
        '"feat-1", "rel-1", "hot-1" — every commit id and tag value MUST be a quoted string.',
  ),
  PromptTemplate(
    id: 'gcp-timeline',
    icon: Icons.timeline,
    title: 'GCP launches timeline',
    diagramType: 'timeline',
    subtitle: 'Major products 2008–2026',
    category: TemplateCategory.planning,
    prompt:
        'Draw a timeline titled "Major Google Cloud launches" with: '
        '2008 App Engine, 2010 Cloud Storage, 2012 BigQuery, 2014 Kubernetes open-sourced, '
        '2015 GCP general availability, 2018 Cloud Run, 2019 Anthos, 2021 Vertex AI, '
        '2024 Gemini API on Vertex AI.',
  ),

  // ── Knowledge & Analysis ───────────────────────────────────────────────────
  PromptTemplate(
    id: 'gcp-mindmap',
    icon: Icons.lightbulb_outline,
    title: 'GCP service catalog',
    diagramType: 'mindmap',
    subtitle: 'Compute · Data · AI · Storage',
    category: TemplateCategory.knowledge,
    prompt:
        'Draw a mindmap centered on "Google Cloud" with main branches Compute '
        '(Compute Engine, GKE, Cloud Run, Cloud Functions), Data (BigQuery, Spanner, '
        'Cloud SQL, Firestore), Storage (GCS, Filestore, Persistent Disk), '
        'AI (Vertex AI, Gemini, Document AI), and DevOps (Cloud Build, Artifact Registry, '
        'Cloud Deploy).',
  ),
  PromptTemplate(
    id: 'gcp-org-tree',
    icon: Icons.account_tree_rounded,
    title: 'GCP organization hierarchy',
    diagramType: 'flowchart',
    subtitle: 'Org · Folders · Projects',
    category: TemplateCategory.knowledge,
    prompt:
        'Draw a `flowchart TD` representing a typical GCP organization hierarchy. '
        'Top: a single node "Organization". Below it, three folder nodes: '
        '"Production folder", "Staging folder", "Sandbox folder", connected from '
        'Organization. Below Production: leaf nodes "web-prod" and "data-prod". '
        'Below Staging: "web-staging". Below Sandbox: "dev-personal-1" and '
        '"dev-personal-2". Use rounded rectangles `(...)` for folders and regular '
        'rectangles `[...]` for projects.',
  ),
  PromptTemplate(
    id: 'gcp-compliance-req',
    icon: Icons.verified_outlined,
    title: 'Compliance requirements',
    diagramType: 'requirementDiagram',
    subtitle: 'SOC2 · PCI · GDPR on GCP',
    category: TemplateCategory.knowledge,
    prompt:
        'Draw a requirementDiagram for a SaaS on Google Cloud. CRITICAL FORMAT: indent every '
        'block 4 spaces; put a blank line between each `requirement {}` block, between requirements '
        'and elements, and between elements and relationships. `risk:` accepts ONLY `low`, '
        '`medium`, `high` (NEVER `critical`). Always quote the `text:` value. '
        'Three requirements: R1 with text "SOC 2 - data encrypted at rest" (risk high), satisfied '
        'by element CloudKMS; R2 with text "PCI-DSS - segregated card data network" (risk high), '
        'satisfied by element VPCServiceControls; R3 with text "GDPR - EU data residency" '
        '(risk medium), satisfied by element EURegions. Use `verifymethod: test` for each.',
  ),
  PromptTemplate(
    id: 'gcp-fishbone',
    icon: Icons.linear_scale,
    title: 'Migration delays — root cause',
    diagramType: 'flowchart',
    subtitle: 'Why is the migration slipping?',
    category: TemplateCategory.knowledge,
    prompt:
        'Draw a `flowchart LR` structured like an Ishikawa fishbone diagram. '
        'Center: a single node "AWS to GCP migration is behind schedule". '
        'Branch six category nodes from it: People, Process, Tools, Data, Network, Budget. '
        'Under each category, branch 3 concrete sub-cause leaves specific to a cloud '
        'migration (e.g., People → "Lack of GCP expertise", "High SME turnover", '
        '"Insufficient cross-team collaboration"). Use clear short labels.',
  ),
  PromptTemplate(
    id: 'gcp-venn-providers',
    icon: Icons.bubble_chart_outlined,
    title: 'Cloud provider service overlap',
    diagramType: 'venn-beta',
    subtitle: 'AWS ∩ GCP ∩ Azure',
    category: TemplateCategory.knowledge,
    prompt:
        'Output ONLY a `venn-beta` diagram (NOT `venn`, NOT `flowchart`). Use this exact structure: '
        'header `venn-beta` then `title "Cloud provider services"` then three `set` lines '
        '(`set AWS`, `set GCP`, `set Azure`) then four `union` lines: '
        '`union AWS,GCP,Azure["Object Storage (S3 / GCS / Blob)"]`, '
        '`union AWS,GCP["Functions"]`, `union AWS,Azure["Enterprise DB"]`, '
        '`union GCP,Azure["Kubernetes (GKE / AKS)"]`. NO subgraph, NO arrows, NO flowchart syntax.',
  ),
  PromptTemplate(
    id: 'gcp-vpc-packet',
    icon: Icons.dns,
    title: 'IPv4 packet through VPC',
    diagramType: 'packet',
    subtitle: 'Header layout · bit ranges',
    category: TemplateCategory.knowledge,
    prompt:
        'Draw a `packet` diagram (NOT `packet-beta`) of an IPv4 header (160 bits total). '
        'Use the syntax `start-end: "Label"`, with sequential non-overlapping bit ranges '
        'starting at 0. NO flowchart syntax. Fields: Version (4 bits), IHL (4), ToS (8), '
        'Total Length (16), Identification (16), Flags (3), Fragment Offset (13), TTL (8), '
        'Protocol (8), Header Checksum (16), Source IP (32), Destination IP (32).',
  ),
];
