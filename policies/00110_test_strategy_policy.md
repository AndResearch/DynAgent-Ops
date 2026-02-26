# テスト方針と深化ステップ

## 目的

DynAgentの品質を最優先にし、重要領域から深くテストを整備する。自動テストを徹底し、失敗許容度は低く（厳格に）運用する。

## 抽象方針（決定済み）

- 品質最優先
- 自動化は徹底
- 失敗許容度は低い（厳格）
- 重要領域から深く

## 位置づけ（テストピラミッド）

AIは内部実装の変更が起きやすいため、**契約テストを最重要**とする。E2Eは手動検証書に従う運用とし、自動化では契約・単体・統合を厚くする。

## テスト設計の前提

- **契約テスト**: 外部境界（CLI/設定/DBスキーマ/ツールAPI/ワークフロー定義）を固定化する。
- **単体テスト**: 純粋ロジックと副作用境界の内側を自動で徹底検証する。
- **統合テスト**: DBやI/Oなど、実体を使う境界連携を最小構成で検証する。

## 深化ステップ（重要領域から深く）

1. **境界の確定と契約化**
   - 重要I/Fの一覧化（CLI、設定、DBスキーマ、ツール、ワークフロー）
   - 期待入出力を固定化（スナップショット/JSONスキーマ/ゴールデンファイル）
   - 破壊的変更が起きた場合に即検知できる状態を作る

2. **単体テストの基盤整備**
   - テスト共通基盤（fixtures、モック方針、タイムアウト）を先に確立
   - 重要領域の純粋ロジックから優先して網羅
   - 例外系・境界値の集中カバレッジ

3. **統合テストの最小セット**
   - DB接続・マイグレーション・永続化の最小経路
   - ファイルI/O・CLI実行の最小経路
   - レースや非同期処理の最小検証

4. **回帰強化**
   - 重要バグは必ずテストで再発防止
   - 重要領域の契約テストを拡張
   - テスト失敗時の診断情報を強化

5. **適用範囲の拡大**
   - 単体テストの補完（重要→周辺）
   - 統合テストの補完（複合経路）
   - 手動E2E検証書とのギャップを縮小

## 運用ルール（厳格）

- PR段階で契約テスト + 単体テストを必須
- 失敗時は修正が完了するまで先へ進めない
- 重要領域から先に整備し、周辺は段階的に拡張する

## 実装フロー（標準）

1. 仕様変更
2. コード実装
3. テスト実装
4. pytestで全て通るまでコードとテストを反復
5. `scripts/update-test-strategy.py` を実行
6. git commit

## 重要領域の具体一覧（契約テスト対象）

- CLIインターフェース（コマンド/オプション/終了コード/標準出力）
- 設定ロード（環境変数・設定ファイルの優先順位）
- DBスキーマ（マイグレーション結果と主要テーブル）
- セッション管理（開始/終了/再開の状態遷移）
- プロジェクトファイル管理（生成/更新/削除の契約）
- ツールAPI（tool registryと組み込みツールの入力/出力）
- LLMアダプタI/F（プロバイダ切替時のリクエスト形）
- MCPアダプタI/F（接続テストとツール一覧）
- ワークフロー定義I/F（読み込み/検証/実行順序）
- リカバリ/バックアップ（保存/復元の入出力）

## 統合テストの最小シナリオ

1. **CLI最小経路**
   - `dynagent version` の成功と出力フォーマット固定
   - `dynagent new` で最小プロジェクト生成（テンプレートの存在確認）

2. **DB最小経路**
   - DB初期化 → マイグレーション適用 → 主要テーブルへのCRUD

3. **ツール最小経路**
   - ツール登録 → built-in file tool の read/write → 結果検証

4. **ワークフロー最小経路**
   - 定義ロード → 検証 → スタブ実行（I/Oだけ確認）

5. **バックアップ最小経路**
   - バックアップ作成 → 生成ファイルの存在と最小内容確認

## テスト実装の着手順（Worklog/requests から抽出）

重要領域から深く着手し、契約→単体→統合の順で展開する。

