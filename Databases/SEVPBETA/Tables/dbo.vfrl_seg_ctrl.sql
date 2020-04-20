CREATE TABLE [dbo].[vfrl_seg_ctrl]
(
[entity_num] [int] NOT NULL,
[seg_num] [tinyint] NOT NULL,
[seg_desc] [nvarchar] (60) COLLATE Latin1_General_BIN NULL,
[seg_start_pos] [tinyint] NOT NULL,
[seg_length] [tinyint] NOT NULL,
[last_updated] [datetime] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [PK_frl_seg_ctrl] ON [dbo].[vfrl_seg_ctrl] ([entity_num], [seg_num]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
