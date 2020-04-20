CREATE TABLE [dbo].[vfrl_attr_category]
(
[entity_num] [int] NOT NULL,
[attr_type] [tinyint] NOT NULL,
[cat_num] [tinyint] NOT NULL,
[cat_code] [nvarchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[zoom] [tinyint] NOT NULL,
[data_type] [tinyint] NOT NULL,
[last_updated] [datetime] NOT NULL
) ON [PRIMARY]
GO