1. **境界確定と契約テスト**
   - `Worklog/requests/00010_Project_Scaffolding_and_Entry_Points.md`
   - `Worklog/requests/00020_Configuration_System.md`
   - `Worklog/requests/00030_Database_Infrastructure_SQLite_MVP.md`
   - `Worklog/requests/00040_SQLAlchemy_Models.md`
   - `Worklog/requests/00210_CLI_Commands.md`

2. **単体テストの重点領域**
   - `Worklog/requests/00050_Session_Management.md`
   - `Worklog/requests/00060_Project_File_Management.md`
   - `Worklog/requests/00070_Activity_Tracker.md`
   - `Worklog/requests/00080_Cost_Tracker_and_Budget_Control.md`
   - `Worklog/requests/00090_Tool_System_Base_and_Registry.md`

3. **統合テストの重点領域**
   - `Worklog/requests/00100_Built_in_File_Tools.md`
   - `Worklog/requests/00110_Built_in_Git_Tools.md`
   - `Worklog/requests/00120_Built_in_Code_Execution_Tools.md`
   - `Worklog/requests/00140_LLM_Adapter_and_Providers.md`
   - `Worklog/requests/00150_MCP_Adapter_and_Manager.md`
   - `Worklog/requests/00190_Workflow_Engine_and_Definitions.md`

4. **運用系の回帰強化**
   - `Worklog/requests/00200_CLI_UI_Layout_and_Panels.md`
   - `Worklog/requests/00220_Slash_Commands.md`
   - `Worklog/requests/00230_Recovery_Manager.md`
   - `Worklog/requests/00240_Backup_Manager.md`
   - `Worklog/requests/00250_GCP_Deploy_Integration.md`
   - `Worklog/requests/00330_CLI_Delete_Command.md`

## 単体テスト（重点領域）

- [x] 00050 Session Management: `tests/unit/test_session_manager.py`
- [x] 00060 Project File Management: `tests/unit/test_project_manager.py`
- [x] 00070 Activity Tracker: `tests/unit/test_activity_tracker.py`
- [x] 00080 Cost Tracker and Budget Control: `tests/unit/test_cost_tracker.py`
- [x] 00090 Tool System Base and Registry: `tests/unit/test_tool_registry.py`
- [x] 00200 CLI UI Layout and Panels: `tests/unit/test_cli_ui.py`
- [x] 00220 Slash Commands: `tests/unit/test_slash_commands.py`
- [x] 00230 Recovery Manager: `tests/unit/test_recovery_manager.py`
- [x] 00240 Backup Manager: `tests/unit/test_backup_manager.py`
- [x] 00250 GCP Deploy Integration: `tests/unit/test_gcp_deploy_manager.py`

## 統合テスト（重点領域）

- [x] 00100 Built-in File Tools: `tests/integration/test_file_tools_integration.py`
- [x] 00110 Built-in Git Tools: `tests/integration/test_git_tools_integration.py`
- [x] 00120 Built-in Code Execution Tools: `tests/integration/test_code_tools_integration.py`
- [x] 00140 LLM Adapter and Providers: `tests/integration/test_llm_adapter_integration.py`
- [x] 00150 MCP Adapter and Manager: `tests/integration/test_mcp_adapter_integration.py`
- [x] 00190 Workflow Engine and Definitions: `tests/integration/test_workflow_engine_integration.py`
- [x] CLI Delete Command: `tests/integration/test_delete_cli_integration.py`

## テスト実行結果

- 2026-01-26: `pytest tests/integration/test_delete_cli_integration.py` (pass)
- 2026-01-26: `pytest` (pass)

## 契約テスト

### 00010 Project Scaffolding and Entry Points

- [x] TC-SCAFFOLD-001: CLIヘルプに主要コマンドが列挙される。  
- [x] TC-SCAFFOLD-002: `dynagent version` がパッケージ版を返す。  
- [x] TC-SCAFFOLD-003: `import dynagent` が成功する。

### 00020 Configuration System

