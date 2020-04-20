SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[PMContractChangeOrderCommit] as select a.* From vPMContractChangeOrderCommit a


GO
GRANT SELECT ON  [dbo].[PMContractChangeOrderCommit] TO [public]
GRANT INSERT ON  [dbo].[PMContractChangeOrderCommit] TO [public]
GRANT DELETE ON  [dbo].[PMContractChangeOrderCommit] TO [public]
GRANT UPDATE ON  [dbo].[PMContractChangeOrderCommit] TO [public]
GO
