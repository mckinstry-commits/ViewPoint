CREATE TABLE [dbo].[vfrl_acct_code]
(
[entity_num] [int] NOT NULL,
[acct_code] [char] (60) COLLATE Latin1_General_BIN NOT NULL,
[seg01_code] [char] (20) COLLATE Latin1_General_BIN NULL,
[seg02_code] [char] (20) COLLATE Latin1_General_BIN NULL,
[seg03_code] [char] (20) COLLATE Latin1_General_BIN NULL,
[seg04_code] [char] (20) COLLATE Latin1_General_BIN NULL,
[seg05_code] [char] (20) COLLATE Latin1_General_BIN NULL,
[seg06_code] [char] (20) COLLATE Latin1_General_BIN NULL,
[acct_desc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[acct_type] [varchar] (16) COLLATE Latin1_General_BIN NULL,
[normal_bal_rule] [tinyint] NOT NULL,
[acct_status] [tinyint] NOT NULL,
[last_updated] [smalldatetime] NOT NULL,
[rollup_level] [tinyint] NOT NULL,
[attr01] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[attr02] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[attr03] [varchar] (20) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [XPKfrl_acct_code] ON [dbo].[vfrl_acct_code] ([acct_code], [entity_num]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [XIE1frl_acct_code] ON [dbo].[vfrl_acct_code] ([seg01_code], [seg02_code], [seg03_code], [entity_num], [acct_code], [acct_status], [rollup_level]) ON [PRIMARY]
GO
