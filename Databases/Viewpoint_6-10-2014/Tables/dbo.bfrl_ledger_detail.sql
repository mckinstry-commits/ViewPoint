CREATE TABLE [dbo].[bfrl_ledger_detail]
(
[ledg_criteria_id] [int] NULL,
[row_number] [int] NOT NULL,
[acct_code] [char] (64) COLLATE Latin1_General_BIN NOT NULL,
[negsign] [tinyint] NULL,
[acct_id] [int] NULL,
[acct_group] [tinyint] NULL,
[ledger_set] [int] NULL,
[acct_desc] [varchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
