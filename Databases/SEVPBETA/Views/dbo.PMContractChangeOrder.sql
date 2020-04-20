SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[PMContractChangeOrder] as select a.* From vPMContractChangeOrder a


GO
GRANT SELECT ON  [dbo].[PMContractChangeOrder] TO [public]
GRANT INSERT ON  [dbo].[PMContractChangeOrder] TO [public]
GRANT DELETE ON  [dbo].[PMContractChangeOrder] TO [public]
GRANT UPDATE ON  [dbo].[PMContractChangeOrder] TO [public]
GO
