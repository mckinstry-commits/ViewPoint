CREATE TABLE [dbo].[vfrl_seg_code]
(
[entity_num] [int] NOT NULL,
[seg_num] [tinyint] NOT NULL,
[seg_code] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[seg_code_desc] [nvarchar] (60) COLLATE Latin1_General_BIN NULL,
[is_parent] [tinyint] NOT NULL,
[email] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[last_updated] [datetime] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [PK_frl_seg_code] ON [dbo].[vfrl_seg_code] ([entity_num], [seg_num], [seg_code]) ON [PRIMARY]
GO
