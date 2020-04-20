CREATE TABLE [dbo].[bfrl_ledger_master]
(
[ledg_criteria_id] [int] NOT NULL,
[spec_set] [char] (32) COLLATE Latin1_General_BIN NULL,
[row_format] [char] (32) COLLATE Latin1_General_BIN NULL,
[rptng_tree] [char] (32) COLLATE Latin1_General_BIN NULL,
[h_code] [char] (32) COLLATE Latin1_General_BIN NULL,
[last_update] [datetime] NULL,
[being_built] [smallint] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [bifrl_ledger_mast] ON [dbo].[bfrl_ledger_master] ([ledg_criteria_id]) ON [PRIMARY]
GO
