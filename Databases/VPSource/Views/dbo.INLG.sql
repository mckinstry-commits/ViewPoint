SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INLG] as select a.* From bINLG a
GO
GRANT SELECT ON  [dbo].[INLG] TO [public]
GRANT INSERT ON  [dbo].[INLG] TO [public]
GRANT DELETE ON  [dbo].[INLG] TO [public]
GRANT UPDATE ON  [dbo].[INLG] TO [public]
GO
