<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.41-02569B?logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/BLoC-9.1-blueviolet" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Windows-brightgreen" />
  <img src="https://img.shields.io/badge/License-Proprietário-red" />
</p>

# 🚀 Performaz Mobile

**Gestão de vendas gamificada para distribuidoras de alimentos.**

Performaz é um aplicativo mobile que transforma a rotina do vendedor externo em uma experiência gamificada. O app combina gestão de rotas, pedidos e check-ins com um sistema de XP, conquistas e ranking — motivando a equipe enquanto o gestor monitora tudo em tempo real.

---

## 📋 Índice

- [Funcionalidades](#-funcionalidades)
- [Arquitetura](#-arquitetura)
- [Tech Stack](#-tech-stack)
- [Estrutura de Pastas](#-estrutura-de-pastas)
- [Pré-requisitos](#-pré-requisitos)
- [Instalação e Execução](#-instalação-e-execução)
- [Design System](#-design-system)
- [Fluxos Principais](#-fluxos-principais)
- [Mock Data](#-mock-data--apresentação)
- [Roadmap](#-roadmap)
- [Autores](#-autores)

---

## ✨ Funcionalidades

### 👤 Vendedor (Mobile)
| Módulo | Descrição |
|--------|-----------|
| **Rota do Dia** | Lista de clientes para visitar, com status colorido (pendente/visitado/sem venda/concluído) e reordenação por drag & drop |
| **Check-in** | Registro de visita com geolocalização e foto comprobatória |
| **Catálogo de Produtos** | Busca com filtros por categoria, adição rápida ao carrinho |
| **Carrinho & Pedidos** | Gestão de itens, observações e confirmação com persistência offline (Drift) |
| **Visita sem Venda** | Registro de motivo (cliente fechado, sem interesse, etc.) via API |
| **Gamificação** | Dashboard com nível, XP, barra de progresso animada, pontuação diária/semanal |
| **Conquistas** | 6 tipos de badges com animação de desbloqueio (confetti) |
| **Ranking** | Leaderboard com pódio visual, filtro por XP ou faturamento |
| **Perfil** | Visualização e edição de dados do vendedor |

### 📊 Gestor (Painel)
| Módulo | Descrição |
|--------|-----------|
| **Dashboard** | KPIs em tempo real: vendedores ativos, receita, meta da equipe, pedidos do dia + gráfico semanal |
| **Mapa ao Vivo** | Posições dos vendedores em mapa interativo (flutter_map + OpenStreetMap) |
| **Metas** | Definição e acompanhamento de metas por vendedor (receita + positivação) |
| **Notificações** | Envio de avisos para vendedores individuais ou toda a equipe |
| **Rotas** | Construção visual de rotas — arrastar clientes para vendedores |
| **CRUD** | Gestão completa de Clientes, Produtos e Vendedores com busca, filtros e toolbar |

---

## 🏗 Arquitetura

O projeto segue a arquitetura **Feature-First** com separação clara de camadas:

```
┌──────────────────────────────────────────────┐
│                    UI Layer                   │
│   Screens (StatelessWidget / StatefulWidget)  │
├──────────────────────────────────────────────┤
│               State Management                │
│        BLoC / Cubit (flutter_bloc)            │
├──────────────────────────────────────────────┤
│               Domain / Data                   │
│  Repositories → ApiClient (Dio) + LocalDB     │
├──────────────────────────────────────────────┤
│              Infrastructure                   │
│  Drift (SQLite) · GetIt (DI) · GoRouter       │
└──────────────────────────────────────────────┘
```

### Padrões utilizados

- **BLoC/Cubit** — gerenciamento de estado reativo
- **Repository Pattern** — abstração entre UI e fonte de dados
- **Offline-First** — pedidos e check-ins salvos localmente (Drift/SQLite) e sincronizados via `SyncService`
- **Dependency Injection** — via `GetIt` + `injectable`
- **Shell Routes** — `GoRouter` com shells separados para vendedor e gestor

---

## 🛠 Tech Stack

| Categoria | Tecnologia | Versão |
|-----------|------------|--------|
| Framework | Flutter | 3.41.7 |
| Linguagem | Dart | 3.11.5 |
| Estado | flutter_bloc | 9.1.0 |
| Navegação | go_router | 15.1.2 |
| HTTP | Dio | 5.8.0 |
| DB Local | Drift (SQLite) | 2.25.0 |
| DI | get_it + injectable | 8.0.3 |
| Mapas | flutter_map + latlong2 | 7.0.2 |
| Gráficos | fl_chart | 0.70.2 |
| Firebase | firebase_core + messaging | 3.12.1 |
| Localização | geolocator | 13.0.2 |
| Tipografia | google_fonts | 6.2.1 |

---

## 📁 Estrutura de Pastas

```
lib/
├── app/                          # Configuração do app
│   ├── app.dart                  # MaterialApp + providers
│   ├── di.dart                   # Injeção de dependências (GetIt)
│   ├── router.dart               # GoRouter — todas as rotas
│   ├── shell/
│   │   ├── seller_shell.dart     # Bottom nav do vendedor
│   │   └── manager_shell.dart    # Sidebar do gestor
│   └── theme/
│       ├── app_colors.dart       # Paleta OKLCH → sRGB (Indigo + Purple)
│       ├── app_radius.dart       # Escala de border-radius
│       ├── app_theme.dart        # ThemeData (light + dark)
│       └── app_typography.dart   # Tipografia (Inter via Google Fonts)
│
├── core/                         # Infraestrutura
│   ├── auth/
│   │   ├── auth_bloc.dart        # Autenticação (login/logout/check)
│   │   └── auth_repository.dart  # Persistência de token
│   ├── network/
│   │   ├── api_client.dart       # Dio wrapper com interceptors
│   │   └── interceptors/        # Auth, logging, retry
│   ├── repositories/
│   │   ├── gamification_repository.dart
│   │   └── manager_repository.dart
│   ├── storage/
│   │   └── local_database.dart   # Drift — tabelas offline
│   └── sync/
│       └── sync_service.dart     # Sincronização offline → API
│
├── features/                     # Módulos de funcionalidade
│   ├── auth/                     # Login, esqueci senha, perfil
│   ├── gamification/             # Dashboard, conquistas, ranking
│   ├── manager/                  # Dashboard gestor, mapa, metas, CRUD
│   │   └── crud/                 # Clientes, produtos, vendedores
│   ├── orders/                   # Catálogo, carrinho, resumo, sem-venda
│   └── routes/                   # Rota do dia, check-in, detalhe do cliente
│
└── shared/                       # Componentes reutilizáveis
    ├── models/                   # User, Product, Order, Route, Achievement
    └── widgets/                  # AppCard, DotGridBackground, StatCard, etc.
```

---

## 📦 Pré-requisitos

- **Flutter** 3.41+ ([instalação](https://docs.flutter.dev/get-started/install))
- **Dart** 3.11+
- **Git**
- **Visual Studio** (para build Windows) ou **Android Studio** (para Android)

---

## 🚀 Instalação e Execução

```bash
# 1. Clone o repositório
git clone https://github.com/RenanDiniz21/performaz-mobile.git
cd performaz-mobile

# 2. Instale as dependências
flutter pub get

# 3. Gere os arquivos do Drift (banco local)
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Execute o app
flutter run -d windows    # Desktop
flutter run -d chrome      # Web (limitado)
flutter run                # Android/iOS conectado
```

### 🔐 Login de teste (sem backend)

| Campo | Valor |
|-------|-------|
| E-mail | `teste@performaz.com` |
| Senha | `123456` |

> ⚠️ Este login é um bypass temporário para apresentação. Em produção, será substituído pela autenticação via API.

---

## 🎨 Design System

O app utiliza um design system baseado na paleta **Indigo + Purple** do frontend web da Performaz, convertida de OKLCH para sRGB:

| Token | Light | Dark | Uso |
|-------|-------|------|-----|
| **Primary** | `#4F62D4` | `#7B8FE8` | Botões, links, destaques |
| **Background** | `#FAFAFA` | `#151520` | Fundo principal |
| **Card** | `#FFFFFF` | `#1E1F32` | Cards e containers |
| **XP Gold** | `#F59E0B` | `#FBBF24` | XP, conquistas, streaks |
| **Destructive** | `#DC2626` | `#EF4444` | Erros e ações destrutivas |

### Componentes visuais

- **`AppCard`** — card padronizado com borda, sombra e suporte a tema
- **`DotGridBackground`** — fundo pontilhado sutil para telas de conteúdo
- **`StatCard`** — card de métrica com ícone, valor e tendência
- **`StatusDot`** — indicador de status com animação de pulso

---

## 🔄 Fluxos Principais

### Fluxo de Pedido (Vendedor)
```
Rota do Dia → Selecionar Cliente → Check-in (GPS + foto)
    ↓
Catálogo de Produtos → Adicionar ao Carrinho → Resumo do Pedido
    ↓
Confirmar → Salvo offline (Drift) → SyncService envia para API
```

### Fluxo de Visita sem Venda
```
Rota do Dia → Selecionar Cliente → "Sem Venda"
    ↓
Selecionar motivo (RadioGroup) → Observações → Registrar via API
```

### Fluxo de Autenticação
```
Login Screen → AuthBloc → AuthRepository → API / Bypass mock
    ↓
Vendedor → SellerShell (bottom nav)
Gestor   → ManagerShell (sidebar)
```

---

## 🎭 Mock Data — Apresentação

Todas as telas utilizam **dados mock** para funcionar sem backend. Cada cubit/BLoC que usa mock está marcado com o comentário padrão:

```dart
// ════════════════════════════════════════════════════════════════════
// 🚧 MOCK — dados falsos para apresentação.
//    Para integrar com a API real:
//    1. Descomente a linha com _repository.método()
//    2. Remova o Future.delayed e o _buildMock*()
//    3. Rode: flutter pub get && dart run build_runner build
// ════════════════════════════════════════════════════════════════════
```

### Dados mock disponíveis

| Tela | Dados |
|------|-------|
| Rota do Dia | 5 clientes com status variados |
| Gamificação | XP 4750, nível 12, 3 conquistas, 5 eventos XP |
| Ranking | 8 vendedores, usuário em 3º lugar |
| Conquistas | 4 desbloqueadas + 2 bloqueadas |
| Dashboard (Gestor) | 12 vendedores, R$18.450 receita, 73% meta |
| Mapa ao Vivo | 5 posições mock em São Paulo |
| Metas | 5 vendedores com metas e progresso |
| Notificações | 3 vendedores + 2 notificações históricas |
| Rotas Builder | 6 vendedores + 20 clientes |

---

## 🗺 Roadmap

- [x] Design system Indigo/Purple (OKLCH)
- [x] Autenticação com bypass para testes
- [x] Rota do dia com reordenação
- [x] Fluxo completo de pedidos (catálogo → carrinho → resumo)
- [x] Visita sem venda
- [x] Gamificação (dashboard + conquistas + ranking)
- [x] Painel do gestor (dashboard + mapa + metas + CRUD)
- [x] Persistência offline com Drift
- [x] SyncService para sincronização
- [x] Mock data para todas as telas
- [ ] Integração com API real
- [ ] Push notifications (Firebase Cloud Messaging)
- [ ] Relatórios PDF/CSV
- [ ] Testes unitários e de integração
- [ ] Deploy na Play Store / App Store

---

## 👥 Autores

| Nome | GitHub |
|------|--------|
| Renan Diniz | [@RenanDiniz21](https://github.com/RenanDiniz21) |
| Diego | Colaborador |

---

## 📄 Licença

Este projeto é de uso **proprietário** — desenvolvido como Trabalho de Graduação (TG) na FATEC.

---

<p align="center">
  <b>Performaz</b> — Transformando vendas em conquistas 🏆
</p>
