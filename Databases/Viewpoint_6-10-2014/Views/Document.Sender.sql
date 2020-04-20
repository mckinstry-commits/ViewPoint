SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Document].[Sender]
	AS SELECT * FROM Document.[vSender]
GO
GRANT SELECT ON  [Document].[Sender] TO [public]
GRANT INSERT ON  [Document].[Sender] TO [public]
GRANT DELETE ON  [Document].[Sender] TO [public]
GRANT UPDATE ON  [Document].[Sender] TO [public]
GO
