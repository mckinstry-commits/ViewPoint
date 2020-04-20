SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE view [dbo].[PMContractChangeOrderACO] as select a.* From vPMContractChangeOrderACO a





GO
GRANT SELECT ON  [dbo].[PMContractChangeOrderACO] TO [public]
GRANT INSERT ON  [dbo].[PMContractChangeOrderACO] TO [public]
GRANT DELETE ON  [dbo].[PMContractChangeOrderACO] TO [public]
GRANT UPDATE ON  [dbo].[PMContractChangeOrderACO] TO [public]
GO
