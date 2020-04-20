CREATE TABLE [dbo].[vDDLHc]
(
[Lookup] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Title] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[FromClause] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[WhereClause] [varchar] (512) COLLATE Latin1_General_BIN NULL,
[JoinClause] [varchar] (512) COLLATE Latin1_General_BIN NULL,
[OrderByColumn] [tinyint] NULL,
[Memo] [varchar] (1024) COLLATE Latin1_General_BIN NULL,
[GroupByClause] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[Version] [tinyint] NOT NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [viDDLHc] ON [dbo].[vDDLHc] ([Lookup]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
