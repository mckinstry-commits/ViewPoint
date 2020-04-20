SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMRFIResponse] as select a.* From vPMRFIResponse a
GO
GRANT SELECT ON  [dbo].[PMRFIResponse] TO [public]
GRANT INSERT ON  [dbo].[PMRFIResponse] TO [public]
GRANT DELETE ON  [dbo].[PMRFIResponse] TO [public]
GRANT UPDATE ON  [dbo].[PMRFIResponse] TO [public]
GO
