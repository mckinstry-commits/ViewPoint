SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE     view [dbo].[RPFDc] as select a.* From dbo.vRPFDc a








GO
GRANT SELECT ON  [dbo].[RPFDc] TO [public]
GRANT INSERT ON  [dbo].[RPFDc] TO [public]
GRANT DELETE ON  [dbo].[RPFDc] TO [public]
GRANT UPDATE ON  [dbo].[RPFDc] TO [public]
GO
