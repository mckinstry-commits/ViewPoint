CREATE TABLE [dbo].[vfrl_per_bal]
(
[entity_num] [int] NOT NULL,
[fiscal_year] [smallint] NOT NULL,
[per_num] [smallint] NOT NULL,
[acct_code] [char] (128) COLLATE Latin1_General_BIN NOT NULL,
[curr_code] [char] (3) COLLATE Latin1_General_BIN NOT NULL,
[book_code] [char] (20) COLLATE Latin1_General_BIN NOT NULL,
[amt_nat_dr] [money] NOT NULL,
[amt_nat_cr] [money] NOT NULL,
[amt_funct_dr] [money] NOT NULL,
[amt_funct_cr] [money] NOT NULL,
[last_updated] [smalldatetime] NOT NULL,
[amt_rpt01_dr] [money] NULL,
[amt_rpt01_cr] [money] NULL,
[amt_bucket01] [money] NULL,
[delta_id] [int] NOT NULL IDENTITY(14783, 1)
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [XPKfrl_per_bal] ON [dbo].[vfrl_per_bal] ([acct_code], [per_num], [fiscal_year], [book_code], [curr_code], [entity_num]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [XPK1frl_per_bal] ON [dbo].[vfrl_per_bal] ([book_code], [entity_num], [fiscal_year], [per_num], [acct_code]) ON [PRIMARY]
GO
