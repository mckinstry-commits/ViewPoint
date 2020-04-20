CREATE TABLE [dbo].[vfrl_seg_tree]
(
[entity_num] [int] NOT NULL,
[seg_num] [tinyint] NOT NULL,
[parent_code] [nchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[child_low] [nchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[child_high] [nchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[is_parent] [tinyint] NOT NULL,
[last_updated] [datetime] NOT NULL
) ON [PRIMARY]
GO