- [x] TC-CONFIG-001: Settings がデフォルトを適用する。  
- [x] TC-CONFIG-002: TOMLが環境変数より優先される。  
- [x] TC-CONFIG-003: 不正値はバリデーションエラーになる。

### 00030 Database Infrastructure (SQLite MVP)

- [x] TC-DB-001: SQLite URLがAsyncに正規化される。  
- [x] TC-DB-002: 非同期セッションでクエリ実行できる。  
- [x] TC-DB-003: GUIDがSQLiteで往復できる。

### 00040 SQLAlchemy Models

- [x] TC-MODEL-001: 主要モデルがBase.metadataに登録される。  
- [x] TC-MODEL-002: 主要制約（PK/UNIQUE/FK/INDEX）が定義される。  
- [x] TC-MODEL-003: 必須カラムがnull不可で定義される。

### 00210 CLI Commands

- [x] TC-CLI-001: `new --help` が起動し必須引数を表示する。  
- [x] TC-CLI-002: `chat --help` が起動し主要オプションを表示する。  
- [x] TC-CLI-003: `config llm/mcp --help` が起動する。  
- [x] TC-CLI-004: `list/show/export --help` が起動する。  
- [x] TC-CLI-005: 未知コマンドで非0終了とエラー表示。

<!-- BEGIN TEST SPECS -->
## 契約テスト一覧（自動生成）

- `TC-CLI-001`: `new --help` runs and shows required arguments. (`tests/contract/test_cli_contract.py::test_new_help`)
- `TC-CLI-002`: `chat --help` runs and shows primary options. (`tests/contract/test_cli_contract.py::test_chat_help`)
- `TC-CLI-003`: `config llm/mcp --help` runs and shows subcommand help. (`tests/contract/test_cli_contract.py::test_config_llm_mcp_help`)
- `TC-CLI-004`: `list/show/export --help` runs successfully. (`tests/contract/test_cli_contract.py::test_list_show_export_help`)
- `TC-CLI-005`: Unknown commands exit non-zero and report an error. (`tests/contract/test_cli_contract.py::test_unknown_command_fails`)
- `TC-CONFIG-001`: Settings use defaults when no configuration is provided. (`tests/contract/test_config_contract.py::test_settings_defaults`)
- `TC-CONFIG-002`: Config file values override environment variables. (`tests/contract/test_config_contract.py::test_config_file_overrides_env`)
- `TC-CONFIG-003`: Invalid default LLM provider triggers validation errors. (`tests/contract/test_config_contract.py::test_invalid_default_llm_provider_raises`)
- `TC-DB-001`: SQLite URLs normalize to async driver URLs. (`tests/contract/test_db_contract.py::test_normalize_async_url_sqlite`)
- `TC-DB-002`: Async sessions can execute simple queries against SQLite. (`tests/contract/test_db_contract.py::test_async_session_executes`)
- `TC-DB-003`: GUID values round-trip through SQLite models. (`tests/contract/test_db_contract.py::test_guid_roundtrip_sqlite`)
- `TC-MODEL-001`: Core persistence models are registered in metadata. (`tests/contract/test_models_contract.py::test_models_registered_in_metadata`)
- `TC-MODEL-002`: Primary constraints (PK/UNIQUE/FK/INDEX/CHECK) are defined on key tables. (`tests/contract/test_models_contract.py::test_core_constraints_defined`)
- `TC-MODEL-003`: Required columns are marked non-nullable on core tables. (`tests/contract/test_models_contract.py::test_required_columns_non_nullable`)
- `TC-SCAFFOLD-001`: CLI help lists the core command surface. (`tests/contract/test_scaffolding_contract.py::test_cli_help_lists_core_commands`)
- `TC-SCAFFOLD-002`: `dynagent version` returns the package version string. (`tests/contract/test_scaffolding_contract.py::test_version_command_matches_package_version`)
- `TC-SCAFFOLD-003`: Package is importable and exposes a version. (`tests/contract/test_scaffolding_contract.py::test_package_importable`)
<!-- END TEST SPECS -->
