# MovieStream demo with Edition-Based Redefinition (EBR)

MovieStream is a streaming-style sample workload that demonstrates how to run
multi-edition rollouts on Oracle Autonomous Database using Liquibase. This
README walks through the assets in this directory and how to run the demo end
to end.

- See it in action (demo on YouTube): [https://www.youtube.com/watch?v=RkhtkfmI7-I](https://www.youtube.com/watch?v=RkhtkfmI7-I)

## Requirements

- Infrastructure provisioned via [`../../terraform-stacks/ebr-terraform`](../../terraform-stacks/ebr-terraform/README.md)
  (the stack creates the database, compute host, wallet copy, and supporting resources)
- Wallet of the Autonomous Database saved next to this README as
  `adb_wallet.zip`
- Recent `SQLcl` (21.4+ recommended) with Liquibase integration enabled
- Optional: `tmux` if you want to follow the scripted multi-pane experience in
  `run.txt` / `run_bigger.txt`

The Terraform stack is self-contained: it deploys its own VCN and does not
depend on the landing-zone modules in the repo root.

## Directory layout

```
ebr-moviestream/
├── initial_setup/         # bootstrap scripts for the MOVIESTREAM schema
├── changes/               # Liquibase changelog hierarchy (base + editions)
├── insert_app/            # Python data loaders used during the demo
├── run.txt                # compact tmux script
├── run_bigger.txt         # extended tmux script
└── README.md              # this file
```

### Initial setup

The `initial_setup` folder contains two important scripts:

- `moviestream_main.sql` — creates the `MOVIESTREAM` schema, grants all
  necessary privileges (editions, REST, Graph, ML, DBMS_REDEFINITION, helper
  procedures), and loads the LiveLabs MovieStream dataset.
- `reset_edition.sql` — reinitializes edition metadata and helper procedures so
  the environment can be replayed from a clean state.

Typical bootstrap flow (values based on `run.txt`):

```bash
cd misc-labs/ebr-online/ebr-moviestream/initial_setup
export WALLET=$HOME/Wallet_<ADB_OCID>.zip
sql -cloudconfig $WALLET admin/<ADMIN_PASSWORD>@<ADB_SERVICE>
  SQL> @reset_edition
  SQL> @moviestream_main
  Enter value for 1 (MOVIESTREAM password): Welcome#Welcome#123
  Enter value for 5 (log path): ./
  Enter value for 6 (connect string): <ADB_SERVICE>
```

The script drops/recreates the user, enables editions, sets up REST endpoints,
and preloads all base tables / editioning views shipped under
`changes/moviestream.000.base`.

### Liquibase changelog hierarchy

- `changes/moviestream.000.base.xml` — contains hundreds of generated includes
  that define the base tables (`customer$0`, `movie$0`, `genre$0`, …), views,
  external tables, indexes, constraints, and helper PL/SQL objects.
- `changes/moviestream.002.v2.xml` — illustrates an editioned rollout where the
  `customer` domain gains geography-aware data. Key change steps:
  - Create edition `V2` and switch the session (`moviestream.0001/0002`)
  - Introduce `continents$0` / `countries$0` base tables and their editioning
    views (`moviestream.0003`–`0007`)
  - Patch country codes (Serbia) and add FK relationships to `customer$0`
  - Update the `customer` editioning view plus forward/reverse cross-edition
    triggers so legacy code keeps working
  - `moviestream.0010`–`0012` finalize the view and trigger enablement
- `changes/moviestream.003.v2_post_rollout.xml` — demonstrates post-rollout
  cleanup:
  - Force sessions into `V2`, call `admin.default_edition('V2')`
  - Drop the previous edition via `admin.drop_edition`
  - Remove cross-edition triggers once traffic has migrated
  - Redefine `customer$0` using DBMS_REDEFINITION to physically remove the old
    `country` column and rely only on `country_code`

`changes/main.xml` can include each phase sequentially when you want an
all-in-one `lb update`, while the run books typically execute the edition
changelogs individually for storytelling clarity.

### Data loaders (`insert_app`)

- `insert_app/v1/insert_data.py` — simulates the legacy application issuing DML
  against edition `V0`.
- `insert_app/v2/insert_data.py` — simulates the modernized application that
  targets edition `V2` and the new geography model.

The scripts connect using `oracledb` (thick mode) and expect the wallet path to
be available in the environment (see `run.txt`). They are run in parallel panes
to showcase how cross-edition triggers keep both applications consistent during
the rollout.

## Demo flow (summary of `run.txt`)

1. **Reset & bootstrap (optional)**
   - `sql` as ADMIN → `@reset_edition`, `@moviestream_main`
   - Validate editions via `user_objects_ae` / `dba_editions`
2. **Baseline inspection**
   - Connect as `moviestream` (edition `V0`)
   - `DESC customer`, `DESC customer$0`, sample data (shows `country` text field)
3. **Stage the V2 release**
   - In `changes/`, run `lb status -changelog-file moviestream.00002.edition_v2.xml`
   - Browse SQL files if desired (`cat moviestream.00002.edition_v2/moviestream.000*`)
   - Launch `insert_app/v1/insert_data.py` to simulate legacy load
   - Execute `lb update -changelog-file moviestream.00002.edition_v2.xml`
   - Verify session edition, new tables/views, run joins between `customer`,
     `countries`, `continents`
4. **Switch traffic to V2**
   - Optionally start `insert_app/v2/insert_data.py`
   - Call `admin.default_edition('V2')` (or use helper procedure packaged in
     changelog 003)
5. **Post-rollout cleanup**
   - `lb status/update` with `moviestream.00003.edition_v2_post_rollout.xml`
   - Confirm `customer$0` was redefined and only `country_code` remains
6. **Close demo**
   - Stop data loader scripts, exit SQL sessions / tmux panes.

`run_bigger.txt` contains the same steps with more narration, tmux layout
commands, and pauses suitable for recorded demos.

## Tips

- Use `rlwrap sql /nolog` while developing to keep command history.
- All SQL examples in `run.txt` expect `set cloudconfig ../adb_wallet.zip` (or
  `$WALLET` exported ahead of time).
- Liquibase commands (`lb status`, `lb update`) must be executed from within
  SQLcl once connected as `MOVIESTREAM`.
- If you plan to re-run the demo frequently, keep `insert_app` panes ready so
  you can start/stop the Python generators quickly.

Enjoy building zero-downtime rollouts with EBR!