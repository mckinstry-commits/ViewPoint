CREATE TABLE [dbo].[vfrl_attr_value]
(
[entity_num] [int] NOT NULL,
[attr_type] [tinyint] NOT NULL,
[cat_code] [nvarchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[attr_value] [nvarchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[last_updated] [datetime] NOT NULL
) ON [PRIMARY]
GO
