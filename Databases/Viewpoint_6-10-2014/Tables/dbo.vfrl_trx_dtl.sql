CREATE TABLE [dbo].[vfrl_trx_dtl]
(
[entity_num] [int] NOT NULL,
[fiscal_year] [smallint] NOT NULL,
[per_num] [smallint] NOT NULL,
[acct_code] [char] (128) COLLATE Latin1_General_BIN NOT NULL,
[curr_code] [char] (3) COLLATE Latin1_General_BIN NOT NULL,
[book_code] [char] (20) COLLATE Latin1_General_BIN NOT NULL,
[dr_cr_flag] [tinyint] NOT NULL,
[amt_nat] [money] NOT NULL,
[amt_funct] [money] NOT NULL,
[adj_trx] [tinyint] NOT NULL,
[trx_desc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[date_applied] [smalldatetime] NOT NULL,
[last_updated] [smalldatetime] NOT NULL,
[amt_rpt01] [money] NULL,
[attr01] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[attr02] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[attr03] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[delta_id] [int] NOT NULL IDENTITY(51207, 1)
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [XIE2frl_trx_dtl] ON [dbo].[vfrl_trx_dtl] ([acct_code], [date_applied], [entity_num]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [XIE1frl_trx_dtl] ON [dbo].[vfrl_trx_dtl] ([acct_code], [per_num], [fiscal_year], [entity_num]) ON [PRIMARY]
GO
