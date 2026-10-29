/* =====================================================================
   build.sql
   Builds QuanLyTheVeDienTu from scratch and runs the tests.
   WARNING: drops and recreates QuanLyTheVeDienTu.

   1. Set root below to the absolute path of this database/ folder.
   2. SSMS: open this file, turn on Query > SQLCMD Mode, execute (F5).
      Terminal: sqlcmd -S <server> -E -I -f 65001 -i build.sql
      (-f 65001 reads the scripts as UTF-8 so Vietnamese text is kept.)
   ===================================================================== */

:setvar root "C:\path\to\it3090-database-project\database"
:on error exit

:r "$(root)\schema\01_create_database.sql"
:r "$(root)\schema\02_tables.sql"
:r "$(root)\schema\03_indexes_sequences.sql"
:r "$(root)\schema\04_triggers.sql"

:r "$(root)\procedures\01_functions.sql"
:r "$(root)\procedures\02_the.sql"
:r "$(root)\procedures\03_giao_dich.sql"
:r "$(root)\procedures\04_quet_the.sql"
:r "$(root)\procedures\05_van_hanh.sql"

:r "$(root)\views\01_bao_cao.sql"

:r "$(root)\seed\01_reference_data.sql"
:r "$(root)\seed\02_demo_activity.sql"

:r "$(root)\tests\01_test_business_rules.sql"
